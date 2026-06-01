# Сцена 10 — вычисление ending_id + 9 ОТДЕЛЬНЫХ финалов (ВАРИАНТ Б)

jump НЕ используется. Переходы — через main.gd (match current_timeline + _start_timeline).
Паттерн уже есть в scene3 (чтение Dialogic.VAR + условный переход) — копируем его.

## Часть 1 — в конце scene10_timeline.dtl (ПОСЛЕ общей части, ПЕРЕД [end_timeline])

Вставить вычисление ending_id (вложенные if, elif нет, отступы ТАБЫ):

```
if {lesson_act1} == "" or {lesson_act2} == "":
	set ending_id = 5
else:
	if {lesson_act1} == "compassion":
		if {lesson_act2} == "acceptance":
			set ending_id = 1
		else:
			if {lesson_act2} == "humility":
				set ending_id = 2
			else:
				set ending_id = 3
	else:
		if {lesson_act1} == "boundaries":
			if {lesson_act2} == "acceptance":
				set ending_id = 4
			else:
				if {lesson_act2} == "humility":
					set ending_id = 5
				else:
					set ending_id = 6
		else:
			if {lesson_act2} == "acceptance":
				set ending_id = 7
			else:
				if {lesson_act2} == "humility":
					set ending_id = 8
				else:
					set ending_id = 9
```

Затем обычный [end_timeline] (он уже есть). main.gd поймает завершение.

## Часть 2 — правка main.gd (ТОЧНАЯ, под реальный код)

В match current_timeline ветка "scene10_timeline" сейчас (строки ~69-70):
```gdscript
		"scene10_timeline":
			print("Игра завершена. Финальный каркас пройден.")
```
ЗАМЕНИТЬ на:
```gdscript
		"scene10_timeline":
			print("ending_id = ", Dialogic.VAR.ending_id)
			await get_tree().process_frame
			var n = Dialogic.VAR.ending_id
			if n < 1 or n > 9:
				n = 5
			_start_timeline("scene10_ending_%d" % n)
		"scene10_ending_1", "scene10_ending_2", "scene10_ending_3", "scene10_ending_4", "scene10_ending_5", "scene10_ending_6", "scene10_ending_7", "scene10_ending_8", "scene10_ending_9":
			print("Игра завершена. Концовка: ", current_timeline)
```
Логика 1:1 как у работающей ветки scene3 (accepted_initiation). Завершение игры —
простой print, как в ending_bad_early (в проекте титров/меню пока нет). Ветку
ending_bad_early и остальные НЕ трогать. Отступы в main.gd — как в файле (табы).

## Часть 3 — 9 файлов финалов

Создать dialogic/timelines/scene10_ending_1.dtl ... scene10_ending_9.dtl.
В каждый — ПОЛНЫЙ текст из docs/branching/endings/ending_N (реплики + # TODO арт +
set-флаги). [end_timeline] в конце каждого ОСТАВИТЬ (он уже есть в файлах endings/).

## Что НЕ делаем
- jump не используем.
- В main.gd меняем ТОЛЬКО ветку scene10_timeline (+ добавляем ветку 9 финалов). Прочее не трогать.

ТЕСТ: через debug_scene_select задать lesson_act1/lesson_act2, дойти до конца scene10 —
запускается верный scene10_ending_N, в Output печатается номер концовки, нет ошибок.
