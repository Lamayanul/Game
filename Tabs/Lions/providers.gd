# res://ProviderDisplay.gd
extends Control

signal provider_clicked(p_name: String)

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
	# Seed unic per instanță (evită aceleași rezultate când se creează multe în același frame)
	_rng.seed = int(Time.get_ticks_usec()) ^ int(get_instance_id())
	_pick_provider_and_texture()  # alege provider + imagine
	_update_ui()
	
	# Conectăm butonul pentru a emite semnalul
	var btn = get_node_or_null("PanelContainer/Button")
	if btn:
		btn.pressed.connect(_on_button_pressed)
	
	print("prov: ",provider_uid )

func _on_button_pressed():
	# Trimitem numele providerului (textul de pe label)
	provider_clicked.emit(provider_to_string(_provider))

# ===== Public API =====
func reroll() -> void:
	# Poți apela asta oricând pentru a re-randomiza providerul și imaginea
	_pick_provider_and_texture()
	_update_ui()

# ===== Logică internă =====
func _pick_provider_and_texture() -> void:
	# 1) listează providerii eligibili (din flaguri) care AU imagini
	var candidates := _eligible_providers_with_images()
	if candidates.is_empty():
		push_warning("Niciun provider eligibil cu imagini. Verifică provider_pool_flags și listele de imagini.")
		return

	# 2) alege random provider
	_provider = candidates[_rng.randi_range(0, candidates.size() - 1)]
	provider_uid = _provider_uid(_provider)

	# 3) alege random o imagine din providerul ales
	var imgs := _get_provider_images(_provider)
	var tex: Texture2D = imgs[_rng.randi_range(0, imgs.size() - 1)]
	if tex and icon_node:
		icon_node.texture = tex
	else:
		push_warning("Textura selectată este invalidă pentru providerul ales.")

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

# ===== Mapping / denumiri =====
func _provider_uid(p: int) -> StringName:
	match p:
		ProviderType.OWNER_1: return &"owner_1"
		ProviderType.OWNER_2: return &"owner_2"
		ProviderType.OWNER_3: return &"owner_3"
		ProviderType.OWNER_4: return &"owner_4"
		_: return &"unknown"

# Adaugă asta în ProviderDisplay.gd

# ===== Funcție apelată de Market.gd pentru sincronizare =====
func force_provider_visuals(target_uid: String) -> void:
	# 1. Actualizăm variabila publică
	provider_uid = target_uid
	
	# 2. Convertim String-ul (din Market) în Enum-ul intern (int)
	match target_uid:
		"owner_1": _provider = ProviderType.OWNER_1
		"owner_2": _provider = ProviderType.OWNER_2
		"owner_3": _provider = ProviderType.OWNER_3
		"owner_4": _provider = ProviderType.OWNER_4
		_: 
			print("ProviderDisplay: UID necunoscut ", target_uid)
			return

	# 3. Alegem o imagine random DOAR din lista provider-ului ales
	var imgs := _get_provider_images(_provider)
	if not imgs.is_empty():
		icon_node.texture = imgs[_rng.randi_range(0, imgs.size() - 1)]
	
	# 4. Actualizăm textul
	_update_ui()
	
func provider_to_string(p: int) -> String:
	match p:
		ProviderType.OWNER_1: return "Duck's Empire"
		ProviderType.OWNER_2: return "Bit Buyer"
		ProviderType.OWNER_3: return "Factory of FOOD"
		ProviderType.OWNER_4: return "Lions Market"
		_: return "Unknown"

# doar ca să vezi UID-ul în Inspector (read-only feel)
func _get_provider_uid_editor() -> StringName:
	return provider_uid
