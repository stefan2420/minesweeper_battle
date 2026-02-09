import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _seenInstructionsKey = 'seen_game_instructions';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().newGame(widget.initialDifficulty);
      _checkAndShowInstructions();
    });
  }

  /// Check if this is the first game and show instructions if needed
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
              context.read<GameProvider>().newGame(difficulty);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Difficulty.beginner,
                child: Text('Beginner (9x9)'),
              ),
              const PopupMenuItem(
                value: Difficulty.intermediate,
                child: Text('Intermediate (16x16)'),
              ),
              const PopupMenuItem(
                value: Difficulty.expert,
                child: Text('Expert (30x16)'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, _) {
          final board = gameProvider.board;
          final state = gameProvider.state;

          if (board == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check for game end
          if (state.status == GameStatus.won || state.status == GameStatus.lost) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showGameEndDialog(
                context,
                state.status == GameStatus.won,
                state.elapsedSeconds,
                gameProvider.difficulty,
              );
            });
          }

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GameHeader(
                    mineCount: gameProvider.remainingMines,
                    elapsedSeconds: state.elapsedSeconds,
                    status: state.status,
                    onRestart: () => gameProvider.newGame(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: GameGrid(
                      board: board,
                      gameOver: state.isGameOver,
                      onCellTap: (row, col) => gameProvider.revealCell(row, col),
                      onCellLongPress: (row, col) => gameProvider.toggleFlag(row, col),
                    ),
                  ),
                ),
                // Instructions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tap to reveal | Long press to flag',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _dialogShown = false;

  void _showGameEndDialog(
    BuildContext context,
    bool won,
    int time,
    Difficulty difficulty,
  ) {
    if (_dialogShown) return;
    _dialogShown = true;

    _onGameEnd(won, time, difficulty);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(won ? 'You Won!' : 'Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? '😎' : '😵',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              won
                  ? 'Completed in ${_formatTime(time)}'
                  : 'Better luck next time!',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _dialogShown = false;
              this.context.read<GameProvider>().newGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              _dialogShown = false;
            },
            child: const Text('Back to Menu'),
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
