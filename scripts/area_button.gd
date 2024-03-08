extends Button

# This is just for the "enter region" button on the world map screen.
# If there's dialogue, it'll play the dialogue first.
# Then it'll go to a Battle Sequence if one is set.
# It'll always trigger dialogue first, and then a Battle Sequence.
# Nothing too special.

func _on_pressed():
	UI.get_node("%RegionEnter").disabled = true
	
	if Global.current_area.area_dialogue and !Global.skip_dialogue:
		Global.do_fade(1, true)
		await(Global.faded_out)
		
		Global.dialogue.trigger_dialogue(Global.current_area.area_dialogue)
		
		Global.do_fade(1, false)
	elif Global.current_area.area_battle or Global.skip_dialogue:
		if !Global.current_area.area_battle:
			return
		
		Global.do_fade(1, true)
		await(Global.faded_out)
		
		BattleManager.start_battle(Global.current_area.area_battle)
		Global.do_fade(1.5, false)
