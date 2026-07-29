import 'dart:ui';

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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: CupertinoAlertDialog(
        title: const Text('AI Generation Prompt'),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              CupertinoTextField(
                padding: const EdgeInsets.all(16),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                autofocus: true,
                controller: _controller,
                placeholder: 'Describe the scribble...',
                maxLines: 5,
                minLines: 1,
                textAlignVertical: TextAlignVertical.top,
              ),
              const SizedBox(height: 12),
              const Text(
                'Generation needs an internet connection. AI Horde’s shared '
                'anonymous queue can be slow. LineLeap reports the actual '
                'connection or provider result after submission.',
                textAlign: TextAlign.start,
              ),
            ],
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
      ),
    );
  }
}
