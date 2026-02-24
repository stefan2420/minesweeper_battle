import 'package:flutter/material.dart';
import '../config/design_tokens.dart';
import '../models/cell.dart';

class CellWidget extends StatefulWidget {
  final Cell cell;
  final double size;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool gameOver;

  const CellWidget({
    super.key,
    required this.cell,
    required this.size,
    required this.onTap,
    required this.onLongPress,
    this.gameOver = false,
  });

  @override
  State<CellWidget> createState() => _CellWidgetState();
}

class _CellWidgetState extends State<CellWidget>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _revealController;
  late Animation<double> _revealScale;
  late Animation<double> _revealOpacity;
  CellState? _prevState;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: DesignTokens.animationNormal,
    );
    _revealScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutBack),
    );
    _revealOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOut),
    );
    _prevState = widget.cell.state;
  }

  @override
  void didUpdateWidget(CellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when cell transitions to revealed or flagged
    if (_prevState != widget.cell.state) {
      if (widget.cell.isRevealed || widget.cell.isFlagged) {
        _revealController.forward(from: 0);
      }
      _prevState = widget.cell.state;
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Color _getNumberColor(int number) {
    if (number < 0 || number >= AppColors.numberColors.length) {
      return Colors.transparent;
    }
    return AppColors.numberColors[number];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isHiddenOrFlagged = widget.cell.isHidden || widget.cell.isFlagged;

    return Semantics(
      label: _getCellSemanticLabel(),
      hint: widget.cell.isRevealed ? null : 'Double tap to reveal, long press to flag',
      button: !widget.cell.isRevealed,
      enabled: !widget.gameOver,
      child: GestureDetector(
        onTapDown: widget.gameOver ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.gameOver ? null : (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: widget.gameOver ? null : widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : 1.0,
          duration: DesignTokens.animationFast,
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: DesignTokens.animationFast,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _getBackgroundColor(context),
              borderRadius: BorderRadius.circular(widget.size * 0.12),
              border: isHiddenOrFlagged
                  ? Border.all(
                      color: colors.outline.withValues(alpha: 0.4),
                      width: 1,
                    )
                  : null,
              boxShadow: isHiddenOrFlagged
                  ? [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: _isPressed ? 0.05 : 0.12),
                        blurRadius: _isPressed ? 2 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(child: _buildContent()),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (widget.cell.isRevealed) {
      if (widget.cell.hasMine) return colors.errorContainer;
      return colors.surfaceContainerHighest.withValues(alpha: 0.5);
    }
    if (widget.cell.isFlagged) return colors.primaryContainer;
    return colors.surfaceContainerHighest;
  }

  Widget? _buildContent() {
    if (widget.cell.isFlagged) {
      return ScaleTransition(
        scale: _revealScale,
        child: FadeTransition(
          opacity: _revealOpacity,
          child: Icon(
            Icons.flag_rounded,
            color: Theme.of(context).colorScheme.error,
            size: widget.size * 0.58,
          ),
        ),
      );
    }

    if (widget.cell.isRevealed) {
      if (widget.cell.hasMine) {
        return ScaleTransition(
          scale: _revealScale,
          child: FadeTransition(
            opacity: _revealOpacity,
            child: Text('💣', style: TextStyle(fontSize: widget.size * 0.62)),
          ),
        );
      }
      if (widget.cell.adjacentMines > 0) {
        return ScaleTransition(
          scale: _revealScale,
          child: FadeTransition(
            opacity: _revealOpacity,
            child: Text(
              '${widget.cell.adjacentMines}',
              style: TextStyle(
                color: _getNumberColor(widget.cell.adjacentMines),
                fontWeight: FontWeight.w800,
                fontSize: widget.size * 0.58,
                height: 1.0,
              ),
            ),
          ),
        );
      }
    }
    return null;
  }

  String _getCellSemanticLabel() {
    if (widget.cell.isFlagged) return 'Flagged cell';
    if (widget.cell.isRevealed) {
      if (widget.cell.hasMine) return 'Mine';
      if (widget.cell.adjacentMines > 0) {
        return '${widget.cell.adjacentMines} adjacent mine${widget.cell.adjacentMines == 1 ? "" : "s"}';
      }
      return 'Empty cell';
    }
    return 'Hidden cell';
  }
}
