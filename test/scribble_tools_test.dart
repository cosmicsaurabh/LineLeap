import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lineleap/core/config/mirror_mode.dart';
import 'package:lineleap/core/config/tool_item.dart';
import 'package:lineleap/presentation/features/scribble/pinned_tools_sheet.dart';
import 'package:lineleap/presentation/features/scribble/scribble_tools.dart';

void main() {
  test('pinned tools do not expose a model selector', () {
    final toolIds = scribbleToolRegistry.values.map((tool) => tool.id);
    final toolLabels = scribbleToolRegistry.values.map(
      (tool) => tool.label.toLowerCase(),
    );

    expect(toolIds, isNot(contains('model')));
    expect(toolLabels, isNot(contains('model')));
    expect(resolvePinnedToolIds(['undo', 'model', 'prompt', 'undo']), [
      ScribbleToolType.undo,
      ScribbleToolType.prompt,
    ]);
  });

  testWidgets('the pinned tools sheet has no model choices', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => showPinnedToolsSheet(
                        context: context,
                        pinnedTools: defaultPinnedTools,
                        mirrorMode: MirrorMode.none,
                        onPinnedToolsChanged: (_) {},
                        onMirrorModeChanged: (_) {},
                      ),
                  child: const Text('Open tools'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open tools'));
    await tester.pumpAndSettle();

    expect(find.text('Prompt'), findsOneWidget);
    expect(find.text('Model'), findsNothing);
    expect(find.text('DALL-E 3'), findsNothing);
    expect(find.text('Midjourney'), findsNothing);
    expect(find.text('Leonardo AI'), findsNothing);
  });
}
