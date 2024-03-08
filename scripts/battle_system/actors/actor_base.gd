extends Node
class_name Battle_Actor

var defeated : bool
@export var actor_name : String
# For use in connecting actor_pawn to this
@export var actor_identifier : String
@export var sprite_group : Actor_SpriteGroup

@export var max_health : int
@onready var current_health : int = max_health

@export var initiative_bonus : int
var init_result : int
@export var armor_class : int
@onready var current_ac : int = armor_class
# bonus to add to ability checks against infliction DC
@export var infliction_save : int
# Values must exactly match damage types found in attack_base
@export var resistances : Array[String]
# Same format as resistances
@export var weaknesses : Array[String]
@export var attacks : Array[Attack_Base]
# This is empty and only allocated by attacks when the Actor is hit.
var inflictions : Array[Infliction_Base]


func has_infliction(inflict_name : String) -> bool:
	for infliction in inflictions:
		if infliction.effect_name == inflict_name:
			return true
	
	return false


# get infliction by name and return it
func get_infliction(inflict_name : String) -> Infliction_Base:
	for infliction in inflictions:
		if infliction.effect_name == inflict_name:
			return infliction
	
	return null
