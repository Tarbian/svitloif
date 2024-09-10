
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsPage({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Налаштування'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Тема'),
            SwitchListTile(
              title: const Text('Темний режим'),
              value: currentThemeMode == ThemeMode.dark,
              onChanged: (bool value) {
                onThemeChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
