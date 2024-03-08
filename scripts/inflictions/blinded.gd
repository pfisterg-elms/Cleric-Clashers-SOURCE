extends Infliction_Base
class_name Infliction_Blinded


func start_effects():
	BattleManager.output_to_battlelog("[color=orange]" + actor_link.actor_name + " looks a bit cross-eyed! They are now BLINDED![/color]")


func perform_effects():
	turns_left -= 1
	if turns_left <= 0:
		BattleManager.output_to_battlelog("[color=yellow]" + actor_link.actor_name + " recovers from their hazy vision. -BLINDED[/color]")
		remove_effect_from_link()

