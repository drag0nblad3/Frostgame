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
