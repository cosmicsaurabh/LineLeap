import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/generation_request.dart';

class MiniQueuePreview extends StatefulWidget {
  final List<GenerationRequest> queueItems;
  final VoidCallback onExpand;
  final bool isExpanded;

  const MiniQueuePreview({
    Key? key,
    required this.queueItems,
    required this.onExpand,
    required this.isExpanded,
  }) : super(key: key);

  @override
  _MiniQueuePreviewState createState() => _MiniQueuePreviewState();
}

class _MiniQueuePreviewState extends State<MiniQueuePreview> {
  @override
  Widget build(BuildContext context) {
    if (widget.queueItems.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onExpand,
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 5 && widget.isExpanded) {
          widget.onExpand();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildPreviewHeader(),
                const SizedBox(height: 8),
                _buildQueueCardsStack(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Row(
      children: [
        const Icon(Icons.hourglass_bottom, size: 18),
        const SizedBox(width: 8),
        Text(
          'Processing (${widget.queueItems.length})',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Icon(
          widget.isExpanded ? Icons.expand_more : Icons.expand_less,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildQueueCardsStack() {
    final visibleItems =
        widget.queueItems.length > 3
            ? widget.queueItems.sublist(0, 3)
            : widget.queueItems;

    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          for (int i = 0; i < visibleItems.length; i++)
            Positioned(
              left: i * 30.0,
              child: Transform.scale(
                scale: 1.0 - (i * 0.1),
                child: _buildQueueCard(visibleItems[i], i),
              ),
            ),
          if (widget.queueItems.length > 3)
            Positioned(
              left: 90,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '+${widget.queueItems.length - 3}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(GenerationRequest request, int index) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildStatusThumbnail(request),
      ),
    );
  }

  Widget _buildStatusThumbnail(GenerationRequest request) {
    if (request.scribblePath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(request.scribblePath!), fit: BoxFit.cover),
          _buildStatusOverlay(request.status),
        ],
      );
    }

    return Container(
      color: Colors.grey.shade200,
      child: Center(child: _buildStatusIcon(request.status)),
    );
  }

  Widget _buildStatusOverlay(GenerationStatus? status) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: _buildStatusIcon(status)),
    );
  }

  Widget _buildStatusIcon(GenerationStatus? status) {
    switch (status) {
      case GenerationStatus.queued:
        return const Icon(Icons.schedule, size: 20, color: Colors.white);
      case GenerationStatus.submitting:
      case GenerationStatus.polling:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.8),
            ),
          ),
        );
      case GenerationStatus.completed:
        return const Icon(Icons.check, size: 20, color: Colors.white);
      case GenerationStatus.failed:
        return const Icon(Icons.error_outline, size: 20, color: Colors.white);
      default:
        return const Icon(Icons.help_outline, size: 20, color: Colors.white);
    }
  }
}
