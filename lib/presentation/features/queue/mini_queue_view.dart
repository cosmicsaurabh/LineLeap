import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/presentation/common/widgets/view.dart';

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

class _MiniQueuePreviewState extends State<MiniQueuePreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.queueItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 72),
            const SizedBox(height: 16),
            const Text("Queue is empty", style: TextStyle(fontSize: 18)),
            ElevatedButton(
              onPressed: widget.onExpand,
              child: const Text("Start Generation"),
            ),
          ],
        ),
      );
    }
    return CardSwiper(
      cardBuilder:
          (
            context,
            index,
            horizontalThresholdPercentage,
            verticalThresholdPercentage,
          ) => GestureDetector(
            onTap: widget.onExpand,
            child: buildCard(context, widget.queueItems[index]),
          ),

      cardsCount: widget.queueItems.length,
      numberOfCardsDisplayed: math.min(3, widget.queueItems.length),
      isLoop: true,
    );
  }
}
