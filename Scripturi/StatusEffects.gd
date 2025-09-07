extends Node
class_name StatusEffects

@onready var inv = get_node("/root/world/CanvasLayer/Inv")

var base_stats := {"atk":10, "def":10, "max_hp":100, "spd":100}
var cur_stats  := {"atk":10, "def":10, "max_hp":100, "spd":100}
var ui_max_hp: int = -1   # <— max-ul vizual (scara), setat o singură dată

var active_curses: Array = [] # {data:Dictionary, source}
var active_buffs:  Array = [] # {data:Dictionary, source, time_left}
var active_effects:Array = [] # {id, amount, time_left, period, accum, source, extra}
var active_cleansers: Array = [] # {rules:Dictionary, source, time_left:float}

const MODE_HOLDING    := "holding"
const MODE_CONSUMABLE := "consumable"

signal hp_changed(hp, max_hp, ui_max_hp)

func _get_mode(d: Dictionary, default := MODE_HOLDING) -> String:
	var m := String(d.get("mode", default)).to_lower()
	# acceptă și typo-ul "comsumable"
	if m == "comsumable": m = MODE_CONSUMABLE
	if m != MODE_HOLDING and m != MODE_CONSUMABLE:
		m = default
	return m
	
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

	# păstrează %HP când se schimbă max_hp
	var new_hp: int
	if old_max > 0.0:
		var ratio = clamp(old_hp / old_max, 0.0, 1.0)
		new_hp = int(round(ratio * float(owner.max_hp)))
	else:
		new_hp = min(int(old_hp), owner.max_hp)

	owner.health = clamp(new_hp, 0, owner.max_hp)

	# UI: emitem hp curent, cap efectiv și max-ul UI fix
	emit_signal("hp_changed", owner.health, owner.max_hp, ui_max_hp)
	print("HP %: ", old_hp, "/", old_max, " -> max=", owner.max_hp, " => ", owner.health, "/", owner.max_hp)


#func _write_stats_to_owner() -> void:
	#if owner == null: return
	#owner.atk = cur_stats.atk
	#owner.def = cur_stats.def
	#owner.max_hp = cur_stats.max_hp
	#owner.spd = cur_stats.spd
	#owner.health = clamp(int(owner.health), 0, owner.max_hp)
	#emit_signal("hp_changed", owner.health, owner.max_hp)
	
	
# ------------ API de folosit din inventar ------------

# Folosește direct slotul (source = slot) – aplică curse + efecte
func apply_from_slot(slot: Node) -> void:
	if slot == null: return

	# CURSE
	var c = slot.get_curse()
	if c is Dictionary and not c.is_empty() and _get_mode(c) == MODE_HOLDING:
		add_curse(c, slot)

	# EFFECTS
	var e = slot.get_effects()
	if e is Array:
		for one in e:
			if one is Dictionary and _get_mode(one) == MODE_HOLDING:
				add_effect(one, slot)
	elif e is Dictionary and _get_mode(e) == MODE_HOLDING:
		add_effect(e, slot)

# StatusEffects.gd
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

	# NU mai apela inv.eat() aici!




func remove_from_slot(slot: Node) -> void:
	_remove_curses_by_source(slot)
	_remove_buffs_by_source(slot)
	_remove_effects_by_source(slot)
	_recompute_stats()

# Pentru consumabile (numai efecte)
func apply_consumable_effects(effects: Array) -> void:
	for e in effects:
		if e is Dictionary:
			add_effect(e, "consumable")

# ------------ Adăugare/gestionare curse & efecte ------------

func add_curse(c: Dictionary, source = null) -> void:
	var inst := {
		"data": c,
		"source": source,                    # păstrezi sursa originală (obiect/string)
		"source_tag": _source_tag(source),   # și tag normalizat pentru comparații
		"time_left": float(c.get("duration", -1.0))
	}
	active_curses.append(inst)
	_recompute_stats()

func add_effect(e: Dictionary, source = null) -> void:
	var id := String(e.get("id","")).to_lower()

	# 1) Cleanse – curăță curses & effects
	if id == "cleanse":
		var remove_rules := e.get("remove", {}) as Dictionary
		var dur := float(e.get("duration", 0.0))

		var rules_curses  : Dictionary
		var rules_effects : Dictionary

		# Dacă lipsesc ambele chei "curses"/"effects", folosește același set pentru ambele (compat).
		if not remove_rules.has("curses") and not remove_rules.has("effects"):
			rules_curses  = remove_rules
			rules_effects = remove_rules
		else:
			rules_curses  = remove_rules.get("curses",  {})
			rules_effects = remove_rules.get("effects", {})

		# 1) curăță imediat ce e activ
		_purge_curses(rules_curses)
		_purge_effects(rules_effects)

		# 2) păstrează cleanser-ul dacă are durată ≠ 0
		if dur != 0.0:
			active_cleansers.append({
				"rules": {"curses": rules_curses, "effects": rules_effects},
				"source": source,
				"source_tag": _source_tag(source),
				"time_left": dur
			})
		return


	# 2) Dacă există un cleanser activ care blochează efectul, nu-l adăuga
# 2) Blochează efecte noi dacă există un cleanser holding activ
	for cl in active_cleansers:
		var rules = cl.get("rules", {})
		var ef_rules = rules.get("effects", {})   # <- IMPORTANT: să fie regulile de effects
		if _effect_matches_rules({"id": id, "tags": e.get("tags", [])}, ef_rules):
			return  # nu adăugăm poison-ul, e blocat de cleanser


	# 3) Adaugă efectul normal
	var inst := {
		"id": id,
		"amount": float(e.get("amount", 0)),
		"time_left": float(e.get("duration", 0.0)),
		"period": float(e.get("period", 1.0)),
		"accum": 0.0,
		"source": source,
		"source_tag": _source_tag(source),
		"extra": e.get("extra", null),
		"tags": e.get("tags", [])      # <— NOU
	}
	active_effects.append(inst)

	if e.has("modifiers") and e["modifiers"] is Dictionary:
		active_buffs.append({
			"data": {"modifiers": e["modifiers"]},
			"source": source,
			"source_tag": _source_tag(source),
			"time_left": inst["time_left"]
		})
		_recompute_stats()



# ------------ Damage pipeline (scut, etc.) ------------

func on_incoming_damage(dmg: int) -> int:
	var remaining := dmg
	var i := 0
	while i < active_effects.size():
		var ef: Dictionary = active_effects[i]
		if String(ef.get("id","")) == "shield" and float(ef.get("amount",0)) > 0.0:
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

# ------------ Tick/expirare efecte ------------

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
			"shield":
				# doar expiră în timp, absorbția e tratată la on_incoming_damage
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

# ------------ Recalcul statistici ------------

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

	# aplică cap-urile
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


# ------------ Utils/clean-up ------------

func _heal(q: int) -> void:
	if owner == null or q == 0: return
	owner.health = clamp(int(owner.health) + q, 0, cur_stats.max_hp)  # <— vindecare plafonată la capul efectiv
	emit_signal("hp_changed", owner.health, owner.max_hp, ui_max_hp)
	print("viata - %d" % owner.health)



# --- helper ---
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

func _update_cleansers(delta: float) -> void:
	var i := 0
	while i < active_cleansers.size():
		var cl = active_cleansers[i]
		var rules = cl.get("rules", {})
		_purge_curses(rules.get("curses", {}))
		_purge_effects(rules.get("effects", {}))   # <— NOU

		var tl := float(cl.get("time_left", 0.0))
		if tl != -1.0:
			tl -= delta
			cl["time_left"] = tl
			active_cleansers[i] = cl
			if tl <= 0.0:
				active_cleansers.remove_at(i)
				continue
		i += 1


func _effect_matches_rules(ef_data: Dictionary, rules: Dictionary) -> bool:
	if rules.get("all", false):
		return true

	# Acceptă 'ids' ca Array sau ca String
	var ids_val = rules.get("ids", null)
	if ids_val != null:
		if ids_val is String:
			ids_val = [ids_val]
		if ids_val is Array and not ids_val.is_empty():
			var eid := _canon(ef_data.get("id",""))
			for rid in ids_val:
				if _canon(rid) == eid:
					return true

	# Acceptă 'tags' ca Array sau ca String
	var tags_val = rules.get("tags", null)
	if tags_val != null:
		if tags_val is String:
			tags_val = [tags_val]
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

	var ids_val = rules.get("ids", null)
	if ids_val != null:
		if ids_val is String:
			ids_val = [ids_val]
		if ids_val is Array and not ids_val.is_empty():
			var cid := _canon(curse_data.get("id",""))
			for rid in ids_val:
				if _canon(rid) == cid:
					return true

	var tags_val = rules.get("tags", null)
	if tags_val != null:
		if tags_val is String:
			tags_val = [tags_val]
		if tags_val is Array and not tags_val.is_empty():
			var ctags = curse_data.get("tags", [])
			if ctags is Array:
				for t in ctags:
					for rt in tags_val:
						if _canon(t) == _canon(rt):
							return true

	return false



func _purge_effects(rules: Dictionary, limit: int = -1) -> int:
	var removed := 0
	var i := 0
	while i < active_effects.size():
		var ef = active_effects[i]
		if _effect_matches_rules(ef, rules):
			# scoate buff-urile aferente acestei surse dacă e cazul
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

# Scoate TOT ce a venit din surse de tip "slot" (obiecte) – curse, buffs, effects
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

# Aplică din nou toate curse-urile/efectele "holding" din inventar
# container = nodul care conține toate sloturile (ex: GridContainer)
func refresh_holding(container: Node) -> void:
	_clear_all_slot_sources()
	if container == null: return
	for s in container.get_children():
		# adaptează condiția la tipul tău de slot
		if s != null and s.has_method("get_item") and s.get_item() != null:
			# Aplică doar ce e HOLDING (funcția ta apply_from_slot deja filtrează după 'mode')
			apply_from_slot(s)

# Apelezi asta după ORICE schimbare de inventar (drop, pick-up, consum, mutare, echipare/desechipare).

func _canon(x) -> String:
	return String(x).strip_edges().to_lower()
	
