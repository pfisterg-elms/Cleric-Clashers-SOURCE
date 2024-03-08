extends Node
class_name Global_Manager

# Simple manager class that's added as a Singleton as soon as the game loads
# I do this for anything I do, especially since Godot makes it so easy to add a Singleton via AutoLoads.
# I just use this for all kinds of data that I need to refer to between other scripts on the fly.

@onready var rng : RandomNumberGenerator

var site_tween : Tween
var area_swap_allowed : bool = true

var fade_tween : Tween
signal faded_in
signal faded_out

var song_tween : Tween

var map_player

var map_music = preload("res://sounds/music/WorldMap.mp3")
var victory_big_music = preload("res://sounds/music/victory_big.mp3")
var victory_normal_music = preload("res://sounds/music/victory_normal.mp3")
var crit_sound = preload("res://sounds/critical_hit.mp3")

@onready var dialogue = UI.get_node_or_null("%DialogueBox")
var dialog_active : bool = false
var continue_dialog : bool = false

@onready var battle_scene = UI.get_node_or_null("%BattleScene")
var current_actor_target
var current_battle_pawn
var current_pawn_target

var skip_dialogue : bool = false

var current_area : Area_Site
var cur_area_name
# This is tracked and populated both by save-data being loaded, and by a battle when one is completed, adding the next site of the current site
# to the array when the player wins.
# Stored back in the save-data and overridden when the player saves.
# Simplest, quickest way I could figure out saving/loading; cur_area_name also is a part of the save system as a result, to track the current area
# and that works in a similar way.
var unlocked_sites = []


func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	map_player = get_tree().current_scene.get_node("Player")
	do_fade(2, false)


func change_area_site(new_site : Area_Site):
	area_swap_allowed = false
	
	current_area.get_node("Sprite2D").visible = false
	current_area = new_site
	cur_area_name = new_site.name
	
	current_area.get_node("Sprite2D").visible = true
	UI.get_node("%SiteTitle").text = "[center]" + current_area.site_name + "[/center]"
	UI.get_node("%SiteTitle").visible_ratio = 0
	UI.get_node("%SiteDescriptor").text = current_area.description
	UI.get_node("%SiteDescriptor").visible_ratio = 0

	site_tween = get_tree().create_tween()
	
	site_tween.tween_property(UI.get_node("%SiteTitle"), "visible_ratio", 1, 0.35).set_trans(Tween.TRANS_LINEAR)
	site_tween.parallel().tween_property(UI.get_node("%SiteDescriptor"), "visible_ratio", 1, 1.5).set_trans(Tween.TRANS_LINEAR)
	site_tween.parallel().tween_property(map_player, "position", current_area.position + current_area.pawn_offset, 0.5).set_trans(Tween.TRANS_LINEAR)
	
	await(site_tween.finished)
	area_swap_allowed = true


# Returns one of four string values to determine roll success.
# Crit fail/success if rng value without modifier is 1 or 20 respectively
# Regular success/fail if value WITH modifier meets or does not meet the difficulty class
# Check this in statement with smth like "if ability_check == 'success'" or whatever
func ability_check(modifier : int, difficulty : int, adv : bool, disadv : bool) -> String:
	rng.randomize()
	
	var roll_result = randi_range(1, 20)
	var final_roll
	
	if adv:
		var adv_result = randi_range(1, 20)
		if adv_result > roll_result:
			final_roll = adv_result
		else:
			final_roll = roll_result
	elif disadv:
		var disadv_result = randi_range(1, 20)
		if disadv_result < roll_result:
			final_roll = disadv_result
		else:
			final_roll = roll_result
	else:
		final_roll = roll_result
	
	# Check roll for 1 or 20 before adding modifier to determine nats
	if final_roll == 20:
		return "crit_success"
	elif final_roll == 1:
		return "crit_fail"
	
	var roll_modified = final_roll + modifier
	
	if roll_modified >= difficulty:
		return "success"
	elif roll_modified < difficulty:
		return "fail"
	
	# maybe an error msg? shouldnt be possible to get to this point lol
	return "indecisive"


# Returns an int as the result of a flat dice roll without requiring a DC
func dice_roll(modifier : int) -> int:
	rng.randomize()
	return randi_range(1, 20) + modifier


func do_fade(fade_length : float, fade_out : bool):
	fade_tween = get_tree().create_tween()
	var fade_rect = UI.get_node_or_null("GlobalFade")
	if fade_out:
		fade_tween.tween_property(fade_rect, "modulate:a", 1, fade_length)
	else:
		fade_tween.tween_property(fade_rect, "modulate:a", 0, fade_length)
	
	await fade_tween.finished
	
	if fade_out:
		faded_out.emit()
	else:
		faded_in.emit()


func do_lose_fade(fade_length : float, fade_out : bool):
	fade_tween = get_tree().create_tween()
	var fade_rect = UI.get_node_or_null("LoseFade")
	if fade_out:
		fade_tween.tween_property(fade_rect, "modulate:a", 1, fade_length)
	else:
		fade_tween.tween_property(fade_rect, "modulate:a", 0, fade_length)
	
	await fade_tween.finished
	
	if faded_out:
		faded_out.emit()
	else:
		faded_in.emit()


# This is the only part of code that spits out errors anymore, and only because I kill the Tween
# before starting a new one to transition into the next song.
# But if I don't kill/stop the tween- which is what causes the error, it gets confused about a Tween that isn't configured at all-
# it doesn't do the fade in/out effect as well as I liked it. Whatever, it doesn't affect the game so it's fine.
# it just irks me to no end. So close to an error-free output log... this is the true tragedy of programming
func play_new_music(new_song : AudioStream, length : float, reset_playback : bool):
	if song_tween and song_tween.is_running():
		song_tween.stop()
		song_tween.kill()
	
	song_tween = get_tree().create_tween()
	
	var cur_player = UI.get_node("%Music")
	var cur_playback = cur_player.get_playback_position()
	var prev_player = UI.get_node("%PreviousMusic")
	
	prev_player.stream = cur_player.stream
	prev_player.volume_db = 0
	prev_player.play()
	prev_player.seek(cur_playback)
	
	cur_player.stream = new_song
	cur_player.volume_db = -80
	cur_player.play()
	if !reset_playback:
		cur_player.seek(cur_playback)
	
	var final_length
	if !reset_playback:
		final_length = length * 4
	else:
		final_length = length
	
	song_tween.tween_property(cur_player, "volume_db", -4, length).set_ease(Tween.EASE_OUT)
	song_tween.parallel().tween_property(prev_player, "volume_db", -80, final_length * 4).set_ease(Tween.EASE_OUT)


func save_game():
	SaveSystem.set_var("unlocked_sites", unlocked_sites)
	SaveSystem.set_var("current_site", cur_area_name)
	SaveSystem.save()


func load_game():
	if SaveSystem.has("unlocked_sites"):
		unlocked_sites = SaveSystem.get_var("unlocked_sites")
		
		for site in unlocked_sites:
			var site_to_unlock = get_tree().current_scene.get_node(NodePath(site))
			site_to_unlock.unlocked = true
			site_to_unlock.visible = true
	
	var cur_area = SaveSystem.get_var("current_site")
	print(cur_area)
	current_area = get_tree().current_scene.get_node(NodePath(cur_area))
	
	current_area.starting_site = true
	current_area.get_node("Sprite2D").visible = true
	Global.map_player.position = current_area.position + current_area.pawn_offset
	UI.get_node("%SiteTitle").text = "[center]" + current_area.site_name + "[/center]"
	UI.get_node("%SiteDescriptor").text = current_area.description
	
	print(str(cur_area) + " set as current site successfully")


func clear_save():
	SaveSystem.delete_all()
	SaveSystem.save()

