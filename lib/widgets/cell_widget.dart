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

class _CellWidgetState extends State<CellWidget> {
  bool _isPressed = false;

  /// Get theme-aware number color based on adjacent mine count
  Color _getNumberColor(BuildContext context, int number) {
    final colors = Theme.of(context).colorScheme;
    switch (number) {
      case 1:
        return colors.primary;
      case 2:
        return Colors.green.shade700;
      case 3:
        return colors.error;
      case 4:
        return Colors.purple.shade700;
      case 5:
        return Colors.brown.shade700;
      case 6:
        return Colors.cyan.shade700;
      case 7:
        return colors.onSurface;
      case 8:
        return colors.onSurfaceVariant;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _getCellSemanticLabel(),
      hint: widget.cell.isRevealed ? null : 'Double tap to reveal, long press to flag',
      button: !widget.cell.isRevealed,
      enabled: !widget.gameOver,
      child: GestureDetector(
        onTapDown: widget.gameOver ? null : (_) {
          setState(() => _isPressed = true);
        },
        onTapUp: widget.gameOver ? null : (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        onLongPress: widget.gameOver ? null : widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: DesignTokens.animationFast,
          child: AnimatedContainer(
            duration: DesignTokens.animationFast,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _getBackgroundColor(context),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1.0,
              ),
              boxShadow: widget.cell.isHidden || widget.cell.isFlagged
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(_isPressed ? 0.6 : 0.8),
                        offset: const Offset(-1, -1),
                        blurRadius: 0,
                      ),
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(_isPressed ? 0.8 : 0.6),
                        offset: const Offset(1, 1),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (widget.cell.isRevealed) {
      if (widget.cell.hasMine) {
        return colors.errorContainer;
      }
      return colors.surface;
    }
    return colors.surfaceVariant;
  }

  Widget? _buildContent() {
    if (widget.cell.isFlagged) {
      return Icon(
        Icons.flag,
        color: Theme.of(context).colorScheme.error,
        size: widget.size * 0.6,
      );
    }

    if (widget.cell.isRevealed) {
      if (widget.cell.hasMine) {
        return Icon(
          Icons.brightness_7,
          color: Theme.of(context).colorScheme.onErrorContainer,
          size: widget.size * 0.7,
        );
      }

      if (widget.cell.adjacentMines > 0) {
        return Text(
          '${widget.cell.adjacentMines}',
          style: TextStyle(
            color: _getNumberColor(context, widget.cell.adjacentMines),
            fontWeight: FontWeight.bold,
            fontSize: widget.size * 0.6,
          ),
        );
      }
    }

    return null;
  }

  String _getCellSemanticLabel() {
    if (widget.cell.isFlagged) {
      return 'Flagged cell';
    }
    if (widget.cell.isRevealed) {
      if (widget.cell.hasMine) {
        return 'Mine';
      }
      if (widget.cell.adjacentMines > 0) {
        return '${widget.cell.adjacentMines} adjacent ${widget.cell.adjacentMines == 1 ? "mine" : "mines"}';
      }
      return 'Empty cell';
    }
    return 'Hidden cell';
  }
}
