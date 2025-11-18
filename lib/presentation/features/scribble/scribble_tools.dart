import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum ScribbleToolType {
  undo,
  redo,
  brush,
  color,
  mirror,
  clear,
  prompt,
  modelSelect,
}

class ScribbleToolConfig {
  final ScribbleToolType type;
  final String id;
  final IconData icon;
  final String label;
  final String tooltip;

  const ScribbleToolConfig({
    required this.type,
    required this.id,
    required this.icon,
    required this.label,
    required this.tooltip,
  });
}

const Map<ScribbleToolType, ScribbleToolConfig> scribbleToolRegistry =
    <ScribbleToolType, ScribbleToolConfig>{
      ScribbleToolType.undo: ScribbleToolConfig(
        type: ScribbleToolType.undo,
        id: 'undo',
        icon: CupertinoIcons.arrow_uturn_left,
        label: 'Undo',
        tooltip: 'Undo last stroke',
      ),
      ScribbleToolType.redo: ScribbleToolConfig(
        type: ScribbleToolType.redo,
        id: 'redo',
        icon: CupertinoIcons.arrow_uturn_right,
        label: 'Redo',
        tooltip: 'Redo',
      ),
      ScribbleToolType.brush: ScribbleToolConfig(
        type: ScribbleToolType.brush,
        id: 'brush',
        icon: CupertinoIcons.paintbrush,
        label: 'Brush',
        tooltip: 'Brush style',
      ),
      ScribbleToolType.color: ScribbleToolConfig(
        type: ScribbleToolType.color,
        id: 'color',
        icon: CupertinoIcons.color_filter,
        label: 'Color',
        tooltip: 'Color picker',
      ),
      ScribbleToolType.mirror: ScribbleToolConfig(
        type: ScribbleToolType.mirror,
        id: 'mirror',
        icon: CupertinoIcons.square_split_2x2,
        label: 'Mirror',
        tooltip: 'Mirror mode',
      ),
      ScribbleToolType.clear: ScribbleToolConfig(
        type: ScribbleToolType.clear,
        id: 'clear',
        icon: CupertinoIcons.clear,
        label: 'Clear',
        tooltip: 'Clear canvas',
      ),
      ScribbleToolType.prompt: ScribbleToolConfig(
        type: ScribbleToolType.prompt,
        id: 'prompt',
        icon: CupertinoIcons.textformat,
        label: 'Prompt',
        tooltip: 'Open prompt input',
      ),
      ScribbleToolType.modelSelect: ScribbleToolConfig(
        type: ScribbleToolType.modelSelect,
        id: 'model_select',
        icon: CupertinoIcons.square_list,
        label: 'Model',
        tooltip: 'Select model',
      ),
    };

List<ScribbleToolType> get defaultPinnedTools => const <ScribbleToolType>[
  ScribbleToolType.undo,
  ScribbleToolType.brush,
];
