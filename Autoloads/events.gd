## Event Autoload - Handles all events - Essentaillay master Observer. 
##Any change to Globals must be done through Events. 
extends Node

signal turn_update_signal(mob: Mob)
signal player_turn_ended_signal
signal player_action_selected(dir: Vector2)   # or pass a target point, etc.

func update_turn(mob: Mob) -> void:
	Globals.prior_mob = Globals.active_mob
	Globals.active_mob = mob
	Globals.turn_number += 1
	emit_signal("turn_update_signal", mob)

func player_turn_ended()->void:
	emit_signal("player_turn_ended_signal")
	
