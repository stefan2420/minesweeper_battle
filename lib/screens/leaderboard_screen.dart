import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/design_tokens.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../utils/rank_tier_helper.dart';
import '../utils/level_helper.dart';
import '../services/config_service.dart';

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
          ? _buildSkeleton()
          : _leaders == null || _leaders!.isEmpty
              ? const Center(child: Text('No players yet. Be the first!'))
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: ListView(
                    padding: const EdgeInsets.all(DesignTokens.spacingM),
                    children: _buildGroupedList(_leaders!),
                  ),
                ),
    );
  }

  /// Shimmer skeleton while loading
  Widget _buildSkeleton() {
    final colors = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHighest,
      highlightColor: colors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        itemCount: 10,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          ),
        ),
      ),
    );
  }

  /// Groups players by rank tier and inserts colored section headers.
  List<Widget> _buildGroupedList(List<UserModel> leaders) {
    final widgets = <Widget>[];
    String? currentTier;

    for (var i = 0; i < leaders.length; i++) {
      final user = leaders[i];
      final tierName = RankTierHelper.shouldShowQualifier(user.stats)
          ? 'Qualifier'
          : RankTierHelper.getTierName(user.stats.eloRating);

      if (tierName != currentTier) {
        currentTier = tierName;
        widgets.add(_buildTierHeader(tierName, user.stats.eloRating));
      }

      widgets.add(_buildLeaderCard(user, i + 1));
    }

    return widgets;
  }

  Widget _buildTierHeader(String tierName, int eloRating) {
    final isQualifier = tierName == 'Qualifier';
    final color = isQualifier
        ? AppColors.tierQualifier
        : RankTierHelper.getTierColor(eloRating);
    final icon = isQualifier
        ? RankTierHelper.getQualifierIcon()
        : RankTierHelper.getTierIcon(eloRating);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            tierName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildLeaderCard(UserModel user, int rank) {
    final colors = Theme.of(context).colorScheme;

    Color? medalColor;
    IconData? medalIcon;
    if (rank == 1) {
      medalColor = AppColors.medalGold;
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      medalColor = AppColors.medalSilver;
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      medalColor = AppColors.medalBronze;
      medalIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: medalColor ?? colors.primaryContainer,
              child: medalIcon != null
                  ? Icon(medalIcon, color: Colors.white)
                  : Text(
                      '$rank',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            Positioned(
              right: -8,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: LevelHelper.getLevelColor(user.stats.level),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
                child: Text(
                  '${user.stats.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Lvl ${user.stats.level} · W/L: ${user.stats.battleWins}/${user.stats.battleLosses} · WR: ${_calculateWinRate(user.stats)}',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        trailing: RankTierHelper.shouldShowQualifier(user.stats)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        RankTierHelper.getQualifierIcon(),
                        color: RankTierHelper.getQualifierColor(),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Q',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: RankTierHelper.getQualifierColor(),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    RankTierHelper.getQualifierProgress(
                      user.stats.rankedGamesPlayed,
                      ConfigService.instance.qualifierMatchCount,
                    ),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        RankTierHelper.getTierIcon(user.stats.eloRating),
                        color: RankTierHelper.getTierColor(user.stats.eloRating),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.stats.eloRating}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: RankTierHelper.getTierColor(user.stats.eloRating),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    RankTierHelper.getTierName(user.stats.eloRating),
                    style: const TextStyle(fontSize: 11),
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
