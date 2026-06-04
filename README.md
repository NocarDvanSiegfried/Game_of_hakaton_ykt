# Баргый: Путь сквозь лёд

«Баргый: Путь сквозь лёд» — визуальная хоррор-новелла на Godot/Dialogic по мотивам якутской мифологии. Айсен, Кюннэй и пёс Баргый проходят через Нижний Мир, встречают духов и Абаасы, а затем выходят к одной из 9 концовок.

Проект сейчас сильнее всего готов как Dialogic-структура: есть цепочка сцен, переменные ветвления, ключевые выборы и финальные таймлайны. Визуальное наполнение ещё частично в работе: в таймлайнах остаются TODO для фонов, портретов и некоторых иллюстраций.

## Технологии

- Godot Engine 4.6.x
- Dialogic 2
- GDScript

## Текущее состояние

- Главная сцена проекта: `res://scenes/ui/intro.tscn`.
- После intro открывается меню; новая игра запускает `res://scenes/main.tscn`.
- Основная цепочка таймлайнов реализована в `scripts/main.gd`: `scene1_timeline` → `scene2_timeline` → ... → `scene10_timeline`.
- Scene 1 есть и использует отдельный overlay для визуального слоя дома бабушки.
- Scene 2-10 есть как Dialogic-таймлайны.
- После Scene 10 вычисляется `ending_id` и запускается `scene10_ending_N`.
- Созданы 9 финальных таймлайнов: `scene10_ending_1.dtl` ... `scene10_ending_9.dtl`.
- Есть ранняя плохая концовка `ending_bad_early.dtl`, если в Scene 3 отказаться от инициации.
- Есть debug-инструмент выбора сцен: `scenes/ui/debug_scene_select.tscn`.
- В меню debug-кнопка сейчас включена в `scripts/ui/main_menu.gd` через `DEBUG_SCENE_SELECT := true`.
- Настройки громкости реализованы через `AudioSettings` и `assets/audio/default_bus_layout.tres`.

Что ещё не финализировано:

- В сценах 2-10 много TODO-комментариев для портретов и фонов.
- У части персонажей в `.dch` ещё нет портретов, что прямо отмечено в timeline TODO.
- Scene 3 готовится к отдельной замене визуального дизайна.
- Все 9 концовок имеют Dialogic-тексты, но полный ручной smoke-test всех финалов нужно прогнать отдельно.
- Финальный экран/титры как отдельная UI-сцена не подтверждены файлами проекта.

## Как запустить

1. Открыть проект в Godot 4.6.x.
2. Убедиться, что плагин Dialogic включён.
3. Запустить проект через F5. Main scene в `project.godot`: `res://scenes/ui/intro.tscn`.
4. В меню нажать «Новая игра», чтобы попасть в `scenes/main.tscn` и начать `scene1_timeline`.
5. Для проверки отдельных сцен открыть «Выбор сцены» в меню. Сейчас debug-кнопка включена.

Управление в новелле: клик мышью или Пробел для следующей реплики, клик по варианту для выбора.

## Цепочка сцен

Переходы находятся в `scripts/main.gd` в `_on_timeline_ended()`:

```text
scene1_timeline
→ scene2_timeline
→ scene3_timeline
→ scene4_timeline
→ scene5_timeline
→ scene6_timeline
→ scene7_timeline
→ scene8_timeline
→ scene9_timeline
→ scene10_timeline
→ scene10_ending_N
```

Особый случай:

```text
scene3_timeline → ending_bad_early
```

если `Dialogic.VAR.accepted_initiation == false`.

## Система ветвления

Финальная матрица строится на двух уроках:

- Scene 2 задаёт `lesson_act1`.
- Scene 6 задаёт `lesson_act2`.
- Scene 10 вычисляет `ending_id`.
- `main.gd` читает `Dialogic.VAR.ending_id` и запускает `scene10_ending_N`.

### Ключевой выбор Scene 2

В конце `dialogic/timelines/scene2_timeline.dtl`:

| Кнопка | Значение |
| ------ | -------- |
| Исцелить | `lesson_act1 = "compassion"` |
| Пощадить с границами | `lesson_act1 = "boundaries"` |
| Запомнить и осудить | `lesson_act1 = "memory"` |

### Ключевой выбор Scene 6

В конце `dialogic/timelines/scene6_timeline.dtl`:

| Кнопка | Значение |
| ------ | -------- |
| Открыться и принять | `lesson_act2 = "acceptance"` |
| Бороться, но смириться | `lesson_act2 = "humility"` |
| Защититься и сохранить силу | `lesson_act2 = "strength"` |

### Таблица 9 концовок

| № | lesson_act1 | lesson_act2 | Название |
| - | ----------- | ----------- | -------- |
| 1 | compassion | acceptance | Прощение |
| 2 | compassion | humility | Светлая |
| 3 | compassion | strength | Мудрая |
| 4 | boundaries | acceptance | Справедливая |
| 5 | boundaries | humility | Тихая |
| 6 | boundaries | strength | Сильная |
| 7 | memory | acceptance | Памятливая |
| 8 | memory | humility | Благодарная |
| 9 | memory | strength | Верная |

Если `lesson_act1` или `lesson_act2` пустые, Scene 10 ставит `ending_id = 5`.

## Как получить концовки в обычном прохождении

1. Пройти Scene 2 и выбрать один из трёх вариантов:
   - `compassion`: «Исцелить»
   - `boundaries`: «Пощадить с границами»
   - `memory`: «Запомнить и осудить»
2. Пройти Scene 6 и выбрать один из трёх вариантов:
   - `acceptance`: «Открыться и принять»
   - `humility`: «Бороться, но смириться»
   - `strength`: «Защититься и сохранить силу»
3. Дойти до Scene 10. Она вычислит `ending_id` по таблице и передаст игру в нужный `scene10_ending_N`.

## Как тестировать через Debug Scene Select

Debug Scene Select реализован в `scripts/ui/debug_scene_select.gd` и доступен из меню, пока `DEBUG_SCENE_SELECT := true`.

Для быстрого теста концовок:

1. Открыть «Выбор сцены» в меню.
2. Выбрать значения `lesson_act1` и `lesson_act2` в двух выпадающих списках.
3. Нажать `Start Scene 10 with selected lessons`.
4. Пройти `scene10_timeline`.
5. Проверить Output: `Игра завершена. Концовка N.`

Для запуска отдельных сцен можно использовать кнопки Scene 1-10 или клавиши F1-F10 на экране debug-select.

## Smoke-test чеклист

- [ ] Scene 1 запускается после новой игры.
- [ ] Scene 1 показывает выборы.
- [ ] Scene 1 переходит в Scene 2.
- [ ] Scene 2 показывает ключевой выбор `lesson_act1`.
- [ ] Scene 6 показывает ключевой выбор `lesson_act2`.
- [ ] Scene 10 считает `ending_id`.
- [ ] Запускается нужный `scene10_ending_N`.
- [ ] Финальный timeline доходит до конца.
- [ ] В Output нет `timeline not found`.
- [ ] В Output нет `Identifier not found`.
- [ ] В Output нет `Invalid cast`.
- [ ] В Output нет `resource not found`.

## Структура проекта

```text
dialogic/timelines/
```

Dialogic-таймлайны сцен, ранней плохой концовки и 9 финалов:

- `scene1_timeline.dtl` ... `scene10_timeline.dtl`
- `scene10_ending_1.dtl` ... `scene10_ending_9.dtl`
- `ending_bad_early.dtl`

```text
dialogic/characters/
```

Dialogic-персонажи `.dch`: Айсен, Кюннэй, Баргый, Эбэ, духи, боссы, narrator и другие.

```text
scenes/
```

Godot-сцены:

- `scenes/ui/intro.tscn`
- `scenes/ui/main_menu.tscn`
- `scenes/ui/debug_scene_select.tscn`
- `scenes/ui/settings_menu.tscn`
- `scenes/main.tscn`
- `scenes/overlays/scene1_grandmother_house_layered.tscn`

```text
scripts/
```

GDScript-логика запуска, меню, настроек, debug-state и overlay:

- `scripts/main.gd`
- `scripts/ui/*.gd`
- `scripts/core/*.gd`
- `scripts/overlays/*.gd`

```text
assets/art/
```

Фоны, портреты, артефакты, relief-изображения и рабочие картинки. Часть визуалов ещё временная или ожидает замены.

```text
assets/audio/
```

Audio bus layout, музыка меню, SFX и озвучка/атмосферы, особенно для Scene 1.

```text
docs/
```

Рабочая документация: branching, тексты концовок, сценарии, аудио-инструкции, тестовые инструкции и asset-чеклисты.

## Roadmap / TODO

- Скрыть debug-экран перед финальной сборкой (`DEBUG_SCENE_SELECT := false` или отдельная сборочная настройка).
- Заменить/доработать визуалы Scene 3 отдельной задачей.
- Добавить недостающие портреты и фоны для сцен 2-10.
- Проверить TODO в timeline-файлах и перевести нужные `# TODO background`, `# TODO portrait`, `# TODO арт` в реальные команды/ассеты.
- Провести полный smoke-test всех 9 концовок.
- Добавить титры или финальный экран, если это нужно для релизной версии.
- Проверить, что в финальной сборке нет `resource not found`, `timeline not found`, `Identifier not found`, `Invalid cast`.

## Полезные документы

- `docs/testing/run_scene2.md`
- `docs/testing/run_scene4_5.md`
- `docs/testing/run_scene6_7.md`
- `docs/testing/run_scene8_9.md`
- `docs/testing/run_scene10.md`
- `docs/testing/volume_settings_scene1.md`
- `docs/branching/00_scenario_architecture.md`
- `docs/branching/endings/`
- `docs/audio/day1_volume_architecture.md`
- `docs/audio/adding_dialogic_audio_channels.md`

## Возможные проблемы

**Новый `.dtl` не виден в Dialogic**  
Обновить файловую систему Godot. `.uid` файлы обычно создаются редактором автоматически.

**Timeline не парсится**  
Открыть `.dtl` в Dialogic Timeline Editor и проверить строку с ошибкой. Для choice-блоков важно, чтобы тело варианта было на TAB глубже строки `- Вариант`.

**Нет звука или громкость не сохраняется**  
Проверить `assets/audio/default_bus_layout.tres`, autoload `AudioSettings` и файл `user://settings.cfg`.

**Финал не запускается**  
Проверить `ending_id` в Output Scene 10, регистрацию `scene10_ending_N` в `project.godot` и ветку `scene10_timeline` в `scripts/main.gd`.
