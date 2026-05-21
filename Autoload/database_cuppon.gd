extends Node

var content:Dictionary= {}

func _ready():
	var file=FileAccess.open("res://Autoload/database_cuppon.json",FileAccess.READ)
	content=JSON.parse_string(file.get_as_text())
	file.close()
 #print("Content:", content)
 #for key in content.keys():
  #print("Key:", key, "Value:", content[key])


func get_texture(ID="0"):
	return content[ID]["texture"]

func get_cantitate(ID="0"):
	return content[ID]["cantitate"]

func get_number(ID="0"):
	return content[ID]["number"]

func get_nume(ID="0"):
	return content[ID]["nume"]

func get_raritate(ID="0"):
	return content[ID]["raritate"]

func get_random_drops(selected_id = null) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var num_drops = 4
	var interval_min = 1
	var interval_max = 10
	var all_keys = content.keys()
	var pool_keys = []

	if str(selected_id) == "27":
		for k in all_keys:
			var kid = int(k)
			if kid >= interval_min and kid <= interval_max:
				pool_keys.append(k)
	else:
		for k in all_keys:
			if k != "0":
				pool_keys.append(k)

	var results = []
	if pool_keys.size() < num_drops: return results

	for i in range(num_drops):
		var id_item = pool_keys[rng.randi_range(0, pool_keys.size() - 1)]
		var item_data = content[str(id_item)]
		var raritate = item_data.get("raritate", "comuna")
		var qty = 1
		match raritate:
			"comuna": qty = rng.randi_range(5, 15)
			"rara": qty = rng.randi_range(1, 10)
			"epica": qty = rng.randi_range(1, 5)
			"legendara": qty = 1
		
		results.append({"id": str(id_item), "qty": qty})
	return results
