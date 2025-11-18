// Model Selector Sheet
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/presentation/common/utils/responsive_layout_helper.dart';

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
    final responsive = ResponsiveLayoutHelper(context);
    final maxHeight = MediaQuery.of(context).size.height * responsive.getBottomSheetMaxHeight();
    final fontSize = responsive.getFontSize(baseSize: 16);
    final iconSize = responsive.getIconSize(baseSize: 20);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: CupertinoActionSheet(
        title: Text(
          'Select AI Model',
          style: TextStyle(fontSize: fontSize + 2),
        ),
        message: Text(
          'Choose the AI model for image generation',
          style: TextStyle(fontSize: fontSize - 2),
        ),
        actions:
            models.map((model) {
              final isSelected = model == selectedModel;
              return CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, model),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected)
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: CupertinoColors.activeBlue,
                        size: iconSize,
                      ),
                    if (isSelected) SizedBox(width: responsive.isSmallScreen ? 6 : 8),
                    Flexible(
                      child: Text(
                        model,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? CupertinoColors.activeBlue : null,
                          fontSize: fontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(fontSize: fontSize),
          ),
        ),
      ),
    );
  }
}
