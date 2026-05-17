import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remixicon/remixicon.dart';
import '../providers/theme_provider.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // استخدام Consumer للاستماع للتغييرات وإعادة بناء الواجهة
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('الإعدادات'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: ExpansionTile(
                  leading: const Icon(Remix.contrast_2_line),
                  title: const Text('المظهر',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_getThemeString(themeProvider.themeMode)),
                  initiallyExpanded: true,
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('فاتح'),
                      value: ThemeMode.light,
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) {
                        if (value != null) themeProvider.setThemeMode(value);
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('داكن'),
                      value: ThemeMode.dark,
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) {
                        if (value != null) themeProvider.setThemeMode(value);
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('تلقائي (حسب النظام)'),
                      value: ThemeMode.system,
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) {
                        if (value != null) themeProvider.setThemeMode(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getThemeString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
      case ThemeMode.system:
        return 'تلقائي';
    }
  }
}
