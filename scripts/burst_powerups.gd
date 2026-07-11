extends Node
## Temporary activatable powerups (sprint / skybound / dire strike).
## Autoloaded as BurstPowerups — shared cooldowns for co-op fairness,
## but each warden tracks their own active buffs on the player node.

signal burst_state_changed

const SPRINT_DURATION := 3.0
const SPRINT_CD := 8.0
const SPRINT_MULT := 1.75

const SKY_DURATION := 5.0
const SKY_CD := 10.0
const SKY_JUMP_MULT := 1.35
const SKY_EXTRA_JUMPS := 1  ## temporary +1 air jump

const DIRE_CD := 12.0
const DIRE_RANGE := 110.0
const DIRE_DAMAGE := 48
const DIRE_LUNGE := 55.0


func defs() -> Array:
	return [
		{"id": "sprint", "name": "Rush", "key": "1", "desc": "Sprint speed boost"},
		{"id": "sky", "name": "Skybound", "key": "2", "desc": "Super jumps for a few seconds"},
		{"id": "dire", "name": "Dire Strike", "key": "3", "desc": "Lunge-attack nearest monster"},
	]
