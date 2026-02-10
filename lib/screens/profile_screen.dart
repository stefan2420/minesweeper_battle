import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/rank_tier_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _formatTime(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Display name
            Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user.email,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 32),

            // Battle Stats
            _buildStatSection(
              title: 'Battle Mode',
              icon: Icons.flash_on,
              color: Colors.orange,
              stats: [
                _StatItem(
                  label: 'Rating',
                  value: '${user.stats.eloRating}',
                  color: RankTierHelper.getTierColor(user.stats.eloRating),
                ),
                _StatItem(
                  label: 'Rank',
                  value: RankTierHelper.getTierName(user.stats.eloRating),
                ),
                _StatItem(
                  label: 'Peak Rating',
                  value: '${user.stats.peakEloRating}',
                ),
                _StatItem(label: 'Wins', value: '${user.stats.battleWins}'),
                _StatItem(label: 'Losses', value: '${user.stats.battleLosses}'),
                _StatItem(
                  label: 'Win Rate',
                  value: _calculateWinRate(
                    user.stats.battleWins,
                    user.stats.battleLosses,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Single Player Stats
            _buildStatSection(
              title: 'Single Player',
              icon: Icons.person,
              color: Colors.blue,
              stats: [
                _StatItem(label: 'Games Played', value: '${user.stats.gamesPlayed}'),
                _StatItem(label: 'Games Won', value: '${user.stats.gamesWon}'),
              ],
            ),

            const SizedBox(height: 24),

            // Best Times
            _buildStatSection(
              title: 'Best Times',
              icon: Icons.timer,
              color: Colors.green,
              stats: [
                _StatItem(
                  label: 'Beginner',
                  value: _formatTime(user.stats.bestTimes['beginner']),
                ),
                _StatItem(
                  label: 'Intermediate',
                  value: _formatTime(user.stats.bestTimes['intermediate']),
                ),
                _StatItem(
                  label: 'Expert',
                  value: _formatTime(user.stats.bestTimes['expert']),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Member since
            Text(
              'Member since ${_formatDate(user.createdAt)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<_StatItem> stats,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats.map((stat) {
                return Column(
                  children: [
                    Text(
                      stat.value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: stat.color,
                      ),
                    ),
                    Text(
                      stat.label,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateWinRate(int wins, int losses) {
    final total = wins + losses;
    if (total == 0) return '0%';
    return '${((wins / total) * 100).toStringAsFixed(1)}%';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatItem {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});
}
