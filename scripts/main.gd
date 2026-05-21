extends Node

# Главный скрипт игры «Баргый: Путь сквозь Лёд»
# Запускает первый таймлайн (Сцена 1: Пурга) при старте проекта.

var current_timeline := ""


func _ready() -> void:
	var timeline_ended_callback := Callable(self, "_on_timeline_ended")
	if not Dialogic.timeline_ended.is_connected(timeline_ended_callback):
		Dialogic.timeline_ended.connect(timeline_ended_callback)

	# Запускаем таймлайн Сцены 1
	# Имя 'scene1_timeline' — это имя файла без расширения (.dtl)
	# Dialogic ищет таймлайны по всему проекту автоматически.
	_start_timeline("scene1_timeline")


func _start_timeline(timeline_name: String) -> void:
	current_timeline = timeline_name
	print("Запуск таймлайна: %s" % timeline_name)
	Dialogic.start(timeline_name)


func _on_timeline_ended() -> void:
	match current_timeline:
		"scene1_timeline":
			await get_tree().process_frame
			_start_timeline("scene2_timeline")
		"scene2_timeline":
			await get_tree().process_frame
			_start_timeline("scene3_timeline")
		"scene3_timeline":
			await get_tree().process_frame
			_start_timeline("scene4_timeline")
		"scene4_timeline":
			await get_tree().process_frame
			_start_timeline("scene5_timeline")
		"scene5_timeline":
			await get_tree().process_frame
			_start_timeline("scene6_timeline")
		"scene6_timeline":
			await get_tree().process_frame
			_start_timeline("scene7_timeline")
		"scene7_timeline":
			await get_tree().process_frame
			_start_timeline("scene8_timeline")
		"scene8_timeline":
			await get_tree().process_frame
			_start_timeline("scene9_timeline")
		"scene9_timeline":
			print("Сцена 9 завершена. Здесь будет переход к Сцене 10.")
		_:
			print("Таймлайн завершён: %s" % current_timeline)
