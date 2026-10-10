import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Acesso aos tokens do tema pelo contexto.
extension ThemeContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  AppTextStyles get textStyles => Theme.of(this).extension<AppTextStyles>()!;
}
