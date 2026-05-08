extends Node2D

# Referencias actualizadas con rutas completas
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var start_button: Button = $CanvasLayer/CenterContainer/VBoxContainer/ButtonContainer/StartButton
@onready var quit_button: Button = $CanvasLayer/CenterContainer/VBoxContainer/ButtonContainer/QuitButton
@onready var easy_button: Button = $CanvasLayer/CenterContainer/VBoxContainer/ButtonContainer/EasyButton
@onready var normal_button: Button = $CanvasLayer/CenterContainer/VBoxContainer/ButtonContainer/NormalButton
@onready var hard_button: Button = $CanvasLayer/CenterContainer/VBoxContainer/ButtonContainer/HardButton

# Ajusta estas rutas según dónde estén tus etiquetas en el árbol
@onready var game_title: Label = $CanvasLayer/CenterContainer/VBoxContainer/TitleContainer/GameTitle
@onready var credits: Label = $CanvasLayer/CenterContainer/VBoxContainer/Credits


@onready var menu_music = get_node_or_null("MenuMusic")
@onready var click_sound = get_node_or_null("ClickSound")

var game_scene = preload("res://scenes/GameManager.tscn")
var current_game_instance = null

func _ready():
	if menu_music:
		menu_music.play()
	setup_button_connections()
	show_menu_elements(true)

func setup_button_connections():
	if start_button: start_button.pressed.connect(_on_StartButton_pressed)
	if quit_button: quit_button.pressed.connect(_on_QuitButton_pressed)
	if easy_button: easy_button.pressed.connect(_on_EasyButton_pressed)
	if normal_button: normal_button.pressed.connect(_on_NormalButton_pressed)
	if hard_button: hard_button.pressed.connect(_on_HardButton_pressed)

func show_menu_elements(show: bool):
	# En lugar de ocultar uno por uno, ocultamos la capa entera
	if canvas_layer:
		canvas_layer.visible = show
	
	# Detener música del menú si el juego empieza
	if not show and menu_music:
		menu_music.stop()

func _on_StartButton_pressed():
	play_click_sound()
	start_game_with_difficulty(1)

func _on_EasyButton_pressed():
	play_click_sound()
	start_game_with_difficulty(0)

func _on_NormalButton_pressed():
	play_click_sound()
	start_game_with_difficulty(1)

func _on_HardButton_pressed():
	play_click_sound()
	start_game_with_difficulty(2)

func start_game_with_difficulty(difficulty: int):
	show_menu_elements(false)
	
	current_game_instance = game_scene.instantiate()
	add_child(current_game_instance)
	
	current_game_instance.tree_exiting.connect(_on_game_finished)
	
	await get_tree().create_timer(0.1).timeout
	
	# Usamos el nombre exacto que le pusiste al nodo raíz
	var game_manager = current_game_instance
	if game_manager and game_manager.has_method("start_game"):
		match difficulty:
			0: game_manager.start_game(game_manager.Difficulty.EASY)
			1: game_manager.start_game(game_manager.Difficulty.NORMAL)
			2: game_manager.start_game(game_manager.Difficulty.HARD)

func _on_game_finished():
	show_menu_elements(true)
	if menu_music:
		menu_music.play()

func _on_QuitButton_pressed():
	play_click_sound()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func play_click_sound():
	if click_sound:
		click_sound.play()
