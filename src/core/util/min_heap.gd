class_name MinHeap
extends RefCounted
## Binary min-heap of [priority, value] pairs for path searches.
## Priorities and values sit in parallel arrays so a push allocates nothing.

var _keys := PackedFloat64Array()
var _values: Array = []


func is_empty() -> bool:
	return _values.is_empty()


func push(priority: float, value: Variant) -> void:
	_keys.append(priority)
	_values.append(value)
	var i := _values.size() - 1
	while i > 0:
		var parent := (i - 1) / 2
		if _keys[parent] <= _keys[i]:
			break
		_swap(parent, i)
		i = parent


## Removes and returns [priority, value].
func pop() -> Array:
	var top := [_keys[0], _values[0]]
	var n := _values.size() - 1
	_keys[0] = _keys[n]
	_values[0] = _values[n]
	_keys.resize(n)
	_values.resize(n)
	var i := 0
	while true:
		var l := i * 2 + 1
		var r := l + 1
		var m := i
		if l < n and _keys[l] < _keys[m]:
			m = l
		if r < n and _keys[r] < _keys[m]:
			m = r
		if m == i:
			break
		_swap(m, i)
		i = m
	return top


func _swap(a: int, b: int) -> void:
	var k := _keys[a]
	_keys[a] = _keys[b]
	_keys[b] = k
	var v: Variant = _values[a]
	_values[a] = _values[b]
	_values[b] = v
