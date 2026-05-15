extends Node

# Главный скрипт игры «Баргый: Путь сквозь Лёд»
# Запускает первый таймлайн (Сцена 1: Пурга) при старте проекта.

func _ready() -> void:
	# Запускаем таймлайн Сцены 1
	# Имя 'scene1_timeline' — это имя файла без расширения (.dtl)
	# Dialogic ищет таймлайны по всему проекту автоматически.
	Dialogic.start("scene1_timeline")
	
	# Когда таймлайн закончится — печатаем в консоль
	Dialogic.timeline_ended.connect(_on_timeline_ended)


func _on_timeline_ended() -> void:
	print("Сцена 1 завершена. Здесь будет переход к Сцене 2.")
	# В будущем: get_tree().change_scene_to_file("res://scenes/scene2.tscn")
