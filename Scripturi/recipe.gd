extends GridContainer
@onready var slot_container_1: Slot = $HBoxContainer/SlotContainer
@onready var slot_container_2: Slot = $HBoxContainer/SlotContainer2
@onready var slot_container_3: Slot = $HBoxContainer/SlotContainer5
@onready var inv = get_node("/root/world/CanvasLayer/Inv")
@onready var textrect =get_node("/root/world/Node2D/CanvasLayer/Recipe/HBoxContainer/SlotContainer5/TextureHolder/TextureRect3")



func _ready() -> void:
	# Conectează evenimentul de interacțiune pentru slot_container_3
	slot_container_3.connect("gui_input", Callable( self, "_on_slot_container_3_input"))

func _process(_delta: float) -> void:
	# Verifică dacă ingredientele sunt suficiente și setează preview-ul în slotul 3
	for recipe_name in recipes.keys():
		var recipe = recipes[recipe_name]
		var can_craft = true
	   
		# Verifică dacă ingredientele sunt suficiente
		for ingredient_id in recipe["ingredients"].keys():
			var required_amount = recipe["ingredients"][ingredient_id]
			if not has_item_in_slot(ingredient_id, required_amount):
				can_craft = false
				break

		if can_craft:
			# Afișează preview-ul pentru itemul ce urmează să fie craftat
			textrect.texture = recipe["result"]["TEXTURE"]  # Setează textura itemului
			textrect.modulate = Color(1, 1, 1, 0.5)  # Setează opacitatea la jumătate
			print("Preview-ul pentru", recipe["result"]["NUME"], "este afișat în slotul 3")
			return  # Ieși din funcție după ce ai setat preview-ul
	# Dacă ingredientele nu sunt suficiente, ascunde preview-ul
	textrect.texture = null
	textrect.modulate = Color(1, 1, 1, 0)  # Ascunde preview-ul dacă nu există suficiente ingrediente


var recipes = {
	"apple_pie": {
		"ingredients": { "3": 1, "7": 1 },  # ID-urile și cantitățile necesare
		"result": {
			"TEXTURE": preload("res://assets/pie.png"),
			"CANTITATE": 1,
			"NUMBER": 15,
			"NUME": "apple pie"
		}
	},
	"bread": {
		"ingredients": { "6": 2, "11": 1 },  # Altă combinație
		"result": {
			"TEXTURE": preload("res://assets/pickaxe.png"),
			"CANTITATE": 1,
			"NUMBER": 10,
			"NUME": "bread"
		}
	}
}
func _on_slot_container_3_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		print("intra in click")
		if slot_container_3.get_cantitate() > 0:
			# Obține detaliile itemului din slot_container_3
			var item_id = str(slot_container_3.get_number())
			var item_cantitate = slot_container_3.get_cantitate()
			# Adaugă itemul în inventar folosind funcția inv.add_item
			inv.add_item(item_id, item_cantitate)
			# Golește slot_container_3 după transfer
			slot_container_3.clear_item()
			print("Itemul craftat a fost transferat în inventar:", item_id, "Cantitate:", item_cantitate)
		else:
			print("Slotul de crafting este gol.")
	
func _on_button_pressed() -> void:
	# Iterează prin rețete și verifică dacă există o potrivire
	for recipe_name in recipes.keys():
		var recipe = recipes[recipe_name]
		var can_craft = true
		
		# Verifică dacă ingredientele există și sunt suficiente
		for ingredient_id in recipe["ingredients"].keys():
			var required_amount = recipe["ingredients"][ingredient_id]
			if not has_item_in_slot(ingredient_id, required_amount):
				can_craft = false
				break
		
		# Dacă se poate crafta, generează itemul rezultat
		if can_craft:
			print("Crafting item:", recipe["result"]["NUME"])
			textrect.modulate = Color(1, 1, 1, 1)
			#textrect.texture = recipe["result"]["TEXTURE"] 
			#textrect.modulate = Color(1, 1, 1, 1)  
			
			if slot_container_3.get_number() == recipe["result"]["NUMBER"]:
				# Adună 1 la cantitatea existentă
				var existing_cantitate = slot_container_3.get_cantitate()
				var new_cantitate = existing_cantitate + 1
				recipe["result"]["CANTITATE"] = new_cantitate
				print("Updated quantity for existing item:", new_cantitate)
			else:
				# Setează cantitatea la 1 pentru un item nou
				recipe["result"]["CANTITATE"] = 1
				print("Setting new item in slot_container_3")
			slot_container_3.set_property(recipe["result"])
			
			
			# Scade cantitățile necesare din sloturile de ingrediente
			for ingredient_id in recipe["ingredients"].keys():
				var required_amount = recipe["ingredients"][ingredient_id]
				decrease_item_in_slot(ingredient_id, required_amount)
			
			print("Crafted:", recipe["result"]["NUME"])
			return  # Ieșire după crafting reușit
	
	print("No valid recipe found.")

# Verifică dacă un slot conține itemul cu ID-ul specificat și cantitatea necesară
func has_item_in_slot(item_id: String, required_amount: int) -> bool:
	for slot in [$HBoxContainer/SlotContainer, $HBoxContainer/SlotContainer2]:
		if slot.get_id() == item_id and slot.get_cantitate() >= required_amount:
			return true
	return false

# Scade cantitatea unui item din slotul corespunzător
func decrease_item_in_slot(item_id: String, amount: int) -> void:
	for slot in [$HBoxContainer/SlotContainer, $HBoxContainer/SlotContainer2]:
		if slot.get_id() == item_id:
			slot.decrease_cantitate(amount)
			return
