extends Button


func _on_pressed():
	Global.do_fade(3, true)
	await(Global.faded_out)
	
	UI.get_node("MainMenu").visible = false
	UI.get_node("MapInterface").visible = true
	
	Global.do_fade(2, false)
	Global.play_new_music(Global.map_music, 1.5, true)
	await(Global.faded_in)
	
	Global.area_swap_allowed = true
