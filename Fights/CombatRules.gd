extends RefCounted
class_name CombatRules

# Așteaptă mișcări sub formă de dict: {"type":"attack"/"defense", "lane":"up"/"mid"/"down", "power":int}

static func lane_idx(lane: String) -> int:
	match lane.to_lower():
		"up":  return 0
		"mid": return 1
		"down":return 2
		_:     return -1

# Returnează {p_damage, e_damage, note}
static func resolve_by_lane(p_move: Dictionary, e_move: Dictionary, base_damage: int = 10) -> Dictionary:
	var p_is_atk := String(p_move.get("type","attack")).to_lower() == "attack"
	var e_is_atk := String(e_move.get("type","attack")).to_lower() == "attack"
	var p_lane := lane_idx(String(p_move.get("lane","mid")))
	var e_lane := lane_idx(String(e_move.get("lane","mid")))

	var res := {"p_damage":0, "e_damage":0, "note":""}

	if p_is_atk and e_is_atk:
		if p_lane == e_lane:
			res.note = "Atac vs atac pe același culoar: nimic."
		else:
			res.p_damage = base_damage
			res.e_damage = base_damage
			res.note = "Atacuri diferite: amândoi iau damage."
		return res

	if p_is_atk and not e_is_atk:
		if p_lane == e_lane:
			res.note = "Apărare corectă: bloc reușit."
		else:
			res.e_damage = base_damage
			res.note = "Apărare greșită: apărătorul ia damage."
		return res

	if not p_is_atk and e_is_atk:
		if p_lane == e_lane:
			res.note = "Apărare corectă: bloc reușit."
		else:
			res.p_damage = base_damage
			res.note = "Apărare greșită: apărătorul ia damage."
		return res

	res.note = "Apărare vs apărare: nimic."
	return res
