extends TextureButton
class_name Area_Site

# Map Sites are for all the selectable points on the world map that the player can travel to.
# Players can only travel to Map Sites directly linked to their current Site location.

@export var pawn_offset : Vector2
@export var starting_site : bool
@export var unlocked : bool = false
var completed : bool = false
@export var site_name : String
@export_multiline var description : String
@export var previous_site : Area_Site
@export var next_site : Area_Site

# Dialogue plays before a Battle begins.
@export var area_dialogue : Dialogue_Sequence
@export var area_battle : Battle_Sequence


func _ready():
	visible = true
	
	if unlocked:
		Global.unlocked_sites.append(name)
	
	if starting_site:
		# ensure the site is unlocked
		unlocked = true
		Global.current_area = self
		Global.cur_area_name = name
		Global.unlocked_sites.append(name)
		
		if previous_site:
			previous_site.visible = true
		
		if next_site:
			next_site.visible = true
		
		get_node("Sprite2D").visible = true
		Global.map_player.position = position + pawn_offset
		UI.get_node("%SiteTitle").text = "[center]" + site_name + "[/center]"
		UI.get_node("%SiteDescriptor").text = description
	elif !unlocked:
		visible = false
