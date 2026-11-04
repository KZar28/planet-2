extends Node
## Autoload that survives scene reloads: which asteroid we're on and the run's score.

var level := 1
var score := 0


func reset() -> void:
	level = 1
	score = 0


func fuel_quota() -> float:
	return 60.0 + 20.0 * level
