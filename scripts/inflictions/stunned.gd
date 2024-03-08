extends Infliction_Base
class_name Infliction_Stunned

func perform_effects():
	turns_left -= 1
	if turns_left <= 0:
		remove_effect_from_link()
