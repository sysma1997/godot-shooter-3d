# Crea una textura de ajedrez y la guarda como recurso .tres
@tool
extends EditorScript

func _run() -> void:
	var size := 512  # resolución de la textura
	var squares := 8  # número de cuadros por lado
	var square_size := size / squares
	
	var image := Image.create(size, size, false, Image.FORMAT_RGB8)
	
	for x in range(size):
		for y in range(size):
			var square_x := int(x / square_size)
			var square_y := int(y / square_size)
			var is_white := (square_x + square_y) % 2 == 0
			
			# Colores: gris claro y gris oscuro (no blanco puro)
			var color := Color(0.8, 0.8, 0.8) if is_white else Color(0.2, 0.2, 0.2)
			image.set_pixel(x, y, color)
	
	var texture := ImageTexture.create_from_image(image)
	
	# Guardar la textura
	var save_path := "res://assets/textures/checkerboard.tres"
	ResourceSaver.save(texture, save_path)
	print("Textura guardada en: ", save_path)
