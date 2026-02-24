import 'dart:async';
import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

/// Modal dialog shown to winner after PvP battle.
/// Offers choice: Cash Out (safe) vs Risk & Continue (betting).
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
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
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
    final potentialWinXP = widget.earnedXP * 2;
    final potentialLossXP = (widget.earnedXP * 0.1).round();
    final colors = Theme.of(context).colorScheme;
    final progress = _remainingSeconds / widget.timeoutSeconds;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        title: Row(
          children: [
            const Icon(Icons.casino, color: AppColors.warning),
            const SizedBox(width: 8),
            const Expanded(child: Text('You Won!')),
            // Animated countdown pill — smoothly transitions blue→red
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                begin: colors.primary,
                end: colors.error,
              ),
              duration: Duration(seconds: widget.timeoutSeconds),
              builder: (context, color, _) => AnimatedContainer(
                duration: DesignTokens.animationFast,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color.lerp(colors.primary, colors.error, 1 - progress),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Text(
                  '${_remainingSeconds}s',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Risk your winnings to finish the board?',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Cash Out Option
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: AppColors.successSurface(context),
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                border: Border.all(color: AppColors.success, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 8),
                      const Text(
                        'SAFE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
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
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    'Guaranteed',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'VS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Bet & Continue Option
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: AppColors.warningSurface(context),
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                border: Border.all(color: AppColors.warning, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: AppColors.warning),
                      const SizedBox(width: 8),
                      const Text(
                        'RISKY',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
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
                      color: AppColors.warning,
                    ),
                  ),
                  Text(
                    'If you finish the board',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'But only +$potentialLossXP XP if you fail',
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _countdownTimer?.cancel();
                Navigator.of(context).pop();
                widget.onCashOut();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.success, width: 2),
              ),
              child: const Text(
                'Cash Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _countdownTimer?.cancel();
                Navigator.of(context).pop();
                widget.onBet();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Risk It!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
