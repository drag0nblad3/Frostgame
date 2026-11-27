class_name RuleHooks
extends RefCounted
## Named extension points so core rules never call expansion code directly.
## Expansions register callables once (see install()); core rules ask:
##   any("name", [args])          -> true if any hook returns true
##   total("name", [args])        -> sum of int results
##   first("name", [args])        -> first non-null result, else null
## Hooks run in registration order. Hook names and their arguments are listed
## in docs/architecture.md under "Rule hooks".

static var _hooks := {}
static var _installed := false


static func add(hook: String, fn: Callable) -> void:
	_install()
	if not _hooks.has(hook):
		_hooks[hook] = []
	_hooks[hook].append(fn)


## Drops every callable registered under `hook` (tests use this to clean up).
static func clear(hook: String) -> void:
	_hooks.erase(hook)


static func any(hook: String, args: Array) -> bool:
	_install()
	for fn: Callable in _hooks.get(hook, []):
		if fn.callv(args):
			return true
	return false


static func total(hook: String, args: Array) -> int:
	_install()
	var sum := 0
	for fn: Callable in _hooks.get(hook, []):
		sum += int(fn.callv(args))
	return sum


static func run(hook: String, args: Array) -> void:
	_install()
	for fn: Callable in _hooks.get(hook, []):
		fn.callv(args)


static func first(hook: String, args: Array) -> Variant:
	_install()
	for fn: Callable in _hooks.get(hook, []):
		var out: Variant = fn.callv(args)
		if out != null:
			return out
	return null


## The one place that lists rule expansions. Add new content sets here.
static func _install() -> void:
	if _installed:
		return
	_installed = true
	RedKingHooks.install()
