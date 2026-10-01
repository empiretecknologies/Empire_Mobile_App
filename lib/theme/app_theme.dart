import 'package:flutter/material.dart';

class AppColors {
  static const Color forest = Color(0xFF0E6B38);
  static const Color forestDeep = Color(0xFF094D28);
  static const Color forestMid = Color(0xFF157A40);
  static const Color lime = Color(0xFFB8E05A);
  static const Color limeSoft = Color(0xFF9CCC65);
  static const Color card = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF7F7F7);
  static const Color inputBorder = Color(0xFFD9D9D9);
  static const Color mqtBar = Color(0xFFEEEEEE);
  static const Color textDark = Color(0xFF2B2B2B);
  static const Color textMuted = Color(0xFF6F6F6F);
  static const Color onForest = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get light {
    const seed = AppColors.forest;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        primary: AppColors.forest,
      ),
      scaffoldBackgroundColor: AppColors.forestDeep,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _inputBorder(AppColors.inputBorder),
        enabledBorder: _inputBorder(AppColors.inputBorder),
        focusedBorder: _inputBorder(AppColors.forest, width: 1.4),
        errorBorder: _inputBorder(const Color(0xFFC62828)),
        focusedErrorBorder: _inputBorder(const Color(0xFFC62828), width: 1.4),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.forest;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.onForest),
        side: const BorderSide(color: AppColors.forest, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
