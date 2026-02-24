import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/design_tokens.dart';
import '../models/game_board.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../widgets/game_grid.dart';
import '../widgets/game_header.dart';
import '../widgets/game_instructions_dialog.dart';

class GameScreen extends StatefulWidget {
  final Difficulty initialDifficulty;

  const GameScreen({
    super.key,
    this.initialDifficulty = Difficulty.beginner,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final UserService _userService = UserService();
  late final ConfettiController _confettiController;
  static const String _seenInstructionsKey = 'seen_game_instructions';
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().newGame(widget.initialDifficulty);
      _checkAndShowInstructions();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkAndShowInstructions() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenInstructions = prefs.getBool(_seenInstructionsKey) ?? false;
    if (!hasSeenInstructions && mounted) {
      await GameInstructionsDialog.show(context);
      await prefs.setBool(_seenInstructionsKey, true);
    }
  }

  void _onGameEnd(bool won, int time, Difficulty difficulty) async {
    final userId = context.read<AuthProvider>().firebaseUser?.uid;
    if (userId == null) return;

    try {
      if (won) {
        await _userService
            .recordGameWin(userId, difficulty, time)
            .timeout(const Duration(seconds: 10));
      } else {
        await _userService
            .recordGameLoss(userId)
            .timeout(const Duration(seconds: 10));
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save timed out. Stats will sync later.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save stats: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minesweeper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How to Play',
            onPressed: () => GameInstructionsDialog.show(context),
          ),
          PopupMenuButton<Difficulty>(
            icon: const Icon(Icons.settings),
            tooltip: 'Difficulty',
            onSelected: (difficulty) {
              _dialogShown = false;
              context.read<GameProvider>().newGame(difficulty);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Difficulty.beginner,
                child: Text('Beginner (9×9)'),
              ),
              const PopupMenuItem(
                value: Difficulty.intermediate,
                child: Text('Intermediate (16×16)'),
              ),
              const PopupMenuItem(
                value: Difficulty.expert,
                child: Text('Expert (30×16)'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              final board = gameProvider.board;
              final state = gameProvider.state;

              if (board == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if ((state.status == GameStatus.won || state.status == GameStatus.lost) &&
                  !_dialogShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showGameEndDialog(
                    context,
                    state.status == GameStatus.won,
                    state.elapsedSeconds,
                    gameProvider.difficulty,
                    board,
                  );
                });
              }

              return SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(DesignTokens.spacingM),
                      child: GameHeader(
                        mineCount: gameProvider.remainingMines,
                        elapsedSeconds: state.elapsedSeconds,
                        status: state.status,
                        onRestart: () {
                          _dialogShown = false;
                          gameProvider.newGame();
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GameGrid(
                          board: board,
                          gameOver: state.isGameOver,
                          onCellTap: (row, col) {
                            final cell = board.getCell(row, col);
                            if (cell.isRevealed && cell.adjacentMines > 0) {
                              gameProvider.chordCell(row, col);
                            } else {
                              gameProvider.revealCell(row, col);
                            }
                          },
                          onCellLongPress: (row, col) => gameProvider.toggleFlag(row, col),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(DesignTokens.spacingM),
                      child: Text(
                        'Tap to reveal · Long press to flag',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Confetti burst aligned to top-center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.3,
              emissionFrequency: 0.05,
              colors: const [
                Color(0xFFFFD700),
                Color(0xFF1565C0),
                Color(0xFF2E7D32),
                Color(0xFFC62828),
                Color(0xFF9C27B0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGameEndDialog(
    BuildContext context,
    bool won,
    int time,
    Difficulty difficulty,
    dynamic board,
  ) {
    if (_dialogShown) return;
    _dialogShown = true;

    if (won) _confettiController.play();
    _onGameEnd(won, time, difficulty);

    final colors = Theme.of(context).colorScheme;

    // Compute accuracy (revealed non-mine cells / total non-mine cells)
    int totalSafe = 0;
    int revealedSafe = 0;
    try {
      for (var r = 0; r < board.rows; r++) {
        for (var c = 0; c < board.cols; c++) {
          final cell = board.getCell(r, c);
          if (!cell.hasMine) {
            totalSafe++;
            if (cell.isRevealed) revealedSafe++;
          }
        }
      }
    } catch (_) {}

    final accuracyPct = totalSafe > 0
        ? ((revealedSafe / totalSafe) * 100).toStringAsFixed(0)
        : '0';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              won ? '😎' : '😵',
              style: const TextStyle(fontSize: 40),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? 'Board Cleared!' : 'Better luck next time',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.spacingM,
                horizontal: DesignTokens.spacingS,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(
                    label: 'Time',
                    value: _formatTime(time),
                    icon: Icons.timer_rounded,
                    color: colors.primary,
                  ),
                  _StatChip(
                    label: 'Cleared',
                    value: '$accuracyPct%',
                    icon: Icons.grid_on_rounded,
                    color: won ? AppColors.success : colors.onSurfaceVariant,
                  ),
                  _StatChip(
                    label: 'Mode',
                    value: difficulty.displayName,
                    icon: Icons.tune_rounded,
                    color: colors.tertiary,
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _dialogShown = false;
              this.context.read<GameProvider>().newGame();
            },
            child: const Text('Play Again'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              _dialogShown = false;
            },
            child: const Text('Main Menu'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
