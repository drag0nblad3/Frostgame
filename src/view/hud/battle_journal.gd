class_name BattleJournal
extends ExpeditionScreen
## Read-only recent battle history. No controller access or state changes.
const LIMIT := 160
var _text: RichTextLabel
var _timeline: Array[Dictionary]=[]
var _cursor:=0
var _replay:=false
var _changing:=false
var _controls: VBoxContainer
var _toggle: Button
var _play: Button
var _seek: HSlider
var _timer: Timer
var _recent: Array[String]=[]


func _ready() -> void:
	build("BATTLE JOURNAL","Return to battle",navigate_back)
	_text=RichTextLabel.new()
	_text.bbcode_enabled=false
	_text.selection_enabled=true
	_text.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size",24)
	_text.add_theme_constant_override("line_separation",8)
	body.add_child(_text)
	_toggle=WorkshopUI.button(body,"Review recorded turns",_toggle_mode)
	_controls=WorkshopUI.column(body)
	var nav:=HBoxContainer.new()
	_controls.add_child(nav)
	for choice in [["|< Turn",-2],["< Event",-1],["Event >",1],["Turn >|",2]]:
		var button:=WorkshopUI.button(nav,str(choice[0]),_navigate.bind(int(choice[1])))
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y=56
	_seek=HSlider.new()
	_seek.min_value=0
	_seek.step=1
	_seek.custom_minimum_size.y=40
	_seek.value_changed.connect(_scrub)
	_controls.add_child(_seek)
	_play=WorkshopUI.button(_controls,"Play",_toggle_play)
	_timer=Timer.new()
	_timer.wait_time=1.6
	add_child(_timer)
	_timer.timeout.connect(_advance)
	visibility_changed.connect(func() -> void:
		if not visible:
			_stop())
	_controls.hide()


func open(entries: Array[String],timeline: Array[Dictionary]=[]) -> void:
	_stop()
	_recent.assign(entries)
	_timeline.assign(timeline)
	_cursor=0
	_replay=false
	_toggle.disabled=_timeline.is_empty()
	_show_recent()
	show_screen()
	call_deferred("_latest")


func _show_recent() -> void:
	subtitle.text="Recent events and resolved rolls · %d entries"%_recent.size()
	_text.text="No events recorded yet." if _recent.is_empty() else "\n\n".join(_recent)
	_toggle.text="Review recorded turns"
	_controls.hide()


func _toggle_mode() -> void:
	if _timeline.is_empty():
		return
	_stop()
	_replay=not _replay
	if _replay:
		_toggle.text="Return to recent journal"
		_controls.show()
		_seek.max_value=maxi(0,_timeline.size()-1)
		_show_beat()
	else:
		_show_recent()
		call_deferred("_latest")


func _show_beat() -> void:
	if not _replay or _timeline.is_empty():
		return
	var entry: Dictionary=_timeline[_cursor]
	subtitle.text="Turn %d · %s · Event %d / %d"%[entry["turn"],entry["phase"],_cursor+1,_timeline.size()]
	_text.text=str(entry["line"])+("\n\n"+str(entry["roll"]) if not str(entry["roll"]).is_empty() else "")
	_text.scroll_to_line(0)
	_changing=true
	_seek.value=_cursor
	_changing=false


func _navigate(direction: int) -> void:
	_stop()
	_cursor=BattleTimeline.turn_jump(_timeline,_cursor,direction) if absi(direction)==2 else clampi(_cursor+direction,0,_timeline.size()-1)
	_show_beat()


func _scrub(value: float) -> void:
	if _changing or not _replay:
		return
	_stop()
	_cursor=clampi(roundi(value),0,_timeline.size()-1)
	_show_beat()


func _toggle_play() -> void:
	if not _timer.is_stopped():
		_stop()
		return
	if _cursor>=_timeline.size()-1:
		_cursor=0
		_show_beat()
	_play.text="Pause"
	_timer.start()


func _advance() -> void:
	if not visible or not _replay or _cursor>=_timeline.size()-1:
		_stop()
		return
	_cursor+=1
	_show_beat()


func _stop() -> void:
	if _timer!=null:
		_timer.stop()
	if _play!=null:
		_play.text="Play"


func _latest() -> void:
	if visible and not _replay and _text.get_line_count()>0:
		_text.scroll_to_line(_text.get_line_count()-1)


static func record(entries: Array[String],line: String) -> void:
	if line.is_empty():
		return
	entries.append(line)
	if entries.size()>LIMIT:
		entries.pop_front()
