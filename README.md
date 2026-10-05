# Казахстан обои (KazWall)

Обои и открытки Казахстана для Android. Приложение на Flutter, аналог
[KyrgWall](https://github.com/maxims884/KyrgWall) с тем же набором функций:

- лента, категории, избранное, поиск по тегам на трёх языках;
- установка обоев на главный экран, экран блокировки или оба, сохранение в галерею, «Поделиться»;
- открытки для WhatsApp и «открытка с именем» — свой текст поверх открытки;
- автосмена обоев раз в сутки, уведомления «Обои недели», напоминания и открытки к праздникам;
- светлая и тёмная тема, русский, казахский и английский языки;
- реклама AdMob (баннер, нативная в сетке, межстраничная) и покупки в Google Play.

## Сервер — GitHub вместо Firebase

Firebase в проекте нет. Картинки и их список (`catalog.json`) лежат в ветке `content` этого
репозитория, приложение читает их по обычным ссылкам `raw.githubusercontent.com`, запасной
адрес — CDN jsDelivr. Бот в GitHub Actions каждый день добавляет новые картинки коммитом.
Это бесплатно, без ключей и квот на чтение; подробности — в [content_bot/README.md](content_bot/README.md).

Чего при этом нет по сравнению с KyrgWall: статистики Firebase Analytics.

## Что где

```
lib/                    приложение
  config.dart           адреса контента, рекламные блоки, товары — всё, что меняется при публикации
  l10n/strings.dart     тексты на трёх языках
  services/             каталог, избранное, поиск, праздники, реклама, покупки, фоновые задачи
  screens/              главный экран, сетка, просмотр, открытка с именем, настройки
packages/kazwall_native Kotlin: установка обоев, отправка в WhatsApp, открытие ссылок
content_bot/            бот контента (Python)
content/                ветка content, подключённая как git worktree (в main не входит)
store_listing/          описания, скриншоты и обложка для Google Play
tools/                  иконка приложения и съёмка экранов для скриншотов
.github/workflows/      ежедневный запуск бота
```

## Первый запуск

```
git remote add origin git@github.com:maxims884/KazWall.git
git push -u origin main content
```

Репозиторий должен быть публичным. Если он называется иначе — поменять адреса в `lib/config.dart`.
После клонирования на другом компьютере ветка с картинками подключается так:
`git worktree add content content`.

## Сборка

```
flutter pub get
flutter run                       # отладка
flutter build appbundle           # файл для Google Play
```

Отладка без интернета и без рекламы — контент с компьютера:

```
cd content && python -m http.server 8000 --protocol HTTP/1.1
flutter run --dart-define=CONTENT_BASE=http://10.0.2.2:8000/ --dart-define=NO_ADS=true
```

## Перед публикацией в Google Play

1. **AdMob.** Сейчас стоят тестовые блоки Google. Создать приложение в AdMob, вписать свои
   идентификаторы блоков в `lib/config.dart` и идентификатор приложения в
   `android/app/src/main/AndroidManifest.xml`.
2. **Ключ подписи.** Создать `android/key.properties` (в репозиторий не попадает):
   ```
   storeFile=C:/путь/к/ключу.jks
   storePassword=…
   keyAlias=…
   keyPassword=…
   ```
   Без него сборка подписывается отладочным ключом, и Google Play её не примет.
3. **Покупки.** Завести в Play Console товары `ad_off` (отключение рекламы) и `charity`
   (пожертвование). Пока их нет, раздел покупок в настройках скрыт.
4. **Страница приложения.** Тексты — `store_listing/ru.md`, `kk.md`, `en.md`; картинки —
   `store_listing/screenshots/<язык>/` (01–06 и `feature_graphic.png`), иконка — `store_listing/icon_512.png`.
5. Казахские тексты интерфейса, открыток и описания стоит показать носителю языка.

## Скриншоты заново

Экраны снимаются с эмулятора скриптом `tools/capture.sh <язык>` (условия — в его шапке),
затем `python store_listing/make_screenshots.py` и `python store_listing/make_feature_graphic.py`.
