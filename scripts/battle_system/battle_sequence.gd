extends Node
class_name Battle_Sequence

# The battle sequence to be loaded by the BattleManager. Sequences are specified inside an Area Site.

@export var log_message : String
@export var boss_title : String
@export var player_actors : Array[Battle_Actor]
var players_backup = []
@export var enemy_actors : Array[Battle_Actor]
var enemies_backup = []
@export var battle_music : AudioStream
@export var smooth_fade : bool
# Enables background at start, disables at end obviously
# Searches in UI for background root node's name
@export var background_name : String

@export var next_battle : Battle_Sequence
# Plays victory_big or victory_normal if true/false respectively
@export var big_victory : bool
@export var victory_message : String
