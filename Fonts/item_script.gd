@tool
class_name EfectArc
extends RichTextEffect

# Numele tag-ului pe care îl vei folosi în text
var bbcode = "arc"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	# Preluăm setările din tag. Dacă nu le scrii, folosește valorile implicite (30 și 10)
	var inaltime = float(char_fx.env.get("inaltime", 30.0))
	var litere = float(char_fx.env.get("litere", 10.0))
	
	# Calculăm cât de departe suntem în interiorul cuvântului (de la 0.0 la 1.0)
	var progres = float(char_fx.relative_index) / max(1.0, litere - 1.0)
	
	# Folosim PI pentru a crea o boltă perfectă (jumătate de cerc)
	var unghi = progres * PI
	
	# 1. Ridicăm litera pe axa Y (în 2D, minus înseamnă în sus)
	char_fx.offset.y -= sin(unghi) * inaltime
	
	# 2. Rotim litera ca să se încline natural pe curbură
	# Derivata lui sin este cos. Ajustăm cu un factor matematic (35.0) ca să arate bine vizual
	var inclinare = -cos(unghi) * (inaltime / 35.0)
	char_fx.transform = char_fx.transform.rotated(inclinare)
	
	return true
