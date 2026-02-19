import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/daily_challenge_provider.dart';
import '../models/game_state.dart';
import '../widgets/game_grid.dart';
import '../widgets/game_header.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;
  bool _resultSubmitted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().firebaseUser?.uid;
      if (userId != null) {
        context.read<DailyChallengeProvider>().load(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(DailyChallengeProvider provider) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      provider.tick();
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyChallengeProvider>();
    final auth = context.watch<AuthProvider>();
    final userId = auth.firebaseUser?.uid;
    final user = auth.userModel;

    // Submit result when won
    if (provider.gameState.status == GameStatus.won &&
        !_resultSubmitted &&
        userId != null) {
      _resultSubmitted = true;
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await provider.submitResult(
          userId: userId,
          displayName: user?.displayName ?? 'Player',
        );
        if (mounted) _showResultDialog();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenge'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Play'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPlayTab(provider, userId),
                _buildLeaderboardTab(provider),
              ],
            ),
    );
  }

  Widget _buildPlayTab(DailyChallengeProvider provider, String? userId) {
    final board = provider.board;

    if (provider.alreadyCompleted && board == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Already completed today!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Check the leaderboard for your ranking.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('View Leaderboard'),
            ),
          ],
        ),
      );
    }

    if (board == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Daily Challenge',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Date: ${provider.challenge?.date ?? "loading..."}'),
            const SizedBox(height: 4),
            Text('Difficulty: ${provider.challenge?.difficulty ?? "intermediate"}'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Challenge'),
              onPressed: () {
                provider.startChallenge();
                _startTimer(provider);
              },
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: GameHeader(
              mineCount: board.remainingMines,
              elapsedSeconds: provider.gameState.elapsedSeconds,
              status: provider.gameState.status,
              onRestart: () {},
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GameGrid(
                board: board,
                gameOver: provider.gameState.isGameOver,
                onCellTap: (row, col) {
                  final cell = board.getCell(row, col);
                  if (cell.isRevealed && cell.adjacentMines > 0) {
                    provider.chordCell(row, col);
                  } else {
                    provider.revealCell(row, col);
                  }
                },
                onCellLongPress: (row, col) => provider.toggleFlag(row, col),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Tap to reveal | Long press to flag',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(DailyChallengeProvider provider) {
    final results = provider.leaderboard;
    if (results.isEmpty) {
      return const Center(child: Text('No results yet. Be the first!'));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results[index];
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(r.displayName),
          trailing: Text(_formatTime(r.completionTime)),
          subtitle: Text('+${r.xpEarned} XP'),
        );
      },
    );
  }

  void _showResultDialog() {
    final provider = context.read<DailyChallengeProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Challenge Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You finished in', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              _formatTime(provider.gameState.elapsedSeconds),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            if (provider.xpEarned != null) ...[
              const SizedBox(height: 8),
              Text(
                '+${provider.xpEarned} XP',
                style: const TextStyle(fontSize: 20, color: Colors.green),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(1);
            },
            child: const Text('View Leaderboard'),
          ),
        ],
      ),
    );
  }
}
