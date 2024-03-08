extends Button


func _on_pressed():
	disabled = true
	
	Global.save_game()
	
	get_node("SaveLabel").visible = true
	await(get_tree().create_timer(2).timeout)
	get_node("SaveLabel").visible = false
	disabled = false
