import 'package:flutter_test/flutter_test.dart';
import 'package:lineleap/core/config/mirrot_mode.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';

void main() {
  group('EnhancedScribbleNotifier', () {
    test('records strokes and supports undo and redo', () {
      final notifier = EnhancedScribbleNotifier();

      notifier.startStroke(const Offset(10, 10));
      notifier.appendPoint(const Offset(20, 20));
      notifier.endStroke();

      expect(notifier.state.strokes, hasLength(1));
      expect(notifier.state.strokes.first.points, hasLength(2));
      expect(notifier.canUndo, isTrue);
      expect(notifier.canRedo, isFalse);

      notifier.undo();

      expect(notifier.state.strokes, isEmpty);
      expect(notifier.canUndo, isFalse);
      expect(notifier.canRedo, isTrue);

      notifier.redo();

      expect(notifier.state.strokes, hasLength(1));
      expect(notifier.canUndo, isTrue);
    });

    test('mirrors strokes across the vertical axis', () {
      final notifier = EnhancedScribbleNotifier();

      notifier.selectMirrorMode(MirrorMode.vertical);
      notifier.startStroke(
        const Offset(20, 10),
        canvasWidth: 100,
        canvasHeight: 100,
      );
      notifier.appendPoint(
        const Offset(30, 15),
        canvasWidth: 100,
        canvasHeight: 100,
      );
      notifier.endStroke();

      expect(notifier.state.strokes, hasLength(2));
      expect(notifier.state.strokes[0].points, [
        const Offset(20, 10),
        const Offset(30, 15),
      ]);
      expect(notifier.state.strokes[1].points, [
        const Offset(80, 10),
        const Offset(70, 15),
      ]);
    });
  });
}
