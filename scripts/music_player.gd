extends Node2D


var music_track_1
var music_track_2
var anim = AnimationPlayer



func crossfade_to(audio : AudioStream):
	music_track_1 = get_node("Track1")
	music_track_2 = get_node("Track2")
	anim = get_node("AnimationPlayer")
	
	if music_track_1.playing and music_track_2.playing:
		return
	
	if music_track_2.playing:
		music_track_1.stream = audio
		music_track_1.play()
		anim.play("FadeToTrack1")
	else:
		music_track_2.stream = audio
		music_track_2.play()
		anim.play("FadeToTrack2")

