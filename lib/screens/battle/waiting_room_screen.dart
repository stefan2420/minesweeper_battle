import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/design_tokens.dart';
import '../../models/battle_session.dart';
import '../../models/game_board.dart';
import '../../providers/auth_provider.dart';
import '../../providers/battle_provider.dart';
import 'battle_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final battleProvider = context.watch<BattleProvider>();
    final session = battleProvider.session;
    final userId = authProvider.firebaseUser?.uid;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Waiting Room')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Navigate to battle when game starts
    if (session.status == BattleStatus.playing && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BattleScreen()),
        );
      });
    }

    final isHost = session.hostId == userId;
    final myPlayer = session.players[userId];
    final opponentPlayer = session.getOpponent(userId ?? '');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _showLeaveDialog();
        if (shouldLeave && mounted) {
          await battleProvider.leaveRoom(userId ?? '');
          if (mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Waiting Room'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldLeave = await _showLeaveDialog();
              if (shouldLeave && mounted) {
                await battleProvider.leaveRoom(userId ?? '');
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Room Code Display
                Card(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.spacingM),
                    child: Column(
                      children: [
                        const Text(
                          'Room Code',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: DesignTokens.spacingS),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              session.roomCode,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(width: DesignTokens.spacingS),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: session.roomCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Room code copied!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.spacingS),
                        Text(
                          'Difficulty: ${_getDifficultyName(session.difficulty)}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: DesignTokens.spacingXl),

                // Players
                const Text(
                  'Players',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingM),

                // Host
                _buildPlayerCard(
                  name: _getUniquePlayerName(
                    session.players[session.hostId]?.displayName ?? 'Host',
                    true,
                    opponentPlayer?.displayName,
                  ),
                  isReady: session.players[session.hostId]?.isReady ?? false,
                  isYou: isHost,
                  isHost: true,
                ),

                const SizedBox(height: 12),

                // Guest
                if (opponentPlayer != null)
                  _buildPlayerCard(
                    name: _getUniquePlayerName(
                      opponentPlayer.displayName,
                      false,
                      session.players[session.hostId]?.displayName,
                    ),
                    isReady: opponentPlayer.isReady,
                    isYou: !isHost,
                    isHost: false,
                  )
                else
                  _buildWaitingCard(),

                const Spacer(),

                // Ready button
                if (session.isFull) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final currentReady = myPlayer?.isReady ?? false;
                        battleProvider.setReady(userId!, !currentReady);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: myPlayer?.isReady == true
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                      ),
                      child: Text(
                        myPlayer?.isReady == true ? 'Ready!' : 'Click when Ready',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingM),

                  // Start button (host only, when all ready)
                  if (isHost && session.allPlayersReady)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => battleProvider.startGame(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Start Game!',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to get unique player name when both players have same displayName
  String _getUniquePlayerName(String displayName, bool isHost, String? opponentName) {
    if (displayName == opponentName && opponentName != null) {
      return '$displayName (${isHost ? "Host" : "Guest"})';
    }
    return displayName;
  }

  Widget _buildPlayerCard({
    required String name,
    required bool isReady,
    required bool isYou,
    required bool isHost,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isReady
            ? Colors.green
            : Theme.of(context).colorScheme.surfaceVariant,
          child: Icon(
            isReady ? Icons.check : Icons.person,
            color: isReady
              ? Colors.white
              : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Row(
          children: [
            Text(name),
            if (isYou)
              Text(
                ' (You)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        subtitle: Text(isHost ? 'Host' : 'Guest'),
        trailing: isReady
            ? const Chip(
                label: Text('Ready'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white),
              )
            : Chip(
                label: const Text('Waiting'),
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          child: Icon(
            Icons.hourglass_empty,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: const Text('Waiting for opponent...'),
        subtitle: const Text('Share the room code'),
      ),
    );
  }

  String _getDifficultyName(Difficulty difficulty) {
    return difficulty.displayNameWithSize;
  }

  Future<bool> _showLeaveDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Room?'),
            content: const Text('Are you sure you want to leave the room?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
