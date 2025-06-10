import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PromptInputDialog extends StatefulWidget {
  final String initialPrompt;

  const PromptInputDialog({super.key, required this.initialPrompt});

  @override
  State<PromptInputDialog> createState() => _PromptInputDialogState();
}

class _PromptInputDialogState extends State<PromptInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return CupertinoAlertDialog(
      title: const Text('AI Generation Prompt'),
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: CupertinoTextField(
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          autofocus: true,
          controller: _controller,
          placeholder: 'Describe the scribble...',
          maxLines: 4,
          minLines: 3,
          textAlignVertical: TextAlignVertical.top,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
