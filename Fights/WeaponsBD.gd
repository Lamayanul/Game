# WeaponsBD.gd
extends Node

var _db := {
	"FIST": {
		"name":"Pumni",
		"moves":[
			{"name":"Jab Mid",    "type":"attack","lane":"mid","power":6},
			{"name":"Hook Up",    "type":"attack","lane":"up", "power":5},
			{"name":"Kick Down",  "type":"attack","lane":"down","power":5},
			{"name":"Guard Down", "type":"defense","lane":"down","block":5},
			{"name":"Guard Mid",  "type":"defense","lane":"mid","block":8},
			{"name":"Guard Up",   "type":"defense","lane":"up", "block":10},
		]
	},
	"AXE01": {
		"name":"Topor rustic",
		"moves":[
			{"name":"Tăietură Mid",  "type":"attack","lane":"mid","power":12},
			{"name":"Tăietură Up",   "type":"attack","lane":"up", "power":11},
			{"name":"Tăietură Down", "type":"attack","lane":"down","power":10},
			{"name":"Parare Down",   "type":"defense","lane":"down","block":4},
			{"name":"Parare Mid",    "type":"defense","lane":"mid","block":6},
			{"name":"Parare Up",     "type":"defense","lane":"up", "block":9},
		]
	},
	"SWORD01": {
		"name":"Sabie ușoară",
		"moves":[
			{"name":"Slash Mid",  "type":"attack","lane":"mid","power":14},
			{"name":"Slash Up",   "type":"attack","lane":"up", "power":13},
			{"name":"Slash Down", "type":"attack","lane":"down","power":11},
			{"name":"Parare Down",   "type":"defense","lane":"down","block":4},
			{"name":"Parare Mid",    "type":"defense","lane":"mid","block":7},
			{"name":"Parare Up",     "type":"defense","lane":"up", "block":11},
		]
	},
}

func has_weapon(id: String) -> bool:
	return _db.has(id)

func get_weapon_moves(id: String) -> Array:
	var key := id if _db.has(id) else "FIST"
	var arr: Array = _db[key].get("moves", []).duplicate(true)
	for m in arr:
		m["type"] = String(m.get("type","attack")).strip_edges().to_lower()
		var ln := String(m.get("lane","mid")).strip_edges().to_lower()
		if ln in ["low","down","bottom"]: ln = "down"
		if ln in ["mid","middle","center","centre","med"]: ln = "mid"
		if ln in ["up","top","high"]: ln = "up"
		m["lane"] = ln
	return arr


func get_weapon_name(id: String) -> String:
	return String(_db.get(id, {}).get("name","(necunoscut)"))
