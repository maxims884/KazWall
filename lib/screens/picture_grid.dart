import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/picture.dart';
import '../services/ads.dart';
import '../services/catalog.dart';
import '../services/favorites.dart';
import '../services/search.dart';
import '../theme.dart';
import 'viewer_screen.dart';

/// Сетка картинок одной вкладки. После каждых нескольких рядов — нативная реклама на всю ширину
class PictureGrid extends StatefulWidget {
  const PictureGrid({super.key, required this.type});

  /// Категория, "feed", "favorites" или "search:<запрос>"
  final String type;

  @override
  State<PictureGrid> createState() => _PictureGridState();
}

class _PictureGridState extends State<PictureGrid> {
  // Сколько рядов картинок между рекламными блоками
  static const _rowsBetweenAds = 4;

  List<Picture>? _pictures;

  @override
  void initState() {
    super.initState();
    _load(refresh: false);
  }

  Future<void> _load({required bool refresh}) async {
    final type = widget.type;
    List<Picture> pictures;
    if (type == Favorites.type) {
      pictures = Favorites.getAll();
    } else {
      final all = await Catalog.load(refresh: refresh);
      if (type.startsWith(Search.prefix)) {
        pictures = Search.filter(all, type.substring(Search.prefix.length));
      } else if (type == Catalog.feed) {
        // Лента: все категории вперемешку, при каждом открытии в новом порядке
        pictures = Catalog.feedOrder(all);
      } else {
        pictures = Catalog.ofType(all, type);
      }
    }
    if (mounted) setState(() => _pictures = pictures);
  }

  String _emptyText(S s) {
    final type = widget.type;
    if (type == Favorites.type) return s['favorites_empty'];
    if (type == Catalog.cards) return s['cards_empty'];
    if (type.startsWith(Search.prefix)) return s['search_empty'];
    return s['load_failed'];
  }

  @override
  Widget build(BuildContext context) {
    final pictures = _pictures;
    if (pictures == null) return const Center(child: CircularProgressIndicator());

    // На планшетах три колонки
    final columns = MediaQuery.sizeOf(context).shortestSide >= 600 ? 3 : 2;
    final rows = (pictures.length / columns).ceil();
    // Строка списка — либо ряд картинок, либо реклама после каждых _rowsBetweenAds рядов
    final ads = Ads.enabled ? (rows - 1) ~/ _rowsBetweenAds : 0;

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child:
          pictures.isEmpty
              ? LayoutBuilder(
                builder:
                    (context, box) => SingleChildScrollView(
                      // Чтобы пустой экран тоже можно было потянуть вниз
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: box.maxHeight,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _emptyText(S.of(context)),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
              )
              : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(6),
                itemCount: rows + ads,
                itemBuilder: (context, index) {
                  final group = index ~/ (_rowsBetweenAds + 1);
                  final inGroup = index % (_rowsBetweenAds + 1);
                  if (ads > 0 && inGroup == _rowsBetweenAds && group < ads) return const NativeAdTile();
                  final row = index - (ads > 0 ? group.clamp(0, ads) : 0);
                  final first = row * columns;
                  return Row(
                    children: [
                      for (var i = first; i < first + columns; i++)
                        Expanded(
                          child:
                              i < pictures.length
                                  ? _Tile(picture: pictures[i], onTap: () => openViewer(context, pictures, i))
                                  : const SizedBox.shrink(),
                        ),
                    ],
                  );
                },
              ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.picture, required this.onTap});

  final Picture picture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 3 / 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: picture.thumbUrl,
                cacheKey: picture.thumb,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) => ColoredBox(color: colors.surfaceContainerHigh),
                errorWidget: (_, _, _) => ColoredBox(color: colors.surfaceContainerHigh),
              ),
              Material(color: Colors.transparent, child: InkWell(onTap: onTap)),
              Positioned(top: 8, right: 8, child: _FavoriteButton(picture: picture)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.picture});

  final Picture picture;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Favorites.changes,
      builder: (context, _, _) {
        final favorite = Favorites.isFavorite(picture);
        return Material(
          color: Colors.black.withValues(alpha: 0.4),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Favorites.toggle(picture),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                favorite ? Icons.favorite : Icons.favorite_border,
                size: 22,
                color: favorite ? brandGold : Colors.white,
                semanticLabel: S.of(context)['favorite'],
              ),
            ),
          ),
        );
      },
    );
  }
}
