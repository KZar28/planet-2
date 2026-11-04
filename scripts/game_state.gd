extends Node
## Autoload that survives scene reloads: which asteroid we're on, the run's
## score, credits and permanent upgrades.

var level := 1
var score := 0
var credits := 0
var upgrades := {}  # Upgrade id -> owned level.
var shop_offers := {}  # Upgrades.Category -> offered upgrade id for this asteroid.
var shop_bought := {}  # Upgrades.Category -> true once bought on this asteroid.
var _offers_level := 0
## Only the first load of a session shows the title screen.
var show_title := true


func reset() -> void:
	level = 1
	score = 0
	credits = 0
	upgrades.clear()
	_offers_level = 0


func fuel_quota() -> float:
	return 60.0 + 20.0 * level


func upgrade_level(id: String) -> int:
	return upgrades.get(id, 0)


## Rolls one offer per category the first time each asteroid loads.
func ensure_shop_offers() -> void:
	if _offers_level == level:
		return
	_offers_level = level
	shop_bought.clear()
	shop_offers.clear()
	for category: Upgrades.Category in Upgrades.CATEGORY_NAMES:
		var options := Upgrades.ids_in(category).filter(func(id: String) -> bool: return upgrade_level(id) < Upgrades.CATALOG[id].max)
		if not options.is_empty():
			shop_offers[category] = options.pick_random()


## Returns false if the purchase isn't allowed.
func buy(id: String) -> bool:
	var category: Upgrades.Category = Upgrades.CATALOG[id].category
	var price := Upgrades.cost(id, upgrade_level(id))
	if shop_bought.has(category) or shop_offers.get(category) != id or credits < price:
		return false
	credits -= price
	upgrades[id] = upgrade_level(id) + 1
	shop_bought[category] = true
	return true
