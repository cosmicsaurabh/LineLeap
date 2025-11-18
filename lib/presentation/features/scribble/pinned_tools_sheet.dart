import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/core/config/mirrot_mode.dart';
import 'package:lineleap/core/config/tool_item.dart';
import 'package:lineleap/presentation/common/utils/responsive_layout_helper.dart';
import 'package:lineleap/presentation/features/scribble/scribble_tools.dart';

Future<void> showPinnedToolsSheet({
  required BuildContext context,
  required List<ScribbleToolType> pinnedTools,
  required MirrorMode mirrorMode,
  required ValueChanged<List<ScribbleToolType>> onPinnedToolsChanged,
  required ValueChanged<MirrorMode> onMirrorModeChanged,
}) async {
  final theme = Theme.of(context);
  final responsive = ResponsiveLayoutHelper(context);
  final maxHeight = MediaQuery.of(context).size.height * responsive.getBottomSheetMaxHeight();

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
            final localResponsive = ResponsiveLayoutHelper(ctx);
            final iconSize = localResponsive.getIconSize(baseSize: 18);
            final fontSize = localResponsive.getFontSize(baseSize: 12);
            final padding = localResponsive.isSmallScreen ? 6.0 : 10.0;

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
                  padding: EdgeInsets.symmetric(
                    vertical: padding,
                    horizontal: localResponsive.isSmallScreen ? 6 : 8,
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
                        size: iconSize,
                        color:
                            isPinned
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: localResponsive.isSmallScreen ? 4 : 6),
                      if (!localResponsive.isVerySmallScreen)
                        Flexible(
                          child: Text(
                            config.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color:
                                  isPinned
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                              fontSize: fontSize,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      SizedBox(width: localResponsive.isSmallScreen ? 2 : 4),
                      Icon(
                        isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
                        size: iconSize * 0.7,
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
            final localResponsive = ResponsiveLayoutHelper(ctx);
            final iconSize = localResponsive.getIconSize(baseSize: 18);
            final padding = localResponsive.isSmallScreen ? 6.0 : 8.0;

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
                  padding: EdgeInsets.symmetric(
                    vertical: padding,
                    horizontal: padding,
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
                      size: iconSize,
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

          final localResponsive = ResponsiveLayoutHelper(ctx);
          final fontSize = localResponsive.getFontSize(baseSize: 12);
          final padding = localResponsive.isSmallScreen ? 8.0 : 12.0;
          final spacing = localResponsive.isSmallScreen ? 6.0 : 8.0;

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: SafeArea(
                top: false,
                child: CupertinoActionSheet(
                  title: Text(
                    'Pinned tools',
                    style: TextStyle(fontSize: fontSize + 2),
                  ),
                  message: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Choose which tools stay on the canvas.',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      SizedBox(height: spacing),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mirror mode',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                      SizedBox(height: spacing),
                      Row(
                        children: [
                          buildMirrorButton(
                            mode: MirrorMode.vertical,
                            icon: CupertinoIcons.arrow_left_right,
                          ),
                          SizedBox(width: spacing),
                          buildMirrorButton(
                            mode: MirrorMode.horizontal,
                            icon: CupertinoIcons.arrow_up_down,
                          ),
                          SizedBox(width: spacing),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: 4,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Row 1: undo, redo, clear
                            Row(
                              children: [
                                buildPinChip(ScribbleToolType.undo),
                                SizedBox(width: spacing),
                                buildPinChip(ScribbleToolType.redo),
                                SizedBox(width: spacing),
                                buildPinChip(ScribbleToolType.clear),
                              ],
                            ),
                            SizedBox(height: spacing),
                            // Row 2: brush, color
                            Row(
                              children: [
                                buildPinChip(ScribbleToolType.brush),
                                SizedBox(width: spacing),
                                buildPinChip(ScribbleToolType.color),
                                const Spacer(),
                              ],
                            ),
                            SizedBox(height: spacing),
                            // Row 3: mirror tool
                            Row(
                              children: [
                                buildPinChip(ScribbleToolType.mirror),
                                const Spacer(),
                              ],
                            ),
                            SizedBox(height: spacing),
                            // Row 4: prompt, model
                            Row(
                              children: [
                                buildPinChip(ScribbleToolType.prompt),
                                SizedBox(width: spacing),
                                buildPinChip(ScribbleToolType.model),
                                const Spacer(),
                              ],
                            ),
                          ],
                        ),
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
                      child: Text(
                        'Reset to defaults',
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Done',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
