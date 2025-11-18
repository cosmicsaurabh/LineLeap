import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/core/config/mirrot_mode.dart';
import 'package:lineleap/core/config/tool_item.dart';
import 'package:lineleap/presentation/features/scribble/scribble_tools.dart';

Future<void> showPinnedToolsSheet({
  required BuildContext context,
  required List<ScribbleToolType> pinnedTools,
  required MirrorMode mirrorMode,
  required ValueChanged<List<ScribbleToolType>> onPinnedToolsChanged,
  required ValueChanged<MirrorMode> onMirrorModeChanged,
}) async {
  final theme = Theme.of(context);

  await showCupertinoModalPopup(
    context: context,
    builder: (ctx) {
      var localPinned = List<ScribbleToolType>.from(pinnedTools);
      var localMirror = mirrorMode;

      return StatefulBuilder(
        builder: (context, setState) {
          Widget buildPinChip(ScribbleToolType type) {
            final config = scribbleToolRegistry[type]!;
            final isPinned = localPinned.contains(type);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isPinned) {
                      localPinned.remove(type);
                    } else {
                      localPinned.add(type);
                    }
                  });
                  onPinnedToolsChanged(localPinned);
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isPinned
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isPinned
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        config.icon,
                        size: 18,
                        color:
                            isPinned
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        config.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color:
                              isPinned
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
                        size: 14,
                        color:
                            isPinned
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          Widget buildMirrorButton({
            required MirrorMode mode,
            required IconData icon,
          }) {
            final isActive = localMirror == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    localMirror = mode;
                  });
                  onMirrorModeChanged(mode);
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 18,
                      color:
                          isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }

          return Container(
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              child: CupertinoActionSheet(
                title: const Text('Pinned tools'),
                message: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Choose which tools stay on the canvas.'),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Mirror mode',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        buildMirrorButton(
                          mode: MirrorMode.vertical,
                          icon: CupertinoIcons.arrow_left_right,
                        ),
                        const SizedBox(width: 8),
                        buildMirrorButton(
                          mode: MirrorMode.horizontal,
                          icon: CupertinoIcons.arrow_up_down,
                        ),
                        const SizedBox(width: 8),
                        buildMirrorButton(
                          mode: MirrorMode.both,
                          icon: Icons.grid_4x4,
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: undo, redo, clear
                        Row(
                          children: [
                            buildPinChip(ScribbleToolType.undo),
                            const SizedBox(width: 8),
                            buildPinChip(ScribbleToolType.redo),
                            const SizedBox(width: 8),
                            buildPinChip(ScribbleToolType.clear),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 2: brush, color
                        Row(
                          children: [
                            buildPinChip(ScribbleToolType.brush),
                            const SizedBox(width: 8),
                            buildPinChip(ScribbleToolType.color),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 3: mirror tool
                        Row(
                          children: [
                            buildPinChip(ScribbleToolType.mirror),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 4: prompt, model
                        Row(
                          children: [
                            buildPinChip(ScribbleToolType.prompt),
                            const SizedBox(width: 8),
                            buildPinChip(ScribbleToolType.model),
                            const Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CupertinoActionSheetAction(
                    onPressed: () {
                      final defaults = List<ScribbleToolType>.from(
                        defaultPinnedTools,
                      );
                      setState(() {
                        localPinned = defaults;
                      });
                      onPinnedToolsChanged(defaults);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset to defaults'),
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
