extends CanvasLayer

@onready var pause_menu = $PauseMenu
@onready var resume_button = $PauseMenu/ResumeButton
@onready var main_menu_button = $PauseMenu/MainMenuButton

var is_paused = false

func _ready():
	pause_menu.visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	pause_menu.visible = is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_pressed():
	toggle_pause()

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MenuScene.tscn")
