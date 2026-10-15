# DarkCore для Windows

<img src="https://raw.githubusercontent.com/DarkFireReal/DarkCoreRelease/main/darkcore.png" width="96" alt="DarkCore">

Доступ предоставляется только принятым участникам Discord DarkCore.

В PowerShell выполните:

```powershell
irm "https://raw.githubusercontent.com/DarkFireReal/DarkCoreRelease/main/install.ps1" | iex
```

Сохраните работу и разрешите перезапуск Steam. Установщик проверяет SHA-256
закреплённого пакета, устанавливает плагин, DarkFireRuntime и его загрузчики.
Runtime входит в наш релиз и устанавливается из нашего закреплённого пакета.
Если Millennium отсутствует, запускается его проверенный официальный установщик;
выберите тот же каталог Steam, после чего установка DarkCore продолжится.
Неизвестные конфликтующие DLL не перезаписываются: установка остановится.

Войдите на [сайт DarkCore](https://darkcore.ccwu.cc) через Discord, создайте токен
в разделе подключения и вставьте его в окно DarkCore в Steam. Пароли и токены
никому не отправляйте. Если плагин не включён, включите его в настройках Millennium.
Новый токен отзывает предыдущий. Изменение привязки ПК доступно администратору.

Для ручной установки распакуйте весь пользовательский ZIP и выполните обе команды:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-DarkCore.ps1 -NoRestart
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-DarkFireRuntime.ps1
```

При необходимости укажите каждой команде `-SteamRoot "D:\Games\Steam"`.
`-NoRestart` оставляет Steam закрытым. Установщики сохраняют пользовательские
данные плагина, проверяют manifest и откатывают собственную незавершённую установку.
`-KeepBackup` у Install-DarkCore сохраняет резервную копию плагина;
Restore-DarkCore восстанавливает только плагин, а не native-компоненты.

Повторная загрузка доступной игры бесплатна. Покупка использует один самый
младший подходящий ключ; DLC входят в основную игру. Архивы обрабатываются в памяти.
Устанавливаются только Lua выбранной игры и допустимые manifests.
При отзыве игры или подтверждённом исключении из Discord штатный клиент удаляет
собственные неизменённые файлы. При исключении серверная библиотека сохраняется:
после возвращения на сервер доступные игры можно загрузить без нового ключа.

[Условия использования](https://darkcore.ccwu.cc/terms) ·
[Политика конфиденциальности](https://darkcore.ccwu.cc/privacy) ·
[Discord](https://discord.gg/RMqXDvFpMf)
