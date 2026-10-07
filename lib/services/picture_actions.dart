import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart' show DefaultCacheManager;
import 'package:gal/gal.dart';
import 'package:kazwall_native/kazwall_native.dart';

import '../config.dart';
import '../l10n/strings.dart';
import '../models/picture.dart';

enum SaveResult { saved, failed, denied }

class PictureActions {
  /// Скачивает оригинал картинки или берёт его из кэша, если она уже была на экране
  static Future<File?> file(Picture picture) async {
    try {
      return await DefaultCacheManager().getSingleFile(picture.url, key: picture.file);
    } catch (_) {
      return null;
    }
  }

  static Future<SaveResult> saveToGallery(File file) async {
    try {
      if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) {
        return SaveResult.denied;
      }
      // Галерее нужно расширение в имени файла, а в кэше оно есть не всегда
      var source = file;
      if (!RegExp(r'\.(jpe?g|png)$', caseSensitive: false).hasMatch(file.path)) {
        source = await file.copy('${file.parent.path}/${Config.album.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      }
      await Gal.putImage(source.path, album: Config.album);
      return SaveResult.saved;
    } on GalException catch (e) {
      return e.type == GalExceptionType.accessDenied ? SaveResult.denied : SaveResult.failed;
    } catch (_) {
      return SaveResult.failed;
    }
  }

  /// Открывает окно "Поделиться" или, если просили, сразу WhatsApp
  static Future<bool> share(File file, S s, {required bool whatsApp}) => KazwallNative.shareImage(
    file.path,
    text: s['share_text'] + Config.storeUrl,
    title: s['share'],
    name: Config.album.toLowerCase(),
    whatsApp: whatsApp,
  );
}
