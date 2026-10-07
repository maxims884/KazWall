# Казахстан обои (KazWall)

Обои и открытки Казахстана для Android. Приложение на Flutter, аналог
[KyrgWall](https://github.com/maxims884/KyrgWall) с тем же набором функций:

- лента, категории, избранное, поиск по тегам на трёх языках;
- установка обоев на главный экран, экран блокировки или оба, сохранение в галерею, «Поделиться»;
- открытки для WhatsApp и «открытка с именем» — свой текст поверх открытки;
- автосмена обоев раз в сутки, уведомления «Обои недели», напоминания и открытки к праздникам;
- светлая и тёмная тема, русский, казахский и английский языки;
- реклама AdMob (баннер, нативная в сетке, межстраничная) и покупки в Google Play.

## Два приложения из одного кода

Из этого проекта собираются два приложения (flavor): `kaz` — «Казахстан обои» (`kz.black13.kazwall`)
и `uzb` — «Узбекистан обои» (`uz.black13.uzbwall`). Код общий, отличается только то, что относится к стране:

| | Казахстан (`kaz`) | Узбекистан (`uzb`) |
|---|---|---|
| Пакет, идентификатор AdMob | `android/app/build.gradle.kts` | там же |
| Название, иконка | `android/app/src/kaz/res`, `src/main/res` | `android/app/src/uzb/res` |
| Адрес контента, реклама, языки | `lib/config.dart` | там же, по `Config.uzb` |
| Тексты | `lib/l10n/strings.dart`: ru, kk, en | ru, uz, en |
| Праздники, слова поиска, цвета | `lib/services/holidays.dart`, `search.dart`, `lib/theme.dart` | там же |
| Контент | ветка `content`, папка `content/` | ветка `content-uzb`, папка `content_uzb/` |
| Бот | `content_bot/countries/kaz.py`, `.github/workflows/content.yml` | `countries/uzb.py`, `content-uzb.yml` |
| Google Play | `store_listing/` | `store_listing/uzb/` |

Без `--flavor` собирается Казахстан (`default-flavor` в `pubspec.yaml`). В Android Studio flavor
указывается в конфигурации запуска: Run → Edit Configurations → Build flavor.

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
content_uzb/            то же для Узбекистана: ветка content-uzb
store_listing/          описания, скриншоты и обложка для Google Play (uzb/ — для Узбекистана)
tools/                  иконка приложения и съёмка экранов для скриншотов
.github/workflows/      ежедневный запуск бота
```

## Первый запуск

```
git remote add origin git@github.com:maxims884/KazWall.git
git push -u origin main content
```

Репозиторий должен быть публичным. Если он называется иначе — поменять адреса в `lib/config.dart`.
После клонирования на другом компьютере ветки с картинками подключаются так:
`git worktree add content content` и `git worktree add content_uzb content-uzb`.

## Сборка

```
flutter pub get
flutter run                       # отладка, «Казахстан обои»
flutter run --flavor uzb          # «Узбекистан обои»
flutter build appbundle --flavor kaz    # файл для Google Play: build/app/outputs/bundle/kazRelease/
flutter build appbundle --flavor uzb    # …и для Узбекистана: build/app/outputs/bundle/uzbRelease/
```

Отладка без интернета и без рекламы — контент с компьютера:

```
cd content && python -m http.server 8000 --protocol HTTP/1.1
flutter run --dart-define=CONTENT_BASE=http://10.0.2.2:8000/ --dart-define=NO_ADS=true
```

Для Узбекистана — то же с папкой `content_uzb` и `--flavor uzb`.

## Перед публикацией «Узбекистан обои»

1. Отправить на GitHub ветку `content-uzb` (первые картинки уже в папке `content_uzb`) и `main`
   с ботом: `git -C content_uzb push -u KazWall content-uzb`. Пока ветки нет на GitHub, приложение пустое.
2. **AdMob.** Завести приложение `uz.black13.uzbwall` и три блока, вписать идентификатор приложения
   в `android/app/build.gradle.kts`, блоки — в `lib/config.dart` (`_uzbBanner`, `_uzbNative`,
   `_uzbInterstitial`). Сейчас там тестовые идентификаторы Google — дохода с них нет.
3. В Play Console создать новое приложение, товары `ad_off` и `charity`, материалы взять
   из `store_listing/uzb/`. Ключ подписи — тот же `android/key.properties`.
4. Узбекские тексты (интерфейс, открытки, описание) стоит показать носителю языка.

## Перед публикацией в Google Play

1. **AdMob.** Свои идентификаторы уже вписаны (`lib/config.dart` и `AndroidManifest.xml`).
   В отладочной сборке показываются тестовые блоки Google, в релизной — настоящие:
   на свою рекламу не нажимать, телефон добавить в тестовые устройства AdMob.
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
Для Узбекистана: `FLAVOR=uzb tools/capture.sh <язык>`, а скриптам добавить `uzb`;
иконка — `python tools/make_icon.py uzb`.
