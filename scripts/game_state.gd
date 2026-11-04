extends Node
## Autoload that survives scene reloads: which asteroid we're on and the run's score.

var level := 1
var score := 0
## Only the first load of a session shows the title screen.
var show_title := true


func reset() -> void:
	level = 1
	score = 0


func fuel_quota() -> float:
	return 60.0 + 20.0 * level
