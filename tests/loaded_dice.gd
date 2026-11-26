class_name LoadedDice
extends Dice
## Dice for tests: returns queued d20 results in order, then 10s.

var queue: Array[int] = []


func _init(rolls: Array = []) -> void:
	super(1)
	for r in rolls:
		queue.append(int(r))


func d20() -> int:
	return queue.pop_front() if not queue.is_empty() else 10
