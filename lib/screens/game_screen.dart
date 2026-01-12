import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_board.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../widgets/game_grid.dart';
import '../widgets/game_header.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().newGame(widget.initialDifficulty);
    });
  }

  void _onGameEnd(bool won, int time, Difficulty difficulty) async {
    final userId = context.read<AuthProvider>().firebaseUser?.uid;
    if (userId == null) return;

    if (won) {
      await _userService.recordGameWin(userId, difficulty, time);
    } else {
      await _userService.recordGameLoss(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minesweeper'),
        actions: [
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
