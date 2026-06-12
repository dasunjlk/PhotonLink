import 'package:flutter/material.dart';

import '../../ui/spacing.dart';
import '../components/components.dart';

/// Retryable camera access error with optional settings shortcut.
class CameraErrorPanel extends StatelessWidget {
  const CameraErrorPanel({
    required this.message,
    required this.onRetry,
    this.onOpenSettings,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<bool> Function()? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              PhotonButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                expand: false,
                onPressed: onRetry,
              ),
              if (onOpenSettings != null) ...[
                const SizedBox(height: AppSpacing.sm),
                PhotonButton(
                  label: 'Open Settings',
                  variant: PhotonButtonVariant.ghost,
                  expand: false,
                  onPressed: onOpenSettings,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
