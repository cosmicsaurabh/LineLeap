import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

enum ContentReportReason {
  sexual('Sexual or adult content'),
  hateSpeech('Hate speech or discrimination'),
  violence('Violence or graphic content'),
  harassment('Harassment or bullying'),
  misleading('Misleading or false information'),
  copyright('Copyright or IP violation'),
  other('Other');

  final String label;
  const ContentReportReason(this.label);
}

class ReportContentDialog extends StatefulWidget {
  final String contentId; // Could be image path or generation request ID
  final String? contentType; // "generated_image", "scribble", etc.

  const ReportContentDialog({
    super.key,
    required this.contentId,
    this.contentType = 'generated_image',
  });

  @override
  State<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends State<ReportContentDialog> {
  ContentReportReason _selectedReason = ContentReportReason.other;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Prepare report data
      final reportData = {
        'contentId': widget.contentId,
        'contentType': widget.contentType,
        'reason': _selectedReason.label,
        'comment': _commentController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send via email to support
      final emailSubject =
          'LineLeap - Content Report: ${_selectedReason.label}';
      final emailBody = '''
Content Report Submission
========================

Reason: ${_selectedReason.label}
Content ID: ${widget.contentId}
Content Type: ${widget.contentType}
Timestamp: ${reportData['timestamp']}

User Comment:
${_commentController.text.isNotEmpty ? _commentController.text : '(No additional comment)'}

---
This report will be reviewed and acted upon promptly.
Thank you for helping us maintain a safe community.
''';

      final mailtoLink = Uri(
        scheme: 'mailto',
        path: 'saurabh.iiitk.job@gmail.com',
        queryParameters: {'subject': emailSubject, 'body': emailBody},
      );

      if (await canLaunchUrl(mailtoLink)) {
        await launchUrl(mailtoLink);
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Thank you for your report. We will review it shortly.',
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.padding16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    CupertinoIcons.flag,
                    color: theme.colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Report Content',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Help us improve by reporting inappropriate or harmful AI-generated content. Your report is confidential and will be reviewed by our team.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),

              // Reason selector
              Text(
                'Select a reason',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...ContentReportReason.values.map((reason) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedReason = reason);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _selectedReason == reason
                                ? theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                )
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _selectedReason == reason
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                          width: _selectedReason == reason ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    _selectedReason == reason
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline,
                              ),
                            ),
                            child:
                                _selectedReason == reason
                                    ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Text(reason.label),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),

              // Comment field
              Text(
                'Additional details (optional)',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 3,
                minLines: 2,
                decoration: InputDecoration(
                  hintText:
                      'Provide any additional context about this report...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      color: theme.colorScheme.error,
                      onPressed: _isSubmitting ? null : _submitReport,
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
