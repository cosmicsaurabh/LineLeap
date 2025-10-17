import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/presentation/common/widgets/view.dart';

class FullQueueView extends StatefulWidget {
  final List<GenerationRequest> queueItems;
  final VoidCallback onCollapse;
  final Function(GenerationRequest) onRemove;
  final Function(GenerationRequest) onRetry;
  final Function(GenerationRequest) onDownload;
  final Function(GenerationRequest) onView;

  const FullQueueView({
    super.key,
    required this.queueItems,
    required this.onCollapse,
    required this.onRemove,
    required this.onRetry,
    required this.onDownload,
    required this.onView,
  });

  @override
  State<FullQueueView> createState() => _FullQueueViewState();
}

class _FullQueueViewState extends State<FullQueueView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              buildHeader(
                context,
                'Collapse',
                widget.onCollapse,
                'Expanded View',
                _hasCompletedAllItems,
                'Save All',
                () {
                  widget.queueItems.map((item) {
                    if (item.status == GenerationStatus.completed) {
                      widget.onDownload(item);
                    }
                  }).toList();
                },
                'Clear All',
                () {
                  widget.queueItems.map((item) {
                    widget.onRemove(item);
                  }).toList();
                },
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.queueItems.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 1.0;
                        if (_pageController.position.haveDimensions) {
                          value = _pageController.page! - index;
                          value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                        }
                        return Center(
                          child: Transform.scale(scale: value, child: child),
                        );
                      },
                      child: buildQueueCard(
                        context,
                        widget.queueItems[index],
                        widget.onRetry,
                        widget.onDownload,
                        widget.onView,
                        widget.onRemove,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _hasCompletedAllItems {
    return widget.queueItems.every(
      (item) => item.status == GenerationStatus.completed,
    );
  }
}
