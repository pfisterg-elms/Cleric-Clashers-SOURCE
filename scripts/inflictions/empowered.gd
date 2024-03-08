extends Infliction_Base
class_name Infliction_Empowered


func start_effects():
	BattleManager.output_to_battlelog("[color=green]" + actor_link.actor_name + " is EMPOWERED! +4 to their next attack roll.[/color]")


func perform_effects():
	turns_left -= 1
	if turns_left <= 0:
		BattleManager.output_to_battlelog("[color=yellow]" + actor_link.actor_name + " no longer feels as strong. Attack roll bonus lost.[/color]")
		remove_effect_from_link()
