import 'package:flutter_test/flutter_test.dart';
import 'package:lineleap/core/config/mirror_mode.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';

void main() {
  group('EnhancedScribbleNotifier', () {
    test('undo and redo preserve every point in completed strokes', () {
      final notifier = EnhancedScribbleNotifier();

      notifier.startStroke(const Offset(10, 10));
      notifier.appendPoint(const Offset(20, 20));
      notifier.appendPoint(const Offset(30, 30));
      notifier.endStroke();

      notifier.startStroke(const Offset(40, 40));
      notifier.appendPoint(const Offset(50, 50));
      notifier.appendPoint(const Offset(60, 60));
      notifier.endStroke();

      expect(notifier.state.strokes, hasLength(2));
      expect(notifier.state.strokes[0].points, [
        const Offset(10, 10),
        const Offset(20, 20),
        const Offset(30, 30),
      ]);
      expect(notifier.state.strokes[1].points, [
        const Offset(40, 40),
        const Offset(50, 50),
        const Offset(60, 60),
      ]);
      expect(notifier.state.history, hasLength(3));
      expect(notifier.state.history[1].single.points, [
        const Offset(10, 10),
        const Offset(20, 20),
        const Offset(30, 30),
      ]);
      expect(notifier.state.history[2][1].points, [
        const Offset(40, 40),
        const Offset(50, 50),
        const Offset(60, 60),
      ]);
      expect(notifier.canUndo, isTrue);
      expect(notifier.canRedo, isFalse);

      notifier.undo();

      expect(notifier.state.strokes, hasLength(1));
      expect(notifier.state.strokes.single.points, [
        const Offset(10, 10),
        const Offset(20, 20),
        const Offset(30, 30),
      ]);
      expect(notifier.canUndo, isTrue);
      expect(notifier.canRedo, isTrue);

      notifier.redo();

      expect(notifier.state.strokes, hasLength(2));
      expect(notifier.state.strokes[0].points, [
        const Offset(10, 10),
        const Offset(20, 20),
        const Offset(30, 30),
      ]);
      expect(notifier.state.strokes[1].points, [
        const Offset(40, 40),
        const Offset(50, 50),
        const Offset(60, 60),
      ]);
      expect(notifier.canUndo, isTrue);
      expect(notifier.canRedo, isFalse);
    });

    test('a new stroke after undo replaces the redo branch', () {
      final notifier = EnhancedScribbleNotifier();

      notifier.startStroke(const Offset(10, 10));
      notifier.appendPoint(const Offset(20, 20));
      notifier.endStroke();

      notifier.startStroke(const Offset(30, 30));
      notifier.appendPoint(const Offset(40, 40));
      notifier.endStroke();

      notifier.undo();

      notifier.startStroke(const Offset(50, 50));
      notifier.appendPoint(const Offset(60, 60));
      notifier.appendPoint(const Offset(70, 70));
      notifier.endStroke();

      expect(notifier.canRedo, isFalse);
      expect(notifier.state.strokes, hasLength(2));
      expect(notifier.state.strokes[0].points, [
        const Offset(10, 10),
        const Offset(20, 20),
      ]);
      expect(notifier.state.strokes[1].points, [
        const Offset(50, 50),
        const Offset(60, 60),
        const Offset(70, 70),
      ]);

      notifier.undo();
      notifier.redo();

      expect(notifier.state.strokes, hasLength(2));
      expect(notifier.state.strokes[1].points, [
        const Offset(50, 50),
        const Offset(60, 60),
        const Offset(70, 70),
      ]);
    });

    test('ending a stroke more than once does not add an undo step', () {
      final notifier = EnhancedScribbleNotifier();

      notifier.startStroke(const Offset(10, 10));
      notifier.appendPoint(const Offset(20, 20));
      notifier.endStroke();
      notifier.endStroke();

      expect(notifier.state.history, hasLength(2));

      notifier.undo();

      expect(notifier.state.strokes, isEmpty);
      expect(notifier.canUndo, isFalse);
    });

    test('mirrored strokes are restored together with all their points', () {
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
      notifier.appendPoint(
        const Offset(40, 20),
        canvasWidth: 100,
        canvasHeight: 100,
      );
      notifier.endStroke();

      expect(notifier.state.strokes, hasLength(2));
      expect(notifier.state.strokes[0].points, [
        const Offset(20, 10),
        const Offset(30, 15),
        const Offset(40, 20),
      ]);
      expect(notifier.state.strokes[1].points, [
        const Offset(80, 10),
        const Offset(70, 15),
        const Offset(60, 20),
      ]);

      notifier.undo();

      expect(notifier.state.strokes, isEmpty);

      notifier.redo();

      expect(notifier.state.strokes, hasLength(2));
      expect(notifier.state.strokes[0].points, [
        const Offset(20, 10),
        const Offset(30, 15),
        const Offset(40, 20),
      ]);
      expect(notifier.state.strokes[1].points, [
        const Offset(80, 10),
        const Offset(70, 15),
        const Offset(60, 20),
      ]);
    });
  });
}
