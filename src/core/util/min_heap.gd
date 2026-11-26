class_name MinHeap
extends RefCounted
## Binary min-heap of [priority, value] pairs for path searches.

var _items: Array = []


func is_empty() -> bool:
	return _items.is_empty()


func push(priority: float, value: Variant) -> void:
	_items.append([priority, value])
	var i := _items.size() - 1
	while i > 0:
		var parent := (i - 1) / 2
		if _items[parent][0] <= _items[i][0]:
			break
		var t: Array = _items[parent]
		_items[parent] = _items[i]
		_items[i] = t
		i = parent


## Removes and returns [priority, value].
func pop() -> Array:
	var top: Array = _items[0]
	var last: Array = _items.pop_back()
	if not _items.is_empty():
		_items[0] = last
		var i := 0
		var n := _items.size()
		while true:
			var l := i * 2 + 1
			var r := l + 1
			var m := i
			if l < n and _items[l][0] < _items[m][0]:
				m = l
			if r < n and _items[r][0] < _items[m][0]:
				m = r
			if m == i:
				break
			var t: Array = _items[m]
			_items[m] = _items[i]
			_items[i] = t
			i = m
	return top
