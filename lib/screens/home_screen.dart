import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/design_tokens.dart';
import '../models/game_board.dart';
import '../providers/auth_provider.dart';
import '../providers/daily_challenge_provider.dart';
import '../services/daily_challenge_service.dart';
import '../widgets/game_instructions_dialog.dart';
import 'game_screen.dart';
import 'battle/lobby_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'daily_challenge_screen.dart';
import 'dev/dev_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _dailyStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      final userId = context.read<AuthProvider>().firebaseUser?.uid;
      final streak = await DailyChallengeService().getStreak(userId);
      if (mounted) setState(() => _dailyStreak = streak);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minesweeper Battle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How to Play',
            onPressed: () => GameInstructionsDialog.show(context),
          ),
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
          // Dev settings icon (only visible to dev/admin users)
          if (user?.isDev ?? false)
            IconButton(
              icon: const Icon(Icons.developer_mode),
              tooltip: 'Developer Settings',
              color: Colors.deepPurple,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DevSettingsScreen()),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
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
              const SizedBox(height: DesignTokens.spacingS),
              if (user != null)
                Text(
                  'Battle Wins: ${user.stats.battleWins} | Games Won: ${user.stats.gamesWon}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: DesignTokens.spacingXxl),

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

              const SizedBox(height: DesignTokens.spacingM),

              // Daily Challenge Button with streak badge
              _MenuButton(
                icon: Icons.today,
                title: 'Daily Challenge',
                subtitle: 'One board, everyone competes',
                color: const Color(0xFF7B1FA2),
                badge: _dailyStreak > 0
                    ? _StreakBadge(streak: _dailyStreak)
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => DailyChallengeProvider(),
                        child: const DailyChallengeScreen(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: DesignTokens.spacingM),

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
                title: Difficulty.beginner.displayName,
                subtitle: Difficulty.beginner.displayNameWithSize.split('(')[1].replaceAll(')', '') + ', 10 mines',
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

              const SizedBox(height: DesignTokens.spacingS),

              _MenuButton(
                icon: Icons.looks_two,
                title: Difficulty.intermediate.displayName,
                subtitle: Difficulty.intermediate.displayNameWithSize.split('(')[1].replaceAll(')', '') + ', 40 mines',
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

              const SizedBox(height: DesignTokens.spacingS),

              _MenuButton(
                icon: Icons.looks_3,
                title: Difficulty.expert.displayName,
                subtitle: Difficulty.expert.displayNameWithSize.split('(')[1].replaceAll(')', '') + ', 99 mines',
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
  final Widget? badge;

  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          badge!,
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flame + number badge showing the current daily challenge streak.
class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: AppColors.warning, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.warning, size: 14),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
