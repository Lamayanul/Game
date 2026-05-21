extends Control

# --- CONFIGURARE GRAFIC ---
var candles: Array[Dictionary] = []
var current_price: float = 1.1000 # Prețul sincronizat din Database
var tick_timer: float = 0.0
var candle_timeframe: float = 5.0
@onready var btn_buy: Button = $Buy
@onready var lbl_pnl: Label = $Pnl
@onready var btn_close: Button = $"Close potion"
@onready var btn_sell: Button = $Sell
@onready var panel_container: Panel = $InfoPanel

var SlotTrayScene = preload("res://User/slot_container.tscn")
var apple_tex = preload("res://Trade/apple.png")

var candle_width: float = 12.0
var candle_spacing: float = 4.0
var max_history: int = 500

var color_bull = Color("26a69a")
var color_bear = Color("ef5350")

# --- DATE TRANZACȚIONARE ---
var trade_type: int = 0 # 1 = BUY (Long), -1 = SELL (Short), 0 = Nimic
var entry_price: float = 0.0
var current_pnl: float = 0.0
var pip_multiplier: float = 10000.0 # Pentru EUR/USD, 1 pip = 0.0001

# --- ELEMENTE UI (Generate din cod) ---
var ui_container: HBoxContainer


# --- DATE PENTRU PANNING (Mișcare stânga-dreapta) ---
var pan_x: float = 0.0
var is_dragging: bool = false

@onready var apple_bar: TextureProgressBar = $AppleProgressBar # Asigură-te că numele nodului e corect
var pips_per_apple: float = 50.0 # Cât profit (Pips) trebuie să faci pentru 1 măr
var apples_harvested_this_trade: int = 0 # Câte mere am scos din tranzacția curentă



var axis_style := StyleBoxFlat.new()

# ADAUGĂ ASTA: Va ține minte cât la sută din măr ai umplut din tranzacțiile trecute
var saved_apple_progress: float = 0.0


func _ready():
	current_price = ItemData.current_forex_price
	_setup_trading_ui()
	_start_new_candle()
	axis_style.bg_color = Color(0.1, 0.1, 0.1, 0.85) # Culoarea fundalului
	axis_style.corner_radius_bottom_right = 20

func _gui_input(event):
	# 1. Detectăm click stânga pentru drag
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			
		# BONUS: Click Dreapta ca să resetezi camera (să te întorci la prețul live)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			pan_x = 0.0
			queue_redraw()
			
	# 2. Mișcăm graficul liber
	elif event is InputEventMouseMotion:
		if is_dragging:
			pan_x += event.relative.x # Mișcare 100% liberă
			queue_redraw()
			
func _process(delta):

	# 1. SINCRONIZARE CU ECONOMIA GLOBALĂ
	current_price = ItemData.current_forex_price
	
	# 2. ACTUALIZARE CANDELĂ
	var current_candle = candles[-1]
	current_candle.close = current_price
	if current_price > current_candle.high: current_candle.high = current_price
	if current_price < current_candle.low: current_candle.low = current_price
		
	# 3. TIMEFRAME
	tick_timer += delta
	if tick_timer >= candle_timeframe:
		tick_timer = 0.0
		_start_new_candle()
		
	if candles.size() > max_history:
		candles.pop_front()
		
	# 4. CALCUL PROFIT/PIERDERE
	# 4. CALCUL PROFIT/PIERDERE ȘI UMPLERE MĂR
	if trade_type != 0:
		current_pnl = (current_price - entry_price) * trade_type * pip_multiplier
		
		# Calculăm progresul TOTAL (ce aveam salvat + ce am făcut acum pe plus)
		var total_progress = saved_apple_progress
		if current_pnl > 0:
			total_progress += current_pnl
		
		# Verificăm dacă facem mere noi din totalul ăsta
		var target_apples = int(total_progress / pips_per_apple)
		
		if target_apples > apples_harvested_this_trade:
			var new_apples = target_apples - apples_harvested_this_trade
			apples_harvested_this_trade = target_apples
			_receive_apple_item(new_apples) 
		
		# Actualizăm bara vizuală folosind TOTALUL
		apple_bar.max_value = pips_per_apple
		apple_bar.value = fmod(total_progress, pips_per_apple)

		# Texte PnL
		lbl_pnl.text = " Profit: %.1f Pips" % current_pnl
		if current_pnl >= 0:
			lbl_pnl.add_theme_color_override("font_color", Color.GREEN)
		else:
			lbl_pnl.add_theme_color_override("font_color", Color.RED)
	else:
		# Când nu avem tranzacție, bara arată doar progresul salvat (nu se mai face 0)
		apple_bar.max_value = pips_per_apple
		apple_bar.value = saved_apple_progress
		
		lbl_pnl.text = " Fără poziție deschisă"
		lbl_pnl.add_theme_color_override("font_color", Color.WHITE)
		
	queue_redraw() 

func _receive_apple_item(amount: int):
	print("--- LOGICA RECOLTARE: Generare ", amount, " mere ---")
	panel_container.visible = true
	
	for i in range(amount):
		var tray_slot = SlotTrayScene.instantiate()
		panel_container.add_child(tray_slot)
		
		var item_data = {
			"TEXTURE": apple_tex,
			"CANTITATE": 1,
			"NUMBER": 7,
			"NUME": "Mar",
			"RARITATE": "common",
			"EFFECTS": [],
			"CURSE": null,
			"TYPE": ["food"],
			"DURABILITY": 99999.0 # Previne dispariția instantanee
		}
		
		tray_slot.slot_type = "tray"
		tray_slot.z_index = 10
		
		# Așteptăm să fie gata pentru a accesa sub-nodurile
		if not tray_slot.is_node_ready():
			await tray_slot.ready
		
		# Setăm proprietățile standard
		tray_slot.set_property(item_data)
		
		# FORȚĂM vizibilitatea mărului pe toate TextureRect-urile posibile din slot
		var tex_rect = tray_slot.get_node_or_null("TextureHolder/TextureRect")
		if tex_rect:
			tex_rect.texture = apple_tex
			tex_rect.visible = true
			
		var tex_rect2 = tray_slot.get_node_or_null("TextureHolder/TextureRect2")
		if tex_rect2:
			tex_rect2.texture = apple_tex
			tex_rect2.visible = true
			
		# Poziționare la centru
		var center = panel_container.size / 2.0
		if center.x <= 0: center = Vector2(250, 75)
		
		tray_slot.position = center - Vector2(32, 32)
		print("Măr afișat în slot la poziția: ", tray_slot.position)

func _start_new_candle():
	candles.append({
		"open": current_price,
		"high": current_price,
		"low": current_price,
		"close": current_price
	})

# --- FUNCȚII BUTOANE TRANZACȚIONARE ---
func _on_buy_pressed():
	trade_type = 1
	entry_price = current_price
	print("Deschis BUY la ", entry_price)

func _on_sell_pressed():
	trade_type = -1
	entry_price = current_price
	print("Deschis SELL la ", entry_price)

func _on_close_pressed():
	if trade_type != 0:
		print("Poziție închisă. Profit final: %.1f Pips" % current_pnl)
		
		# SALVĂM PROGRESUL CÂND ÎNCHIDEM TRANZACȚIA
		if current_pnl > 0:
			saved_apple_progress += current_pnl
			
			# Curățăm progresul dacă a depășit 50 (pentru că merele întregi au fost deja trimise în inventar)
			# fmod ne păstrează doar restul. Ex: dacă aveam 60, păstrează doar 10.
			saved_apple_progress = fmod(saved_apple_progress, pips_per_apple)
			
		# Resetăm setările pentru următoarea tranzacție
		trade_type = 0
		apples_harvested_this_trade = 0
		
func _draw():
	if candles.is_empty(): return
	
	# 1. CALCULĂM SCALA (Y) DOAR PENTRU CANDELELE VIZIBILE
	var min_p = INF
	var max_p = -INF
	
	# Simulează pe unde ar pica X-ul pentru a vedea ce e pe ecran
	var temp_x = size.x - candle_width - 20 + pan_x
	
	for i in range(candles.size() - 1, -1, -1):
		# Dacă candela e în limitele ecranului
		if temp_x + candle_width > 0 and temp_x < size.x:
			var c = candles[i]
			if c.low < min_p: min_p = c.low
			if c.high > max_p: max_p = c.high
		temp_x -= (candle_width + candle_spacing)

	# Dacă am mers prea mult în spate și nu mai sunt candele, nu da eroare
	if min_p == INF or max_p == -INF:
		min_p = candles[-1].low
		max_p = candles[-1].high

	if max_p == min_p:
		max_p += 0.001
		min_p -= 0.001
		
	var padding_y = 60.0
	var draw_height = size.y - (padding_y * 2)
	
	var map_y = func(price):
		var normalized = (price - min_p) / (max_p - min_p)
		return size.y - padding_y - (normalized * draw_height)
	
	# 2. DESENARE CANDELE (Cu Panning)
	var right_margin = 65.0 # Spațiul rezervat în dreapta pentru text
	# 2. DESENARE CANDELE (Cu Panning)
	var x_pos = size.x - right_margin - candle_width - 10 + pan_x
	
	for i in range(candles.size() - 1, -1, -1):
		# Optimizare: Dacă a ieșit prin dreapta ecranului, o sărim la desenare dar mergem mai departe
		if x_pos > size.x: 
			x_pos -= (candle_width + candle_spacing)
			continue
			
		# Optimizare: Dacă a ieșit prin stânga ecranului, ne oprim din procesat istoria (nu se mai vede)
		if x_pos + candle_width < 0: 
			break
		
		var c = candles[i]
		var y_open = map_y.call(c.open)
		var y_close = map_y.call(c.close)
		var y_high = map_y.call(c.high)
		var y_low = map_y.call(c.low)
		
		var is_bullish = c.close >= c.open
		var color = color_bull if is_bullish else color_bear
		
		var wick_x = x_pos + candle_width / 2.0
		draw_line(Vector2(wick_x, y_high), Vector2(wick_x, y_low), color, 2.0)
		
		var body_top = min(y_open, y_close)
		var body_height = max(abs(y_open - y_close), 1.0)
		draw_rect(Rect2(x_pos, body_top, candle_width, body_height), color)
		
		x_pos -= (candle_width + candle_spacing)

	# 3. LINIA DE PREȚ CURENT
	var current_y = map_y.call(current_price)
	draw_line(Vector2(0, current_y), Vector2(size.x, current_y), Color(1, 1, 1, 0.3), 1.0, true)

	# 4. LINIA DE INTRARE ÎN TRANZACȚIE
	if trade_type != 0:
		var entry_y = map_y.call(entry_price)
		var trade_color = Color.GREEN if current_pnl >= 0 else Color.RED
		
		draw_line(Vector2(0, entry_y), Vector2(size.x, entry_y), trade_color, 2.0)
		
		var type_text = "BUY" if trade_type == 1 else "SELL"
		draw_rect(Rect2(size.x - 120, entry_y - 20, 120, 20), trade_color)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 115, entry_y - 5), "%s @ %.4f" % [type_text, entry_price], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
# --- CREARE INTERFAȚĂ DIN COD ---
# --- CREARE INTERFAȚĂ DIN COD ---
	# 5. DESENARE EVENIMENTE (Axa Timpului)
	var event_y = size.y - 25.0
	for event in ItemData.forex_history:
		# Aflăm cât timp a trecut de la eveniment până acum (în secunde)
		var time_diff = (Time.get_ticks_msec() - event["timestamp"]) / 1000.0
		
		# Calculăm poziția X bazată pe cât de mult s-a mișcat graficul (candelele)
		# 1 candelă = candle_timeframe secunde
		# Deci distanța în pixeli este (timp / timeframe) * (lățime + spațiu)
		var offset_x = (time_diff / candle_timeframe) * (candle_width + candle_spacing)
		var ev_x = size.x - right_margin - 10 - offset_x + pan_x
		
		if ev_x > 0 and ev_x < size.x - right_margin:
			# Desenăm cercul
			draw_circle(Vector2(ev_x, event_y), 12.0, Color(0.2, 0.2, 0.2, 0.8))
			draw_circle(Vector2(ev_x, event_y), 10.0, Color.GOLDENROD)
			# Desenăm pictograma (Emoji)
			draw_string(ThemeDB.fallback_font, Vector2(ev_x - 7, event_y + 6), event["type"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)

	# ==========================================
	# 6. AXA DE PREȚ (În partea dreaptă)
	# ==========================================
	
	# A. Desenăm un fundal semi-transparent doar pentru axa din dreapta ca să putem citi textul ușor
	draw_style_box(axis_style, Rect2(size.x - right_margin, 0, right_margin, size.y))
	
	# B. Împărțim ecranul în 5 segmente orizontale
	var num_labels = 5
	for i in range(num_labels + 1):
		# Calculăm valoarea prețului pentru acest segment
		var val = min_p + (max_p - min_p) * (i / float(num_labels))
		
		# Aflăm la ce înălțime (Y) pică acest preț pe ecran
		var y = map_y.call(val)
		
		# Opțional: Desenăm o linie de grid orizontală subțire care traversează tot graficul
		draw_line(Vector2(0, y), Vector2(size.x - right_margin, y), Color(1, 1, 1, 0.05), 1.0)
		
		# Desenăm textul alb cu prețul formatat la 4 zecimale (ex: 1.1050)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - right_margin + 5, y + 4), "%.4f" % val, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
func _setup_trading_ui():
	ui_container = HBoxContainer.new()
	ui_container.position = Vector2(20, 20)
	
	# SETĂM Z_INDEX AICI PENTRU TOT GRUPUL DE BUTOANE
	ui_container.z_index = -1 # Poți schimba în -1 dacă vrei să fie și mai în spate
	
	add_child(ui_container)
	

	btn_buy.text = " BUY "
	btn_buy.add_theme_color_override("font_color", Color.GREEN)
	btn_buy.pressed.connect(_on_buy_pressed)

	

	btn_sell.text = " SELL "
	btn_sell.add_theme_color_override("font_color", Color.RED)
	btn_sell.pressed.connect(_on_sell_pressed)

	

	btn_close.text = " CLOSE POSITION "
	btn_close.pressed.connect(_on_close_pressed)

	

	lbl_pnl.text = " PnL: 0.0"


func _on_button_subtab() -> void:
	panel_container.visible = !panel_container.visible
