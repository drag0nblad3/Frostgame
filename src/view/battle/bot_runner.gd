class_name BotRunner
extends RefCounted
## Plays one bot activation on a worker thread so the table keeps drawing while
## the bot thinks. Events raised meanwhile are buffered and handed back on the
## main thread. Nothing may read the controller's state until done() is true.

## Single-core devices (and tests that want the old timing) play inline.
var threaded := OS.get_processor_count() > 1
var _task := -1
var _running := false
var _controller: GameController
var _events: Array[GameEvent] = []
var _mutex := Mutex.new()


func busy() -> bool:
	return _running


func start(c: GameController) -> void:
	_controller = c
	if not threaded:
		_play()
		_controller=null
		return
	_running = true
	_task = WorkerThreadPool.add_task(_play, false, "Frostgame bot")


## Called from the controller's event signal. True when the event was buffered.
func capture(e: GameEvent) -> bool:
	if not _running:
		return false
	_mutex.lock()
	_events.append(e)
	_mutex.unlock()
	return true


## Main thread: true once the activation has finished (events are then ready).
func done() -> bool:
	if not _running or not WorkerThreadPool.is_task_completed(_task):
		return false
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1
	_running = false
	_controller=null
	return true


func take_events() -> Array[GameEvent]:
	_mutex.lock()
	var out := _events
	_events = []
	_mutex.unlock()
	return out


## Blocks until any running activation ends and drops its events (new battle).
func finish() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1
	_running = false
	_controller=null
	take_events()


func _play() -> void:
	if _controller.state.active() != null:
		Bot.resume_activation(_controller)
	else:
		Bot.play_activation(_controller)
