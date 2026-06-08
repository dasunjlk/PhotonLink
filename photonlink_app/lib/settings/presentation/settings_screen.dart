import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bootstrap.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/staggered_reveal.dart';
import '../../ui/spacing.dart';
import '../../transfer/scheduler/transfer_mode.dart';
import '../application/settings_controller.dart';

/// Settings screen with theme, transfer, and camera preference placeholders.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final packageInfo = ref.watch(packageInfoProvider);

    return GradientScaffold(
      appBar: photonAppBar(context, title: 'Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            StaggeredReveal(
              children: [
                const SectionHeader(title: 'Appearance'),
                GlassCard(
                  child: Column(
                    children: [
                      _ThemeModeTile(
                        value: settings.themeMode,
                        onChanged: controller.updateThemeMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(
                  title: 'Language',
                  subtitle: 'Localization coming in a future release',
                ),
                GlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('Language'),
                    subtitle: Text(_languageLabel(settings.language)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showLanguageDialog(context, controller),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Transfer Preferences'),
                GlassCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Compression (GZip)'),
                        subtitle: const Text(
                          'Compress before packetization (LZ4 placeholder disabled)',
                        ),
                        value: settings.compressionEnabled,
                        onChanged: controller.toggleCompression,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Encryption'),
                        subtitle: const Text(
                          'ChaCha20-Poly1305 — session key in setup QR',
                        ),
                        value: settings.encryptionEnabled,
                        onChanged: controller.toggleEncryption,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Transfer mode'),
                        subtitle: Text(settings.transferMode.id),
                        trailing: DropdownButton<TransferMode>(
                          value: settings.transferMode,
                          underline: const SizedBox.shrink(),
                          items: TransferMode.values
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.id),
                                ),
                              )
                              .toList(),
                          onChanged: (m) {
                            if (m != null) controller.updateTransferMode(m);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Diagnostics'),
                        subtitle: const Text('Show live transfer metrics'),
                        value: settings.diagnosticsEnabled,
                        onChanged: controller.toggleDiagnostics,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Camera'),
                GlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.camera_alt_rounded),
                    title: const Text('Camera Resolution'),
                    subtitle: Text(
                      settings.cameraResolution == 'high'
                          ? 'High (1080p)'
                          : 'Medium (720p)',
                    ),
                    trailing: DropdownButton<String>(
                      value: settings.cameraResolution,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: 'high',
                          child: Text('High'),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.updateCameraResolution(value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'About'),
                GlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('App Version'),
                    subtitle: Text(
                      '${packageInfo.version} (${packageInfo.buildNumber})',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _languageLabel(String code) {
    return switch (code) {
      'en' => 'English',
      'es' => 'Español',
      'fr' => 'Français',
      'de' => 'Deutsch',
      _ => code,
    };
  }

  void _showLanguageDialog(
    BuildContext context,
    SettingsController controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in {'en': 'English', 'es': 'Español', 'fr': 'Français', 'de': 'Deutsch'}.entries)
              ListTile(
                title: Text(entry.value),
                onTap: () {
                  controller.updateLanguage(entry.key);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.value,
    required this.onChanged,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
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
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
