extends Infliction_Base
class_name Infliction_Staggered


func start_effects():
	BattleManager.output_to_battlelog("[color=orange]" + actor_link.actor_name + " has been sent off-balanced! They are now STAGGERED![/color]")


func perform_effects():
	turns_left -= 1
	if turns_left <= 0:
		BattleManager.output_to_battlelog("[color=yellow]" + actor_link.actor_name + " regains their balance and fighting posture. -STAGGERED[/color]")
		remove_effect_from_link()

