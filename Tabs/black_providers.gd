# res://ProviderDisplay.gd
extends Control

# --- Provider enum ---
enum ProviderType { OWNER_1, OWNER_2, OWNER_3, OWNER_4 }

# Pool de provideri eligibili (flags în Inspector).
# Bifezi ce provideri vrei să poată fi aleși aleator.
@export_flags("OWNER_1", "OWNER_2", "OWNER_3", "OWNER_4")
var provider_pool_flags: int = 0b1111

# UID-ul providerului ales (util pt. salvare/analytics/routing)
@export var provider_uid: StringName = &"unknown"

# Imagini setate direct în Inspector (fără foldere)
@export var owner_1_images: Array[Texture2D] = []
@export var owner_2_images: Array[Texture2D] = []
@export var owner_3_images: Array[Texture2D] = []
@export var owner_4_images: Array[Texture2D] = []

# Referințe UI (ajustează căile dacă ai altă ierarhie)
@onready var icon_node: TextureRect = $PanelContainer/TextureRect
@onready var name_label: RichTextLabel = $PanelContainer/Button/RichTextLabel

var _rng := RandomNumberGenerator.new()
var _provider: int = ProviderType.OWNER_1  # cel ales aleator la instanțiere

func _ready() -> void:
	# Seed unic per instanță
	_rng.seed = int(Time.get_ticks_usec()) ^ int(get_instance_id())
	# _pick_provider_and_texture()  <-- opțional, dacă nu e forțat de Market
	_update_ui()
	
	# CONECTARE BUTON
	var btn = $PanelContainer/Button
	if btn:
		if not btn.pressed.is_connected(_on_provider_pressed):
			btn.pressed.connect(_on_provider_pressed)

func _on_provider_pressed():
	var p_name = name_label.text
	# Curățăm textul dacă are BBCode
	p_name = p_name.strip_edges()
	print("Deschidem pagina pentru: ", p_name)
	
	# Căutăm Browser-ul (folosim grupul global)
	var browser = get_tree().get_first_node_in_group("browser")
	if browser and browser.has_method("open_provider_page"):
		browser.open_provider_page(p_name)

# ===== Public API =====
func reroll() -> void:
	_pick_provider_and_texture()
	_update_ui()

# ===== Logică internă =====
func _pick_provider_and_texture() -> void:
	var candidates := _eligible_providers_with_images()
	if candidates.is_empty(): return

	_provider = candidates[_rng.randi_range(0, candidates.size() - 1)]
	provider_uid = _provider_uid(_provider)

	var imgs := _get_provider_images(_provider)
	if not imgs.is_empty():
		icon_node.texture = imgs[_rng.randi_range(0, imgs.size() - 1)]

func _update_ui() -> void:
	if name_label:
		name_label.text = provider_to_string(_provider)

func _eligible_providers_with_images() -> Array[int]:
	var out: Array[int] = []
	for p in [ProviderType.OWNER_1, ProviderType.OWNER_2, ProviderType.OWNER_3, ProviderType.OWNER_4]:
		if _is_in_pool(p) and not _get_provider_images(p).is_empty():
			out.append(p)
	return out

func _is_in_pool(p: int) -> bool:
	match p:
		ProviderType.OWNER_1: return bool(provider_pool_flags & (1 << 0))
		ProviderType.OWNER_2: return bool(provider_pool_flags & (1 << 1))
		ProviderType.OWNER_3: return bool(provider_pool_flags & (1 << 2))
		ProviderType.OWNER_4: return bool(provider_pool_flags & (1 << 3))
		_: return false

func _get_provider_images(p: int) -> Array[Texture2D]:
	match p:
		ProviderType.OWNER_1: return owner_1_images
		ProviderType.OWNER_2: return owner_2_images
		ProviderType.OWNER_3: return owner_3_images
		ProviderType.OWNER_4: return owner_4_images
		_: return []

func _provider_uid(p: int) -> StringName:
	match p:
		ProviderType.OWNER_1: return &"owner_1"
		ProviderType.OWNER_2: return &"owner_2"
		ProviderType.OWNER_3: return &"owner_3"
		ProviderType.OWNER_4: return &"owner_4"
		_: return &"unknown"

func force_provider_visuals(target_uid: String) -> void:
	provider_uid = target_uid
	match target_uid:
		"owner_1": _provider = ProviderType.OWNER_1
		"owner_2": _provider = ProviderType.OWNER_2
		"owner_3": _provider = ProviderType.OWNER_3
		"owner_4": _provider = ProviderType.OWNER_4
		"black_market": 
			# Putem adăuga un tip special sau folosi un fallback
			name_label.text = "Negustorul Negru"
			return
		_: return

	var imgs := _get_provider_images(_provider)
	if not imgs.is_empty():
		icon_node.texture = imgs[_rng.randi_range(0, imgs.size() - 1)]
	_update_ui()
	
func provider_to_string(p: int) -> String:
	match p:
		ProviderType.OWNER_1: return "Duck's Empire"
		ProviderType.OWNER_2: return "Bit Buyer"
		ProviderType.OWNER_3: return "Factory of FOOD"
		ProviderType.OWNER_4: return "Lions Market"
		_: return "Unknown Merchant"

# doar ca să vezi UID-ul în Inspector (read-only feel)
func _get_provider_uid_editor() -> StringName:
	return provider_uid
