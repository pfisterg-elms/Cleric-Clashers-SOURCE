extends Node
class_name Battle_Manager

# This code is a beast. 700 lines of mayhem. Read it and weep, because I sure did. For almost a month straight.
# Initially I wanted to watch a few tutorials but it was honestly more fun, for the most part, to do it all from scratch.
# This is absolutely too long for me to comment through all of this but I'll list the key mistakes here:
# 
# --- Separate arrays for both the player's party and then what characters are active (still alive/in the fight)
# and also an array for which players are defeated. In the end I only use player_party but just in case I left the vars there. Legacy code ftw
# same logic applied to the enemy party.
# that mess came about because I didn't realize GDscript doesn't actually copy the entries of an array to another array. Instead it references back
# to that original array.

# --- Not using signals more often, and also separating functions into different classes.
# A -lot- of this could most likely be set inside the Attack class, or the Battle Actor/Pawn classes, or the Infliction class!
# Signals are just very nice to use but I only wound up using it once in the whole thing. Another spot I could've used it for was
# signalling whose turn it'll be next in battle. The way the battles worked changed very rapidly over time so plans, and code of course,
# had to be improvised around that. blargh.

# --- Lots of checks just to figure out whether or not the enemy or player was defeated. it's sloppy how it works. i don't even know how it works
# entirely anymore. I hodge-podged it all together until it worked.
# That might be responsible for why, specifically with only Henrick oddly enough, the game takes a few seconds extra to populate the UI
# with his attacks. It's clunky.
#
# --- Not having the turn-check system under one single function segment. Instead I do behaviors individually based on whether the
# enemy or player party is taking a turn. I mean, it's not a bad thing to do if you ask me, but it just really clutters the code a lot.
# Could've had a fair amount of it under one common function though. Especially when checking for certain Inflictions,
# like if the current Actor is stunned or whatnot.
#
# --- General scalability of the code. It became very tedious later on to implement new features or Inflictions because of how
# this is designed. I should've had an actual battle plan in mind from the get-go for what I wanted to do. I did, at first,
# but over time I just winged it. For better and for worse, clearly.
#
# But honestly? It's fine. It's perfectly fine. Game works, it's not tanking performance ever unless your name is Henrick, and nothing
# blew up in the process. I'm proud of it. It is a GREAT battle management system and you will not tell me otherwise.

var current_battle : Battle_Sequence
var wave_index : int

var player_party = []
var active_players = []
var defeated_players = []
var player_pawns = []
var player_index : int = -1
var enemy_party = []
var defeated_enemies = []
var enemy_pawns = []
var enemy_index : int = -1

var player_turn : bool
var enemy_turn : bool

var current_actor : Battle_Actor
var current_pawn

signal damage_calculated

# cleared after every turn
var selected_attack
var pawn_selected : bool = false

var battle_tween : Tween

var battle_bg

var battle_won : bool = false
var battle_lost : bool = false

var boss_bar : ProgressBar


func start_battle(battle : Battle_Sequence):
	UI.get_node("%BattleLog").text = ""
	
	battle_won = false
	current_battle = battle
	
	# juuust in case
	reset_battle_data(true, false)
	
	UI.get_node("%BattleLog").text = ""
	output_to_battlelog(battle.log_message)
	
	battle_bg = UI.get_node(battle.background_name)
	battle_bg.visible = true
	UI.get_node("%MapInterface").visible = false
	UI.get_node("%RegionEnter").disabled = true
	UI.get_node("%BattleInterface").visible = true
	UI.get_node("%BattleScene").visible = true
	
	if current_battle.smooth_fade:
		Global.play_new_music(battle.battle_music, 2, false)
	else:
		Global.play_new_music(battle.battle_music, 2, true)
	
	if !battle.boss_title.is_empty():
		UI.get_node("%BossTitle").text = battle.boss_title
		UI.get_node("%BossTitleHeader").visible = true
	else:
		UI.get_node("%BossTitleHeader").visible = false
	
	# look ma! i figured out how to do arrays properly!
	# only took me 4 weeks of troubleshooting!!!
	player_party = battle.player_actors.duplicate()
	enemy_party = battle.enemy_actors.duplicate()
	
	for player in player_party:
		player.init_result = Global.dice_roll(player.initiative_bonus)
	
	for enemy in enemy_party:
		enemy.init_result = Global.dice_roll(enemy.initiative_bonus)
	
	player_party.sort_custom(sort_init)
	active_players = player_party
	place_actors(player_party, Global.battle_scene.player_spawns, player_pawns)
	enemy_party.sort_custom(sort_init)
	place_actors(enemy_party, Global.battle_scene.enemy_spawns, enemy_pawns)
	
	# always start with player's turn no matter what
	player_turn = true
	begin_turn()


func begin_turn():
	# it SHOULD check when an enemy/player is defeated each time
	# but sometimes theres an edge case
	if check_party_defeat(player_party, defeated_players) or player_party.is_empty() or battle_lost:
		battle_won = false
		battle_lost = true
		lose_battle()
		return
	elif enemy_party.is_empty() or battle_won:
		battle_won = true
		battle_lost = false
		complete_battle()
		return
	
	if player_turn:
		pawn_selected = false
		player_index += 1
		
		# might be >= idk
		#update: it was, indeed, >=
		if player_index >= len(player_party):
			player_index = 0
		
		if !player_party.is_empty():
			current_actor = active_players[player_index]
		else:
			battle_lost = true
			begin_turn()
		
		if current_actor.defeated:
			if check_party_defeat(player_party, defeated_players):
				battle_lost = true
			# restart from top of function to iterate thru all party members
			# and get the next active one
			# this is messy and terrible. hopefully it works though!!
			# we'll check if the entire party is downed for players and enemies
			# in damage_actors so this SHOULD be ok
			begin_turn()
			return
		
		current_pawn = player_pawns[player_index]
		current_pawn.get_node("TurnGlow").visible = true
		
		output_to_battlelog("[color=green]" + current_actor.actor_name + "'s turn![/color]")
		
		if current_actor.has_infliction("STUNNED"):
			output_to_battlelog("[color=yellow]" + current_actor.actor_name + " is currently stunned! TURN SKIPPED![/color]")
			await(get_tree().create_timer(1).timeout)
			
			for i in current_actor.inflictions:
				i.perform_effects()
				await(get_tree().create_timer(1).timeout)
			swap_turn()
			return
		
		for i in current_actor.inflictions:
			i.perform_effects()
			await(get_tree().create_timer(1).timeout)
		
		UI.get_node("%ActionList").clear()
		UI.get_node("%ActionLabel").text = ""
		for attack in current_actor.attacks:
			UI.get_node("%ActionList").add_item(attack.attack_name)
	else:
		enemy_index += 1
		
		if enemy_index >= len(enemy_party):
			enemy_index = 0
		
		current_actor = enemy_party[enemy_index]
		if current_actor.defeated:
			if check_party_defeat(enemy_party, defeated_enemies):
				battle_won = true
			begin_turn()
			return
		
		current_pawn = enemy_pawns[enemy_index]
		current_pawn.get_node("TurnGlow").visible = true
		
		output_to_battlelog("[color=red]" + current_actor.actor_name + "'s turn![/color]")
		
		if current_actor.has_infliction("STUNNED"):
			output_to_battlelog("[color=yellow]" + current_actor.actor_name + " is currently stunned! TURN SKIPPED![/color]")
			await(get_tree().create_timer(1).timeout)
			
			for i in current_actor.inflictions:
				i.perform_effects()
				await(get_tree().create_timer(1).timeout)
			
			swap_turn()
			return
		
		if !current_actor.inflictions.is_empty():
			for i in current_actor.inflictions:
				i.perform_effects()
				await(get_tree().create_timer(1).timeout)
		
		var random_attack = current_actor.attacks[randi() % current_actor.attacks.size()]
		# this also returns the index of the actual pawn in the battle_scene since the party and their respective visual pawns are always the same
		var target_player_index = randi() % active_players.size()
		var target_player = active_players[target_player_index]
		var target_pawn = player_pawns[target_player_index]
		
		# kinda wasting target_player/pawn since theyre preset
		# and im overriding them so im tossing away some calls already but eh whatever idc at this point
		if current_actor.has_infliction("CHALLENGED"):
			target_player = current_actor.get_infliction("CHALLENGED").challenger
			target_player_index = player_party.find(target_player)
			target_pawn = UI.get_node("%BattleScene").player_spawns[target_player_index]
		
		await(get_tree().create_timer(1).timeout)
		
		perform_attack(target_player, target_pawn, random_attack)


func set_selected_attack(index):
	selected_attack = active_players[player_index].attacks[index]
	UI.get_node("%ActionLabel").text = selected_attack.attack_descriptor


func perform_attack(target_actor : Battle_Actor, target_pawn, attack : Attack_Base):
	UI.get_node("%ActionLabel").text = ""
	UI.get_node("%ActionList").clear()
	
	var final_hit_mod
	
	if current_actor.defeated:
		begin_turn()
		return
	
	current_pawn.get_node("TurnGlow").visible = false
	
	output_to_battlelog(current_actor.actor_name + " attacks " + target_actor.actor_name + " using " + attack.attack_name + "!")
	await(get_tree().create_timer(1).timeout)
	
	current_pawn.z_index = 1
	
	battle_tween = get_tree().create_tween()
	battle_tween.tween_property(current_pawn, "position", target_pawn.position + target_pawn.attacker_offset, 0.35)
	
	await(battle_tween.finished)
	
	current_pawn.get_node("PawnSprite").texture = current_actor.sprite_group.attack_sprite
	UI.get_node("%SwingEffect").stream = attack.swing_sound
	UI.get_node("%SwingEffect").play()
	
	await(get_tree().create_timer(0.3).timeout)
	
	if current_actor.has_infliction("EMPOWERED"):
		final_hit_mod = attack.hit_modifier + 4
	else:
		final_hit_mod = attack.hit_modifier
	
	var hit_roll
	
	if attack.attack_name != "Warrior's Challenge":
		if current_actor.has_infliction("PRECISION") or current_actor.has_infliction("CHALLENGED"):
			hit_roll = Global.ability_check(final_hit_mod, target_actor.current_ac, true, false)
		elif current_actor.has_infliction("INACCURACY") or current_actor.has_infliction("STAGGERED") or current_actor.has_infliction("BLINDED"):
			hit_roll = Global.ability_check(final_hit_mod, target_actor.current_ac, false, true)
		else:
			hit_roll = Global.ability_check(attack.hit_modifier, target_actor.current_ac, false, false)
	else:
		hit_roll = "success"
	
	match hit_roll:
		"crit_fail":
			output_to_battlelog("[color=red]CRITICAL MISS![/color]")
			await(get_tree().create_timer(0.5).timeout)
		"crit_success":
			UI.get_node("%HitEffect").stream = Global.crit_sound
			UI.get_node("%HitEffect").play()
			
			target_pawn.modulate.g = 0
			target_pawn.modulate.b = 0
			
			battle_tween = get_tree().create_tween()
			battle_tween.tween_property(target_pawn, "modulate:g", 1, 0.15)
			battle_tween.parallel().tween_property(target_pawn, "modulate:b", 1, 0.15)
			
			output_to_battlelog("[color=yellow]CRITICAL HIT! 1.5X DAMAGE[/color]")
			await(get_tree().create_timer(1).timeout)
			damage_actor(target_actor, attack, true)
			await(damage_calculated)
		"success":
			UI.get_node("%HitEffect").stream = attack.hit_sound
			UI.get_node("%HitEffect").play()
			
			target_pawn.get_node("PawnSprite").texture = target_actor.sprite_group.hurt_sprite
			target_pawn.modulate.g = 0
			target_pawn.modulate.b = 0
			
			battle_tween = get_tree().create_tween()
			battle_tween.tween_property(target_pawn, "modulate:g", 1, 0.15)
			battle_tween.parallel().tween_property(target_pawn, "modulate:b", 1, 0.15)
			
			output_to_battlelog("[color=green]Target Hit![/color]")
			await(get_tree().create_timer(0.5).timeout)
			target_pawn.get_node("PawnSprite").texture = target_actor.sprite_group.idle_sprite
			damage_actor(target_actor, attack, false)
			await(damage_calculated)
		"fail":
			output_to_battlelog("[color=orange]Target Missed![/color]")
			await(get_tree().create_timer(0.5).timeout)
	
	current_pawn.get_node("PawnSprite").texture = current_actor.sprite_group.idle_sprite
	
	battle_tween = get_tree().create_tween()
	battle_tween.tween_property(current_pawn, "position", current_pawn.initial_position, 0.35)
	
	await(battle_tween.finished)
	
	current_pawn.z_index = 0
	swap_turn()


func swap_turn():
	if current_pawn != null:
		current_pawn.get_node("TurnGlow").visible = false
	
	if check_party_defeat(enemy_party, defeated_enemies) or enemy_party.is_empty() or battle_won:
		complete_battle()
		return
	elif check_party_defeat(player_party, defeated_players) or player_party.is_empty() or battle_lost:
		lose_battle()
		return
	
	if player_turn:
		selected_attack = null
		player_turn = false
		enemy_turn = true
		UI.get_node("%ActionLabel").text = ""
		UI.get_node("%ActionList").clear()
	else:
		selected_attack = null
		enemy_turn = false
		player_turn = true
	
	await(get_tree().create_timer(0.5).timeout)
	
	begin_turn()


func damage_actor(actor : Battle_Actor, attack : Attack_Base, crit : bool):
	var final_damage = attack.base_damage
	if crit:
		final_damage *= 1.5
	
	#TODO: strengthed = vikki bolster
	if current_actor.has_infliction("STAGGERED") or current_actor.has_infliction("STRENGTHENED"):
		final_damage *= 1.5
	
	for damage_type in actor.resistances:
		if damage_type == attack.damage_type:
			output_to_battlelog("[color=orange]" + actor.actor_name + " is resistant to " + damage_type + " damage! Damage HALVED![/color]")
			final_damage /= 2
	
	# pls dont be dumb and accidentally put the same dmg type in resistances and weaknesses
	
	for damage_type in actor.weaknesses:
		if damage_type == attack.damage_type:
			output_to_battlelog("[color=red]" + actor.actor_name + " is weak to " + damage_type + " damage! Damage DOUBLED![/color]")
			final_damage *= 2
	
	actor.current_health -= final_damage
	
	output_to_battlelog("[color=red]" + actor.actor_name + " struck with " + str(final_damage) + " " + str(attack.damage_type) + " damage![/color]")
	
	check_actor_downed(actor)
	
	if !actor.defeated and attack.infliction:
		var inflict_save = Global.ability_check(actor.infliction_save, attack.inflict_challenge, false, false)
		
		if inflict_save == "fail" or inflict_save == "crit_fail":
			var infliction = attack.infliction.instantiate()
			
			if actor.inflictions.has(infliction):
				output_to_battlelog("[color=yellow]" + infliction.effect_name + " is already inflicted on the target![/color]")
			else:
				if infliction != null:
					current_pawn.add_child(infliction)
					actor.inflictions.append(infliction)
					infliction.actor_link = actor
					output_to_battlelog("[color=red]" + actor.actor_name + " has been inflicted with " + infliction.effect_name + "![/color]")
					infliction.start_effects()
		elif inflict_save == "success" or inflict_save == "crit_success":
			output_to_battlelog("[color=yellow]" + actor.actor_name + " shakes off the infliction's effects![/color]")
	
	await(get_tree().create_timer(0.5).timeout)
	damage_calculated.emit()


func check_actor_downed(actor):
	if actor.current_health <= 0:
		actor.defeated = true
		
		if player_party.has(actor):
			output_to_battlelog("[color=red]" + actor.actor_name + " is knocked unconscious![/color]")
			var pawn_index = player_party.find(actor)
			defeated_players.append(actor)
			active_players.erase(actor)
			player_party.erase(actor)
			
			if check_party_defeat(player_party, defeated_players) or player_party.is_empty():
				battle_lost = true
			
			var target_pawn = player_pawns[pawn_index]
			target_pawn.modulate.g = 0
			target_pawn.modulate.b = 0
			target_pawn.get_node("SelectGlow").visible = false
			player_pawns.erase(target_pawn)
			
			battle_tween = get_tree().create_tween()
			battle_tween.tween_property(target_pawn, "modulate:a", 0, 0.5)
			battle_tween.parallel().tween_property(target_pawn, "position", target_pawn.position + target_pawn.defeated_offset, 0.75)
			
			if battle_lost:
				lose_battle()
				return
			
		elif enemy_party.has(actor):
			output_to_battlelog("[color=red]" + actor.actor_name + " has been slain![/color]")
			var pawn_index = enemy_party.find(actor)
			defeated_enemies.append(actor)
			enemy_party.erase(actor)
			
			var target_pawn = enemy_pawns[pawn_index]
			enemy_pawns.erase(target_pawn)
			target_pawn.modulate.g = 0
			target_pawn.modulate.b = 0
			target_pawn.get_node("SelectGlow").visible = false
			enemy_pawns.erase(target_pawn)
			
			battle_tween = get_tree().create_tween()
			battle_tween.tween_property(target_pawn, "modulate:a", 0, 0.5)
			battle_tween.parallel().tween_property(target_pawn, "position", target_pawn.position + target_pawn.defeated_offset, 0.75)
			
			if enemy_party.is_empty():
				battle_won = true
			
			await(battle_tween.finished)


func perform_bolster(target_actor, pawn_target, attack):
	var inflict_exists : bool = false
	
	UI.get_node("%SwingEffect").stream = attack.swing_sound
	UI.get_node("%SwingEffect").play()
	
	# BolsterGlow is for the target that RECEIVES the bolster
	# AidGlow is for the AIDING pawn thats GIVING the bolster
	# dumb naming scheme. do not care. too bad!
	pawn_target.get_node("BolsterGlow").modulate.a = 1
	
	battle_tween = get_tree().create_tween()
	battle_tween.tween_property(pawn_target.get_node("BolsterGlow"), "modulate:a", 0, 1.5)
	
	if current_pawn != pawn_target:
		current_pawn.get_node("AidGlow").modulate.a = 1
		battle_tween.parallel().tween_property(current_pawn.get_node("AidGlow"), "modulate:a", 0, 1.5)
	
	current_pawn.get_node("PawnSprite").texture = current_actor.sprite_group.bolster_sprite
	output_to_battlelog("[color=yellow]" + current_actor.actor_name + " bolsters " + target_actor.actor_name + " using " + attack.attack_name + "![/color]")
	await(get_tree().create_timer(0.5).timeout)
	
	if attack.infliction:
		var infliction = attack.infliction.instantiate()
		
		for inflict in target_actor.inflictions:
			# If the Infliction is already on the target then we just ignore the infliction, and remove it
			# imagine being able to stack mending infinitely. lmao.
			if inflict.effect_name == infliction.effect_name:
				inflict_exists = true
				output_to_battlelog("[color=yellow]" + infliction.effect_name + " is already bolstering this ally! No additional effects![/color]")
				infliction.queue_free()
	
	if !inflict_exists:
		var infliction = attack.infliction.instantiate()
		pawn_target.add_child(infliction)
		target_actor.inflictions.append(infliction)
		infliction.actor_link = target_actor
		infliction.start_effects()
		output_to_battlelog(target_actor.actor_name + " has been aided with " + infliction.effect_name + "!")
	
	await(get_tree().create_timer(1).timeout)
	current_pawn.get_node("PawnSprite").texture = current_actor.sprite_group.idle_sprite
	
	swap_turn()


func output_to_battlelog(msg : String):
	UI.get_node("%BattleLog").append_text("\n" + msg)


static func sort_init(a : Battle_Actor, b : Battle_Actor) -> bool:
	return a.init_result > b.init_result


func place_actors(actor_array : Array[Battle_Actor], placement_array : Array[Node2D], pawn_cache : Array):
	var index := 0
	
	for actor in actor_array:
		if !actor.actor_identifier:
			printerr("AN ACTOR HAS NO IDENTIFIER! THIS WILL BREAK THINGS!!! @" + actor.name)
			return
		
		placement_array[index].internal_identifier = actor.actor_identifier
		placement_array[index].actor_link = actor
		placement_array[index].get_node("PawnSprite").texture = actor.sprite_group.idle_sprite
		
		placement_array[index].visible = true
		pawn_cache.append(placement_array[index])
		index += 1


func reset_battle_data(reset_players : bool, next_battle : bool):
	battle_won = false
	battle_lost = false
	
	if battle_tween and battle_tween.is_running():
		battle_tween.stop()
		battle_tween.kill()
	
	enemy_turn = false
	player_turn = false
	
	if reset_players:
		for actor in current_battle.player_actors:
			actor.current_health = actor.max_health
			actor.current_ac = actor.armor_class
			actor.inflictions.clear()
			actor.defeated = false
			actor.init_result = 0
		
		for spawn in Global.battle_scene.player_spawns:
			spawn.get_node("PawnSprite").texture = null
			spawn.get_node("TurnGlow").visible = false
			spawn.modulate.a = 1
			spawn.modulate.r = 1
			spawn.modulate.g = 1
			spawn.modulate.b = 1
			spawn.position = spawn.initial_position
			
			spawn.get_node("SelectGlow").visible = true
			spawn.get_node("SelectGlow").modulate.a = 0
		
		player_party = []
		active_players = []
		player_pawns = []
		player_index = -1
		defeated_players = []
	
	for actor in current_battle.enemy_actors:
		actor.current_health = actor.max_health
		actor.current_ac = actor.armor_class
		actor.inflictions.clear()
		actor.defeated = false
		actor.init_result = 0
	
	for spawn in Global.battle_scene.enemy_spawns:
		spawn.get_node("PawnSprite").texture = null
		spawn.get_node("TurnGlow").visible = false
		spawn.modulate.a = 1
		spawn.modulate.r = 1
		spawn.modulate.g = 1
		spawn.modulate.b = 1
		spawn.position = spawn.initial_position
		
		spawn.get_node("SelectGlow").visible = true
		spawn.get_node("SelectGlow").modulate.a = 0
	
	enemy_party = []
	enemy_pawns = []
	enemy_index = -1
	defeated_enemies = []
	
	current_actor = null
	current_pawn = null
	selected_attack = null
	
	if next_battle:
		current_battle = null


# later, save this to a file or that playerprefs plugin idk just smth quick and dirty
func complete_battle():
	if current_battle.next_battle:
		Global.do_fade(1, true)
		await(Global.faded_out)
		
		goto_next_battle(current_battle.next_battle)
		
		Global.do_fade(2.5, false)
		
		return
	
	if current_battle.victory_message:
		output_to_battlelog(current_battle.victory_message)
	else:
		output_to_battlelog("Battle Victory!")
	
	if current_battle.big_victory:
		Global.play_new_music(Global.victory_big_music, 0, true)
	else:
		Global.play_new_music(Global.victory_normal_music, 1, true)
	
	if Global.current_area.next_site:
		Global.current_area.next_site.unlocked = true
		Global.current_area.next_site.visible = true
		Global.unlocked_sites.append(Global.current_area.next_site.name)
	
	if !current_battle.big_victory:
		Global.do_fade(4.5, true)
	else:
		Global.do_fade(9, true)
	
	await(Global.faded_out)
	
	battle_bg.visible = false
	UI.get_node("%MapInterface").visible = true
	UI.get_node("%BattleInterface").visible = false
	UI.get_node("%BattleScene").visible = false
	reset_battle_data(true, false)
	
	Global.do_fade(4, false)
	await(Global.faded_in)
	UI.get_node("%RegionEnter").disabled = false
	Global.play_new_music(Global.map_music, 2, true)


func lose_battle():
	output_to_battlelog("Battle Lost! ALL IS DOOMED!")
	Global.play_new_music(null, 0.5, true)
	
	Global.do_lose_fade(4, true)
	await(Global.faded_out)
	
	reset_battle_data(true, false)
	battle_bg.visible = false
	UI.get_node("%MapInterface").visible = true
	UI.get_node("%BattleInterface").visible = false
	UI.get_node("%BattleScene").visible = false
	UI.get_node("%RegionEnter").disabled = false
	
	Global.play_new_music(Global.map_music, 4, true)
	Global.do_lose_fade(3, false)


func check_party_defeat(current_party, defeated_party) -> bool:
	if current_party == defeated_party:
		return true
	else:
		return false


# im a little dumb so i'll have this called from complete_battle
# instead of placing several sloppy implementations around begin/swap turn
func goto_next_battle(battle : Battle_Sequence):
	# reset data of the current battle so that restarting each battle from world map doesnt mess up
	reset_battle_data(false, true)
	
	current_battle = battle
	
	UI.get_node("%BattleLog").text = ""
	
	if !battle.boss_title.is_empty():
		UI.get_node("%BossTitle").text = "[center]" + battle.boss_title + "[/center]"
		UI.get_node("%BossTitleHeader").visible = true
	else:
		UI.get_node("%BossTitleHeader").visible = false
	
	output_to_battlelog(battle.log_message)
	
	battle_bg = UI.get_node(battle.background_name)
	battle_bg.visible = true
	UI.get_node("%MapInterface").visible = false
	UI.get_node("%BattleInterface").visible = true
	UI.get_node("%BattleScene").visible = true
	
	if battle.battle_music:
		Global.play_new_music(battle.battle_music, 0.5, false)
	
	enemy_party = battle.enemy_actors
	
	for enemy in enemy_party:
		enemy.init_result = Global.dice_roll(enemy.initiative_bonus)
	
	enemy_party.sort_custom(sort_init)
	place_actors(enemy_party, Global.battle_scene.enemy_spawns, enemy_pawns)
	
	pawn_selected = false
	# weird workaround where PRESUMABLY beginning the turn without going thru swap_turn
	# to reset attack status and whatnot causes the player's next party character they control
	# to attack themselves. what??? how???
	# whatever. this works fine enough. this makes it so its the enemys turn so that
	# when swap_turn is called it actually properly swaps to the player's turn
	player_turn = false
	enemy_turn = true
	swap_turn()
