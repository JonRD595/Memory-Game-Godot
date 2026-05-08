extends RichTextLabel

func update_card_name(card_id: int, is_first: bool):
	var card_names = [
		"Caballo de Ajedrez", "Pato de Goma", "Bola 8", 
		"Ciclista", "Computadora", "Rebanada de Pastel",
		"Taza de Café", "Juego de 3 en Raya", "Calavera",
		"Seta Mágica", "Caballo de Troya", "Vaca"
	]
	
	if card_id >= 0 and card_id < card_names.size():
		if is_first:
			text = "Carta 1: " + card_names[card_id]
		else:
			text = "Carta 2: " + card_names[card_id]
