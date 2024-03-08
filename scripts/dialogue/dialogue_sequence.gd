extends Resource
class_name Dialogue_Sequence

@export var dialogue_statements : Array[Dialogue_Statement]
# Same as how Battle_Sequence does it
# Checks UI for background root node name
@export var scene_background : String
@export var scene_music : AudioStream
@export var smooth_fade : bool
