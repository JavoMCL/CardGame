extends Node

const CATALOG := {
	"stronger": {
		"name": "Stronger",
		"description": "Always wins ties, even with more cards, and ignores the opponent's defense.",
		"icon_animation": "stronger",
		"is_passive": true
	},
	"clairvoyance": {
		"name": "Clairvoyance",
		"description": "Reveals the next card from the deck before deciding to hit.",
		"icon_animation": "clairvoyance",
		"is_passive": false
	},
	"sum": {
		"name": "Sum",
		"description": "Adds the damage of previous consecutive wins to your next win. Resets on a loss.",
		"icon_animation": "sum",
		"is_passive": true
	},
	"discard": {
		"name": "Discard",
		"description": "Discard one of your cards at any point before standing.",
		"icon_animation": "discard",
		"is_passive": false
	},
	"regeneration": {
		"name": "Regeneration",
		"description": "Recovers 1 HP per round, or 2 HP if you win the round.",
		"icon_animation": "regeneration",
		"is_passive": true
	},
	"tank": {
		"name": "Tank",
		"description": "Your defense can never be ignored, under any circumstance.",
		"icon_animation": "tank",
		"is_passive": true
	},
	"thief": {
		"name": "Thief",
		"description": "Steals 1 point from the opponent's score each round.",
		"icon_animation": "thief",
		"is_passive": true
	},
	"spare": {
		"name": "Spare",
		"description": "Halves the mana cost of all skills.",
		"icon_animation": "spare",
		"is_passive": true
	}
}

const ALL_IDS: Array[String] = [
	"stronger", "clairvoyance", "sum", "discard",
	"regeneration", "tank", "thief", "spare"
]

func get_data(id: String) -> Dictionary:
	return CATALOG.get(id, {})
