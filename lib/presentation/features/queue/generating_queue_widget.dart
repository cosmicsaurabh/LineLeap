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

  const GenerationQueueWidget({
    Key? key,
    required this.queueItems,
    required this.onRemove,
    required this.onRetry,
    required this.onDownload,
    required this.onView,
    required this.refreshQueue,
  }) : super(key: key);

  @override
  _GenerationQueueWidgetState createState() => _GenerationQueueWidgetState();
}

class _GenerationQueueWidgetState extends State<GenerationQueueWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Wrap(
        children: [
          if (_isExpanded)
            FullQueueView(
              queueItems: widget.queueItems,
              onCollapse: _toggleExpansion,
              onRemove: widget.onRemove,
              onRetry: widget.onRetry,
              onDownload: widget.onDownload,
              onView: widget.onView,
            ),
          if (!_isExpanded)
            MiniQueuePreview(
              queueItems: widget.queueItems,
              onExpand: _toggleExpansion,
              isExpanded: _isExpanded,
            ),
        ],
      ),
    );
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
}
