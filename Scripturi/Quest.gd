extends Resource
class_name Quest

@export var title: String
@export var description : String

@export var required_item_id: String = ""

@export_enum("Fetch","Kill") var objectives: String
@export var object : String

@export_enum("Active","Complete") var status : String

@export var next_questline : Dialogue
