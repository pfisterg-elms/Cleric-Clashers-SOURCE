extends Infliction_Base
class_name Infliction_Mending


func start_effects():
	BattleManager.output_to_battlelog("[color=green]" + actor_link.actor_name + " feels magically rejuvenated! +5HP[/color]")
	
	actor_link.current_health += 5
	if actor_link.current_health > actor_link.max_health:
		actor_link.current_health = actor_link.max_health


func perform_effects():
	BattleManager.output_to_battlelog("[color=green]" + actor_link.actor_name + " feels magically rejuvenated! +5HP[/color]")
	
	actor_link.current_health += 5
	if actor_link.current_health > actor_link.max_health:
		actor_link.current_health = actor_link.max_health
	
	turns_left -= 1
	if turns_left <= 0:
		BattleManager.output_to_battlelog("[color=yellow]" + actor_link.actor_name + " senses the healing magic has faded...[/color]")
		remove_effect_from_link()
