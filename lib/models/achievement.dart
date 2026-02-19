class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  static const List<Achievement> all = [
    Achievement(id: 'first_win', name: 'First Blood', description: 'Win your first battle', icon: '🩸'),
    Achievement(id: 'wins_10', name: 'Veteran', description: 'Win 10 battles', icon: '🎖️'),
    Achievement(id: 'wins_50', name: 'Warrior', description: 'Win 50 battles', icon: '⚔️'),
    Achievement(id: 'wins_100', name: 'Centurion', description: 'Win 100 battles', icon: '🛡️'),
    Achievement(id: 'elo_1400', name: 'Silver Caliber', description: 'Reach 1400 ELO', icon: '🥈'),
    Achievement(id: 'elo_1600', name: 'Gold Caliber', description: 'Reach 1600 ELO', icon: '🥇'),
    Achievement(id: 'elo_1800', name: 'Diamond Caliber', description: 'Reach 1800 ELO', icon: '💎'),
    Achievement(id: 'level_10', name: 'Level 10', description: 'Reach Level 10', icon: '⭐'),
    Achievement(id: 'level_25', name: 'Level 25', description: 'Reach Level 25', icon: '🌟'),
    Achievement(id: 'bet_first', name: 'High Roller', description: 'Win your first bet', icon: '🎲'),
    Achievement(id: 'bet_10', name: 'Gambler', description: 'Win 10 bets', icon: '🃏'),
    Achievement(id: 'qualifier_graduate', name: 'Graduate', description: 'Complete qualifier matches', icon: '🎓'),
    Achievement(id: 'daily_first', name: 'Day One', description: 'Complete a daily challenge', icon: '📅'),
    Achievement(id: 'daily_streak_7', name: 'Weekly Warrior', description: '7-day daily challenge streak', icon: '🔥'),
    Achievement(id: 'speed_beginner', name: 'Speed Runner', description: 'Beat Beginner in under 30s', icon: '⚡'),
    Achievement(id: 'first_friend', name: 'Social', description: 'Add your first friend', icon: '🤝'),
  ];

  static Achievement? findById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
