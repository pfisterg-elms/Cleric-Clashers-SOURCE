extends Node2D
class_name DialogueBox

# I took this from an old project I did last year. But I added the Statement feature specfically for CC.
# It's more or less self-explanatory.
# Adds dialogue from a Dialogue_Statement, which contains the narrator's portrait and their name, and what side
# of the screen the portrait is displayed.
# Then it displays that statement's text through a Tween to show a typewriter-like effect. It's always the same length of time
# which makes shorter statements type out very slowly and awkwardly. Should've added an override for the speed value tbh. hindsight 20/20 and whatnot.
# After that it goes to the next statement, rinse and repeat until the dialogue is over. if there's a battle in the current site,
# the battle begins. otherwise it goes to 
#
# I tried to let the player click through dialogue individually to skip between entries but I got a little lazy
# and just went for a big button on the world map that lets you skip entire dialogue sequences entirely. 

@onready var text = %DialogueText
@onready var title = %DialogueTitle
@onready var left_sprite = %LeftSprite
@onready var right_sprite = %RightSprite

var active_dialogue = [Dialogue_Statement]
var dialogue_index : int = -1

var dialog_tween : Tween
var dialogue_bg

var skip_dialog : bool = false

func _input(event):
	if event.is_action_released("interact") and Global.continue_dialog and Global.dialog_active:
		progress_dialogue()

func trigger_dialogue(dialogue_seq : Dialogue_Sequence):
	if dialogue_seq.scene_music:
		if dialogue_seq.smooth_fade:
			Global.play_new_music(dialogue_seq.scene_music, 3, false)
		else:
			Global.play_new_music(dialogue_seq.scene_music, 3, true)
	
	active_dialogue = dialogue_seq.dialogue_statements
	dialogue_index = -1
	progress_dialogue()
	
	visible = true
	Global.dialog_active = true
	UI.get_node("%MapInterface").visible = false
	UI.get_node("%RegionEnter").disabled = true
	dialogue_bg = UI.get_node("Dialog/" + dialogue_seq.scene_background)
	dialogue_bg.visible = true


func progress_dialogue():
	get_node("ContinueText").visible = false
	dialogue_index += 1
	
	if dialogue_index >= len(active_dialogue):
		dialogue_index = -1
		Global.dialog_active = false
		visible = false
		
		if !Global.current_area.area_battle:
			Global.do_fade(1, true)
			await(Global.faded_out)
			
			dialogue_bg.visible = false
			UI.get_node("%MapInterface").visible = true
			Global.play_new_music(Global.map_music, 3, true)
			
			Global.do_fade(1, false)
			await(Global.faded_in)
			UI.get_node("%RegionEnter").disabled = false
			return
		else:
			Global.do_fade(1, true)
			await(Global.faded_out)
			
			UI.get_node("BattleInterface").visible = true
			dialogue_bg.visible = false
			BattleManager.start_battle(Global.current_area.area_battle)
			
			Global.do_fade(0.5, false)
	
	var statement : Dialogue_Statement = active_dialogue[dialogue_index]
	
	if statement.narrator_title:
		title.text = statement.narrator_title
	else:
		title.text = ""
	
	text.text = statement.dialogue_contents
	text.visible_ratio = 0
	
	if statement.left_sprite:
		left_sprite.texture = statement.left_sprite
	else:
		left_sprite.texture = null
	
	if statement.right_sprite:
		right_sprite.texture = statement.right_sprite
	else:
		right_sprite.texture = null
	
	if statement.sprite_focus == "Left":
		right_sprite.modulate.r = 0.5
		right_sprite.modulate.g = 0.5
		right_sprite.modulate.b = 0.5
		
		left_sprite.modulate.r = 1
		left_sprite.modulate.g = 1
		left_sprite.modulate.b = 1
	else:
		right_sprite.modulate.r = 1
		right_sprite.modulate.g = 1
		right_sprite.modulate.b = 1
		
		left_sprite.modulate.r = 0.5
		left_sprite.modulate.g = 0.5
		left_sprite.modulate.b = 0.5
	
	Global.continue_dialog = false
	
	if dialog_tween and dialog_tween.is_running():
		dialog_tween.stop()
	
	dialog_tween = get_tree().create_tween()
	dialog_tween.finished.connect(_on_Tween_completed)
	dialog_tween.tween_property(text, "visible_ratio", 1, 5).set_trans(Tween.TRANS_LINEAR)
	

func _on_Tween_completed():
	Global.continue_dialog = true
	get_node("ContinueText").visible = true
