import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bootstrap.dart';
import '../../core/constants.dart';
import '../../services/core/core_backend.dart';
import '../../services/core/core_providers.dart';
import '../../services/native_bridge/native_bridge.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
import '../../ui/colors.dart';
import '../../ui/radii.dart';
import '../../ui/spacing.dart';

/// About screen with app info and native bridge status.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packageInfo = ref.watch(packageInfoProvider);
    final nativeBridge = ref.watch(nativeBridgeProvider);
    final backend = ref.watch(backendProvider);

    final coreLabel = backend == CoreBackend.rust
        ? 'Rust (FRB)'
        : 'Dart fallback';

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const InnerScreenHeader(title: 'About'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        PhotonCard(
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: AppColors.brandGradient,
                                  ),
                                  borderRadius: AppRadii.lgRadius,
                                  border: Border.all(color: AppColors.ashDark),
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: AppColors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                AppConstants.appName,
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Version ${packageInfo.version} (${packageInfo.buildNumber})',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'PhotonLink enables offline peer-to-peer file '
                                'transfer using optical communication — QR codes, '
                                'color matrices, and visual frame streams — with '
                                'no network connection.',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PhotonCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const PhotonSectionHeader(title: 'Engine Status'),
                              PhotonInfoTile(
                                label: 'Phase',
                                value: AppConstants.phaseLabel,
                                dense: true,
                              ),
                              PhotonInfoTile(
                                label: 'Native Core',
                                value: coreLabel,
                                dense: true,
                              ),
                              FutureBuilder<String>(
                                future: nativeBridge.ping(),
                                builder: (context, snapshot) => PhotonInfoTile(
                                  label: 'Bridge Ping',
                                  value: snapshot.data ?? 'Checking…',
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Licensed under MIT. See LICENSE in the repository.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
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
