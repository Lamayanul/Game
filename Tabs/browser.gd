extends Control

# Browser.gd - Gestionarea paginilor din browser
@onready var v_box_container = $VBoxContainer
@onready var provider_page = self
@onready var www = $VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer/www
@onready var title = $VBoxContainer/TitleBar/TextureRect/Title

func _ready():
	# Ne asigurăm că suntem în grupul browser pentru a fi găsiți de add_market.gd
	add_to_group("browser")
	print("Browser: Gata și adăugat în grup.")

func open_provider_page(p_name: String):
	print("Browser: Deschid pagina pentru ", p_name)
	
	# 1. Ascundem toate paginile din browser (Market, Search, Forex, etc.)
	if v_box_container:
		for child in v_box_container.get_children():
			if child is Control:
				child.hide()
				
	# 2. Arătăm și încărcăm pagina de provider
	if provider_page:
		provider_page.show()
		if provider_page.has_method("load_provider"):
			provider_page.load_provider(p_name)
		else:
			print("Browser: Eroare - ProviderPage nu are metoda load_provider")
	
	# 3. Actualizăm interfața browserului
	if is_instance_valid(www):
		www.text = "www.provider/" + p_name
	if is_instance_valid(title):
		title.text = "Provider: " + p_name
