import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/bootstrap.dart';
import '../../core/constants.dart';
import '../../core/router/app_router.dart';
import '../../history/application/history_controller.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/inner_screen_header.dart';
import '../../transfer/adaptive/adaptive_engine_providers.dart';
import '../../transfer/adaptive/diagnostics_export.dart';
import '../../transfer/adaptive/models/transport_profile.dart';
import '../../transfer/application/transfer_providers.dart';
import '../../transfer/scheduler/transfer_mode.dart';
import '../../ui/radii.dart';
import '../../ui/responsive.dart';
import '../../ui/spacing.dart';
import '../application/settings_controller.dart';

/// Settings screen with a category navigation panel and a content area.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selected = 0;

  static const _items = [
    PhotonSettingsItem(label: 'General', icon: Icons.tune_rounded),
    PhotonSettingsItem(label: 'Appearance', icon: Icons.palette_outlined),
    PhotonSettingsItem(label: 'Transfer', icon: Icons.swap_horiz_rounded),
    PhotonSettingsItem(
        label: 'Adaptive Engine', icon: Icons.auto_awesome_rounded,),
    PhotonSettingsItem(label: 'FEC', icon: Icons.shield_moon_rounded),
    PhotonSettingsItem(label: 'Diagnostics', icon: Icons.monitor_heart_rounded),
    PhotonSettingsItem(label: 'History', icon: Icons.history_rounded),
    PhotonSettingsItem(label: 'Language', icon: Icons.language_rounded),
    PhotonSettingsItem(label: 'About', icon: Icons.info_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;

    final nav = PhotonSettingsPanel(
      items: _items,
      selectedIndex: _selected,
      horizontal: !wide,
      onSelected: (i) => setState(() => _selected = i),
    );

    final content = _CategoryContent(index: _selected);

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const InnerScreenHeader(title: 'Settings'),
            Expanded(
              child: wide
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 240,
                            child: PhotonCard(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: nav,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 720),
                                child: content,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        nav,
                        const SizedBox(height: AppSpacing.sm),
                        Expanded(
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.all(AppSpacing.screenPadding),
                            child: content,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryContent extends ConsumerWidget {
  const _CategoryContent({required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (index) {
      0 => const _GeneralSection(),
      1 => const _AppearanceSection(),
      2 => const _TransferSection(),
      3 => const _AdaptiveSection(),
      4 => const _FecSection(),
      5 => const _DiagnosticsSection(),
      6 => const _HistorySection(),
      7 => const _LanguageSection(),
      _ => const _AboutSection(),
    };
  }
}

/// A titled group of setting rows inside a PhotonCard.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotonSectionHeader(title: title, subtitle: subtitle),
          PhotonCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// General
// ---------------------------------------------------------------------------
class _GeneralSection extends ConsumerWidget {
  const _GeneralSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return _Group(
      title: 'General',
      subtitle: 'Device and experimental options',
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.camera_alt_rounded),
          title: const Text('Camera Resolution'),
          subtitle: Text(settings.cameraResolution == 'high'
              ? 'High (1080p)'
              : 'Medium (720p)',),
          trailing: DropdownButton<String>(
            value: settings.cameraResolution,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'high', child: Text('High')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
            ],
            onChanged: (v) {
              if (v != null) controller.updateCameraResolution(v);
            },
          ),
        ),
        const Divider(height: 1),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Experimental Features'),
          subtitle: const Text('Enable in-progress optical modes'),
          value: settings.experimentalFeatures,
          onChanged: controller.toggleExperimentalFeatures,
        ),
        const Divider(height: 1),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Debug Overlay'),
          subtitle: const Text('Show detection overlay during scanning'),
          value: settings.debugOverlay,
          onChanged: controller.toggleDebugOverlay,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance
// ---------------------------------------------------------------------------
class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return _Group(
      title: 'Appearance',
      subtitle: 'Theme defaults to dark for optimal optical contrast',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_rounded, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_rounded, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_rounded, size: 18),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => controller.updateThemeMode(s.first),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Transfer
// ---------------------------------------------------------------------------
class _TransferSection extends ConsumerWidget {
  const _TransferSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Column(
      children: [
        _Group(
          title: 'Transfer Preferences',
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Compression (GZip)'),
              subtitle: const Text('Compress payloads before packetization'),
              value: settings.compressionEnabled,
              onChanged: controller.toggleCompression,
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Encryption'),
              subtitle: const Text('ChaCha20-Poly1305 — key in setup QR'),
              value: settings.encryptionEnabled,
              onChanged: controller.toggleEncryption,
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Transfer mode'),
              subtitle: Text(settings.transferMode.id),
              trailing: DropdownButton<TransferMode>(
                value: settings.transferMode,
                underline: const SizedBox.shrink(),
                items: TransferMode.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.id)))
                    .toList(),
                onChanged: (m) {
                  if (m != null) controller.updateTransferMode(m);
                },
              ),
            ),
          ],
        ),
        _Group(
          title: 'Color Matrix Transport',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Matrix Size (manual)'),
              subtitle: Text(
                  '${settings.colorMatrixSize}×${settings.colorMatrixSize}',),
              trailing: DropdownButton<int>(
                value: settings.colorMatrixSize,
                underline: const SizedBox.shrink(),
                items: const [16, 24, 32, 48]
                    .map(
                        (s) => DropdownMenuItem(value: s, child: Text('$s×$s')),)
                    .toList(),
                onChanged: (s) {
                  if (s != null) controller.updateColorMatrixSize(s);
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Payload Density'),
              subtitle: Text('${settings.colorBitsPerChannel} bits/channel'),
              trailing: DropdownButton<int>(
                value: settings.colorBitsPerChannel,
                underline: const SizedBox.shrink(),
                items: const [1, 2, 3]
                    .map((b) =>
                        DropdownMenuItem(value: b, child: Text('$b bpc')),)
                    .toList(),
                onChanged: (b) {
                  if (b != null) controller.updateColorBitsPerChannel(b);
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Expanded(child: Text('Frame rate')),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      value: settings.colorTransferFrameRate.clamp(1, 10),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label:
                          '${settings.colorTransferFrameRate.toStringAsFixed(0)} fps',
                      onChanged: controller.updateColorTransferFrameRate,
                    ),
                  ),
                  Text(
                      '${settings.colorTransferFrameRate.toStringAsFixed(0)} fps',),
                ],
              ),
            ),
          ],
        ),
        _Group(
          title: 'Optical Stream Transport',
          subtitle: 'Continuous high-speed optical streaming',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Stream Density (grid)'),
              subtitle: Text(
                '${settings.opticalStreamDensity}×${settings.opticalStreamDensity}',
              ),
              trailing: DropdownButton<int>(
                value: settings.opticalStreamDensity,
                underline: const SizedBox.shrink(),
                items: const [16, 24, 32, 48]
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text('$s×$s')),
                    )
                    .toList(),
                onChanged: (s) {
                  if (s != null) controller.updateOpticalStreamDensity(s);
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Expanded(child: Text('Stream speed')),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      value: settings.opticalStreamSpeed.clamp(2, 15),
                      min: 2,
                      max: 15,
                      divisions: 13,
                      label:
                          '${settings.opticalStreamSpeed.toStringAsFixed(0)} fps',
                      onChanged: controller.updateOpticalStreamSpeed,
                    ),
                  ),
                  Text(
                    '${settings.opticalStreamSpeed.toStringAsFixed(0)} fps',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Expanded(child: Text('Sync aggressiveness')),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      value: settings.opticalSyncAggressiveness,
                      min: 0.2,
                      max: 1.0,
                      divisions: 8,
                      label: settings.opticalSyncAggressiveness
                          .toStringAsFixed(1),
                      onChanged: controller.updateOpticalSyncAggressiveness,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Expanded(child: Text('Recovery sensitivity')),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      value: settings.opticalRecoverySensitivity,
                      min: 0.2,
                      max: 1.0,
                      divisions: 8,
                      label: settings.opticalRecoverySensitivity
                          .toStringAsFixed(1),
                      onChanged: controller.updateOpticalRecoverySensitivity,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Stream diagnostics overlay'),
              subtitle: const Text('Show debug overlay on sender frames'),
              value: settings.opticalStreamDiagnostics,
              onChanged: controller.toggleOpticalStreamDiagnostics,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Adaptive Engine
// ---------------------------------------------------------------------------
class _AdaptiveSection extends ConsumerWidget {
  const _AdaptiveSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return _Group(
      title: 'Adaptive Engine',
      subtitle: 'Phase 6 optical adaptation',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Adaptive Mode'),
          subtitle: const Text('Auto-tune matrix size, FPS, and density'),
          value: settings.adaptiveModeEnabled,
          onChanged: controller.toggleAdaptiveMode,
        ),
        const Divider(height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Aggressiveness'),
          subtitle: Text(settings.adaptiveAggressiveness.id),
          trailing: DropdownButton<AdaptiveAggressiveness>(
            value: settings.adaptiveAggressiveness,
            underline: const SizedBox.shrink(),
            items: AdaptiveAggressiveness.values
                .map((a) => DropdownMenuItem(value: a, child: Text(a.id)))
                .toList(),
            onChanged: (a) {
              if (a != null) controller.updateAdaptiveAggressiveness(a);
            },
          ),
        ),
        const Divider(height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Profile Override'),
          subtitle: Text(settings.profileOverride.id),
          trailing: DropdownButton<ProfileOverride>(
            value: settings.profileOverride,
            underline: const SizedBox.shrink(),
            items: ProfileOverride.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.id)))
                .toList(),
            onChanged: (p) {
              if (p != null) controller.updateProfileOverride(p);
            },
          ),
        ),
        const Divider(height: 1),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Quality Monitoring'),
          subtitle: const Text('Show live quality score overlay'),
          value: settings.qualityMonitoringEnabled,
          onChanged: controller.toggleQualityMonitoring,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FEC (read-only — managed by the adaptive engine)
// ---------------------------------------------------------------------------
class _FecSection extends StatelessWidget {
  const _FecSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Group(
      title: 'Forward Error Correction',
      subtitle: 'Automatically managed by the adaptive engine',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.shield_moon_rounded, color: theme.colorScheme.onSurface),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'PhotonLink applies Reed-Solomon erasure coding based on live '
                  'channel quality. Parity overhead scales up in poor conditions '
                  'and down in good ones — no manual tuning required.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const PhotonInfoTile(
          label: 'Codec',
          value: 'Reed-Solomon (adaptive)',
          dense: true,
        ),
        const PhotonInfoTile(
          label: 'Parity overhead',
          value: 'Auto (quality-driven)',
          dense: true,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Diagnostics
// ---------------------------------------------------------------------------
class _DiagnosticsSection extends ConsumerWidget {
  const _DiagnosticsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return _Group(
      title: 'Diagnostics',
      subtitle: 'Live metrics and export',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Diagnostics'),
          subtitle: const Text('Show live transfer metrics'),
          value: settings.diagnosticsEnabled,
          onChanged: controller.toggleDiagnostics,
        ),
        const Divider(height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.download_rounded),
          title: const Text('Export Diagnostics'),
          subtitle: const Text('Save adaptive metrics as JSON'),
          onTap: () => _exportDiagnostics(context, ref),
        ),
        const Divider(height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.analytics_outlined),
          title: const Text('Open Analytics Dashboard'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push(AppRoutes.analytics),
        ),
      ],
    );
  }

  Future<void> _exportDiagnostics(BuildContext context, WidgetRef ref) async {
    final adaptive = ref.read(colorMatrixReceiverAdaptiveProvider);
    final receiver = ref.read(colorMatrixReceiverControllerProvider);
    final exporter = DiagnosticsExporter();
    try {
      final path = await exporter.exportToFile(
        adaptation: adaptive.diagnostics,
        frameDiagnostics: receiver.diagnostics,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Diagnostics exported to $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// History
// ---------------------------------------------------------------------------
class _HistorySection extends ConsumerWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Group(
      title: 'History',
      subtitle: 'Manage the persistent transfer log',
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_rounded),
          title: const Text('Open Transfer History'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push(AppRoutes.history),
        ),
        const Divider(height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,),
          title: const Text('Clear History'),
          subtitle: const Text('Remove all saved transfer records'),
          onTap: () => _confirmClear(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This permanently removes all transfer records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(historyRepositoryProvider).clearAll();
    ref.invalidate(historyProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Language
// ---------------------------------------------------------------------------
class _LanguageSection extends ConsumerWidget {
  const _LanguageSection();

  static const _languages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return _Group(
      title: 'Language',
      subtitle: 'Full localization arrives in a future release',
      children: [
        for (final entry in _languages.entries) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.value),
            trailing: settings.language == entry.key
                ? Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  )
                : Icon(
                    Icons.circle_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            onTap: () => controller.updateLanguage(entry.key),
          ),
          if (entry.key != _languages.keys.last) const Divider(height: 1),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// About
// ---------------------------------------------------------------------------
class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packageInfo = ref.watch(packageInfoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PhotonSectionHeader(title: 'About'),
        PhotonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: AppRadii.mdRadius,
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Icon(Icons.bolt_rounded,
                        color: theme.colorScheme.onSurface, size: 30,),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppConstants.appName,
                          style: theme.textTheme.titleLarge,),
                      Text(
                        'Version ${packageInfo.version} (${packageInfo.buildNumber})',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const PhotonInfoTile(
                label: 'Phase',
                value: AppConstants.phaseLabel,
                dense: true,
              ),
              const PhotonInfoTile(
                label: 'License',
                value: 'MIT',
                dense: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              PhotonButton(
                label: 'Open About Page',
                icon: Icons.open_in_new_rounded,
                variant: PhotonButtonVariant.secondary,
                onPressed: () => context.push(AppRoutes.about),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
