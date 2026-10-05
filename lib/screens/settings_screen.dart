import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kazwall_native/kazwall_native.dart';

import '../l10n/strings.dart';
import '../services/app_settings.dart';
import '../services/background.dart';
import '../services/favorites.dart';
import '../services/prefs.dart';
import '../services/purchases.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = false;
  // Раздел покупок скрыт, пока Google Play не отдал товары
  List<ProductDetails> _products = const [];

  @override
  void initState() {
    super.initState();
    Notifications.hasPermission().then((allowed) {
      if (mounted) setState(() => _notifications = allowed);
    });
    Purchases.products().then((products) {
      if (mounted) setState(() => _products = products);
    });
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _warnIfNoFavorites() {
    if (Prefs.autoWallpaper && Prefs.autoFromFavorites && Favorites.getAll().isEmpty) {
      _toast(S.of(context)['settings_auto_no_favorites']);
    }
  }

  /// Выключить уведомление можно всегда, а включить — только с разрешением системы
  Future<void> _setNotification(bool enabled, void Function(bool) save) async {
    final s = S.of(context);
    if (enabled && !_notifications) {
      final granted = await Notifications.requestPermission();
      if (!mounted) return;
      if (!granted) {
        _toast(s['notifications_denied']);
        return;
      }
      _notifications = true;
    }
    setState(() => save(enabled));
    Scheduler.sync();
  }

  Future<void> _chooseLanguage() async {
    final s = S.of(context);
    final settings = AppSettings.instance;
    final chosen = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text(s['settings_section_language']),
            children: [
              for (final code in ['', ...S.languages])
                // Обычная строка, а не RadioListTile: нажатие на уже выбранный язык тоже закрывает окно
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(
                    code == settings.language ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: code == settings.language ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(code.isEmpty ? s['lang_system'] : languageNames[code]!),
                  onTap: () => Navigator.of(context).pop(code),
                ),
            ],
          ),
    );
    if (chosen != null) settings.language = chosen;
  }

  // Тема и язык меняются снаружи экрана, поэтому перерисовываемся вместе с ними
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: AppSettings.instance, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final s = S.of(context);
    final settings = AppSettings.instance;
    final language = settings.language;

    return Scaffold(
      appBar: AppBar(title: Text(s['action_settings'])),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Section(s['settings_section_auto']),
            SwitchListTile(
              title: Text(s['settings_auto_wallpaper']),
              subtitle: Text(s['settings_auto_wallpaper_hint']),
              value: Prefs.autoWallpaper,
              onChanged: (value) {
                setState(() => Prefs.autoWallpaper = value);
                Scheduler.sync();
                if (value) _warnIfNoFavorites();
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: true, label: Text(s['settings_auto_source_favorites'])),
                  ButtonSegment(value: false, label: Text(s['settings_auto_source_all'])),
                ],
                selected: {Prefs.autoFromFavorites},
                onSelectionChanged:
                    !Prefs.autoWallpaper
                        ? null
                        : (value) {
                          setState(() => Prefs.autoFromFavorites = value.first);
                          _warnIfNoFavorites();
                        },
              ),
            ),
            SwitchListTile(
              title: Text(s['settings_weekly']),
              subtitle: Text(s['settings_weekly_hint']),
              value: Prefs.weekly && _notifications,
              onChanged: (value) => _setNotification(value, (v) => Prefs.weekly = v),
            ),
            SwitchListTile(
              title: Text(s['settings_reminder']),
              subtitle: Text(s['settings_reminder_hint']),
              value: Prefs.reminder && _notifications,
              onChanged: (value) => _setNotification(value, (v) => Prefs.reminder = v),
            ),
            SwitchListTile(
              title: Text(s['settings_holidays']),
              subtitle: Text(s['settings_holidays_hint']),
              value: Prefs.holidays && _notifications,
              onChanged: (value) => _setNotification(value, (v) => Prefs.holidays = v),
            ),

            _Section(s['settings_section_theme']),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: ThemeMode.system, label: Text(s['theme_system'])),
                  ButtonSegment(value: ThemeMode.light, label: Text(s['theme_light'])),
                  ButtonSegment(value: ThemeMode.dark, label: Text(s['theme_dark'])),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (value) => settings.themeMode = value.first,
              ),
            ),

            _Section(s['settings_section_language']),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(language.isEmpty ? s['lang_system'] : languageNames[language]!),
              trailing: const Icon(Icons.chevron_right),
              onTap: _chooseLanguage,
            ),

            _Section(s['settings_section_rate']),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(s['settings_rate']),
              trailing: const Icon(Icons.chevron_right),
              onTap: KazwallNative.openStore,
            ),

            if (_products.isNotEmpty) ...[
              _Section(s['settings_section_purchases']),
              for (final product in _products)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: FilledButton.tonal(
                    onPressed: () => Purchases.buy(product),
                    child: Text('${product.title} · ${product.price}', textAlign: TextAlign.center),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
