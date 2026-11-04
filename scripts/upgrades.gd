class_name Upgrades
extends RefCounted
## Catalog of permanent shop upgrades. Owned levels live in `GameState.upgrades`.

enum Category { OFFENSE, DEFENSE, MINING }

const CATEGORY_NAMES := {Category.OFFENSE: "OFFENSE", Category.DEFENSE: "DEFENSE", Category.MINING: "MINING"}
const CATEGORY_COLORS := {
	Category.OFFENSE: Color(1.0, 0.45, 0.35),
	Category.DEFENSE: Color(0.4, 0.75, 1.0),
	Category.MINING: Color(1.0, 0.8, 0.3),
}

const CATALOG := {
	"extra_gun": {"category": Category.OFFENSE, "name": "Twin Barrel", "desc": "Adds another parallel gun barrel.", "cost": 120, "max": 3},
	"nova_charge": {"category": Category.OFFENSE, "name": "Nova Capacitor", "desc": "+1 Nova charge. Charges refill one at a time.", "cost": 140, "max": 3},
	"regen_shield": {"category": Category.DEFENSE, "name": "Regen Shield", "desc": "+25 shield that recharges after 4s without taking damage.", "cost": 130, "max": 4},
	"bonus_health": {"category": Category.DEFENSE, "name": "Armor Plating", "desc": "+25 max HP.", "cost": 100, "max": 5},
	"mining_speed": {"category": Category.MINING, "name": "Laser Focus", "desc": "+25% mining speed.", "cost": 80, "max": 5},
	"cargo_size": {"category": Category.MINING, "name": "Cargo Pods", "desc": "+10 cargo capacity.", "cost": 80, "max": 5},
}

const COST_GROWTH := 1.6


static func cost(id: String, owned: int) -> int:
	return roundi(CATALOG[id].cost * pow(COST_GROWTH, owned))


static func ids_in(category: Category) -> Array[String]:
	var ids: Array[String] = []
	for id: String in CATALOG:
		if CATALOG[id].category == category:
			ids.append(id)
	return ids
