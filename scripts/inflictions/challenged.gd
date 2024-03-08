extends Infliction_Base
class_name Infliction_Challenged

# who taunted the actor that has this infliction?
var challenger


func start_effects():
	challenger = BattleManager.current_actor
	BattleManager.output_to_battlelog("[color=orange]" + actor_link.actor_name + " has been CHALLENGED by " + challenger.actor_name + "![/color]")


func perform_effects():
	turns_left -= 1
	if turns_left <= 0:
		BattleManager.output_to_battlelog("[color=yellow]" + actor_link.actor_name + " no longer respects " + challenger.actor_name + "'s duel.[/color]")
		remove_effect_from_link()
