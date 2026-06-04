extends Node
## Флаги запуска игры из главного меню (новая / продолжить).

enum StartMode { NONE, NEW_GAME, CONTINUE }

var _start_mode := StartMode.NONE


func request_new_game() -> void:
	_start_mode = StartMode.NEW_GAME


func request_continue() -> void:
	_start_mode = StartMode.CONTINUE


func consume_start_mode() -> StartMode:
	var mode := _start_mode
	_start_mode = StartMode.NONE
	return mode
