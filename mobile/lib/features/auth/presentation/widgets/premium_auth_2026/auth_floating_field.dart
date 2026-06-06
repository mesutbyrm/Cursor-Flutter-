import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../../core/ui/premium_2026/premium_motion.dart';

/// Cam yüzey üzerinde floating label + neon focus.
class AuthFloatingField extends StatefulWidget {
  const AuthFloatingField({
    super.key,
    this.controller,
    this.focusNode,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  State<AuthFloatingField> createState() => _AuthFloatingFieldState();
}

class _AuthFloatingFieldState extends State<AuthFloatingField> {
  late final FocusNode _focus;
  var _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focused = _focus.hasFocus;
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    setState(() => _focused = _focus.hasFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);
    final glow = _focused
        ? [
            BoxShadow(
              color: const Color(0xFF9B4DFF).withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: -4,
            ),
          ]
        : <BoxShadow>[];

    return AnimatedContainer(
      duration: PremiumMotion.medium,
      curve: PremiumMotion.easeOut,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: glow,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        autofillHints: widget.autofillHints,
        textCapitalization: widget.textCapitalization,
        validator: widget.validator,
        onChanged: widget.onChanged,
        style: TextStyle(
          color: context.colors.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            color: _focused
                ? const Color(0xFFC4B5FD)
                : context.colors.onSurfaceMuted.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: context.colors.onSurfaceMuted.withValues(alpha: 0.65),
            fontSize: 14,
          ),
          prefixIcon: widget.prefixIcon == null
              ? null
              : Icon(
                  widget.prefixIcon,
                  color: _focused
                      ? const Color(0xFF9D6BFF)
                      : context.colors.onSurfaceMuted,
                  size: 22,
                ),
          filled: true,
          fillColor: const Color(0xFF140A28).withValues(alpha: 0.72),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(
              color: Color(0xFF9D6BFF),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: AppThemeColors.liveRed.withValues(alpha: 0.85),
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(color: AppThemeColors.liveRed),
          ),
        ),
      ),
    );
  }
}
