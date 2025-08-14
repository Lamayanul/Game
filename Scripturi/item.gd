extends Sprite2D

@export var ID =""
@export var item_cantitate:int =1
@export var type: String
@onready var shadow = Sprite2D.new()
var raritate: String 
var float_amplitude: float = 2.0  
var float_speed: float = 2.0 
var original_position: Vector2 
var time_passed: float = 0.0  
# Variabile pentru textura și cantitate
var item_texture: Texture
@onready var grid_container = get_node("/root/world/CanvasLayer/Inv/MarginContainer/GridContainer")
@onready var player_light = get_node_or_null("/root/world/player/PointLight2D")




func _ready():
	# Setează textura folosind ID-ul
	if type=="slot":
		set_texture1(load("res://assets/" + ItemData.get_texture(ID)) as Texture)
	else:
		set_texture1(load("res://assets/" + DatabaseCuppon.get_texture(ID)) as Texture)
	original_position = position    
	custom_scale()


func _on_body_entered(body):
	
	if QuestManager.quest and QuestManager.quest.objectives == "Fetch":
		if ID == QuestManager.quest.required_item_id:
			print("✔️ Itemul necesar pentru quest a fost colectat:", ID)
			QuestManager.next_quest()
			queue_free()
			return
	
	if body.is_in_group("player"):
		if type=="slot":
			var inventory = get_parent().find_child("Inv")
			
			print("Jucătorul a atins obiectul. ID:", ID, " Cantitate:", item_cantitate)
			print("Inventar plin:", inventory.plin)

			# 1. Încearcă să adauge itemul în inventar
			var added = inventory.add_item(ID, self.get_cantiti())

			# 2. Dacă s-a adăugat cu succes, elimină obiectul din scenă
			if added:
				queue_free()
				print("Obiect colectat și șters.")
			else:
				print("Inventarul este plin! Nu pot adăuga obiectul.")
				
				
		if type=="slot_cup":
			var inventory = get_parent().find_child("Inv2")
		
			print("Jucătorul a atins obiectul. ID:", ID, " Cantitate:", item_cantitate)
			print("Inventar plin:", inventory.plin)

			# 1. Încearcă să adauge itemul în inventar
			var added = inventory.add_item(ID, self.get_cantiti())

			# 2. Dacă s-a adăugat cu succes, elimină obiectul din scenă
			if added:
				queue_free()
				print("Obiect colectat și șters.")
			else:
				print("Inventarul este plin! Nu pot adăuga obiectul.")
		

func custom_scale():
	if ID=="15" || ID=="23":
		scale=Vector2(0.65,0.65)
	if  ID=="26" || ID=="27" || ID=="28" || ID=="29" || ID=="30" || ID=="31" || ID=="32":
		scale=Vector2(0.1,0.1)

		
func _process(_delta: float):
	#time_passed += delta
	#position.y = original_position.y + sin(time_passed * float_speed) * float_amplitude
	#lamp()
	pass
	

# Metodă pentru a seta textura pe obiect
func set_texture1(texture_drop: Texture):
	item_texture = texture_drop
	self.texture = item_texture  # Asigură-te că setezi textura pe Sprite2D

# Metodă pentru a seta cantitatea pe obiect
func set_cantitate(cantitate: int):
	if cantitate==0:
		
		return
	item_cantitate = cantitate
	# Dacă ai un Label pentru a afișa cantitatea, îl poți seta aici
	# Exemplu: label.text = str(item_cantitate)
func get_cantiti():
	return item_cantitate
	
#func set_lumina(new_ID):
	#if new_ID=="23":
		#$PointLight2D.visible=true
		#$PointLight2D.enabled=true
		#print("Aprind lumina!")
		
		
#func lamp():
	#var item_23_gasit = false
	#for i in range(grid_container.get_child_count()):
			#var slot = grid_container.get_child(i)
			#if slot is Slot:
				## Verifica daca slotul este plin si contine un scut
				#if slot.get_id() == "23":
					#item_23_gasit = true
					#$CanvasLayer.visible = true
					#if slot_container.get_id()=="7":
						#var cantitate= slot_container.get_cantitate()
						#if cantitate>0:
							#timp_ramas=cantitate*60
							#label.text = format_time(timp_ramas)
							#timer.start()
							#slot_container.clear_item()
	#if not item_23_gasit:
		#$CanvasLayer.visible = false
		#player_light.visible=false
		#player_light.enabled=false
#
#func lumina_pe_player():
	#if timp_ramas>0:
		#player_light.visible=true
		#player_light.enabled=true
		#
#func _on_timer_timeout() -> void:
	#if timp_ramas > 0:
		#timp_ramas -= 1  # Scade o secundă din timpul rămas
		#label.text = format_time(timp_ramas)  # 🔥 Actualizează UI-ul
#
		## Consumă 1 combustibil la fiecare 60 secunde
		#if timp_ramas % 60 == 0:
			#var cantitate = slot_container.get_cantitate()
			#if cantitate > 0:
				#slot_container.set_cantitate(cantitate - 1)  # 🔥 Consumă combustibil
				#print("Cantitatea rămasă: " + str(cantitate - 1))
#
			#if cantitate - 1 <= 0:
				#print("Combustibilul s-a epuizat!")
			#
	#else:
		#light.enabled=false
		#timer.stop()
		#print("Timpul a expirat!")
		#
#
#
#func format_time(seconds: int) -> String:
	#var minutes = seconds / 60
	#var secs = seconds % 60
	#return str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)
