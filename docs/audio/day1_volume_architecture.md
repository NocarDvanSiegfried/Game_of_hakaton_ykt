# День 1 — Архитектура громкости

Документ фиксирует результаты первого дня настройки системы громкости для **BargyyIcePath**.

## 1. Audio bus layout

Файл: `res://assets/audio/default_bus_layout.tres`  
Подключение: `project.godot` → `[audio]` → `buses/default_bus_layout`

| Bus | Назначение | UI (День 3) |
|-----|------------|-------------|
| **Master** | Общая громкость всего звука | Общая |
| **Music** | Музыка меню, будущий BGM | Музыка |
| **Voice** | Озвучка персонажей и рассказчика | Голоса |
| **SFX** | One-Shot эффекты, звуки UI, type sounds | Эффекты |
| **Ambient** | Цикличная атмосфера (ветер, пурга, камин) | Фон |

Все дочерние bus отправляют сигнал в **Master** (`send = Master`).

## 2. Значения по умолчанию

Хранятся в `scripts/core/audio_settings.gd` → `DEFAULT_VOLUMES`:

| Ключ | Bus | Значение | Комментарий |
|------|-----|----------|-------------|
| `volume_master` | Master | 100 % | |
| `volume_music` | Music | 80 % | Меню не перебивает голос |
| `volume_voice` | Voice | 100 % | Главный контент VN |
| `volume_sfx` | SFX | 75 % | В .dtl уже есть относительные dB |
| `volume_ambient` | Ambient | 80 % | Пурга, ветер — фон |

Персистентность: `user://settings.cfg`, секция `[audio]`.

## 3. Маппинг Dialogic-каналов (scene1)

Источник: `dialogic/timelines/scene1_timeline.dtl`

### Voice → bus `Voice`

| Канал | Описание |
|-------|----------|
| `narrator_voice` | Рассказчик |
| `ebe_voice` | Бабушка (Эбэ) |
| `aisen_voice` | Айсен |
| `kunney_voice` | Кюннэй |
| `tongus_voice` | Тонгус |

### Ambient → bus `Ambient`

| Канал | Описание |
|-------|----------|
| `yakut_night` | Ночной ветер (intro, финал) |
| `fireplace` | Камин в избе |
| `house_morning` | Утро в доме |
| `stove_embers` | Тлеющая печь |
| `blizzard` | Пурга на дворе |
| `snow_run` | Бег по снегу (погоня) |

### SFX → bus `SFX`

| Источник | Пример |
|----------|--------|
| `audio "path.wav"` без имени канала | `door_open.wav`, `bargyy_missing_2.wav` |
| Dialogic type sounds | `dialogic/audio/type_sound_bus` (День 2) |
| Файлы `tongus_voice_1.wav` и т.п. | One-Shot SFX, **не** путать с каналом `tongus_voice` |

### Music → bus `Music`

| Источник | Файл |
|----------|------|
| `MainMenu` → `MenuMusic` | `assets/audio/menu/menu.wav` (День 2: `bus = Music`) |
| Будущий BGM сцен | TBD |

## 4. Черновик API (`AudioSettings`)

Файл: `scripts/core/audio_settings.gd`

| Метод | Назначение |
|-------|------------|
| `load_settings()` | Загрузка из `user://settings.cfg` |
| `save_settings()` | Сохранение |
| `apply_all()` | Применить все bus через `AudioServer` |
| `get_volume(key)` / `set_volume(key, linear)` | Чтение/запись категории |
| `linear_to_bus_db(linear)` | 0 → -80 dB (mute), иначе `linear_to_db` |

Константы для Дня 2: `DIALOGIC_VOICE_CHANNELS`, `DIALOGIC_AMBIENT_CHANNELS`, `DIALOGIC_SFX_CHANNEL`.

## 5. Проверка (чек-лист Дня 1)

- [ ] Открыть проект в Godot 4.6 → вкладка **Audio** → видны 5 bus: Master, Music, Voice, SFX, Ambient
- [ ] Project Settings → Audio → Default Bus Layout указывает на `assets/audio/default_bus_layout.tres`
- [ ] Создать тестовый `AudioStreamPlayer`, назначить bus Music / Voice / SFX / Ambient — слышно разделение
- [ ] Убедиться, что игра запускается без ошибок (bus layout не ломает текущий звук)

## 6. День 2 — выполнено

- [x] Autoload `AudioSettings` (первым в списке autoload)
- [x] `dialogic/audio/channel_defaults` в `project.godot`
- [x] `dialogic/audio/type_sound_bus = "SFX"`
- [x] `MenuMusic.bus = "Music"`

## 7. День 3 — выполнено

- [x] `scenes/ui/settings_menu.tscn` — оверлей с пятью ползунками
- [x] Кнопка **«Настройки»** в главном меню
- [x] Live preview: музыка меню реагирует на «Музыка» и «Общая»
- [x] Сохранение в `user://settings.cfg` при движении ползунка
- [x] **Esc** / «Назад» — закрыть настройки

## 8. День 4 — выполнено

- [x] `reset_to_defaults()` в `AudioSettings`
- [x] Кнопка **«Сбросить»** в настройках
- [x] Повторное `apply_all()` при старте игры (`main.gd`)
- [x] Чеклист: `docs/testing/volume_settings_scene1.md`
- [x] Раздел в README + troubleshooting

## 9. День 5 — выполнено

- [x] Настройки во время VN: **O** (`game_open_settings`) или повторное **O** / **Esc** для закрытия
- [x] `Dialogic.paused = true` пока открыт оверлей; `CanvasLayer` (layer 128) поверх Dialogic
- [x] Общий хелпер `scripts/ui/settings_overlay.gd` (`SettingsOverlayHelper`)
- [x] UI: `ScrollContainer` для 720p, подсказка «Esc — закрыть»
- [x] Документация для команды: `docs/audio/adding_dialogic_audio_channels.md`

## 10. Дальше

1. Буфер на баги после ручного прогона scene1
2. Новые каналы — по инструкции в `adding_dialogic_audio_channels.md`
