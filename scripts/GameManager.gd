extends Node2D

# --- CONFIGURACIÓN ---
@export var card_scene: PackedScene
@export var grid_container: GridContainer
@export var background_sprite: Sprite2D
@export var ui_lives_label: Label
@export var ui_score_label: Label
@export var ui_timer_label: Label
@export var ui_question_panel: Panel
@export var ui_question_text: Label
@export var ui_answer_buttons: Array[Button]
@export var ui_game_over_panel: Panel
@export var ui_win_panel: Panel
@export var ui_final_score_label: Label

# Efectos de sonido
@export var sfx_flip: AudioStreamPlayer
@export var sfx_match: AudioStreamPlayer
@export var sfx_error: AudioStreamPlayer
@export var sfx_victory: AudioStreamPlayer
@export var music_player: AudioStreamPlayer

# Fondos por dificultad
@export var bg_easy: Texture2D
@export var bg_normal: Texture2D
@export var bg_hard: Texture2D

# --- ENUMS Y CONSTANTES ---
enum Difficulty { EASY, NORMAL, HARD }
enum GameState { MENU, PLAYING, QUESTION, GAME_OVER, WIN }

# --- VARIABLES DEL JUEGO ---
var current_difficulty = Difficulty.NORMAL
var current_state = GameState.MENU
var lives: int = 3
var max_lives: int = 3
var score: int = 0
var game_time: float = 0.0
var is_timer_running: bool = false

var cards_list: Array = []
var first_card_selected = null
var current_pair_candidate = []
var can_interact: bool = true
var matched_pairs: int = 0
var total_pairs: int = 0

# Sistema de combos
var combo_count: int = 0
var last_combo_time: float = 0.0
const COMBO_TIMEOUT: float = 3.0

# --- DATOS DE CARTAS ---
var card_images = [
	preload("res://sprites/0.png"),
	preload("res://sprites/1.png"),
	preload("res://sprites/2.png"),
	preload("res://sprites/3.png"),
	preload("res://sprites/4.png"),
	preload("res://sprites/5.png"),
	preload("res://sprites/6.png"),
	preload("res://sprites/7.png"),
	preload("res://sprites/8.png"),
	preload("res://sprites/9.png"),
	preload("res://sprites/10.png"),
	preload("res://sprites/11.png"),
	preload("res://sprites/12.png"),
	preload("res://sprites/13.png"),
	preload("res://sprites/14.png"),
	preload("res://sprites/15.png"),
	preload("res://sprites/16.png"),
	preload("res://sprites/17.png"),
	preload("res://sprites/18.png"),
	preload("res://sprites/19.png")
]

var back_image = preload("res://sprites/card_back.png")

# --- PREGUNTAS DE ESTRUCTURAS DINÁMICAS ---
var math_questions = [
	# Permutaciones
	{
		"q": "P(5,2): ¿Cuántas permutaciones de 2 elementos hay en 5?",
		"a": ["20", "10", "25", "15"],
		"correct": 0,
		"explanation": "P(n,k) = n!/(n-k)! = 5!/(5-2)! = 120/6 = 20"
	},
	{
		"q": "¿De cuántas formas pueden sentarse 4 personas en 6 sillas?",
		"a": ["360", "120", "240", "720"],
		"correct": 0,
		"explanation": "P(6,4) = 6!/(6-4)! = 720/2 = 360"
	},
	# Combinaciones
	{
		"q": "C(7,3): ¿Cuántas combinaciones de 3 elementos hay en 7?",
		"a": ["35", "21", "42", "28"],
		"correct": 0,
		"explanation": "C(n,k) = n!/(k!(n-k)!) = 7!/(3!4!) = 5040/(6*24) = 35"
	},
	{
		"q": "¿Cuántos equipos de 5 se pueden formar con 9 jugadores?",
		"a": ["126", "84", "210", "15120"],
		"correct": 0,
		"explanation": "C(9,5) = 9!/(5!4!) = 362880/(120*24) = 126"
	},
	# Factoriales
	{
		"q": "¿Cuál es el valor de 6! (factorial de 6)?",
		"a": ["720", "120", "360", "5040"],
		"correct": 0,
		"explanation": "6! = 6×5×4×3×2×1 = 720"
	},
	{
		"q": "¿Cuántos subconjuntos tiene un conjunto de 4 elementos?",
		"a": ["16", "8", "12", "24"],
		"correct": 0,
		"explanation": "2^n = 2^4 = 16 subconjuntos"
	},
	# Aplicaciones prácticas
	{
		"q": "¿Cuántas placas de 3 letras y 2 números se pueden hacer? (26 letras)",
		"a": ["1,757,600", "676,000", "3,276,000", "456,976"],
		"correct": 0,
		"explanation": "26³ × 10² = 17,576 × 100 = 1,757,600"
	},
	{
		"q": "¿De cuántas formas se pueden repartir 3 premios distintos entre 10 personas?",
		"a": ["720", "120", "360", "1000"],
		"correct": 0,
		"explanation": "P(10,3) = 10×9×8 = 720"
	},
	# Permutaciones con repetición
	{
		"q": "¿Cuántas permutaciones tiene la palabra 'MEMORIA'?",
		"a": ["2520", "1260", "5040", "720"],
		"correct": 0,
		"explanation": "7!/(2!2!) = 5040/(2×2) = 1260"
	},
	{
		"q": "¿Cuántos números de 4 cifras pares se pueden formar con 1,2,3,4?",
		"a": ["12", "24", "6", "8"],
		"correct": 0,
		"explanation": "Para ser par debe terminar en 2 o 4: 3×2×1×2 = 12"
	}
]

# --- FUNCIONES PRINCIPALES ---
func _ready():
	# Conectar botones de respuesta
	for i in range(ui_answer_buttons.size()):
		ui_answer_buttons[i].pressed.connect(_on_answer_selected.bind(i))
	
	# Iniciar música
	if music_player:
		music_player.play()
	
	# Ocultar paneles
	ui_question_panel.visible = false
	ui_game_over_panel.visible = false
	ui_win_panel.visible = false
	
	# Configurar conexiones de UI
	setup_ui_connections()

func setup_ui_connections():
	# PANEL DE GAME OVER
	var go_vbox = ui_game_over_panel.get_node_or_null("CenterContainer/VBoxContainer")
	if go_vbox:
		var btn_restart = go_vbox.get_node_or_null("RestartButton")
		if btn_restart:
			if btn_restart.pressed.is_connected(_on_restart_button_pressed):
				btn_restart.pressed.disconnect(_on_restart_button_pressed)
			btn_restart.pressed.connect(_on_restart_button_pressed)
		
		var btn_menu = go_vbox.get_node_or_null("MainMenuButton")
		if btn_menu:
			if btn_menu.pressed.is_connected(_on_main_menu_button_pressed):
				btn_menu.pressed.disconnect(_on_main_menu_button_pressed)
			btn_menu.pressed.connect(_on_main_menu_button_pressed)
			
	# PANEL DE VICTORIA
	var win_vbox = ui_win_panel.get_node_or_null("CenterContainer/VBoxContainer")
	if win_vbox:
		# IMPORTANTE: Revisa si en el Inspector este botón se llama "RestartButton"
		var btn_restart_win = win_vbox.get_node_or_null("RestartButton")
		if btn_restart_win:
			if btn_restart_win.pressed.is_connected(_on_restart_button_pressed):
				btn_restart_win.pressed.disconnect(_on_restart_button_pressed)
			btn_restart_win.pressed.connect(_on_restart_button_pressed)
		
		# IMPORTANTE: Aquí estaba el posible error. Buscamos ambos nombres por seguridad.
		var btn_menu_win = win_vbox.get_node_or_null("MainButton")
		if not btn_menu_win: 
			btn_menu_win = win_vbox.get_node_or_null("MainMenuButton")
			
		if btn_menu_win:
			if btn_menu_win.pressed.is_connected(_on_main_menu_button_pressed):
				btn_menu_win.pressed.disconnect(_on_main_menu_button_pressed)
			btn_menu_win.pressed.connect(_on_main_menu_button_pressed)

func start_game(difficulty: Difficulty):
	current_difficulty = difficulty
	current_state = GameState.PLAYING
	matched_pairs = 0
	score = 0
	game_time = 0.0
	is_timer_running = true
	combo_count = 0
	current_pair_candidate.clear()
	
	# Configurar según dificultad
	match difficulty:
		Difficulty.EASY:
			total_pairs = 6
			lives = 7
			grid_container.columns = 4
			if bg_easy:
				background_sprite.texture = bg_easy
		Difficulty.NORMAL:
			total_pairs = 8
			lives = 5
			grid_container.columns = 4
			if bg_normal:
				background_sprite.texture = bg_normal
		Difficulty.HARD:
			total_pairs = 12
			lives = 4
			grid_container.columns = 6
			if bg_hard:
				background_sprite.texture = bg_hard
	
	max_lives = lives
	update_ui()
	generate_cards(total_pairs)
	
	# Iniciar timer
	if has_node("GameTimer"):
		$GameTimer.start()
	else:
		# Crear timer si no existe
		var timer = Timer.new()
		timer.name = "GameTimer"
		timer.wait_time = 1.0
		timer.autostart = true
		timer.timeout.connect(_on_game_timer_timeout)
		add_child(timer)

func generate_cards(num_pairs):
	# Limpiar tablero
	for child in grid_container.get_children():
		child.queue_free()
	
	first_card_selected = null
	can_interact = true
	cards_list.clear()
	current_pair_candidate.clear()
	
	# Crear mazo
	var deck = []
	for i in range(num_pairs):
		deck.append(i)
		deck.append(i)
	
	# Barajar usando algoritmo Fisher-Yates
	for i in range(deck.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = deck[i]
		deck[i] = deck[j]
		deck[j] = temp
	
	# Crear cartas
	for card_id in deck:
		var new_card = card_scene.instantiate()
		grid_container.add_child(new_card)
		var img_index = card_id % card_images.size()
		new_card.setup(card_id, card_images[img_index], back_image)
		new_card.card_clicked.connect(_on_card_clicked)
		cards_list.append(new_card)

func _on_card_clicked(card):
	if current_state != GameState.PLAYING or not can_interact:
		return
	if card == first_card_selected:
		return
	
	if sfx_flip:
		sfx_flip.play()
	
	card.flip_up()
	
	if first_card_selected == null:
		first_card_selected = card
	else:
		_check_match(first_card_selected, card)

func _check_match(card1, card2):
	can_interact = false
	
	if card1.card_id == card2.card_id:
		# Verificar combo
		var current_time = Time.get_unix_time_from_system()
		if current_time - last_combo_time < COMBO_TIMEOUT:
			combo_count += 1
		else:
			combo_count = 1
		
		last_combo_time = current_time
		
		# Calcular puntos con combo
		var base_points = 100
		var combo_bonus = combo_count * 50
		var points = base_points + combo_bonus
		score += points
		
		# Si no es fácil, activar pregunta matemática
		if current_difficulty != Difficulty.EASY:
			current_state = GameState.QUESTION
			current_pair_candidate = [card1, card2]
			trigger_math_question()
		else:
			complete_match(card1, card2, points)
	else:
		# Error - perder vida
		lives -= 1
		combo_count = 0
		update_ui()
		if sfx_error:
			sfx_error.play()
		
		# Animación de error en ambas cartas
		card1.shake()
		card2.shake()
		
		await get_tree().create_timer(0.8).timeout
		
		# Voltear cartas
		card1.flip_down()
		card2.flip_down()
		
		if lives <= 0:
			game_over()
		else:
			reset_turn()

func complete_match(card1, card2, points_earned: int):
	if sfx_match:
		sfx_match.play()
	
	card1.match_found()
	card2.match_found()
	
	matched_pairs += 1
	update_ui()
	
	# Verificar victoria
	if matched_pairs >= total_pairs:
		victory()
	else:
		reset_turn()

func reset_turn():
	first_card_selected = null
	can_interact = true

func update_ui():
	if ui_lives_label:
		ui_lives_label.text = "❤️ × %d" % lives
	
	if ui_score_label:
		ui_score_label.text = "Puntos: %d" % score
		
		# Mostrar combo si hay
		if combo_count > 1:
			ui_score_label.text += " (Combo ×%d!)" % combo_count
	
	if ui_timer_label:
		# Actualizar timer
		var minutes = int(game_time) / 60
		var seconds = int(game_time) % 60
		ui_timer_label.text = "Tiempo: %02d:%02d" % [minutes, seconds]

func _process(delta):
	if is_timer_running and current_state == GameState.PLAYING:
		game_time += delta
		update_ui()

func trigger_math_question():
	var q_data = math_questions.pick_random()
	ui_question_panel.visible = true
	ui_question_text.text = "¡Par encontrado!\n%s" % q_data["q"]
	
	# Mezclar respuestas
	var answers = q_data["a"].duplicate()
	var correct_idx = q_data["correct"]
	
	# Configurar botones
	for i in range(ui_answer_buttons.size()):
		if i < answers.size():
			ui_answer_buttons[i].text = answers[i]
			ui_answer_buttons[i].disabled = false
	
	ui_question_panel.set_meta("correct_idx", correct_idx)
	ui_question_panel.set_meta("explanation", q_data["explanation"])

func _on_answer_selected(btn_index):
	ui_question_panel.visible = false
	var correct = ui_question_panel.get_meta("correct_idx")
	
	if btn_index == correct:
		# Respuesta correcta - obtener puntos extra
		var extra_points = 50 * (combo_count + 1)
		score += extra_points
		complete_match(current_pair_candidate[0], current_pair_candidate[1], extra_points)
	else:
		# Respuesta incorrecta - perder el par
		if sfx_error:
			sfx_error.play()
		lives -= 1
		current_pair_candidate[0].flip_down()
		current_pair_candidate[1].flip_down()
		
		# Mostrar explicación
		var explanation = ui_question_panel.get_meta("explanation")
		print("Incorrecto. Explicación: ", explanation)
		
		update_ui()
		
		if lives <= 0:
			game_over()
		else:
			reset_turn()
	
	current_state = GameState.PLAYING

func game_over():
	current_state = GameState.GAME_OVER
	is_timer_running = false
	ui_game_over_panel.visible = true
	if ui_final_score_label:
		ui_final_score_label.text = "Puntuación Final: %d\nTiempo: %02d:%02d" % [
			score, int(game_time)/60, int(game_time)%60 
		]
	for card in cards_list:
				if is_instance_valid(card):
					card.mouse_filter = Control.MOUSE_FILTER_IGNORE

func victory():
	current_state = GameState.WIN
	is_timer_running = false
	if sfx_victory:
		sfx_victory.play()
	
	# Calcular bonus por tiempo
	var time_bonus = max(0, 1000 - int(game_time) * 10)
	score += time_bonus
	
	ui_win_panel.visible = true
	if ui_final_score_label:
		ui_final_score_label.text = "¡Victoria!\nPuntos: %d\nBonus Tiempo: +%d\nTiempo Total: %02d:%02d" % [
			score - time_bonus, time_bonus, int(game_time)/60, int(game_time)%60
		]

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MenuScene.tscn")

func _on_game_timer_timeout():
	if is_timer_running:
		game_time += 1.0
		update_ui()
