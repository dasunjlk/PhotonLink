import '../../settings/domain/app_settings.dart';
import '../fec/models/fec_configuration.dart';
import '../fec/models/fec_profile.dart';

/// Builds [FecConfiguration] from application settings.
class FecConfigurationFactory {
  const FecConfigurationFactory();

  FecConfiguration fromSettings(AppSettings settings) {
    final profile = settings.fecProfile;
    final redundancy = profile == FecProfile.auto
        ? settings.redundancyPercent
        : profile.resolveRedundancy(overridePercent: settings.redundancyPercent);

    return FecConfiguration(
      enabled: settings.fecEnabled,
      profile: profile,
      redundancyPercent: redundancy,
    );
  }
}
