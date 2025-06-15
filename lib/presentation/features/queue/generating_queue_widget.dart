import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/presentation/features/queue/full_queue_view.dart';
import 'package:lineleap/presentation/features/queue/mini_queue_view.dart';

class GenerationQueueWidget extends StatefulWidget {
  final List<GenerationRequest> queueItems;
  final Function(GenerationRequest) onRemove;
  final Function(GenerationRequest) onRetry;
  final Function(GenerationRequest) onDownload;
  final Function(GenerationRequest) onView;
  final VoidCallback refreshQueue;
  final Function(bool) onExpansionChanged;

  const GenerationQueueWidget({
    Key? key,
    required this.queueItems,
    required this.onRemove,
    required this.onRetry,
    required this.onDownload,
    required this.onView,
    required this.refreshQueue,
    required this.onExpansionChanged,
  }) : super(key: key);

  @override
  _GenerationQueueWidgetState createState() => _GenerationQueueWidgetState();
}

class _GenerationQueueWidgetState extends State<GenerationQueueWidget> {
  bool _isExpanded = false;

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child:
          _isExpanded
              ? FullQueueView(
                key: const ValueKey('full'),
                queueItems: widget.queueItems,
                onCollapse: _toggleExpansion,
                onRemove: widget.onRemove,
                onRetry: widget.onRetry,
                onDownload: widget.onDownload,
                onView: widget.onView,
              )
              : MiniQueuePreview(
                key: const ValueKey('mini'),
                queueItems: widget.queueItems,
                onExpand: _toggleExpansion,
                isExpanded: _isExpanded,
              ),
    );
  }
}
