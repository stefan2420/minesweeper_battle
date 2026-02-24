import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../models/game_board.dart';
import '../../providers/auth_provider.dart';
import '../../providers/battle_provider.dart';
import 'waiting_room_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _roomCodeController = TextEditingController();
  Difficulty _selectedDifficulty = Difficulty.beginner;

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final authProvider = context.read<AuthProvider>();
    final battleProvider = context.read<BattleProvider>();

    final userId = authProvider.firebaseUser?.uid;
    final displayName = authProvider.userModel?.displayName ?? 'Player';

    if (userId == null) return;

    final roomCode = await battleProvider.createRoom(
      hostId: userId,
      hostDisplayName: displayName,
      difficulty: _selectedDifficulty,
    );

    if (roomCode != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WaitingRoomScreen()),
      );
    } else if (battleProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(battleProvider.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _joinRoom() async {
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-character room code'),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final battleProvider = context.read<BattleProvider>();

    final userId = authProvider.firebaseUser?.uid;
    final displayName = authProvider.userModel?.displayName ?? 'Player';

    if (userId == null) return;

    final success = await battleProvider.joinRoom(
      roomCode: code,
      guestId: userId,
      guestDisplayName: displayName,
    );

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WaitingRoomScreen()),
      );
    } else if (battleProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(battleProvider.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final battleProvider = context.watch<BattleProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Battle Mode')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Create Room ──────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Room',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: DesignTokens.spacingS),
                      Text(
                        'Choose difficulty',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: DesignTokens.spacingM),

                      // Difficulty cards
                      Row(
                        children: Difficulty.values.map((d) {
                          final selected = _selectedDifficulty == d;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _DifficultyCard(
                                difficulty: d,
                                selected: selected,
                                onTap: () => setState(() => _selectedDifficulty = d),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: DesignTokens.spacingM),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: battleProvider.isLoading ? null : _createRoom,
                          icon: battleProvider.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add),
                          label: Text(
                            battleProvider.isLoading ? 'Creating…' : 'Create Room',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: DesignTokens.spacingL),

              // ── Divider ─────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: colors.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
                    child: Text('OR', style: TextStyle(color: colors.onSurfaceVariant)),
                  ),
                  Expanded(child: Divider(color: colors.outlineVariant)),
                ],
              ),

              const SizedBox(height: DesignTokens.spacingL),

              // ── Join Room ────────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Room',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: DesignTokens.spacingM),
                      TextField(
                        controller: _roomCodeController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Room Code',
                          hintText: 'Enter 6-character code',
                          prefixIcon: Icon(Icons.meeting_room),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingM),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: battleProvider.isLoading ? null : _joinRoom,
                          icon: battleProvider.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            battleProvider.isLoading ? 'Joining…' : 'Join Room',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable card showing difficulty info and mine count.
class _DifficultyCard extends StatelessWidget {
  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  Color get _accentColor {
    switch (difficulty) {
      case Difficulty.beginner:
        return const Color(0xFF2E7D32); // green
      case Difficulty.intermediate:
        return const Color(0xFF1565C0); // blue
      case Difficulty.expert:
        return const Color(0xFFC62828); // red
    }
  }

  IconData get _icon {
    switch (difficulty) {
      case Difficulty.beginner:
        return Icons.looks_one_rounded;
      case Difficulty.intermediate:
        return Icons.looks_two_rounded;
      case Difficulty.expert:
        return Icons.looks_3_rounded;
    }
  }

  String get _subtitle {
    switch (difficulty) {
      case Difficulty.beginner:
        return '9×9 · 10 💣';
      case Difficulty.intermediate:
        return '16×16 · 40 💣';
      case Difficulty.expert:
        return '30×16 · 99 💣';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: DesignTokens.animationFast,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: AnimatedContainer(
          duration: DesignTokens.animationFast,
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.spacingM,
            horizontal: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _accentColor.withValues(alpha: 0.12)
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: selected ? _accentColor : colors.outline.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, color: _accentColor, size: 28),
              const SizedBox(height: 4),
              Text(
                difficulty.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: selected ? _accentColor : colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                _subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
