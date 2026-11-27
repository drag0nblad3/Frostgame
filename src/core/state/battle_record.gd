class_name BattleRecord
extends RefCounted
## Immutable, plain event records for checkpoint history and debugging.
## A record is an audit trail, not a command replay.


static func pack(events: Array[GameEvent]) -> Array:
	var result: Array=[]
	for event in events:
		if BattleSnapshot.plain(event.data):
			result.append({"type":event.type,"data":event.data.duplicate(true)})
	return result


static func unpack(records: Array) -> Array[GameEvent]:
	var result: Array[GameEvent]=[]
	for entry: Dictionary in records:
		result.append(GameEvent.new(str(entry["type"]),entry["data"].duplicate(true)))
	return result


## Record a top-level accepted command, including calls from the bot.
## Nested commands belong to the outer transaction rather than a duplicate record.
static func run(c: GameController,key: String,args: Dictionary,apply: Callable) -> bool:
	if c.recording_command:
		return bool(apply.call())
	c.recording_command=true
	var rng_before := c.dice._rng.state
	var first := c.history.size()
	var accepted := bool(apply.call())
	c.recording_command=false
	if accepted:
		c.command_history.append({"key":key,"args":args.duplicate(true),"rng_before":rng_before,"rng_after":c.dice._rng.state,"event_start":first,"event_end":c.history.size()})
	return accepted
