import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a TextField to enable standard keyboard shortcuts
/// Supports: Ctrl+A (Select All), Ctrl+C (Copy), Ctrl+X (Cut), Ctrl+V (Paste)
class KeyboardShortcutTextField extends StatelessWidget {
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? hintText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const KeyboardShortcutTextField({
    super.key,
    this.controller,
    this.decoration,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.hintText,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Ctrl+A - Select All
        const SingleActivator(LogicalKeyboardKey.keyA, control: true): () {
          if (controller != null && controller!.text.isNotEmpty) {
            controller!.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller!.text.length,
            );
          }
        },
        // Ctrl+C - Copy (handled by system, but we can add custom behavior)
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): () {
          if (controller != null &&
              controller!.selection.baseOffset !=
                  controller!.selection.extentOffset) {
            final selectedText = controller!.text.substring(
              controller!.selection.baseOffset,
              controller!.selection.extentOffset,
            );
            Clipboard.setData(ClipboardData(text: selectedText));
          }
        },
        // Ctrl+X - Cut
        const SingleActivator(LogicalKeyboardKey.keyX, control: true): () {
          if (controller != null &&
              controller!.selection.baseOffset !=
                  controller!.selection.extentOffset) {
            final selectedText = controller!.text.substring(
              controller!.selection.baseOffset,
              controller!.selection.extentOffset,
            );
            Clipboard.setData(ClipboardData(text: selectedText));

            final newText = controller!.text.replaceRange(
              controller!.selection.baseOffset,
              controller!.selection.extentOffset,
              '',
            );
            final cursorPosition = controller!.selection.baseOffset;
            controller!.text = newText;
            controller!.selection = TextSelection.collapsed(
              offset: cursorPosition,
            );
          }
        },
        // Ctrl+V - Paste
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): () {
          if (controller != null) {
            Clipboard.getData(Clipboard.kTextPlain).then((value) {
              if (value != null && value.text != null) {
                final text = value.text!;
                final selection = controller!.selection;

                if (selection.baseOffset == selection.extentOffset) {
                  // No selection, insert at cursor
                  final newText = controller!.text.replaceRange(
                    selection.baseOffset,
                    selection.extentOffset,
                    text,
                  );
                  controller!.text = newText;
                  controller!.selection = TextSelection.collapsed(
                    offset: selection.baseOffset + text.length,
                  );
                } else {
                  // Replace selection
                  final newText = controller!.text.replaceRange(
                    selection.baseOffset,
                    selection.extentOffset,
                    text,
                  );
                  controller!.text = newText;
                  controller!.selection = TextSelection.collapsed(
                    offset: selection.baseOffset + text.length,
                  );
                }
              }
            });
          }
        },
      },
      child: Focus(
        child: TextField(
          controller: controller,
          decoration:
              decoration ??
              InputDecoration(
                hintText: hintText,
                suffixIcon: suffixIcon,
                prefixIcon: prefixIcon,
              ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          maxLines: maxLines,
          minLines: minLines,
          enabled: enabled,
          focusNode: focusNode,
          autofocus: autofocus,
        ),
      ),
    );
  }
}
