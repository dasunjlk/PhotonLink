import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/router/app_router.dart';
import '../../protocols/transfer_method.dart';
import '../../shared/components/components.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../ui/colors.dart';
import '../../ui/motion.dart';
import '../../ui/responsive.dart';
import '../../ui/spacing.dart';

/// Main home screen: branding, transport method selection, and chrome.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final methods = TransferMethod.homeMethods;

    return GradientScaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _HomeHeader(),
                      SizedBox(
                          height: context.responsive(
                              mobile: AppSpacing.xl, desktop: AppSpacing.xxl,),),
                      const _Branding(),
                      SizedBox(
                          height: context.responsive(
                              mobile: AppSpacing.xl, desktop: AppSpacing.xxl,),),
                      _MethodGrid(methods: methods),
                      const SizedBox(height: AppSpacing.xl),
                      const _HomeFooter(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PhotonIconButton(
          icon: Icons.history_rounded,
          tooltip: 'History',
          onPressed: () => context.push(AppRoutes.history),
        ),
        PhotonIconButton(
          icon: Icons.settings_rounded,
          tooltip: 'Settings',
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
    ).animate().fadeIn(duration: AppMotion.normal);
  }
}

class _Branding extends StatelessWidget {
  const _Branding();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.brandGradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 40),
        )
            .animate()
            .scale(duration: AppMotion.normal, curve: AppMotion.enter)
            .fadeIn(),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppConstants.appTagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppMotion.slow).slideY(begin: 0.1, end: 0);
  }
}

class _MethodGrid extends StatelessWidget {
  const _MethodGrid({required this.methods});

  final List<TransferMethod> methods;

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;

    void open(TransferMethod method) {
      if (method.isAvailable) {
        context.push(AppRoutes.transferSetupPath(method));
      }
    }

    if (wide) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < methods.length; i++) ...[
                Expanded(
                  child: PhotonMethodCard(
                    method: methods[i],
                    onTap:
                        methods[i].isAvailable ? () => open(methods[i]) : null,
                  )
                      .animate(delay: AppMotion.stagger * i)
                      .fadeIn(duration: AppMotion.normal)
                      .slideY(begin: 0.12, end: 0),
                ),
                if (i != methods.length - 1)
                  const SizedBox(width: AppSpacing.md),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < methods.length; i++) ...[
          PhotonMethodCard(
            method: methods[i],
            compact: true,
            onTap: methods[i].isAvailable ? () => open(methods[i]) : null,
          )
              .animate(delay: AppMotion.stagger * i)
              .fadeIn(duration: AppMotion.normal)
              .slideX(begin: 0.1, end: 0),
          if (i != methods.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          children: [
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.about),
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              label: const Text('About'),
            ),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.analytics),
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text('Analytics'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '© ${DateTime.now().year} PhotonLink · All rights reserved.',
          textAlign: TextAlign.center,
          style: muted,
        ),
        const SizedBox(height: 2),
        Text(
          'Version ${AppConstants.appVersion} · ${AppConstants.phaseLabel}',
          textAlign: TextAlign.center,
          style: muted,
        ),
      ],
    );
  }
}
