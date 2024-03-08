extends Button

# This controls both arrow buttons above the Enter Region button on the world map UI.
# Very self-explanatory. If the current area site has a previous/next site and it's unlocked it'll go to it.

@export var go_to_next : bool


func _on_pressed():
	if Global.area_swap_allowed:
		if !go_to_next and Global.current_area.previous_site and Global.current_area.previous_site.unlocked:
			Global.change_area_site(Global.current_area.previous_site)
		elif go_to_next and Global.current_area.next_site and Global.current_area.next_site.unlocked:
			Global.change_area_site(Global.current_area.next_site)
