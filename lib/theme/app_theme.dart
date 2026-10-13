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
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color pageBackground(BuildContext context) =>
      isDark(context) ? const Color(0xFF101614) : const Color(0xFFF4F7F4);

  static Color cardColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF1B2420) : AppColors.card;

  static Color primaryText(BuildContext context) =>
      isDark(context) ? const Color(0xFFE7EEE9) : AppColors.textDark;

  static Color secondaryText(BuildContext context) =>
      isDark(context) ? const Color(0xFFB7C3BB) : AppColors.textMuted;

  static Color dividerColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF2C3832) : const Color(0xFFE8EEE8);

  static Color zebraColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF161E1B) : const Color(0xFFF7FAF7);

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
      inputDecorationTheme: _inputDecoration(
        fill: AppColors.inputFill,
        hint: AppColors.textMuted,
        border: AppColors.inputBorder,
        focus: AppColors.forest,
      ),
      checkboxTheme: _checkboxTheme,
      navigationBarTheme: _navigationBarTheme(
        background: AppColors.card,
        selected: AppColors.forest,
        unselected: AppColors.textMuted,
        indicator: AppColors.forest.withValues(alpha: 0.12),
      ),
      bottomSheetTheme: _bottomSheetTheme,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.forestMid,
        surface: const Color(0xFF121816),
        onSurface: const Color(0xFFE7EEE9),
      ),
      scaffoldBackgroundColor: const Color(0xFF101614),
      inputDecorationTheme: _inputDecoration(
        fill: const Color(0xFF1B2420),
        hint: const Color(0xFFB7C3BB),
        border: const Color(0xFF314039),
        focus: AppColors.limeSoft,
      ),
      checkboxTheme: _checkboxTheme,
      navigationBarTheme: _navigationBarTheme(
        background: const Color(0xFF1B2420),
        selected: AppColors.lime,
        unselected: const Color(0xFFB7C3BB),
        indicator: AppColors.forest.withValues(alpha: 0.45),
      ),
      bottomSheetTheme: _bottomSheetTheme,
    );
  }

  static InputDecorationTheme _inputDecoration({
    required Color fill,
    required Color hint,
    required Color border,
    required Color focus,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: TextStyle(color: hint, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: _inputBorder(border),
      enabledBorder: _inputBorder(border),
      focusedBorder: _inputBorder(focus, width: 1.4),
      errorBorder: _inputBorder(const Color(0xFFC62828)),
      focusedErrorBorder: _inputBorder(const Color(0xFFC62828), width: 1.4),
    );
  }

  static CheckboxThemeData get _checkboxTheme {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.forest;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.onForest),
      side: const BorderSide(color: AppColors.forest, width: 1.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    );
  }

  static NavigationBarThemeData _navigationBarTheme({
    required Color background,
    required Color selected,
    required Color unselected,
    required Color indicator,
  }) {
    return NavigationBarThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: indicator,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? selected : unselected,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: isSelected ? selected : unselected,
          size: 22,
        );
      }),
    );
  }

  static const BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class AppThemeScope extends StatelessWidget {
  const AppThemeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.mode,
      builder: (context, mode, child) {
        return Theme(
          data: mode == ThemeMode.dark ? AppTheme.dark : AppTheme.light,
          child: child!,
        );
      },
      child: child,
    );
  }
}
