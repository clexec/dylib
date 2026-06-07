====================================================
  DouX — УСТАНОВКА НА IPHONE БЕЗ ДЖЕЙЛБРЕЙКА
====================================================

ЧТО НУЖНО:
  - Python 3.x  (python.org)
  - Sideloadly   (sideloadly.io)
  - TikTok IPA   (папка DeTok или .ipa файл)

ШАГ 1 — Собери dylib через GitHub Actions
  Залей проект DouX-main на GitHub.
  Actions → Build DouX → Run workflow.
  Скачай артефакт "DouX-inject-kit".

ШАГ 2 — Распакуй inject-kit
  Внутри будет:
    DouX.dylib
    Ellekit.framework/
    inject_ipa.py
    README.txt  ← ты здесь

ШАГ 3 — Установи Python зависимость
  Открой командную строку (cmd или PowerShell):
    pip install lief

ШАГ 4 — Сделай модифицированный IPA
  В командной строке:
    python inject_ipa.py "C:\Users\...\DeTok" DouX.dylib TikTok-DouX.ipa

  Или если у тебя .ipa файл:
    python inject_ipa.py TikTok.ipa DouX.dylib TikTok-DouX.ipa

ШАГ 5 — Установи через Sideloadly
  1. Открой Sideloadly
  2. Перетащи TikTok-DouX.ipa в окно
  3. Введи Apple ID
  4. Нажми Start
  5. На iPhone: Настройки → Основные → VPN и управление устройством
     → Найди свой Apple ID → Доверять

====================================================
  ФУНКЦИИ DOUX
====================================================

  Ghost Mode (Настройки → DouX Settings → Ghost Mode):
    - Read Receipt Ghost  — нечиталка в ЛС
    - Profile View Ghost  — невидимка при просмотре профилей
    - Hide Online Status  — всегда оффлайн
    - Hide Typing         — нет "печатает..."

  Region Bypass (Настройки → DouX Settings → Region):
    - Включи "Enable Region Changing"
    - Выбери страну

  + Скачивание видео, скрытие рекламы и многое другое

====================================================
  ВАЖНО
====================================================

  - IPA нужно переустанавливать каждые 7 дней
    (или купи Apple Developer за $99/год — тогда 1 год)
  - После обновления TikTok придётся делать inject заново
  - Если что-то не работает — напиши в Issues на GitHub

====================================================
