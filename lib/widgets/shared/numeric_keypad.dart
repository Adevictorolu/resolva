import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Six-digit masked PIN indicators.
class PinIndicators extends StatelessWidget {
  final int length;
  final int totalDigits;
  final bool hasError;

  const PinIndicators({
    super.key,
    required this.length,
    this.totalDigits = 6,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDigits, (index) {
        final isFilled = index < length;
        final isCurrent = index == length;

        Color borderColor;
        Color fillColor;

        if (hasError) {
          borderColor = AppColors.error;
          fillColor = AppColors.error.withValues(alpha: 0.15);
        } else if (isFilled) {
          borderColor = AppColors.royalBlue;
          fillColor = AppColors.royalBlue;
        } else if (isCurrent) {
          borderColor = AppColors.royalBlue;
          fillColor = Colors.transparent;
        } else {
          borderColor = AppColors.cardBorder;
          fillColor = AppColors.cardBackground;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fillColor,
            border: Border.all(
              color: borderColor,
              width: isFilled || isCurrent || hasError ? 2 : 1.5,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

/// Custom responsive on-screen numeric keypad for Security PIN entry.
/// Also listens to physical keyboard events (0-9, numpad 0-9, Backspace, Delete, Escape, Enter)
/// so laptop/desktop users can type their PIN directly without using the mouse pointer.
class NumericKeypad extends StatefulWidget {
  final Function(String) onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onClearPressed;
  final VoidCallback? onSubmitPressed;

  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    required this.onClearPressed,
    this.onSubmitPressed,
  });

  @override
  State<NumericKeypad> createState() => _NumericKeypadState();
}

class _NumericKeypadState extends State<NumericKeypad> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'NumericKeypadFocus');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // Backspace -> delete last digit
    if (key == LogicalKeyboardKey.backspace) {
      widget.onDeletePressed();
      return KeyEventResult.handled;
    }

    // Delete or Escape -> clear all digits
    if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.escape) {
      widget.onClearPressed();
      return KeyEventResult.handled;
    }

    // Enter or Numpad Enter -> submit if callback provided
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (widget.onSubmitPressed != null) {
        widget.onSubmitPressed!();
        return KeyEventResult.handled;
      }
    }

    // Check character if available (covers top-row 0-9 and numpad 0-9)
    final char = event.character;
    if (char != null && char.length == 1) {
      final code = char.codeUnitAt(0);
      if (code >= 48 && code <= 57) {
        widget.onDigitPressed(char);
        return KeyEventResult.handled;
      }
    }

    // Fallback explicit logical key check for number & numpad keys
    final digit = _digitFromLogicalKey(key);
    if (digit != null) {
      widget.onDigitPressed(digit);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  String? _digitFromLogicalKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) return '0';
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) return '1';
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) return '2';
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) return '3';
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) return '4';
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) return '5';
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) return '6';
    if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) return '7';
    if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) return '8';
    if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) return '9';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            children: [
              _buildRow(['1', '2', '3']),
              const SizedBox(height: 14),
              _buildRow(['4', '5', '6']),
              const SizedBox(height: 14),
              _buildRow(['7', '8', '9']),
              const SizedBox(height: 14),
              _buildBottomRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) => _buildDigitButton(d)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Clear button
        _buildActionButton(
          label: 'Clear',
          icon: null,
          onTap: () {
            _focusNode.requestFocus();
            widget.onClearPressed();
          },
          tooltip: 'Clear all digits (Esc / Del)',
        ),
        // 0 digit
        _buildDigitButton('0'),
        // Backspace button
        _buildActionButton(
          label: null,
          icon: Icons.backspace_outlined,
          onTap: () {
            _focusNode.requestFocus();
            widget.onDeletePressed();
          },
          tooltip: 'Delete digit (Backspace)',
        ),
      ],
    );
  }

  Widget _buildDigitButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _focusNode.requestFocus();
          widget.onDigitPressed(digit);
        },
        borderRadius: BorderRadius.circular(16),
        hoverColor: AppColors.royalBlue.withValues(alpha: 0.08),
        splashColor: AppColors.royalBlue.withValues(alpha: 0.15),
        child: Container(
          width: 76,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String? label,
    required IconData? icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: AppColors.royalBlue.withValues(alpha: 0.08),
          splashColor: AppColors.royalBlue.withValues(alpha: 0.15),
          child: Container(
            width: 76,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, color: AppColors.textSecondary, size: 22)
                : Text(
                    label ?? '',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
