import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final UserService _userService = UserService();
  List<UserModel>? _leaders;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final leaders = await _userService.getLeaderboard();
      setState(() {
        _leaders = leaders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaders == null || _leaders!.isEmpty
              ? const Center(
                  child: Text('No players yet. Be the first!'),
                )
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaders!.length,
                    itemBuilder: (context, index) {
                      final user = _leaders![index];
                      return _buildLeaderCard(user, index + 1);
                    },
                  ),
                ),
    );
  }

  Widget _buildLeaderCard(UserModel user, int rank) {
    Color? medalColor;
    IconData? medalIcon;

    if (rank == 1) {
      medalColor = Colors.amber;
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      medalColor = Colors.grey.shade400;
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      medalColor = Colors.brown.shade300;
      medalIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: medalColor ?? Colors.blue.shade100,
          child: medalIcon != null
              ? Icon(medalIcon, color: Colors.white)
              : Text(
                  '$rank',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Games: ${user.stats.gamesPlayed} | Win rate: ${_calculateWinRate(user.stats)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${user.stats.battleWins}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Text(
              'wins',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateWinRate(UserStats stats) {
    final total = stats.battleWins + stats.battleLosses;
    if (total == 0) return '0%';
    return '${((stats.battleWins / total) * 100).toStringAsFixed(0)}%';
  }
}
