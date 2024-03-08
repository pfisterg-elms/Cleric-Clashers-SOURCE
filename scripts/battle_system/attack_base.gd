extends Resource
class_name Attack_Base

# All attacks derive from this class. They are Resources unlike Inflictions, and specified
# in an individual Battle Actor's scene definition.

# attack_name/descriptor are seen in the battle menu when the player has control of a character with that attack on them.
@export var attack_name : String
@export_multiline var attack_descriptor : String
@export_enum("Damage", "Bolster", "SelfBolster") var attack_type : String
# Adds to the d20 attack roll when a character tries to hit their target. Can be positive or negative.
@export var hit_modifier : int
# Always inflicts this damage on a hit.
@export var base_damage : int
# Damage type determines if it's doubled or halved according to weakness or resistance accordingly
@export_enum("Bludgeoning", "Slashing", "Piercing", "Poison", "Fire", "Psychic") var damage_type : String
@export var swing_sound : AudioStream
@export var hit_sound : AudioStream
# instantiates the infliction on the target actor itself
# for an easier way of tracking them and executing their effects on the afflicted character
@export var infliction : PackedScene
# The DC that a character needs to roll higher than or equal to in order to shake off an infliction spawned from the attack.
@export var inflict_challenge : int
