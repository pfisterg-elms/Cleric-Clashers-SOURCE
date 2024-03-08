extends CheckBox


func _on_toggled(toggled_on):
	if toggled_on:
		Global.skip_dialogue = true
	else:
		Global.skip_dialogue = false
