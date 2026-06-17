import 'package:flutter/material.dart';

Future<void> showAlertDialog({
  required BuildContext context,
  required String message,
  String? title,
  AlertType type = AlertType.info,
}) {
  final theme = Theme.of(context);
  
  final iconData = switch (type) {
    AlertType.success => Icons.check_rounded,
    AlertType.error => Icons.error_outline_rounded,
    AlertType.warning => Icons.warning_amber_rounded,
    AlertType.info => Icons.info_outline_rounded,
  };
  
  final iconColor = switch (type) {
    AlertType.success => Colors.green,
    AlertType.error => Colors.red,
    AlertType.warning => Colors.orange,
    AlertType.info => theme.colorScheme.primary,
  };
  
  final defaultTitle = switch (type) {
    AlertType.success => 'Success',
    AlertType.error => 'Error',
    AlertType.warning => 'Warning',
    AlertType.info => 'Notice',
  };

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              title ?? defaultTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

enum AlertType {
  success,
  error,
  warning,
  info,
}

