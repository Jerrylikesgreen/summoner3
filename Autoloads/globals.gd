## Globals Autoload. 
## Holds all Gloabl Dynamic Variables - Should only be accessed via API call from Events script. 
extends Node

var turn_history: Dictionary[int, Mob] = {}
var active_mob: Mob = null
var prior_mob: Mob = null
var turn_number: int = 0
