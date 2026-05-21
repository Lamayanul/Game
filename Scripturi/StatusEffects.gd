extends Node
class_name StatusEffects

@onready var inv = get_node("/root/world/CanvasLayer/Inv")

# ======================= CONFIG / REGISTRIES =======================

const MODE_HOLDING    := "holding"
const MODE_CONSUMABLE := "consumable"

# Registru efecte â€“ adaugi uÈ™or intrÄƒri noi.
# Chei suportate: id, mode, tags, default_duration, default_period, default_amount, modifiers, special("cleanse"|"shield"|nil)
const REG_EFFECTS := {
	"regen": {
		"id": "regen", "mode": MODE_CONSUMABLE, "tags": ["heal","over_time"],
		"default_amount": 3.0, "default_duration": 10.0, "default_period": 1.0
	},
	"poison": {
		"id": "poison", "mode": MODE_CONSUMABLE, "tags": ["poison","dot"],
		"default_amount": 1.0, "default_duration": 8.0, "default_period": 1.0
	},
	"shield": {
		"id": "shield", "mode": MODE_CONSUMABLE, "tags": ["shield"],
		"default_amount": 20.0, "default_duration": 10.0, "special": "shield"
	},
	"buff_atk": {
		"id": "buff_atk", "mode": MODE_CONSUMABLE, "tags": ["buff","atk"],
		"default_duration": 15.0,
		"modifiers": {"atk_add": 5.0}
	},
	"swift": {
		"id": "swift", "mode": MODE_CONSUMABLE, "tags": ["buff","spd"],
		"default_duration": 12.0,
		"modifiers": {"spd_mult": 1.2}
	},
	"cleanse": {
		"id": "cleanse", "mode": MODE_HOLDING, "tags": ["cleanse"],
		# duration: -1 => permanent cÃ¢t timp itemul e È›inut; 0 => doar â€žburstâ€; >0 => temporar
		"default_duration": -1.0,
		"special": "cleanse" # apeleazÄƒ pipeline-ul de curÄƒÈ›are/blocare
	},
	"burning": {
		"id": "burning", "mode": MODE_HOLDING, "tags": ["dot", "fire"],
		"default_amount": 2.0, "default_duration": -1.0, "default_period": 1.0
	}
}

# Registru curse â€“ la fel, extins uÈ™or.
# Chei suportate: id, mode, tags, default_duration, modifiers, lock, slot_types (opÈ›ional)
const REG_CURSES := {
	"lock": {
		"id": "lock", "mode": MODE_HOLDING, "tags": ["lock"], "default_duration": -1.0,
		"lock": {"move":true, "drop":true, "unequip":true}
	},
	"capped": {
		"id": "capped", "mode": MODE_HOLDING, "tags": ["hp","cap"], "default_duration": -1.0,
		"modifiers": {"max_hp_cap": 60.0}
	},
	"heavy": {
		"id": "heavy", "mode": MODE_HOLDING, "tags": ["heavy"], "default_duration": -1.0,
		"modifiers": {"spd_mult": 0.8}
	},
	"fragile": {
		"id": "fragile", "mode": MODE_HOLDING, "tags": ["fragile"], "default_duration": -1.0,
		"modifiers": {"def_mult": 0.7}
	}
}

# ======================= STATE =======================

var base_stats := {"atk":10, "def":10, "max_hp":100, "spd":100}
var cur_stats  := {"atk":10, "def":10, "max_hp":100, "spd":100}
var ui_max_hp: int = -1  # â€žscalaâ€ UI, setatÄƒ o singurÄƒ datÄƒ

# active_curses: Array< { data:Dictionary, source, source_tag:String, time_left:float } >
var active_curses: Array = []
# active_buffs : Array< { data:Dictionary, source, source_tag:String, time_left:float } >  (doar modifiers provenite din efecte)
var active_buffs:  Array = []
# active_effects: Array< { id, amount, time_left, period, accum, source, source_tag, extra, tags } >
var active_effects:Array = []
# active_cleansers: Array< { rules:{curses:Dict,effects:Dict}, source, source_tag, time_left:float } >
var active_cleansers: Array = []

signal hp_changed(hp, max_hp, ui_max_hp)

# ======================= LIFECYCLE =======================

func _ready() -> void:
	await get_tree().process_frame
	_read_base_from_owner()
	await get_tree().process_frame
	_recompute_stats()

func _read_base_from_owner() -> void:
	if owner == null: return
	base_stats = {
		"atk":    int(owner.atk),
		"def":    int(owner.def),
		"max_hp": int(owner.max_hp),
		"spd":    int(owner.spd),
	}
	if ui_max_hp < 0:
		ui_max_hp = base_stats.max_hp
	owner.health = clamp(int(owner.health), 0, base_stats.max_hp)

func _write_stats_to_owner() -> void:
	if owner == null: return

	var old_hp  = float(owner.health)
	var old_max = float(owner.max_hp)

	owner.atk    = cur_stats.atk
	owner.def    = cur_stats.def
	owner.max_hp = cur_stats.max_hp
	owner.spd    = cur_stats.spd

	var new_hp: int
	if old_max > 0.0:
		var ratio = clamp(old_hp / old_max, 0.0, 1.0)
		new_hp = int(round(ratio * float(owner.max_hp)))
	else:
		new_hp = min(int(old_hp), owner.max_hp)
	owner.health = clamp(new_hp, 0, owner.max_hp)

	emit_signal("hp_changed", owner.health, owner.max_hp, ui_max_hp)

# ======================= PUBLIC API (inventar) =======================

func apply_from_slot(slot: Node) -> void:
	if slot == null: return
	var c = slot.get_curse()
	if c is Dictionary and not c.is_empty() and _get_mode(c) == MODE_HOLDING:
		add_curse(c, slot)

	var e = slot.get_effects()
	if e is Array:
		for one in e:
			if one is Dictionary and _get_mode(one) == MODE_HOLDING:
				add_effect(one, slot)
	elif e is Dictionary and _get_mode(e) == MODE_HOLDING:
		add_effect(e, slot)

func apply_on_use_from_slot(slot: Node) -> void:
	if slot == null: return
	var source_tag := "consumable:" + str(slot.get_instance_id())

	var c = slot.get_curse()
	if c is Dictionary and not c.is_empty() and _get_mode(c, MODE_CONSUMABLE) == MODE_CONSUMABLE:
		add_curse(c, source_tag)

	var e = slot.get_effects()
	if e is Array:
		for one in e:
			if one is Dictionary and _get_mode(one, MODE_CONSUMABLE) == MODE_CONSUMABLE:
				add_effect(one, source_tag)
	elif e is Dictionary and _get_mode(e, MODE_CONSUMABLE) == MODE_CONSUMABLE:
		add_effect(e, source_tag)

func remove_from_slot(slot: Node) -> void:
	if not can_unequip_slot(slot):
		if owner and owner.has_method("show_toast"):
			owner.show_toast("Itemul este blestemat: nu-l poÈ›i scoate!")
		return
	_remove_curses_by_source(slot)
	_remove_buffs_by_source(slot)
	_remove_effects_by_source(slot)
	_recompute_stats()

func refresh_holding(container: Node) -> void:
	_clear_all_slot_sources()
	if container == null: return
	for s in container.get_children():
		if s != null and s.has_method("get_item") and s.get_item() != null:
			apply_from_slot(s)

# ======================= ADDERS =======================

func add_curse_by_id(id: String, overrides: Dictionary = {}, source = null) -> void:
	var def = REG_CURSES.get(_canon(id), null)
	if def == null:
		return
	var data = def.duplicate(true)
	for k in overrides.keys():
		data[k] = overrides[k]
	add_curse(data, source)

func add_effect_by_id(id: String, overrides: Dictionary = {}, source = null) -> void:
	var def = REG_EFFECTS.get(_canon(id), null)
	if def == null:
		return
	var data = def.duplicate(true)
	for k in overrides.keys():
		data[k] = overrides[k]
	add_effect(data, source)

func add_curse(c: Dictionary, source = null) -> void:
	# respectÄƒ cleanser-ele active: dacÄƒ regulile lor acoperÄƒ acest curse, nu-l adÄƒugÄƒm
	for cl in active_cleansers:
		var rules = cl.get("rules", {})
		if _curse_matches_rules(c, rules.get("curses", {})):
			return

	var inst := {
		"data": c,
		"source": source,
		"source_tag": _source_tag(source),
		"time_left": float(c.get("duration", c.get("default_duration", -1.0)))
	}
	active_curses.append(inst)
	_recompute_stats()

func add_effect(e: Dictionary, source = null) -> void:
	var id := _canon(e.get("id",""))
	# CompleteazÄƒ cu default-uri din registru (dacÄƒ existÄƒ)
	var def = REG_EFFECTS.get(id, {})
	var mode := String(e.get("mode", def.get("mode", MODE_HOLDING))).to_lower()
	var amount := float(e.get("amount", def.get("default_amount", 0.0)))
	var duration := float(e.get("duration", def.get("default_duration", 0.0)))
	var period := float(e.get("period", def.get("default_period", 1.0)))
	var tags = e.get("tags", def.get("tags", []))
	var modifiers = e.get("modifiers", def.get("modifiers", null))
	var special = String(e.get("special", def.get("special","")))

	# 1) CLEANSE â€“ curÄƒÈ›are + (opÈ›ional) persistenÈ›Äƒ pentru blocare
	if id == "cleanse" or special == "cleanse":
		var remove_rules = e.get("remove", {})
		var rules_curses  = remove_rules.get("curses", remove_rules)
		var rules_effects = remove_rules.get("effects", remove_rules)

		var rem_c := _purge_curses(rules_curses)
		var rem_e := _purge_effects(rules_effects)
		if rem_c > 0 or rem_e > 0:
			_recompute_stats()
		if duration != 0.0:
			active_cleansers.append({
				"rules": {"curses": rules_curses, "effects": rules_effects},
				"source": source,
				"source_tag": _source_tag(source),
				"time_left": duration
			})
		return

	# 2) Cleanser-ele active pot BLOCA efecte noi
	for cl in active_cleansers:
		var rules = cl.get("rules", {})
		if _effect_matches_rules({"id": id, "tags": tags}, rules.get("effects", {})):
			return

	# 3) AdaugÄƒ efectul
	var inst := {
		"id": id,
		"amount": amount,
		"time_left": duration,
		"period": period,
		"accum": 0.0,
		"source": source,
		"source_tag": _source_tag(source),
		"extra": e.get("extra", null),
		"tags": tags
	}
	active_effects.append(inst)

	# Buff-uri (modifiers)
	if modifiers is Dictionary:
		active_buffs.append({
			"data": {"modifiers": modifiers},
			"source": source,
			"source_tag": _source_tag(source),
			"time_left": inst["time_left"]
		})
		_recompute_stats()

# ======================= DAMAGE PIPELINE =======================

func on_incoming_damage(dmg: int) -> int:
	var remaining := dmg
	var i := 0
	while i < active_effects.size():
		var ef: Dictionary = active_effects[i]
		if ef.get("id","") == "shield" and float(ef.get("amount",0)) > 0.0:
			var cap := int(round(ef["amount"]))
			var absorbed = min(cap, remaining)
			ef["amount"] = cap - absorbed
			remaining -= absorbed
			active_effects[i] = ef
			if int(round(ef["amount"])) <= 0 and float(ef.get("time_left",0.0)) <= 0.0:
				active_effects.remove_at(i)
				i -= 1
		i += 1
	return max(0, remaining)

# ======================= TICK =======================

func _process(delta: float) -> void:
	_update_effects(delta)
	_update_timed_curses(delta)
	_update_cleansers(delta)

func _update_timed_curses(delta: float) -> void:
	var i := 0
	while i < active_curses.size():
		var cur = active_curses[i]
		var tl := float(cur.get("time_left", -1.0))
		if tl >= 0.0:
			tl -= delta
			cur["time_left"] = tl
			active_curses[i] = cur
			if tl <= 0.0:
				active_curses.remove_at(i)
				_recompute_stats()
				continue
		i += 1

func _update_effects(delta: float) -> void:
	var i := 0
	while i < active_effects.size():
		var ef: Dictionary = active_effects[i]
		ef["time_left"] = float(ef.get("time_left",0.0)) - delta
		ef["accum"]     = float(ef.get("accum",0.0)) + delta

		match String(ef.get("id","")):
			"regen":
				while ef["accum"] >= ef.get("period",1.0):
					ef["accum"] -= ef.get("period",1.0)
					_heal(int(round(ef.get("amount",0.0))))
			"poison":
				while ef["accum"] >= ef.get("period",1.0):
					ef["accum"] -= ef.get("period",1.0)
					_heal(-int(round(ef.get("amount",0.0))))
			"burning":
				while ef["accum"] >= ef.get("period",1.0):
					ef["accum"] -= ef.get("period",1.0)
					_heal(-int(round(ef.get("amount",0.0))))
			"shield":
				# doar expirÄƒ Ã®n timp, absorbÈ›ia e la on_incoming_damage()
				pass
			_:
				pass

		var expired = ef["time_left"] <= 0.0
		if expired:
			_remove_buffs_by_source(ef.get("source",null), true)
			active_effects.remove_at(i)
			_recompute_stats()
		else:
			active_effects[i] = ef
			i += 1

func _update_cleansers(delta: float) -> void:
	var i := 0
	while i < active_cleansers.size():
		var cl = active_cleansers[i]
		var rules = cl.get("rules", {})
		_purge_curses(rules.get("curses", {}))
		_purge_effects(rules.get("effects", {}))

		var tl := float(cl.get("time_left", 0.0))
		if tl != -1.0:
			tl -= delta
			cl["time_left"] = tl
			active_cleansers[i] = cl
			if tl <= 0.0:
				active_cleansers.remove_at(i)
				continue
		i += 1

# ======================= RECOMPUTE STATS =======================

func _recompute_stats() -> void:
	cur_stats = base_stats.duplicate(true)
	var mults := {"atk":1.0, "def":1.0, "max_hp":1.0, "spd":1.0}
	var adds  := {"atk":0.0, "def":0.0, "max_hp":0.0, "spd":0.0}
	var caps  := {"atk":INF, "def":INF, "max_hp":INF, "spd":INF}

	for c in active_curses:
		_apply_mods_dict(c["data"], mults, adds, caps)
	for b in active_buffs:
		_apply_mods_dict(b["data"], mults, adds, caps)

	for s in mults.keys():
		cur_stats[s] = int(round((base_stats[s] + adds[s]) * mults[s]))

	for s in caps.keys():
		if caps[s] < INF:
			cur_stats[s] = min(cur_stats[s], int(round(caps[s])))
	_write_stats_to_owner()

func _apply_mods_dict(d: Dictionary, mults: Dictionary, adds: Dictionary, caps: Dictionary = {}) -> void:
	if not (d.has("modifiers") and d["modifiers"] is Dictionary): return
	for k in d["modifiers"].keys():
		var v := float(d["modifiers"][k])
		if String(k).ends_with("_mult"):
			var stat := String(k).trim_suffix("_mult")
			if mults.has(stat): mults[stat] *= v
		elif String(k).ends_with("_add"):
			var stat := String(k).trim_suffix("_add")
			if adds.has(stat): adds[stat] += v
		elif String(k).ends_with("_cap") and caps.has(String(k).trim_suffix("_cap")):
			var stat := String(k).trim_suffix("_cap")
			caps[stat] = min(caps[stat], v)

# ======================= CLEAN / PURGE / MATCH =======================

func _purge_curses(rules: Dictionary, limit: int = -1) -> int:
	var removed := 0
	var i := 0
	while i < active_curses.size():
		var cur = active_curses[i]
		if _curse_matches_rules(cur.get("data", {}), rules):
			active_curses.remove_at(i)
			removed += 1
			if limit > 0 and removed >= limit:
				break
			continue
		i += 1
	if removed > 0:
		_recompute_stats()
	return removed

func _purge_effects(rules: Dictionary, limit: int = -1) -> int:
	var removed := 0
	var i := 0
	while i < active_effects.size():
		var ef = active_effects[i]
		if _effect_matches_rules(ef, rules):
			_remove_buffs_by_source(ef.get("source", null), true)
			active_effects.remove_at(i)
			removed += 1
			if limit > 0 and removed >= limit:
				break
			continue
		i += 1
	if removed > 0:
		_recompute_stats()
	return removed

func _effect_matches_rules(ef_data: Dictionary, rules: Dictionary) -> bool:
	if rules.get("all", false):
		return true

	var ids_val = rules.get("ids", null)
	if ids_val != null:
		if ids_val is String: ids_val = [ids_val]
		if ids_val is Array and not ids_val.is_empty():
			var eid := _canon(ef_data.get("id",""))
			for rid in ids_val:
				if _canon(rid) == eid:
					return true

	var tags_val = rules.get("tags", null)
	if tags_val != null:
		if tags_val is String: tags_val = [tags_val]
		if tags_val is Array and not tags_val.is_empty():
			var etags = ef_data.get("tags", [])
			if etags is Array:
				for t in etags:
					for rt in tags_val:
						if _canon(t) == _canon(rt):
							return true
	return false

func _curse_matches_rules(curse_data: Dictionary, rules: Dictionary) -> bool:
	if rules.get("all", false):
		return true

	var has_lock := not _lock_from_data(curse_data).is_empty()  # virtual lock

	var ids_val = rules.get("ids", null)
	if ids_val != null:
		if ids_val is String: ids_val = [ids_val]
		if ids_val is Array and not ids_val.is_empty():
			var cid := _canon(curse_data.get("id",""))
			for rid in ids_val:
				var rr := _canon(rid)
				if rr == cid: return true
				if rr == "lock" and has_lock: return true

	var tags_val = rules.get("tags", null)
	if tags_val != null:
		if tags_val is String: tags_val = [tags_val]
		if tags_val is Array and not tags_val.is_empty():
			for rt in tags_val:
				if _canon(rt) == "lock" and has_lock:
					return true
			var ctags = curse_data.get("tags", [])
			if ctags is Array:
				for t in ctags:
					for rt in tags_val:
						if _canon(t) == _canon(rt):
							return true
	return false

# ======================= SOURCE/REMOVE HELPERS =======================

func _clear_all_slot_sources() -> void:
	var i := 0
	while i < active_curses.size():
		if typeof(active_curses[i].get("source", null)) == TYPE_OBJECT:
			active_curses.remove_at(i)
		else:
			i += 1
	i = 0
	while i < active_buffs.size():
		if typeof(active_buffs[i].get("source", null)) == TYPE_OBJECT:
			active_buffs.remove_at(i)
		else:
			i += 1
	i = 0
	while i < active_effects.size():
		if typeof(active_effects[i].get("source", null)) == TYPE_OBJECT:
			active_effects.remove_at(i)
		else:
			i += 1
	_recompute_stats()

func _remove_curses_by_source(source, _only_if_expired := false) -> void:
	var tag := _source_tag(source)
	var i := 0
	while i < active_curses.size():
		var cur = active_curses[i]
		var cur_tag = cur.get("source_tag", _source_tag(cur.get("source", null)))
		if cur_tag == tag:
			active_curses.remove_at(i)
		else:
			i += 1
	_recompute_stats()

func _remove_buffs_by_source(source, only_if_time_left_lte_zero := false) -> void:
	var tag := _source_tag(source)
	var i := 0
	while i < active_buffs.size():
		var b = active_buffs[i]
		var cur_tag = b.get("source_tag", _source_tag(b.get("source", null)))
		var rem = cur_tag == tag
		if only_if_time_left_lte_zero and rem:
			var still_running := false
			for ef in active_effects:
				var ef_tag = ef.get("source_tag", _source_tag(ef.get("source", null)))
				if ef_tag == tag and float(ef.get("time_left",0.0)) > 0.0:
					still_running = true
					break
			if still_running: rem = false
		if rem: active_buffs.remove_at(i)
		else:  i += 1

func _remove_effects_by_source(source) -> void:
	var tag := _source_tag(source)
	var i := 0
	while i < active_effects.size():
		var ef = active_effects[i]
		var cur_tag = ef.get("source_tag", _source_tag(ef.get("source", null)))
		if cur_tag == tag:
			active_effects.remove_at(i)
		else:
			i += 1

# ======================= LOCK / CLEANSE vs LOCK =======================

func _lock_from_data(d: Dictionary) -> Dictionary:
	if not d.has("lock"):
		var flags = d.get("flags", {})
		if flags is Dictionary and flags.get("lock_equip", false):
			return {"unequip": true, "drop": true, "move": true}
		return {}
	var L = d["lock"]
	if typeof(L) == TYPE_BOOL:
		return {"unequip": true, "drop": true, "move": true} if L else {}
	return L if (L is Dictionary) else {}

func _has_lock_for_action(source, action: String) -> bool:
	if _cleanse_disables_locks_now():
		return false
	var tag := _source_tag(source)
	for c in active_curses:
		var d = c.get("data", {})
		var lock := _lock_from_data(d)
		if lock.is_empty():
			continue
		var ctag = c.get("source_tag", _source_tag(c.get("source", null)))
		if ctag != tag:
			continue
		if lock.get("all", false) or lock.get(action, false):
			return true
	return false

func can_unequip_slot(slot: Node) -> bool: return not _has_lock_for_action(slot, "unequip")
func can_drop_slot(slot: Node)    -> bool: return not _has_lock_for_action(slot, "drop")
func can_move_slot(slot: Node)    -> bool: return not _has_lock_for_action(slot, "move")

func _curse_is_lock(d: Dictionary) -> bool:
	var id := String(d.get("id","")).to_lower()
	if id == "lock": return true
	if d.has("tags") and d["tags"] is Array:
		for t in d["tags"]:
			if String(t).to_lower() == "lock":
				return true
	return false

func is_slot_locked(slot: Node) -> bool:
	var tag := _source_tag(slot)
	for c in active_curses:
		var data = c.get("data", {})
		if _curse_is_lock(data):
			if c.get("source_tag", _source_tag(c.get("source", null))) == tag:
				return true
			var st = data.get("slot_types", [])
			if slot.has_method("slot_type") and st is Array and slot.slot_type in st:
				return true
	return false

func can_move_slot_lock(slot: Node) -> bool:
	return not is_slot_locked(slot)

func _cleanse_disables_locks_now() -> bool:
	for cl in active_cleansers:
		var rules = cl.get("rules", {})
		var cr = rules.get("curses", {})
		if cr.get("all", false): return true
		var ids_val = cr.get("ids", null)
		if ids_val is String: ids_val = [ids_val]
		if ids_val is Array:
			for rid in ids_val:
				if String(rid).to_lower() == "lock":
					return true
		var tags_val = cr.get("tags", null)
		if tags_val is String: tags_val = [tags_val]
		if tags_val is Array:
			for t in tags_val:
				if String(t).to_lower() == "lock":
					return true
	return false

# ======================= UTILS =======================

func _get_mode(d: Dictionary, default := MODE_HOLDING) -> String:
	var m := String(d.get("mode", default)).to_lower()
	if m == "comsumable": m = MODE_CONSUMABLE
	if m != MODE_HOLDING and m != MODE_CONSUMABLE: m = default
	return m

func _heal(q: int) -> void:
	if owner == null or q == 0: return
	owner.health = clamp(int(owner.health) + q, 0, cur_stats.max_hp)
	emit_signal("hp_changed", owner.health, owner.max_hp, ui_max_hp)

func _canon(x) -> String:
	return String(x).strip_edges().to_lower()

func _source_tag(s) -> String:
	match typeof(s):
		TYPE_OBJECT:
			return "obj:" + str(s.get_instance_id()) if is_instance_valid(s) else "obj:dead"
		TYPE_STRING:
			return s
		TYPE_NIL:
			return ""
		_:
			return String(s)
