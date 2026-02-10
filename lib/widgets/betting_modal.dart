import 'dart:async';
import 'package:flutter/material.dart';

/// Modal dialog shown to winner after PvP battle
/// Offers choice: Cash Out (safe) vs Risk & Continue (betting)
class BettingModal extends StatefulWidget {
  final int earnedXP;
  final Function() onCashOut;
  final Function() onBet;
  final int timeoutSeconds;

  const BettingModal({
    super.key,
    required this.earnedXP,
    required this.onCashOut,
    required this.onBet,
    this.timeoutSeconds = 10,
  });

  @override
  State<BettingModal> createState() => _BettingModalState();
}

class _BettingModalState extends State<BettingModal> {
  late int _remainingSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeoutSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        // Auto cash-out on timeout
        Navigator.of(context).pop();
        widget.onCashOut();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final potentialWinXP = (widget.earnedXP * 2);
    final potentialLossXP = (widget.earnedXP * 0.1).round();

    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing by tapping outside
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.casino, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('You Won!'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _remainingSeconds <= 3 ? Colors.red : Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_remainingSeconds s',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Risk your winnings to finish the board?',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Cash Out Option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'SAFE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+${widget.earnedXP} XP',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text(
                    'Guaranteed',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),

            // Bet & Continue Option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'RISKY',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+$potentialWinXP XP',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Text(
                    'If you finish the board',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'But only +$potentialLossXP XP if you fail',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Cash Out Button
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _countdownTimer?.cancel();
                Navigator.of(context).pop();
                widget.onCashOut();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              child: const Text(
                'Cash Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Risk & Continue Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _countdownTimer?.cancel();
                Navigator.of(context).pop();
                widget.onBet();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Risk It!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );
  }
}
