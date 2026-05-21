# MarketSlot.gd
extends Control 

@onready var timer_label: Label = $TimerLabel

var lifetime_timer: Timer = null

func _ready():
	set_process(false) 
	timer_label.text = "..."
	
	# Căutăm nodul Provider prin ierarhia sa
	var provider_node = get_node_or_null("PanelContainer2/Provider")
	if provider_node and provider_node.has_signal("provider_clicked"):
		if not provider_node.provider_clicked.is_connected(_on_provider_clicked):
			provider_node.provider_clicked.connect(_on_provider_clicked)

func _on_provider_clicked(p_name: String):
	# Folosim sistemul de navigare al browserului
	var browser = get_tree().get_first_node_in_group("browser")
	if browser and browser.has_method("open_provider_page"):
		browser.open_provider_page(p_name)
	else:
		# Fallback: căutăm pagina de provider în grupul ei dacă browserul nu e găsit
		var p_page = get_tree().get_first_node_in_group("provider_page_group")
		if p_page and p_page.has_method("open_page"):
			p_page.open_page(p_name)
		else:
			print("MarketSlot: Nu s-a găsit browserul sau pagina de provider!")

func set_lifetime_timer(timer_node: Timer):
	self.lifetime_timer = timer_node
	set_process(true)

func _process(delta):
	if is_instance_valid(lifetime_timer):
		var time_left = lifetime_timer.time_left
		var minutes = int(time_left / 60)
		var seconds = int(time_left) % 60
		timer_label.text = "%s:%s" % [str(minutes).pad_zeros(2), str(seconds).pad_zeros(2)]
	else:
		set_process(false)
