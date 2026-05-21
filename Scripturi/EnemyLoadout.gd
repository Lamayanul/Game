class_name EnemyLoadout extends Resource

@export_group("Inventar de Start")
# Lista de ID-uri de iteme (ex: ["2", "13"] pentru Axe + Scut)
@export var items: Array[String] = []

@export_group("AI Combat Style")
# Cât de des își schimbă arma (0 = niciodată, 1 = în fiecare tură dacă are mai multe)
@export_range(0.0, 1.0) var switch_weapon_chance: float = 0.2
# Preferința: "random", "melee_only", "ranged_priority"
@export_enum("random", "melee", "ranged") var style: String = "random"

@export_group("AI Survival")
# La ce procentaj de viață începe să mănânce (0.5 = 50% HP)
@export_range(0.0, 1.0) var heal_threshold: float = 0.5 
# Cât de des verifică să mănânce dacă este rănit (0.1 = 10% șansă pe tick)
@export_range(0.0, 1.0) var heal_chance: float = 0.2

@export_group("Night Transformation")
@export var night_texture: Texture2D
@export var night_background: Texture2D
# Amount to heal when night starts (-1 = Full Heal)
@export var night_heal_amount: int = -1
# Items that REPLACE the normal loadout at night (if not empty)
@export var night_items: Array[String] = []
