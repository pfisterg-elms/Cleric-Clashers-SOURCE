extends Panel


# Health should include HP *AND* AC
func display_pawn_info(name_label, health_label, armor_class):
	get_node("PawnInfo").text = "[center]" + name_label + "\n" + health_label + "\n" + armor_class + "[/center]"


func _process(_delta):
	if Global.current_battle_pawn != null:
		visible = true
		display_pawn_info(Global.current_actor_target.actor_name, 
		str(Global.current_actor_target.current_health) + "/" + str(Global.current_actor_target.max_health) + " HP REMAINING",
		"ARMOR CLASS: " + str(Global.current_actor_target.current_ac))
	else:
		get_node("PawnInfo").text = ""
		visible = false
