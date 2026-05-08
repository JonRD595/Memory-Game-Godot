extends Control

signal card_clicked(card_ref)

# Referencias actualizadas: si moviste ClickSound fuera de Area2D, 
# asegúrate de que el nombre coincida aquí.
@onready var sprite = $Area2D/Sprite2D
@onready var click_sound = $ClickSound

var face_texture: Texture2D
var back_texture: Texture2D
var card_id: int
var is_flipped: bool = false
var is_matched: bool = false
var is_animating: bool = false

# Variables para los tweens
var flip_tween: Tween
var match_tween: Tween

func setup(id: int, front: Texture2D, back: Texture2D):
	card_id = id
	face_texture = front
	back_texture = back
	sprite.texture = back_texture
	is_flipped = false
	is_matched = false
	scale = Vector2(1, 1)
	modulate = Color(1, 1, 1, 1)
	# Nota: input_pickable ya no es necesario en Control, 
	# usaremos mouse_filter si quisiéramos desactivar el clic.
	mouse_filter = Control.MOUSE_FILTER_STOP

# Esta es la nueva función que detecta clics en nodos tipo Control
func _gui_input(event):
	if (event is InputEventMouseButton 
		and event.button_index == MOUSE_BUTTON_LEFT 
		and event.pressed):
		if not is_flipped and not is_matched and not is_animating:
			if click_sound:
				click_sound.play()
			emit_signal("card_clicked", self)

func flip_up():
	if is_animating:
		return
	
	is_animating = true
	is_flipped = true
	
	if flip_tween:
		flip_tween.kill()
	flip_tween = create_tween()
	
	# Usamos pivot_offset para que el escalado sea desde el centro de la carta
	pivot_offset = size / 2
	
	flip_tween.tween_property(self, "scale:x", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await flip_tween.finished
	
	sprite.texture = face_texture
	
	flip_tween = create_tween()
	flip_tween.tween_property(self, "scale:x", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await flip_tween.finished
	is_animating = false

func flip_down():
	if is_animating or is_matched:
		return
	
	is_animating = true
	
	if flip_tween:
		flip_tween.kill()
	flip_tween = create_tween()
	
	pivot_offset = size / 2
	
	flip_tween.tween_property(self, "scale:x", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await flip_tween.finished
	
	sprite.texture = back_texture
	is_flipped = false
	
	flip_tween = create_tween()
	flip_tween.tween_property(self, "scale:x", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await flip_tween.finished
	is_animating = false

func match_found():
	is_matched = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if match_tween:
		match_tween.kill()
	match_tween = create_tween()
	
	pivot_offset = size / 2
	
	match_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	match_tween.parallel().tween_property(self, "modulate", Color(0.5, 1, 0.5, 0.7), 0.3)
	await match_tween.finished
	
	match_tween = create_tween()
	match_tween.tween_property(self, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

func shake():
	if is_animating: return
	is_animating = true
	var original_pos = position
	var tween = create_tween()
	for i in range(4):
		var offset = 10 if i % 2 == 0 else -10
		tween.tween_property(self, "position:x", original_pos.x + offset, 0.05)
	
	tween.tween_property(self, "position:x", original_pos.x, 0.05)
	await tween.finished
	is_animating = false
