import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/services/password_strength.dart';

/// Texto e cor de cada nível de força de senha.
extension StrengthLevelPresentation on StrengthLevel {
  String get label => switch (this) {
    StrengthLevel.weak => AppStrings.strengthWeak,
    StrengthLevel.medium => AppStrings.strengthMedium,
    StrengthLevel.strong => AppStrings.strengthStrong,
  };

  double get hue => switch (this) {
    StrengthLevel.weak => AppColors.weakHue,
    StrengthLevel.medium => AppColors.mediumHue,
    StrengthLevel.strong => AppColors.strongHue,
  };
}
