# Добавление Dialogic audio-каналов

Краткая инструкция для команды: как подключить новый канал озвучки или атмосферы в таймлайне.

## 1. Выберите bus

| Тип звука | Audio bus | Пример |
|-----------|-----------|--------|
| Озвучка персонажа / рассказчика | **Voice** | `aisen_voice`, `narrator_voice` |
| Цикличная атмосфера | **Ambient** | `blizzard`, `fireplace` |
| Короткий эффект | **SFX** | без имени канала или отдельный SFX-канал |
| Музыка | **Music** | BGM-треки |

Полный маппинг scene1: `docs/audio/day1_volume_architecture.md`.

## 2. Зарегистрируйте канал в `project.godot`

Секция `[dialogic]` → `audio/channel_defaults`:

```ini
"имя_канала": {
"audio_bus": "Voice",   ; или Ambient / SFX / Music
"fade_length": 0.0,
"loop": false,          ; true для ambient
"volume": 0.0
}
```

Пример для нового персонажа:

```ini
"new_character_voice": {
"audio_bus": "Voice",
"fade_length": 0.0,
"loop": false,
"volume": 0.0
}
```

## 3. Остановка голосов при смене спикера

Если канал — **голос персонажа**, добавьте имя в `scripts/core/dialogic_voice_stop.gd`:

```gdscript
const VOICE_CHANNELS := [
    "narrator_voice",
    "ebe_voice",
    # ...
    "new_character_voice",
]
```

Autoload `DialogicVoiceStop` останавливает чужие каналы при смене реплики и при быстром скипе.

## 4. Использование в `.dtl`

Перед репликой:

```text
audio new_character_voice "res://assets/audio/scene_01/voice/new_character/line_01.wav" [volume="0" loop="false"]
new_character: Текст реплики.
```

- `volume="0"` — относительная громкость в dB внутри bus **Voice**; категория «Голоса» в настройках управляет bus целиком.
- Для ambient с loop: `[volume="-6" loop="true"]`.
- One-Shot SFX **без** имени канала идут на bus **SFX** автоматически:

```text
audio "res://assets/audio/scene_01/sfx/door_open.wav" [volume="-10" loop="false"]
```

## 5. Файлы и именование

- Голоса: `assets/audio/scene_XX/voice/<персонаж>/`
- Ambient/SFX: `assets/audio/scene_XX/` (подпапки по смыслу)
- Имена файлов: `персонаж_сцена_номер.wav` или согласованная схема сцены

## 6. Проверка

1. Запустить сцену → **Настройки** (меню) или **O** (в игре).
2. Двигать ползунок **Голоса** / **Фон** / **Эффекты** — слышно изменение нужной категории.
3. Быстрый скип через реплики — предыдущий голос обрывается, новый стартует без наложения.
4. Чеклист пресетов: `docs/testing/volume_settings_scene1.md`.

## 7. Частые ошибки

| Проблема | Причина | Решение |
|----------|---------|---------|
| Звук не реагирует на «Голоса» | Канал не в `channel_defaults` или bus не Voice | П. 2 |
| Два голоса одновременно | Канал не в `dialogic_voice_stop.gd` | П. 3 |
| SFX слишком громкий | Нет относительного dB в `.dtl` | `volume="-8"` … `-14` |
| Ambient не зацикливается | `loop="false"` в `.dtl` | `loop="true"` + канал в Ambient |
