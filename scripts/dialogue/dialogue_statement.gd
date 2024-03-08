extends Resource
class_name Dialogue_Statement

@export var narrator_title : String
@export_multiline var dialogue_contents : String
@export var left_sprite : Texture2D
@export var right_sprite : Texture2D
# Unfocused sprite (if that one isnt null) will have greyed modulation 
# so that the sprite_focus target is more pronounced as the current speaker of dialogue
@export_enum("Left", "Right") var sprite_focus : String = "Left"
