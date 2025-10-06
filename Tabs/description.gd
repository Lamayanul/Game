extends RichTextLabel

#func _ready() -> void:
	## Lărgește bara (pixeli)
	#add_theme_constant_override("scrollbar_width", 18)
#
	#var sb := get_v_scroll_bar() # VScrollBar intern
	#if sb == null:
		#return
	#var track := StyleBoxFlat.new()
	#track.corner_radius_top_left = 6
	#track.corner_radius_top_right = 6
	#track.corner_radius_bottom_left = 6
	#track.corner_radius_bottom_right = 6
	#sb.add_theme_stylebox_override("scroll", track)
