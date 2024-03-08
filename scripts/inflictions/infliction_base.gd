extends Node
class_name Infliction_Base

var actor_link : Battle_Actor

@export var effect_name : String
@export var turn_count : int
@onready var turns_left = turn_count


# Effect to trigger immediately when the Infliction is added to the Actor
func start_effects():
	pass


# Effects that are triggered on the Actor when it is the start of their turn
func perform_effects():
	pass


func remove_effect_from_link():
	BattleManager.output_to_battlelog("[color=orange]" + effect_name + " has worn off on " + actor_link.actor_name + "![/color]")
	actor_link.inflictions.erase(self)
	queue_free()
