# НТрнет: API и вход игроков (этап 2)

Python 3.11+, Flask, SQLAlchemy, MariaDB и Waitress. Сервис слушает только
`127.0.0.1:8091`. SQLite допускается исключительно для локальной разработки.
Каталог и страницы из базы совместимы с PDA первого этапа. В браузере доступны
вход и личный список сайтов. Создание сайтов, редактор, обработка HTML/CSS и R2
относятся к этапу 3 и пока не реализованы.

## Локальная проверка

Из корня репозитория, PowerShell:

```powershell
python -m venv .cache/ntrnet-venv
.cache/ntrnet-venv/Scripts/python -m pip install -r services/ntrnet/requirements.lock
$env:NTRNET_DATABASE_URL = 'sqlite:///ntrnet-local.sqlite'
$env:NTRNET_PUBLIC_URL = 'http://127.0.0.1:8091'
Set-Location services/ntrnet
../../.cache/ntrnet-venv/Scripts/python manage.py init-db
../../.cache/ntrnet-venv/Scripts/python manage.py register-server dark-paradise 'Dark Paradise' ss13dp
../../.cache/ntrnet-venv/Scripts/python manage.py seed-demo --owner yourckey
../../.cache/ntrnet-venv/Scripts/python app.py
```

Регистрация выводит случайный ключ сервера один раз. Сохраните его в локальном
игровом конфиге, не в исходниках. `seed-demo` — необязательная команда для
локального checkout: импортирует данные из `tools/ntrnet/sites.json` и не
перезаписывает существующие сайты. Подставьте собственный канонический ckey
(строчные латинские буквы и цифры).

```text
NTRNET_ENABLED 1
NTRNET_API_URL http://127.0.0.1:8091
NTRNET_SERVER_KEY <ключ из register-server>
NTRNET_EDITOR_URL http://127.0.0.1:8091
```

Пересоберите игру и TGUI. В PDA откройте НТрнет, запросите код и введите его
на странице сервиса. Код принадлежит подключённому игроку, а не владельцу PDA.
Проверенный launcher-аккаунт использует `account_ckey`; гостям вход закрыт.
На рабочем сервере URL API и редактора должны использовать HTTPS.

## Протокол и хранение

- `POST /api/v1/device/new`, заголовок `X-Server-Key`, JSON `{"ckey":"yourckey"}`:
  ответ 201, `{"code":"XXXX-XXXX-XXXX","expires_in":900}`.
  Код генерирует API через криптографический генератор Python, а игра получает
  его асинхронно. Это уточнение исходного плана: генератор BYOND не используется.
- Один код действует 15 минут и погашается атомарно один раз, в том числе при
  одновременных запросах. Новый код отменяет предыдущий для того же сервера и ckey.
- Выдача ограничена одним запросом на игрока в минуту и 120 на сервер;
  попытки входа — десятью на IP в минуту. Ограничения сохраняются в БД.
- Cookie-сессия действует семь дней. В production используется `__Host-` cookie
  с Secure, HttpOnly и SameSite=Strict. Формы защищены CSRF-токеном и проверкой Origin.
- Ключи серверов, коды и сессии хранятся только в виде SHA-256 хешей.
  HTTP-запрос игры помечен confidential/sensitive; код не попадает в HTTP-лог игры.
- `GET /api/v1/catalog`, `/api/v1/sites/<id>/pages/<slug>` и `/api/v1/zones`
  требуют ключ сервера. Браузерная сессия не даёт доступа к игровому API.
  Скрытые сайты не выдаются игре. Выключенная зона сохраняет старые сайты.
- `/` показывает только сайты текущего автора; общего браузерного каталога нет.
  `/health` проверяет соединение с базой. `manage.py cleanup` удаляет истёкшие записи.

Отключение `servers.active` отзывает доступ сервера, его коды и сессии.
Код может оставаться видимым в PDA после погашения: повторно войти с ним нельзя.
`init-db` создаёт отсутствующие таблицы, но не мигрирует существующую схему.
Перед последующими изменениями схемы нужны отдельная миграция и резервная копия.

## Развёртывание на VDS

Рабочий сервер этими изменениями не настроен. Файлы в `deploy/` — шаблоны для
последующего развёртывания. Пароли и ключи в репозитории отсутствуют.

1. Создайте отдельную базу `ntrnet` (InnoDB, utf8mb4) в существующей MariaDB.
   Для инициализации схемы используйте учётную запись с правом CREATE; для
   работающего приложения — отдельную с SELECT, INSERT, UPDATE, DELETE только
   на `ntrnet.*`. Не используйте root в постоянном конфиге.
2. Установите Python 3.11+, создайте системного пользователя `ntrnet` без shell.
   Скопируйте содержимое `services/ntrnet` в `/srv/ntrnet`, создайте там `.venv`
   и установите `requirements.lock`. Исходники и окружение могут принадлежать root
   и быть доступны сервису только для чтения.
3. Создайте `/etc/ntrnet.env` по `deploy/ntrnet.env.example`, права root:root 0600.
   Пароль в URL БД должен быть URL-encoded. Не публикуйте этот файл или вывод
   `register-server`. Загрузите переменные в административное окружение, выполните
   `manage.py init-db` и `manage.py register-server dark-paradise 'Dark Paradise' ss13dp`.
   После инициализации используйте ограниченную учётную запись БД.
4. Установите три unit-файла из `deploy/` в `/etc/systemd/system/` и выполните
   `systemctl daemon-reload`, затем `systemctl enable --now ntrnet.service ntrnet-cleanup.timer`.
   Приложение ограничено 256 МБ RAM, 50% CPU, Nice=19, OOMScoreAdjust=500.
   Очистка выполняется раз в час. Для проверки используйте `systemctl status ntrnet`
   и `/health` с заголовком Host, соответствующим `NTRNET_PUBLIC_URL`.
5. Настройте TLS и nginx по разделу ниже. Порт 8091 и MariaDB не открывайте наружу.
   Добавьте рабочий ключ и HTTPS URL в конфиг игры, затем перезапустите игру.
   Настройте резервное копирование базы вместе с существующими резервными копиями VDS.

## Cloudflare: что понадобится потом

Для API и страницы входа нужен поддомен `ntrnet.wiki-ss13.space`. В DNS зоны
`wiki-ss13.space` создайте A-запись `ntrnet` с адресом VDS и включённым проксированием.
AAAA нужна только при действительно работающем IPv6. Перед изменением проверьте,
что запись ещё не занята. [Инструкция Cloudflare](https://developers.cloudflare.com/dns/manage-dns-records/how-to/create-dns-records/).

На VDS сначала установите сертификат для этого имени (публичный либо Cloudflare
Origin CA), настройте nginx и проверьте `nginx -t`. Затем используйте Full (strict)
между Cloudflare и VDS. При изменении режима всей зоны сначала проверьте сертификаты
остальных её сайтов. Шаблон `deploy/nginx.conf.example` требует подстановки путей
сертификата. [Требования Full (strict)](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/full-strict/).

Для этого поддомена отключите принудительное кэширование страниц и API; сохраняйте
`Cache-Control: no-store`. Машинные запросы игры не умеют проходить JavaScript Challenge:
не применяйте к `/api/v1/*` интерактивные проверки. Секретный `X-Server-Key`
остаётся обязательным независимо от настроек Cloudflare.

Лимиты входа используют IP клиента. За Cloudflare nginx должен доверять
`CF-Connecting-IP` **только актуальным диапазонам Cloudflare** через `set_real_ip_from`
и `real_ip_header CF-Connecting-IP`. Не доверяйте этому заголовку от всего интернета.
После этого nginx передаёт приложению один проверенный IP через X-Forwarded-For.
`NTRNET_TRUST_PROXY=1` допустим только при таком доверенном прокси перед loopback-портом.
Без real-ip настройки лимит будет общим для посетителей одного узла Cloudflare.

`media.wiki-ss13.space` понадобится на этапе 3: это custom domain бакета R2,
его не нужно направлять A-записью на VDS. Настройка выполняется в R2 → bucket →
Settings → Custom Domains. [Документация R2](https://developers.cloudflare.com/r2/buckets/public-buckets/).
Маршрут вики `/ntrnet` можно будет сделать перенаправлением на поддомен; сейчас
он является исходным значением игрового `NTRNET_EDITOR_URL`, поэтому при развёртывании
задайте этот параметр явно.

## Проверки

Из корня репозитория:

```powershell
.cache/ntrnet-venv/Scripts/python -m unittest discover -s services/ntrnet -p test_app.py -v
```

По умолчанию каждый тест использует временную SQLite. Для проверки MariaDB задайте
`NTRNET_TEST_DATABASE_URL` на отдельную одноразовую базу с именем `ntrnet_test...`.
Тесты очищают её таблицы; рабочую базу использовать нельзя. Проверяются одноразовость
и конкурентное погашение, срок действия, CSRF, лимиты, изоляция авторов, отзыв доступа,
совместимость каталога, сохранение сессий и отсутствие открытых токенов в БД.

Проверено 17.09.2026: 20/20 тестов API на MariaDB 11.4.8; на SQLite — 19 прошли,
один тест production-cookie пропущен намеренно. В браузере проверены вход и выход.
DM 516.1682: 0 ошибок и предупреждений; DreamChecker 1.11: 0 диагностик.
Три игровых теста НТрнета прошли. Общий игровой прогон не зелёный:
`sql_version` падает из-за отсутствующего подключения к игровой SQL-базе.
Это отдельное подключение, не MariaDB, использованная в тестах API.
TGUI: сборка production, TypeScript, ESLint и шесть тестов рендерера прошли;
проверки identical_variables, icons, ru_names, grep и локальных define прошли.
