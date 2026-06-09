# Аудит озвучки Scene 1 — «Пурга»

**Проект:** BargyyIcePath (Godot 4.6 + Dialogic 2)  
**Объект:** только `scene1_timeline` и аудио `assets/audio/scene_01/`  
**Дата анализа:** июнь 2026  
**Статус:** только анализ, код и файлы игры не изменялись.

---

## 1. Краткий вывод

Инфраструктура озвучки Scene 1 **работоспособна**: Dialogic audio events, пять голосовых каналов, шесть ambient-каналов, One-Shot SFX, autoload `AudioSettings` и `default_bus_layout.tres` согласованы. Все **179** ссылок на `res://assets/audio/scene_01/…` в timeline **существуют**; битых путей, пустых файлов и ошибок регистра нет.

**Главная проблема** — не «сломанный плеер», а **утро в доме (строки ~148–197)**: часть реплик озвучена через **WAV на шине SFX** (`morning_stove_desc_*`, `anxious_silence_*` и т.д.) вместо каналов `narrator_voice` / `aisen_voice` / `kunney_voice`. При настройке «только голоса» (Voice 100%, SFX 0%) этот блок **почти не слышен**.

Дополнительно: **6 готовых MP3** лежат на диске, но **не подключены** к timeline.

| Показатель | Значение |
|------------|----------|
| Всего реплик в Scene 1 | **142** |
| С командой `*_voice` | **125** (**88,0%**) |
| Без голосового канала | **17** (**12,0%**) |
| MP3 в `voice/` на диске | **131** |
| Уникальных MP3 в timeline | **125** |
| Файлов без вызова в timeline | **6** |
| Битых ссылок в timeline | **0** |

---

## 2. Как воспроизводится звук в Scene 1

| Механизм | Где | Поведение |
|----------|-----|-----------|
| `audio` в `.dtl` | `dialogic/timelines/scene1_timeline.dtl` | Основной способ; `audio` **перед** репликой |
| `narrator_voice`, `ebe_voice`, `aisen_voice`, `kunney_voice`, `tongus_voice` | `project.godot` → `dialogic/audio/channel_defaults` | Шина **Voice** |
| `yakut_night`, `fireplace`, `house_morning`, `stove_embers`, `blizzard`, `snow_run` | там же | Шина **Ambient** |
| `audio "…wav"` без канала | One-Shot | Шина **SFX**, параллельно |
| `volume="0"` в timeline | — | **0 dB** относительно канала, не mute |
| `DialogicVoiceStop` | `scripts/core/dialogic_voice_stop.gd` | Стоп других голосов при смене спикера; быстрый клик = skip; для `intro_part0_02` с `[n]` — SFX `frost_trees_crack_*` |
| Видео главы | `scripts/main.gd` | `Dialogic.paused = true` → все subsystems, включая Audio, на pause; timeline ждёт `dialogic_resumed` |
| Intro-атмосфера | `main.gd` | Dialogic **не** на паузе; видео на Ambient, −80 dB |
| Громкость | `AudioSettings` | `user://settings.cfg`; при старте `apply_all()` |
| Запуск сцены | intro → main_menu → новая игра → `main.tscn` | То же timeline, что Debug Scene Select (F1) |

**AudioStreamPlayer** создаёт Dialogic (`addons/dialogic/Modules/Audio/subsystem_audio.gd`) динамически. На одном канале новый клип **заменяет** предыдущий.

**Шины** (`assets/audio/default_bus_layout.tres`): Master → Music, Voice, SFX, Ambient.

---

## 3. Реплики без голосового канала (17)

### 3.1. Намеренная тишина / нет файлов (5 реплик)

| Строка | Спикер | Суть |
|--------|--------|------|
| 109 | narrator | Тишина, треск дров |
| 111 | narrator | Айсен не спит |
| 113 | aisen | Внутренний монолог про свет в пурге |
| 115 | aisen | «Запомни» |
| 117 | narrator | Закрывает глаза |

После `show_scene1_sleep_pose` (106–107). В timeline нет `audio`; в `voice/` **нет** соответствующих MP3. Вероятно **задуманный текстовый блок**.

### 3.2. Утро: SFX вместо озвучки (11 реплик) — **High**

| Строка | Спикер | Сейчас | Должно / есть на диске |
|--------|--------|--------|-------------------------|
| 149 | narrator | `morning_stove_desc_1.wav` (SFX) | `morning_part2_01_morning.mp3` (коммент. стр. 131) |
| 154 | narrator | `morning_stove_desc_2.wav` (SFX) | то же |
| 162 | aisen | `cloth_rustle_wake_1.wav` | **`aisen_voice_01_morning.mp3`** — не подключён |
| 166 | narrator | `anxious_silence_1.wav` | нет MP3 |
| 169 | aisen | `cloth_rustle_wake_2.wav` | **`aisen_voice_02_wake.mp3`** — не подключён |
| 172 | narrator | `bargyy_missing_2.wav` | нет MP3 |
| 175 | narrator | `sharp_silence_1.wav` | нет MP3 |
| 177 | narrator | **нет audio вообще** | нет MP3 |
| 182 | kunney | `cloth_rustle_wake_3.wav` | **`kunney_voice_02_morning.mp3`** — не подключён |
| 188 | kunney | `children_awakening_4.wav` | нет MP3 |
| 197 | aisen | `bargyy_bark_whine_1.wav` | нет MP3 |

### 3.3. Неканоническая ветка (1 реплика)

| Строка | Спикер | Сейчас |
|--------|--------|--------|
| 300 | narrator | Только `light_trap_2` + `ice_crystal_laugh_2`; нет `narrator_voice` |

---

## 4. MP3 на диске, но не в timeline (6 файлов)

| Файл | Назначение |
|------|------------|
| `voice/morning_part2_01_morning.mp3` | Озвучка утра (коммент. «одна запись на три строки») |
| `voice/aisen_voice_01_morning.mp3` | «Баргый?» (стр. 162) |
| `voice/aisen_voice_02_wake.mp3` | «(громче) Баргый!» (стр. 169) |
| `voice/kunney_voice_02_morning.mp3` | «Айсен? Уже утро?» (стр. 182) |
| `voice/morning_part2_03_door_voice.mp3` | Запас / дверь (в timeline используется `yard_part3_01_door`) |
| `voice/house_part1_04_chapter.mp3` | Заголовок главы — нигде не вызывается |

---

## 5. Таблица проблем

| Приоритет | Строка | Момент | Ожидание | Файл | Сейчас | Причина | Как исправить | Проверка |
|-----------|--------|--------|----------|------|--------|---------|---------------|----------|
| **High** | 149 | Утро, описание | `narrator_voice` | `morning_part2_01_morning.mp3` | `morning_stove_desc_1.wav` на SFX | Озвучка в MP3, в timeline — WAV на SFX | `audio narrator_voice "…/morning_part2_01_morning.mp3"` | Пресет A: только Voice |
| **High** | 154 | Айсен садится | `narrator_voice` | см. выше / отдельный | `morning_stove_desc_2.wav` | то же | Подключить MP3 | Пресет A |
| **High** | 162 | «Баргый?» | `aisen_voice` | `aisen_voice_01_morning.mp3` | только rustle SFX | MP3 не подключён | Добавить `audio aisen_voice` | Пресет A |
| **High** | 169 | «(громче) Баргый!» | `aisen_voice` | `aisen_voice_02_wake.mp3` | только SFX | MP3 не подключён | Добавить `audio aisen_voice` | Пресет A |
| **High** | 182 | Кюннэй проснулась | `kunney_voice` | `kunney_voice_02_morning.mp3` | только SFX | MP3 не подключён | Добавить `audio kunney_voice` | Пресет A |
| **Medium** | 166, 175 | «Тишина» | voice или атмосфера | нет | silence SFX | Атмосфера, не речь | Решить: MP3 или оставить как SFX | На слух |
| **Medium** | 172 | Пёс исчез | `narrator_voice` | нет | `bargyy_missing_2.wav` | Только SFX | Записать MP3 + timeline | На слух |
| **Medium** | 177 | Нужно найти Баргыя | `narrator_voice` | **нет** | **нет audio** | Не настроено | Записать + подключить | На слух |
| **Medium** | 188, 197 | Кюннэй / Айсен | voice | нет | только SFX | Нет MP3 | Записать + подключить | На слух |
| **Medium** | 109–117 | Sleep-монолог | опционально | нет | нет audio | Вероятно задумано | При необходимости — новые MP3 | На слух |
| **Medium** | 300 | Ветка «на свет» | `narrator_voice` | нет | только trap/laugh | Пропуск в ветке | MP3 + `narrator_voice` | Ветка выбора |
| **Low** | 131 | Комментарий | `morning_part2_01` | MP3 есть | используются `morning_stove_desc_*` | Расхождение комментария и кода | Синхронизировать | Ревью |
| **Low** | 214–218 | Обереги | порядок реплик | MP3 есть | aisen (211) раньше narrator (214) | Возможный перепутанный порядок | Переставить audio/текст | На слух |
| **Low** | — | `house_part1_04_chapter.mp3` | — | на диске | не используется | Запас | Подключить или убрать | — |

**Подтверждено кодом:** битых путей нет; шины корректны; `volume="0"` — не mute; видео главы ставит Dialogic на паузу до конца ролика.

**Требует ручного прослушивания:** громкость, обрезка клипов, skip, Continue с checkpoint.

---

## 6. Почему звук «должен быть, но не слышен»

| Причина | Где | Статус |
|---------|-----|--------|
| Озвучка в MP3, в timeline — WAV на SFX | Утро 149–154 | Подтверждено кодом |
| MP3 есть, не подключены | 162, 169, 182 | Подтверждено кодом |
| Нет команды `audio` | 177 | Подтверждено кодом |
| Только атмосферные SFX, без MP3 | 166, 172, 175, 188, 197 | Подтверждено кодом |
| Voice = 0% в настройках | Везде | Ожидаемое поведение |
| SFX = 0%, реплика только на SFX | Утро | Подтверждено кодом |
| Быстрый skip | Везде | `DialogicVoiceStop` |
| Пауза на видео главы | ~126 | Норма; после resume — продолжение |

---

## 7. Сводка покрытия

- **142** реплики всего  
- **125** с `*_voice` в timeline (**88%**)  
- **17** без голосового канала  
- **125** MP3 подключены; **6** MP3 без вызова  
- **0** вызовов без файла  
- **~5–8** реплик без MP3 на диске (если нужна полная озвучка утра + sleep + ветка 300)

**Эффективное покрытие «ожидаемой озвучки»:** при строгой трактовке (каждая реплика = voice MP3) — **~77–87%**; технически подключено **88%** каналов.

---

## 8. План исправления

1. **Утро (стр. 148–197)** — правки только `scene1_timeline.dtl`:
   - 149, 154: `morning_stove_desc_*` → `narrator_voice` + `morning_part2_01_morning.mp3`
   - 162, 169, 182: подключить `aisen_voice_01/02`, `kunney_voice_02`
   - SFX оставить **параллельно**, не вместо голоса

2. **Дозапись MP3** (если SFX не заменяют речь): 172, 175, 177, 188, 197; опционально 166, 300, sleep 109–117

3. **Проверить порядок** 211 / 214–218 (обереги)

4. **Не трогать** без необходимости: `DialogicVoiceStop`, `AudioSettings`, bus layout, Fire/overlay

5. Прогнать чеклист из `docs/testing/volume_settings_scene1.md`

---

## 9. Файлы для изменения (на этапе исправления)

| Файл | Изменения |
|------|-----------|
| `dialogic/timelines/scene1_timeline.dtl` | Основные правки утреннего блока |
| `assets/audio/scene_01/voice/*.mp3` | Возможно новые записи (177 и др.) |
| `docs/testing/volume_settings_scene1.md` | Опционально: уточнить поведение утра |

---

## 10. Чеклист тестов после исправления

1. Пресет A (Voice 100%, SFX/Ambient 0%): утро 149–197 — слышны все голоса  
2. Пресет B (Voice 0%): текст без голоса, SFX слышны  
3. Главное меню → новая игра и Debug F1 — одинаково  
4. Видео главы (стр. 126): Part 2 не стартует до конца видео  
5. Быстрый клик — один голос, без наложения  
6. Смена спикера — без двух voice одновременно  
7. Intro с `[n]` — `frost_trees_crack` на сегментах  
8. Пауза / настройки (O, Esc) — audio возобновляется  
9. Continue с `scene1_part2_morning` — состояние звука корректно  
10. Экспорт — все `assets/audio/scene_01/**` в сборке  

---

## 11. Инструмент аудита

Для повторной проверки: `python tools/audit_scene1_audio.py`  
(скрипт только читает timeline и файлы, ничего не меняет.)

---

*Отчёт составлен по статическому анализу кода, timeline и файловой системы. Runtime smoke-test в Godot не выполнялся.*
