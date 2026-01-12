import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        MaterialPageRoute(
          builder: (_) => const WaitingRoomScreen(),
        ),
      );
    } else if (battleProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(battleProvider.error!),
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
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
        MaterialPageRoute(
          builder: (_) => const WaitingRoomScreen(),
        ),
      );
    } else if (battleProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(battleProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final battleProvider = context.watch<BattleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Mode'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Create Room Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Room',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Difficulty:'),
                      const SizedBox(height: 8),
                      SegmentedButton<Difficulty>(
                        segments: const [
                          ButtonSegment(
                            value: Difficulty.beginner,
                            label: Text('Easy'),
                          ),
                          ButtonSegment(
                            value: Difficulty.intermediate,
                            label: Text('Medium'),
                          ),
                          ButtonSegment(
                            value: Difficulty.expert,
                            label: Text('Hard'),
                          ),
                        ],
                        selected: {_selectedDifficulty},
                        onSelectionChanged: (selected) {
                          setState(() {
                            _selectedDifficulty = selected.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: battleProvider.isLoading ? null : _createRoom,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Room'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                ],
              ),

              const SizedBox(height: 24),

              // Join Room Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Join Room',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _roomCodeController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Room Code',
                          hintText: 'Enter 6-character code',
                          prefixIcon: Icon(Icons.meeting_room),
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: battleProvider.isLoading ? null : _joinRoom,
                          icon: const Icon(Icons.login),
                          label: const Text('Join Room'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (battleProvider.isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
