extends TestCase
## RuleHooks combine expansion answers; Red King plugs into core combat through them.


func test_any_total_first() -> void:
	RuleHooks.add("test_any", func(x: int) -> bool: return x > 5)
	RuleHooks.add("test_total", func(x: int) -> int: return x)
	RuleHooks.add("test_total", func(x: int) -> int: return 1)
	RuleHooks.add("test_first", func(_x: int) -> Variant: return null)
	RuleHooks.add("test_first", func(x: int) -> Variant: return x * 2)
	check(RuleHooks.any("test_any", [6]))
	check(not RuleHooks.any("test_any", [2]))
	check_eq(RuleHooks.total("test_total", [4]), 5)
	check_eq(RuleHooks.first("test_first", [3]), 6)
	check(not RuleHooks.any("no_such_hook", []))
	check_eq(RuleHooks.first("no_such_hook", []), null)
	for hook in ["test_any", "test_total", "test_first"]:
		RuleHooks.clear(hook)


func test_red_king_hooks_installed() -> void:
	RuleHooks._install()
	for hook in ["objective_figure", "no_support", "fight_bonus", "melee_damage_bonus", "range", "sight", "forced_move_blocked", "group_blocked"]:
		check(RuleHooks._hooks.has(hook), hook)
