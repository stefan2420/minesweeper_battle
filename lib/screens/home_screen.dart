import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_board.dart';
import '../providers/auth_provider.dart';
import 'game_screen.dart';
import 'battle/lobby_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minesweeper Battle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Leaderboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message
              Text(
                'Welcome, ${user?.displayName ?? 'Player'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (user != null)
                Text(
                  'Battle Wins: ${user.stats.battleWins} | Games Won: ${user.stats.gamesWon}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 48),

              // Battle Mode Button
              _MenuButton(
                icon: Icons.flash_on,
                title: 'Battle Mode',
                subtitle: 'Challenge another player',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LobbyScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Single Player Section
              const Text(
                'Single Player',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _MenuButton(
                icon: Icons.looks_one,
                title: 'Beginner',
                subtitle: '9x9 grid, 10 mines',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GameScreen(
                        initialDifficulty: Difficulty.beginner,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              _MenuButton(
                icon: Icons.looks_two,
                title: 'Intermediate',
                subtitle: '16x16 grid, 40 mines',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GameScreen(
                        initialDifficulty: Difficulty.intermediate,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              _MenuButton(
                icon: Icons.looks_3,
                title: 'Expert',
                subtitle: '30x16 grid, 99 mines',
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GameScreen(
                        initialDifficulty: Difficulty.expert,
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Sign out button
              TextButton.icon(
                onPressed: () => authProvider.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
