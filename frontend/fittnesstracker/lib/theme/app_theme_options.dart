import 'package:flutter/material.dart';

class AppThemeOption {
  final String label;
  final Color seedColor;

  const AppThemeOption({required this.label, required this.seedColor});
}

const List<AppThemeOption> appThemeOptions = [
  AppThemeOption(label: 'Standard Blau', seedColor: Colors.blue),
  AppThemeOption(label: 'Waldgrün', seedColor: Colors.green),
  AppThemeOption(label: 'Sonnenorange', seedColor: Colors.orange),
  AppThemeOption(label: 'Violett', seedColor: Colors.deepPurple),
  AppThemeOption(label: 'Kirschrot', seedColor: Colors.red),
];

int normalizeThemeIndex(int index) {
  if (index < 0 || index >= appThemeOptions.length) return 0;
  return index;
}

ThemeData buildAppTheme(int selectedThemeIndex) {
  final normalized = normalizeThemeIndex(selectedThemeIndex);
  final option = appThemeOptions[normalized];

  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: option.seedColor,
    brightness: Brightness.light,
  );
}
