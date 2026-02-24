import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/design_tokens.dart';
import '../providers/auth_provider.dart';
import '../utils/rank_tier_helper.dart';
import '../utils/level_helper.dart';
import '../services/config_service.dart';
import '../services/friends_service.dart';
import '../models/achievement.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import '../widgets/achievement_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendsService _friendsService = FriendsService();

  List<FriendModel> _friends = [];
  List<FriendModel> _pendingRequests = [];
  bool _friendsLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && _friends.isEmpty) {
        _loadFriends();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final userId = context.read<AuthProvider>().firebaseUser?.uid;
    if (userId == null) return;
    setState(() => _friendsLoading = true);
    final friends = await _friendsService.getFriends(userId);
    final pending = await _friendsService.getIncomingRequests(userId);
    setState(() {
      _friends = friends;
      _pendingRequests = pending;
      _friendsLoading = false;
    });
  }

  Future<void> _searchUsers(String query) async {
    final results = await _friendsService.searchUsersByName(query);
    setState(() => _searchResults = results);
  }

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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stats'),
            Tab(text: 'Achievements'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(context, user),
          _buildAchievementsTab(user),
          _buildFriendsTab(context, user),
        ],
      ),
    );
  }

  Widget _buildStatsTab(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gradient avatar based on rank tier
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.avatarGradient(user.stats.eloRating),
              boxShadow: [
                BoxShadow(
                  color: AppColors.avatarGradient(user.stats.eloRating)
                      .colors
                      .first
                      .withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
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
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            user.email,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // Level & XP Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LevelHelper.buildLevelBadge(level: user.stats.level, size: 48),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${user.stats.level}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            LevelHelper.getLevelTier(user.stats.level),
                            style: TextStyle(
                              fontSize: 14,
                              color: LevelHelper.getLevelColor(user.stats.level),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: LevelHelper.buildProgressBar(
                      totalXP: user.stats.totalXP,
                      height: 12,
                      showLabel: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total XP: ${LevelHelper.formatXP(user.stats.totalXP)}',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Battle Stats
          _buildStatSection(
            title: 'Battle Mode',
            icon: Icons.flash_on,
            color: Colors.orange,
            stats: [
              if (RankTierHelper.shouldShowQualifier(user.stats)) ...[
                _StatItem(
                  label: 'Status',
                  value: RankTierHelper.getQualifierProgress(
                    user.stats.rankedGamesPlayed,
                    ConfigService.instance.qualifierMatchCount,
                  ),
                  color: RankTierHelper.getQualifierColor(),
                ),
              ] else ...[
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
              ],
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
              _StatItem(label: 'Beginner', value: _formatTime(user.stats.bestTimes['beginner'])),
              _StatItem(label: 'Intermediate', value: _formatTime(user.stats.bestTimes['intermediate'])),
              _StatItem(label: 'Expert', value: _formatTime(user.stats.bestTimes['expert'])),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            'Member since ${_formatDate(user.createdAt)}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(UserModel user) {
    final unlocked = Set<String>.from(user.stats.unlockedAchievements);
    final all = Achievement.all;
    final unlockedCount = all.where((a) => unlocked.contains(a.id)).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '$unlockedCount / ${all.length} unlocked',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: all.length,
            itemBuilder: (context, index) {
              final achievement = all[index];
              return GestureDetector(
                onTap: () => _showAchievementDetail(achievement, unlocked.contains(achievement.id)),
                child: AchievementBadge(
                  achievement: achievement,
                  unlocked: unlocked.contains(achievement.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAchievementDetail(Achievement achievement, bool unlocked) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${achievement.icon} ${achievement.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(achievement.description),
            const SizedBox(height: 12),
            Text(
              unlocked ? 'Unlocked!' : 'Locked',
              style: TextStyle(
                color: unlocked ? AppColors.success : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(BuildContext context, UserModel user) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search players...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _searchUsers,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _searchUsers(_searchController.text),
                child: const Text('Search'),
              ),
            ],
          ),
        ),

        // Search results
        if (_searchResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Search Results', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          ..._searchResults.map((u) => ListTile(
                title: Text(u.displayName),
                subtitle: Text('Level ${u.stats.level}'),
                trailing: u.id == user.id
                    ? const Text('You')
                    : ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final name = u.displayName;
                          await _friendsService.sendRequest(
                            fromId: user.id,
                            fromDisplayName: user.displayName,
                            toId: u.id,
                            toDisplayName: name,
                          );
                          setState(() => _searchResults = []);
                          _searchController.clear();
                          messenger.showSnackBar(
                            SnackBar(content: Text('Friend request sent to $name')),
                          );
                        },
                        child: const Text('Add'),
                      ),
              )),
          const Divider(),
        ],

        if (_friendsLoading)
          const Center(child: CircularProgressIndicator())
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFriends,
              child: ListView(
                children: [
                  // Pending requests
                  if (_pendingRequests.isNotEmpty) ...[
                    const ListTile(
                      title: Text(
                        'Incoming Requests',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ..._pendingRequests.map((r) => ListTile(
                          title: Text(r.displayName),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () async {
                                  await _friendsService.acceptRequest(
                                    myId: user.id,
                                    requesterId: r.userId,
                                  );
                                  _loadFriends();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () async {
                                  await _friendsService.removeRelationship(
                                    myId: user.id,
                                    otherId: r.userId,
                                  );
                                  _loadFriends();
                                },
                              ),
                            ],
                          ),
                        )),
                    const Divider(),
                  ],

                  // Friends list
                  const ListTile(
                    title: Text(
                      'Friends',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_friends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No friends yet. Search for players above!',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._friends.map((f) => ListTile(
                          title: Text(f.displayName),
                          leading: const Icon(Icons.person),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove, color: Colors.red),
                            onPressed: () async {
                              await _friendsService.removeRelationship(
                                myId: user.id,
                                otherId: f.userId,
                              );
                              _loadFriends();
                            },
                          ),
                        )),
                ],
              ),
            ),
          ),
      ],
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
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
