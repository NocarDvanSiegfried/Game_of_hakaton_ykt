# Баргый: Путь сквозь Лёд

Визуальная новелла на Godot 4.6 + Dialogic 2. Якутская мифология, три брата-Абаасы, путешествие в Нижний Мир.

---

## Структура проекта

```
res://
├── addons/dialogic/           ← плагин Dialogic 2
├── assets/
│   └── art/
│       ├── backgrounds/       ← фоны по сценам (scene_01/, scene2/, scene3/, scene4/, scene5/)
│       ├── characters/        ← портреты персонажей (aisen/, kunney/, …)
│       └── cg/                ← CG-иллюстрации по сценам
├── dialogic/
│   ├── characters/            ← .dch файлы персонажей
│   └── timelines/             ← .dtl файлы таймлайнов
├── docs/
│   ├── asset_checklists/      ← списки недостающих артов
│   ├── scenarios/             ← рабочие тексты сценариев
│   └── testing/               ← инструкции ручного тестирования
├── scenes/
│   └── main.tscn              ← главная сцена (запускает Scene 1)
└── scripts/
    └── main.gd                ← скрипт запуска Dialogic
```

---

## Статус сцен

| Сцена | Название | Ветка | Статус |
|-------|----------|-------|--------|
| Сцена 1 | Пурга | `develop` | Готова, запускается |
| Сцена 2 | Теневой Бегун | `develop` | Dialogic-основа готова, подключена после Scene 1 |
| Сцена 3 | Белая Шаманка | `develop` | Таймлайн готов, подключён после Scene 2 |
| Сцена 4 | Плачущая Вода | `develop` | Dialogic-основа готова, подключена после Scene 3 |
| Сцена 5 | Железный Зуб | `develop` | Dialogic-основа готова, подключена после Scene 4 |
| Сцена 6 | Чёрный Трон | `develop` | Dialogic-основа готова, подключена после Scene 5 |
| Сцена 7 | Мясник | `develop` | Dialogic-основа готова, подключена после Scene 6 |
| Сцена 8 | Водоворот Разума | `develop` | Dialogic-основа готова, подключена после Scene 7 |
| Сцена 9 | Зовущий Дух | `develop` | Dialogic-основа готова, подключена после Scene 8 |
| Сцена 10 | Сердце Тьмы | `develop` | Финальный Dialogic-каркас готов, подключён после Scene 9 |

---

## Персонажи

| Файл | Display Name | Цвет | Описание |
|------|-------------|------|----------|
| `aisen.dch` | Айсен | #5B9BD5 | Мальчик 10 лет, главный герой |
| `kunney.dch` | Кюннэй | #F4C2D7 | Девочка 8 лет, сестра Айсена |
| `ebe.dch` | Бабушка Эбэ | #E8A95C | Хранительница знаний |
| `bargyy.dch` | Баргый | _(серый)_ | Якутская лайка, пёс-спутник |
| `tongus.dch` | Тонгус Харах | #B8D4E3 | Первый брат-Абаасы, Мерзлый Глаз |
| `narrator.dch` | _(пробел)_ | #AAAAAA | Нарратор, без отображаемого имени |
| `emeehsin.dch` | Эмээхсин Удаганка | #F0EBD8 | Белая Шаманка, Сцена 3 |
| `raven.dch` | Ворон | #7A6A5A | Ворон-страж у юрты, Сцена 3 |
| `stolb.dch` | Голос столба | #5A6A7A | Голоса застывших путников, Сцена 3 |
| `kyulyuk_suyuryuk.dch` | Кюлюк Сююрюк | #3A2F55 | Теневой Бегун, Сцена 2 |
| `shadow.dch` | Тень | #555566 | Тень-миньон, голос лабиринта, Сцена 2 |
| `ytyyr_uu.dch` | Ытыыр Уу | #6DB7D6 | Плачущая Вода, босс-исцеление Сцены 4 |
| `memory_shadow.dch` | Тень-воспоминание | #7A8A9A | Тень прошлого в Пещере Слёз, Сцена 4 |
| `timir_tiis.dch` | Тимир Тиис | #B45A3C | Железный Зуб, босс-перековка Сцены 5 |
| `iron_echo.dch` | Железный отголосок | #8C6A5A | Миньон кузни, Сцена 5 |
| `khara_sandal.dch` | Хара Сандал | #3A3A46 | Чёрный Трон, Судья Нижнего Мира, Сцена 6 |
| `accused_shadow.dch` | Тень обвинённого | #777777 | Тень души в коридорах Чёрного Трона, Сцена 6 |
| `syuyulukke.dch` | Сююлюккэ | #8A3F3F | Мясник, символический инициатор Сцены 7 |
| `butcher_memory.dch` | Тень-воспоминание | #6F5A5A | Осколок прошлого в ритуале Мясника, Сцена 7 |
| `oibon_kuturuk.dch` | Ойбон Кутурук | #6B4FA3 | Водоворот Разума, хаос и созданный смысл, Сцена 8 |
| `failed_life.dch` | Несостоявшаяся жизнь | #8A7AA0 | Возможная жизнь героя, Сцена 8 |
| `uguyar_tyyn.dch` | Угуйар Тыын | #6A3A3A | Зовущий Дух, Предок-Предатель, Сцена 9 |
| `ancestral_shadow.dch` | Тень предка | #5A4A4A | Родовая память о предательстве и вине, Сцена 9 |
| `father_voice.dch` | Голос отца | #9A7A5A | Голос отца через Угуйар Тыына, Сцена 9 |
| `first_abaasy.dch` | Первые Абаасы | #2E2E38 | Три древние сущности у Сердца Тьмы, Сцена 10 |
| `heart_of_darkness.dch` | Сердце Тьмы | #1A0F1F | Финальный босс-явление, источник холода |
| `freed_spirit.dch` | Освобождённый дух | #B8D4E8 | Голос исцелённых духов в финале |
| `dyuluskhan.dch` | Дьулусхан | #7A4A3A | Проводник к финалу после принятия/прощения |

---

## Переменные Dialogic

| Переменная | Тип | Где используется |
|------------|-----|-----------------|
| `scene1_choice` | String | Сцена 1 — первый выбор (light/bark/kunney) |
| `boss_tactic` | String | Сцена 1 — тактика против Тонгуса |
| `boss_end` | String | Сцена 1 — добить или пощадить |
| `scene2_path` | String | Сцена 2 — выбранный путь в лабиринте |
| `bargyy_bond` | Number | Сцена 2 — связь с Баргыем |
| `shadow_noise` | Number | Сцена 2 — шум и риск обнаружения |
| `kunney_courage` | Number | Сцена 2 — смелость Кюннэй |
| `aisen_fear` | Number | Сцена 2/4 — страх Айсена |
| `shadow_runner_outcome` | String | Сцена 2 — итог встречи с Теневым Бегуном |
| `scene3_path` | String | Сцена 3 — путь через трещину (jump/detour) |
| `met_emeehsin_full` | Bool | Сцена 3 — полная встреча с шаманкой |
| `shaman_trust` | Number | Сцена 3 — доверие Эмээхсин (0–3) |
| `knows_lunar_maiden` | Bool | Сцена 3→4 — изучен барельеф Лунной Девы |
| `knows_judge` | Bool | Сцена 3→6 — изучен барельеф Хара Сандала |
| `accepted_initiation` | Bool | Сцена 3 — согласие на инициации (главный флаг) |
| `scene4_memory` | String | Сцена 4 — выбранное ключевое воспоминание |
| `empathy_score` | Number | Сцена 4 — понимание боли Ытыыр Уу |
| `water_truth` | Number | Сцена 4 — правда о Лунной Деве |
| `forgiveness_choice` | String | Сцена 4 — месть, прощение или свидетельство |
| `ytyyr_outcome` | String | Сцена 4 — итог boss-исцеления |
| `scene5_forge_path` | String | Сцена 5 — путь через кузню |
| `forge_rhythm` | Number | Сцена 5 — попадание в ритм молота |
| `idea_strength` | Number | Сцена 5 — сила идеи/надежды |
| `knife_resonance` | Number | Сцена 5 — резонанс Поющего Ножа |
| `timir_outcome` | String | Сцена 5 — итог boss-перековки |
| `scene6_verdict` | String | Сцена 6 — выбранный путь суда |
| `guilt_score` | Number | Сцена 6 — принятая/усиленная вина |
| `mercy_score` | Number | Сцена 6 — способность к милосердию |
| `truth_seen` | Number | Сцена 6 — увиденная полная правда |
| `khara_outcome` | String | Сцена 6 — итог суда Хара Сандала |
| `scene7_cut_choice` | String | Сцена 7 — что герой готов отпустить |
| `pain_released` | Number | Сцена 7 — отпущенная боль |
| `self_acceptance` | Number | Сцена 7 — принятие себя |
| `memory_weight` | Number | Сцена 7 — тяжесть воспоминаний |
| `butcher_outcome` | String | Сцена 7 — итог инициации |
| `scene8_meaning_choice` | String | Сцена 8 — созданный смысл |
| `chaos_acceptance` | Number | Сцена 8 — принятие хаоса |
| `mirror_truth` | Number | Сцена 8 — правда зеркал |
| `false_life_released` | Number | Сцена 8 — отпущенные несостоявшиеся жизни |
| `oibon_outcome` | String | Сцена 8 — итог Водоворота Разума |
| `scene9_ancestor_choice` | String | Сцена 9 — выбор по Предку-Предателю |
| `ancestral_guilt` | Number | Сцена 9 — сила родовой вины |
| `forgiveness_strength` | Number | Сцена 9 — сила прощения |
| `father_truth` | Number | Сцена 9 — правда об отце |
| `uguyar_outcome` | String | Сцена 9 — итог Зовущего Духа |
| `scene10_final_choice` | String | Сцена 10 — главный финальный выбор |
| `heart_resonance` | Number | Сцена 10 — понимание ритма Сердца Тьмы |
| `sacrifice_score` | Number | Сцена 10 — готовность платить цену героя |
| `spirits_support` | Number | Сцена 10 — поддержка освобождённых духов |
| `door_state` | String | Сцена 10 — состояние двери между мирами |
| `final_outcome` | String | Сцена 10 — итог игры |

---

## Запуск игры

Нажми **F5** — запустится `scenes/main.tscn`, которая стартует `scene1_timeline`.

Текущая цепочка в `scripts/main.gd`:

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
→ Output: «Игра завершена. Финальный каркас пройден.»
```

Первая реплика:
> «Слушай, путник. Слушай так, как слушали мои предки тысячу зим назад...»

Навигация: клик по экрану или Пробел — следующая реплика. При выборе — кликай мышкой на вариант.

---

## Тестирование сцен

Подробные инструкции:

- `docs/testing/run_scene2.md`
- `docs/testing/run_scene4_5.md`
- `docs/testing/run_scene6_7.md`
- `docs/testing/run_scene8_9.md`
- `docs/testing/run_scene10.md`

Чеклисты недостающего арта:

- `docs/asset_checklists/scene2_assets.md`
- `docs/asset_checklists/scene4_5_assets.md`
- `docs/asset_checklists/scene6_7_assets.md`
- `docs/asset_checklists/scene8_9_assets.md`
- `docs/asset_checklists/scene10_assets.md`

Для Scene 4 и Scene 5 фоны пока не подключены командами `[background ...]`, если соответствующих файлов нет. В таймлайнах оставлены TODO-комментарии с ожидаемыми путями.

---

## Возможные проблемы

**«Character 'X' not found»** — персонаж не зарегистрирован или файл `.dch` отсутствует. Проверь `project.godot` → секция `[dialogic]`.

**Таймлайн не парсится** — открой файл `.dtl` в Dialogic → Timeline → переключись на **Text Editor** — проблемная строка подсветится красным.

**Новые `.dch`/`.dtl` не видны** — правый клик на `res://` в файловой системе Godot → **«Обновить файловую систему»**. `.uid` файлы создадутся автоматически.

**Переменные новых сцен не видны в Dialogic → Variables** — открой `project.godot` и проверь секцию `variables={}` в блоке `[dialogic]`.

---

## Ветки

| Ветка | Содержимое |
|-------|-----------|
| `main` | Стабильный релиз |
| `develop` | Текущая разработка: Scene 1→5 через Dialogic |
| `feature/scene2-shadow-runner` | Историческая ветка разработки Scene 2 |
| `feature/scene3-shaman` | Историческая ветка разработки Scene 3 |
