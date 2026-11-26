class_name Dice
extends RefCounted
## Seedable dice. All randomness in the rules goes through one Dice instance
## so seeded games replay identically and tests stay deterministic.

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value


func d20() -> int:
	return _rng.randi_range(1, 20)


## Random index in 0..n-1.
func pick(n: int) -> int:
	return _rng.randi_range(0, n - 1)


## Chance (0..1) that d20 + `mod` beats d20 + `opp_mod` outright (ties excluded).
static func chance_win(mod: int, opp_mod: int) -> float:
	# Closed form of the same triangular d20 difference distribution.
	var delta := mod-opp_mod
	if delta>=20:
		return 1.0
	if delta<=-19:
		return 0.0
	if delta<=0:
		var n := 19+delta
		return float(n*(n+1))/800.0
	var losses := 20-delta
	return 1.0-float(losses*(losses+1))/800.0
