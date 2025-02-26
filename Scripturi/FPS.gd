extends Label  # Atașează acest script unui nod Label pentru a afișa textul

func _process(_delta):
	text = "FPS: " + str(Engine.get_frames_per_second())
