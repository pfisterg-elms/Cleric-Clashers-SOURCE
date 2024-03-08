extends Sprite2D

# Actor Pawns, or as they should be called BATTLE PAWNS (way better name imo), are what populate the battle scene during an encounter.
# They're just the visual representation of Battle Actors. Probably should've had the Actor share the Pawn's data.
# The way I structured the battle system was very much improvised on the fly. Mistakes made, oh well! It works fine and dandy at any rate.
#
# Selecting a pawn and inflicting an attack will then link that attack back to the Battle Actor that the pawn is currently linked to
# via actor_link. I also, for some reason, used an "identifier" string that has a Battle Actor's ID in it. Completely pointless and redundant
# and I guess I forgot I already had a link via actor_link?
# It's a bit of a blur. woopsie!

# Direct link back to a Battle Actor. Gets set when a Battle Sequence is loaded.
var actor_link : Battle_Actor

# I... don't think I even use this. Lol.
var pawn_disabled : bool
@onready var initial_position = position
# Attacker offset is where a Pawn will move to when it's attacking this Pawn.
# This should've been on a per-Actor basis since some Actors have huge sprites. Namely the Warlord.
@export var attacker_offset : Vector2
# This is where the Pawn tweens to when it's killed, to better visualize it fading out and being removed from the fight.
# Gets reset to its initial_position when the next Battle occurs.
@export var defeated_offset : Vector2

# String link back to a Battle Actor. Set when battle sequence is loaded.
# Totally redundant in hindsight. Coulda just used actor_link by itself. Woops.
var internal_identifier : String

var tween : Tween


# I add some variance in when the subtle pawn bobbing animation starts to play so they don't all play at the same time.
# Makes all the characters move of their own accord in a sense, adds to the visual flair I think.
# I should've added a larger maximum amount for the timer range since it takes way longer
func _ready():
	visible = false
	
	await(get_tree().create_timer(randf_range(0, 3)).timeout)
	get_node("AnimationPlayer").play("IdleSway")


# Checks for inputs, so long as a Battle Pawn is selected and the player has selected an attack already.
#
# Mostly self-explanatory. If the Pawn is in the enemy party currently active in the BattleManager,
# the player can inflict an attack of type Damage, but not Bolster or Self-Bolster. That'd just be a waste of a turn!
#
# Otherwise if the Pawn is in the player party we can inflict those attacks. But only Self-Bolsters for Pawns of the currently active character
# and Bolsters work for the whole party regardless of current character or otherwise.
# Again, it's all pretty self-explanatory. The implementation could definitely use some work though.
#
# pawn_selected prevents the player from continually clicking a Pawn, allowing them to spam attacks constantly.
# That somehow completely escaped me to fix it during my own testing sessions. lol.
func _input(event):
	if event.is_action_released("interact") and Global.current_battle_pawn == self and !BattleManager.pawn_selected:
		if !BattleManager.selected_attack: return
		
		Global.current_pawn_target = self
		BattleManager.pawn_selected = true
		
		for enemy in BattleManager.enemy_party:
			if enemy.actor_identifier == internal_identifier:
				if BattleManager.selected_attack.attack_type == "Damage":
					BattleManager.perform_attack(enemy, self, BattleManager.selected_attack)
				else:
					BattleManager.output_to_battlelog("[color=orange]You cannot inflict a Bolster action on an enemy![/color]")
					BattleManager.pawn_selected = false
				return
		
		for player in BattleManager.player_party:
			if player.actor_identifier == internal_identifier:
				if BattleManager.selected_attack.attack_type == "Bolster":
					BattleManager.perform_bolster(player, Global.current_battle_pawn, BattleManager.selected_attack)
				elif BattleManager.selected_attack.attack_type == "SelfBolster":
					if Global.current_pawn_target != BattleManager.current_pawn:
						BattleManager.output_to_battlelog("[color=orange]You can only use this Bolster action on your current character![/color]")
						BattleManager.pawn_selected = false
					else:
						BattleManager.perform_bolster(player, Global.current_battle_pawn, BattleManager.selected_attack)
				else:
					BattleManager.output_to_battlelog("[color=orange]You cannot inflict an attack on an ally![/color]")
					BattleManager.pawn_selected = false


# Both funcs below deal with determining the currently selected Battle Pawn.
# Mouse into the Pawn's collision box, that Pawn is selected.
# Mouse out of it, Pawn is deselected.
# Spawns a glow effect that waxes and wanes to better visualize what Pawn you're currently selecting.
func _on_area_2d_mouse_entered():
	tween = get_tree().create_tween()
	
	if !Global.current_battle_pawn and !actor_link.defeated:
		Global.current_battle_pawn = self
		Global.current_actor_target = actor_link
		tween.tween_property($SelectGlow, "modulate:a", 1, 0.25)


func _on_area_2d_mouse_exited():
	tween = get_tree().create_tween()
	
	if Global.current_battle_pawn == self:
		Global.current_battle_pawn = null
		Global.current_actor_target = null
		tween.tween_property($SelectGlow, "modulate:a", 0, 0.25)
