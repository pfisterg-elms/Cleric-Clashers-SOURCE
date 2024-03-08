extends ItemList


func _on_item_selected(index):
	BattleManager.set_selected_attack(index)
