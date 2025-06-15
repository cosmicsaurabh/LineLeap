import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/presentation/common/widgets/action_button.dart';
import 'package:lineleap/theme/app_theme.dart';

// ------------mini queue view widgets----------------

Widget buildCard(
  BuildContext context,
  GenerationRequest request, {
  bool isTopCard = false,
}) {
  return Container(
    width: 350,
    height: 100,
    margin: EdgeInsets.only(
      top: isTopCard ? 0 : 2, // Less margin for more compact stack
      bottom: 12, // Space for shadow
    ),

    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                children: [
                  buildThumbnail(request.scribblePath),
                  const SizedBox(width: 12),
                  Expanded(child: buildPromptText(context, request)),
                  const SizedBox(width: 12),
                  if (request.status == GenerationStatus.completed)
                    buildThumbnail(request.generatedPath)
                  else
                    buildStatusWidget(request),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildThumbnail(String? imagePath) {
  if (imagePath != null) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(imagePath),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );
  } else {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, size: 24, color: Colors.grey),
    );
  }
}

Widget buildPromptText(BuildContext context, GenerationRequest request) {
  return Container(
    constraints: const BoxConstraints(maxHeight: 120),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey.withAlpha((0.8 * 255).toInt()),
      borderRadius: BorderRadius.circular(8),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Text(
        request.prompt,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}

// ------------full queue view widgets----------------

Widget buildStatusWidget(GenerationRequest request) {
  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: Colors.grey[500],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[400]!, width: 1),
    ),
    alignment: Alignment.center,
    child: getStatusIcon(request),
  );
}

Widget getStatusIcon(GenerationRequest request) {
  switch (request.status) {
    case GenerationStatus.failed:
      return Icon(Icons.refresh);
    case GenerationStatus.polling:
      return const SizedBox(
        width: 24,
        height: 24,
        child: CupertinoActivityIndicator(radius: 12),
      );
    case GenerationStatus.submitting:
      return const SizedBox(
        width: 24,
        height: 24,
        child: CupertinoActivityIndicator(radius: 12),
      );
    case GenerationStatus.queued:
      return const Icon(Icons.schedule);
    case GenerationStatus.completed:
      return const Icon(Icons.check_circle);
  }
}

Widget buildHeader(
  BuildContext context,
  String leftButtonText,
  VoidCallback onLeftButtonPressed,
  String text,
  bool? condition,
  String rightButtonText1,
  VoidCallback onRightButton1Pressed,
  String rightButtonText2,
  VoidCallback onRightButton2Pressed,
) {
  return Padding(
    padding: const EdgeInsets.all(AppTheme.padding16),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(CupertinoIcons.arrowtriangle_up_square),
          onPressed: () {
            HapticFeedback.lightImpact();
            onLeftButtonPressed();
          },
        ),
        const SizedBox(width: 8),
        // Text(
        //   text,
        //   style: Theme.of(
        //     context,
        //   ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        // ),
        const Spacer(),

        ActionButton(
          onPressed: onRightButton1Pressed,
          tooltip: rightButtonText1,
          disabled: condition != true,
        ),
        ActionButton(
          onPressed: onRightButton2Pressed,
          tooltip: rightButtonText2,
        ),
      ],
    ),
  );
}

Widget buildImageRow(GenerationRequest request) {
  return SizedBox(
    height: 300,
    width: 300,
    child: CardSwiper(
      cardsCount: 2,
      isLoop: true,
      cardBuilder: (
        context,
        index,
        horizontalThresholdPercentage,
        verticalThresholdPercentage,
      ) {
        if (index == 0) {
          // First card: scribblePath image
          return buildImage(request.scribblePath);
        } else {
          // Second card: generated image if completed, else status widget
          if (request.status == GenerationStatus.completed) {
            return buildImage(request.generatedPath);
          } else {
            return buildStatusWidget(request);
          }
        }
      },
    ),
  );
}

Widget buildQueueCard(
  BuildContext context,
  GenerationRequest request,
  Function(GenerationRequest) onRetry,
  Function(GenerationRequest) onDownload,
  Function(GenerationRequest) onView,
  Function(GenerationRequest) onRemove,
) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
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
        buildImageRow(request),
        const SizedBox(height: 16),
        buildPromptText(context, request),
        const SizedBox(height: 16),
        buildStatusSection(
          context,
          request,
          (req) => onRetry(req),
          (req) => onDownload(req),
          (req) => onView(req),
          (req) => onRemove(req),
        ),
      ],
    ),
  );
}

Widget buildImage(String? imagePath) {
  if (imagePath != null) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(imagePath),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );
  } else {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, size: 24, color: Colors.grey),
    );
  }
}

Widget buildStatusSection(
  BuildContext context,
  GenerationRequest request,
  Function(GenerationRequest) onRetry,
  Function(GenerationRequest) onDownload,
  Function(GenerationRequest) onView,
  Function(GenerationRequest) onRemove,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      getStatusIcon(request),
      if (request.status == GenerationStatus.completed)
        ActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onView(request);
          },
          icon: Icons.visibility,
          // tooltip: 'View',
        ),
      if (request.status == GenerationStatus.completed)
        ActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onDownload(request);
          },
          icon: Icons.download,
          // tooltip: 'Download',
        ),
      if (request.status == GenerationStatus.failed ||
          request.status == GenerationStatus.completed)
        ActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onRetry(request);
          },
          icon: Icons.refresh,
          // tooltip: 'Retry',
        ),
      if (request.status == GenerationStatus.polling ||
          request.status == GenerationStatus.submitting ||
          request.status == GenerationStatus.queued)
        Text(
          request.status == GenerationStatus.polling
              ? 'Generating...'
              : request.status == GenerationStatus.submitting
              ? 'Submitting...'
              : 'Queued',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:
                request.status == GenerationStatus.polling
                    ? Theme.of(context).primaryColor
                    : request.status == GenerationStatus.submitting
                    ? Colors.orange
                    : Colors.blue,
          ),
        ),

      ActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onRemove(request);
        },
        icon: Icons.delete,
        // tooltip: 'Delete',
      ),
    ],
  );
}
