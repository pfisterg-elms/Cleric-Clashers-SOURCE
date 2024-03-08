extends Infliction_Base
class_name Infliction_Shielded


func start_effects():
	actor_link.current_ac += 4
	BattleManager.output_to_battlelog("[color=orange]" + actor_link.actor_name + " feels temporarily tougher! +4 AC[/color]")


func perform_effects():
	turns_left -= 1
	if turns_left <= 0:
		actor_link.current_ac -= 4
		BattleManager.output_to_battlelog("[color=yellow]" + actor_link.actor_name + " feels their armor return to normal. -4 AC[/color]")
		remove_effect_from_link()
