import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/picture.dart';
import '../services/ads.dart';
import '../services/background.dart';
import '../services/catalog.dart';
import '../services/favorites.dart';
import '../services/prefs.dart';
import '../services/purchases.dart';
import '../services/search.dart';
import 'picture_grid.dart';
import 'settings_screen.dart';
import 'viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Вкладки в том же порядке, что и на экране; первая — избранное
  static const _tabTypes = [
    Favorites.type,
    Catalog.feed,
    Catalog.cards,
    'nature',
    'animals',
    'arch',
    'relig',
    'culture',
  ];
  // Приложение открывается на ленте
  static const _defaultTab = 1;

  late final _tabs = TabController(length: _tabTypes.length, vsync: this, initialIndex: _defaultTab);
  final _searchField = TextEditingController();
  bool _searching = false;
  String _query = '';
  Timer? _pending;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
    Prefs.markOpened();
    Notifications.onOpen = _openFromNotification;
    _start();
  }

  Future<void> _start() async {
    try {
      await Scheduler.init();
      await Scheduler.sync();
    } catch (_) {
      // Фоновые задачи недоступны — остальное приложение работает
    }
    Purchases.init();
    Ads.init();
    await Notifications.handleLaunch();
    // Один раз спрашиваем разрешение на уведомления
    if (!Prefs.notificationsAsked) {
      Prefs.notificationsAsked = true;
      if (!await Notifications.hasPermission()) await Notifications.requestPermission();
    }
  }

  @override
  void dispose() {
    _pending?.cancel();
    _tabs.dispose();
    _searchField.dispose();
    super.dispose();
  }

  String get _type {
    if (_searching && _query.isNotEmpty) return Search.prefix + _query;
    return _tabTypes[_tabs.index];
  }

  Future<void> _openFromNotification(Map<String, dynamic> payload) async {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    _closeSearch();
    // Уведомление о празднике открывает вкладку с открытками
    final tab = _tabTypes.indexOf(payload['openType']?.toString() ?? '');
    if (tab >= 0) {
      _tabs.index = tab;
      return;
    }
    final json = payload['picture'];
    final picture = json is Map ? Picture.fromJson(json.cast<String, dynamic>()) : null;
    if (picture == null) return;
    // Картинка из уведомления показывается первой, дальше листается лента
    _tabs.index = _defaultTab;
    final rest = (await Catalog.cached()).where((p) => p.file != picture.file).toList();
    if (!mounted) return;
    openViewer(context, [picture, ...Catalog.feedOrder(rest)], 0);
  }

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() {
    _pending?.cancel();
    _searchField.clear();
    setState(() {
      _searching = false;
      _query = '';
    });
  }

  // Ищем по мере ввода, но с небольшой паузой, чтобы не перерисовывать сетку на каждую букву
  void _onQueryChanged(String text) {
    _pending?.cancel();
    _pending = Timer(const Duration(milliseconds: 350), () => _search(text));
  }

  void _search(String text) {
    _pending?.cancel();
    final query = text.trim();
    if (query.isEmpty || query == _query) return;
    setState(() => _query = query);
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final titles = [
      s['nav_favorites'],
      s['tab_feed'],
      s['tab_cards'],
      s['tab_nature'],
      s['tab_animals'],
      s['tab_arch'],
      s['tab_relig'],
      s['tab_culture'],
    ];

    return PopScope(
      // "Назад" сначала закрывает поиск
      canPop: !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _searching ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _closeSearch) : null,
          title:
              _searching
                  ? TextField(
                    controller: _searchField,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(hintText: s['search_hint'], border: InputBorder.none),
                    onChanged: _onQueryChanged,
                    onSubmitted: (text) {
                      _search(text);
                      FocusScope.of(context).unfocus();
                    },
                  )
                  : Text(s['app_name']),
          actions: [
            if (!_searching) IconButton(icon: const Icon(Icons.search), tooltip: s['search'], onPressed: _openSearch),
            if (_searching && _searchField.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchField.clear();
                  setState(() {});
                },
              ),
            if (!_searching)
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: s['action_settings'],
                onPressed: _openSettings,
              ),
          ],
          bottom:
              _searching
                  ? null
                  : TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      for (var i = 0; i < titles.length; i++)
                        _tabTypes[i] == Favorites.type
                            ? Tab(icon: Icon(Icons.favorite, semanticLabel: titles[i]))
                            : Tab(text: titles[i]),
                    ],
                  ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child:
                    _searching && _query.isEmpty
                        ? const SizedBox.expand()
                        // Ключ пересоздаёт сетку при смене вкладки или запроса
                        : PictureGrid(key: ValueKey(_type), type: _type),
              ),
              ColoredBox(color: colors.surface, child: const Center(heightFactor: 1, child: BannerAdBox())),
            ],
          ),
        ),
      ),
    );
  }
}
