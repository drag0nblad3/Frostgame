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
	# Count pairs where a - b > opp_mod - mod; a difference d occurs 20 - |d| ways.
	var wins := 0
	for d in range(maxi(opp_mod - mod + 1, -19), 20):
		wins += 20 - absi(d)
	return wins / 400.0
