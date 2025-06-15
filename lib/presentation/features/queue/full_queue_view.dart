import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/domain/entities/generation_request.dart';

class FullQueueView extends StatefulWidget {
  final List<GenerationRequest> queueItems;
  final VoidCallback onCollapse;
  final Function(GenerationRequest) onRemove;
  final Function(GenerationRequest) onRetry;
  final Function(GenerationRequest) onDownload;
  final Function(GenerationRequest) onView;

  const FullQueueView({
    Key? key,
    required this.queueItems,
    required this.onCollapse,
    required this.onRemove,
    required this.onRetry,
    required this.onDownload,
    required this.onView,
  }) : super(key: key);

  @override
  _FullQueueViewState createState() => _FullQueueViewState();
}

class _FullQueueViewState extends State<FullQueueView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    _pageController.addListener(_pageListener);
  }

  @override
  void dispose() {
    _pageController.removeListener(_pageListener);
    _pageController.dispose();
    super.dispose();
  }

  void _pageListener() {
    setState(() {
      _currentPage = _pageController.page?.round() ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            _buildHeader(),
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
                    child: _buildQueueCard(widget.queueItems[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onCollapse();
            },
          ),
          const SizedBox(width: 8),
          Text(
            'Processing Queue',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_hasCompletedItems)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Implement save all functionality
              },
              child: const Text('Save All'),
            ),
        ],
      ),
    );
  }

  bool get _hasCompletedItems {
    return widget.queueItems.any(
      (item) => item.status == GenerationStatus.completed,
    );
  }

  Widget _buildQueueCard(GenerationRequest request) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildImageRow(request),
            const SizedBox(height: 16),
            _buildPromptSection(request),
            const SizedBox(height: 16),
            _buildStatusSection(request),
          ],
        ),
      ),
    );
  }

  Widget _buildImageRow(GenerationRequest request) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                request.scribblePath != null
                    ? Image.file(File(request.scribblePath!), fit: BoxFit.cover)
                    : Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.image)),
                    ),
          ),
        ),
        const SizedBox(width: 16),
        if (request.status == GenerationStatus.completed &&
            request.generatedPath != null)
          Expanded(
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(request.generatedPath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPromptSection(GenerationRequest request) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        request.prompt ?? 'No prompt provided',
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusSection(GenerationRequest request) {
    switch (request.status) {
      case GenerationStatus.completed:
        return Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onDownload(request);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Save Image'),
            ),
          ],
        );
      case GenerationStatus.failed:
        return Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              request.error ?? 'Generation failed',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onRetry(request);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      case GenerationStatus.polling:
        return Column(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 8),
            Text(
              'Generating...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        );
      default:
        return Column(
          children: [
            const Icon(Icons.schedule, color: Colors.orange, size: 32),
            const SizedBox(height: 8),
            Text(
              'In queue',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.orange),
            ),
          ],
        );
    }
  }
}
