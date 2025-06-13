// Model Selector Sheet
import 'package:flutter/cupertino.dart';

class ModelSelectorSheet extends StatelessWidget {
  final String selectedModel;

  const ModelSelectorSheet({super.key, required this.selectedModel});

  @override
  Widget build(BuildContext context) {
    final models = [
      'Stable Diffusion',
      'DALL-E 3',
      'Midjourney',
      'Leonardo AI',
    ];

    return CupertinoActionSheet(
      title: const Text('Select AI Model'),
      message: const Text('Choose the AI model for image generation'),
      actions:
          models.map((model) {
            final isSelected = model == selectedModel;
            return CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, model),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: CupertinoColors.activeBlue,
                    ),
                  if (isSelected) const SizedBox(width: 8),
                  Text(
                    model,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? CupertinoColors.activeBlue : null,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    );
  }
}
