import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/battle_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/battle_provider.dart';
import '../../widgets/game_grid.dart';
import '../../widgets/game_header.dart';
import '../../widgets/opponent_mini_grid.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final battleProvider = context.watch<BattleProvider>();
    final session = battleProvider.session;
    final board = battleProvider.board;
    final gameState = battleProvider.gameState;
    final userId = authProvider.firebaseUser?.uid;

    if (session == null || board == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Battle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final opponent = session.getOpponent(userId ?? '');

    // Check for game end
    if (session.status == BattleStatus.finished && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameEndDialog(context, session, userId);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (session.status == BattleStatus.finished) {
          battleProvider.reset();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Battle'),
          automaticallyImplyLeading: false,
          actions: [
            if (session.status == BattleStatus.finished)
              TextButton(
                onPressed: () {
                  battleProvider.reset();
                  Navigator.pop(context);
                },
                child: const Text('Exit'),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Game header with timer
              Padding(
                padding: const EdgeInsets.all(8),
                child: GameHeader(
                  mineCount: board.remainingMines,
                  elapsedSeconds: gameState.elapsedSeconds,
                  status: gameState.status,
                  onRestart: () {}, // No restart in battle
                ),
              ),

              // Opponent mini grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OpponentMiniGrid(
                  opponent: opponent,
                  difficulty: session.difficulty,
                ),
              ),

              const SizedBox(height: 8),

              // Your grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GameGrid(
                    board: board,
                    gameOver: gameState.isGameOver ||
                        session.status == BattleStatus.finished,
                    onCellTap: (row, col) {
                      if (userId != null) {
                        battleProvider.revealCell(row, col, userId);
                      }
                    },
                    onCellLongPress: (row, col) {
                      if (userId != null) {
                        battleProvider.toggleFlag(row, col, userId);
                      }
                    },
                  ),
                ),
              ),

              // Instructions
              Padding(
                padding: const EdgeInsets.all(8),
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
        ),
      ),
    );
  }

  void _showGameEndDialog(
    BuildContext context,
    BattleSession session,
    String? userId,
  ) {
    final won = session.winnerId == userId;
    final isDraw = session.winnerId == null;

    String title;
    String message;
    String emoji;

    if (isDraw) {
      title = 'Draw!';
      message = 'Both players hit a mine!';
      emoji = '🤝';
    } else if (won) {
      title = 'Victory!';
      message = 'You cleared the board first!';
      emoji = '🏆';
    } else {
      title = 'Defeat';
      message = 'Your opponent finished first.';
      emoji = '😢';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BattleProvider>().reset();
              Navigator.pop(context);
            },
            child: const Text('Back to Lobby'),
          ),
        ],
      ),
    );
  }
}
