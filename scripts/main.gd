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
	Dialogic.start(timeline_name)


func _on_timeline_ended() -> void:
	match current_timeline:
		"scene1_timeline":
			_start_timeline("scene2_timeline")
		"scene2_timeline":
			_start_timeline("scene3_timeline")
		"scene3_timeline":
			print("Сцена 3 завершена. Здесь будет переход к Сцене 4.")
		_:
			print("Таймлайн завершён: %s" % current_timeline)
