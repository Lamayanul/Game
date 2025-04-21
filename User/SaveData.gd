extends Resource
class_name SaveData


@export var player_data: Dictionary = {
	"health": 0,
	"position": Vector2.ZERO,
	"speed":50
}


@export var chest_items_data: Dictionary = {
}

@export var gaini_data: Dictionary = {
}

@export var copaci_data: Dictionary = {
}

@export var bush_data: Dictionary = {
}

@export var radacina_data: Dictionary = {
}

@export var generator_things: Dictionary = {
}

@export var oven_data: Dictionary = {
}

@export var elec_pillar_data: Dictionary = {
}

@export var barca_data: Dictionary = {
}

@export var save_tilemap: Dictionary = {
}
@export var textura_path: String = ""
@export var textura:ImageTexture = null
@export var saved_ogor_tiles: Array=[]
@export var power_generators = []
@export var title:String
@export var scor: int=0
@export var gaina_positions: Array = []
@export var enemy_position: Vector2 = Vector2.ZERO
@export var rocks_position: Array=[]
@export var enemy_data: Array=[]
@export var trees_position: Array = []
@export var item_positions: Array = []
@export var item_ids: Array = []
@export var inv_item: Array = []
@export var power_generator_slot: Array = []
@export var recipe_item: Array =[]
@export var elec_item: Array =[]
@export var chest_items: Array = []
