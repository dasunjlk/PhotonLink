import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../protocols/transfer_method.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
import '../../ui/radii.dart';
import '../../ui/responsive.dart';
import '../../ui/spacing.dart';

/// Method screen: choose Send or Receive for the selected transport.
class TransferSetupScreen extends StatelessWidget {
  const TransferSetupScreen({
    required this.method,
    super.key,
  });

  final TransferMethod method;

  void _send(BuildContext context) {
    switch (method) {
      case TransferMethod.qr:
        context.push(AppRoutes.qrSend);
      case TransferMethod.colorMatrix:
        context.push(AppRoutes.colorMatrixSend);
      default:
        context.push('${AppRoutes.pick}?method=${method.routeName}');
    }
  }

  void _receive(BuildContext context) {
    switch (method) {
      case TransferMethod.qr:
        context.push(AppRoutes.qrReceive);
      case TransferMethod.colorMatrix:
        context.push(AppRoutes.colorMatrixReceive);
      default:
        context.push('${AppRoutes.scan}?method=${method.routeName}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;

    final description = _DescriptionCard(method: method);
    final actions = _ActionsCard(
      method: method,
      onSend: () => _send(context),
      onReceive: () => _receive(context),
    );

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            InnerScreenHeader(title: method.displayName),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: wide
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: description),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(child: actions),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              description,
                              const SizedBox(height: AppSpacing.lg),
                              actions,
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.method});

  final TransferMethod method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = method.accentColor;

    return PhotonCard(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.3),
                  accent.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: AppRadii.lgRadius,
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(method.icon, color: accent, size: 32),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(method.displayName, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            method.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Feature(
              theme: theme,
              icon: Icons.wifi_off_rounded,
              label: 'Fully offline — no network required',),
          _Feature(
              theme: theme,
              icon: Icons.verified_user_rounded,
              label: 'Reliable delivery with integrity checks',),
          _Feature(
              theme: theme,
              icon: Icons.auto_awesome_rounded,
              label: 'Adaptive optical engine',),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(
      {required this.theme, required this.icon, required this.label,});

  final ThemeData theme;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.method,
    required this.onSend,
    required this.onReceive,
  });

  final TransferMethod method;
  final VoidCallback onSend;
  final VoidCallback onReceive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PhotonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PhotonSectionHeader(
            title: 'Choose an action',
            subtitle: 'Send a file or receive one from another device',
          ),
          _ActionTile(
            icon: Icons.upload_file_rounded,
            title: 'Send File',
            subtitle: 'Pick a file and transmit it optically',
            accent: method.accentColor,
            onTap: onSend,
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionTile(
            icon: Icons.download_rounded,
            title: 'Receive File',
            subtitle: 'Scan the sender to receive a file',
            accent: theme.colorScheme.secondary,
            onTap: onReceive,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PhotonCard(
      onTap: onTap,
      accentColor: accent,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: AppRadii.mdRadius,
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: accent),
        ],
      ),
    );
  }
}
