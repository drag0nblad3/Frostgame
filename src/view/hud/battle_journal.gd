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
var _nav: GridContainer
var _toggle: Button
var _play: Button
var _seek: HSlider
var _timer: Timer
var _recent: Array[String]=[]
var _frames: Array[Dictionary]=[]
var _map: ReplayMap
var _map_panel: VBoxContainer
var _map_label: Label
var _floor: OptionButton
var _review_body: BoxContainer
var _map_frame: Dictionary={}


func _ready() -> void:
	build("BATTLE JOURNAL","Return to battle",navigate_back)
	_text=RichTextLabel.new()
	_text.bbcode_enabled=false
	_text.selection_enabled=true
	_text.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size",24)
	_text.add_theme_constant_override("line_separation",8)
	_review_body=BoxContainer.new()
	_review_body.vertical=true
	_review_body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_child(_review_body)
	_review_body.add_child(_text)
	_map_panel=WorkshopUI.column(_review_body)
	_map_label=WorkshopUI.label(_map_panel,"",18,WorkshopUI.MUTED)
	_map_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_floor=OptionButton.new()
	_floor.custom_minimum_size.y=46
	_floor.item_selected.connect(_select_surface)
	_map_panel.add_child(_floor)
	_map=ReplayMap.new()
	_map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_map.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_map_panel.add_child(_map)
	_map_panel.hide()
	_toggle=WorkshopUI.button(body,"Review recorded turns",_toggle_mode)
	_controls=WorkshopUI.column(body)
	_nav=GridContainer.new()
	_nav.columns=2
	_controls.add_child(_nav)
	for choice in [["|< Turn",-2],["< Event",-1],["Event >",1],["Turn >|",2]]:
		var button:=WorkshopUI.button(_nav,str(choice[0]),_navigate.bind(int(choice[1])))
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


func open(entries: Array[String],timeline: Array[Dictionary]=[],frames: Array[Dictionary]=[]) -> void:
	_stop()
	_recent.assign(entries)
	_timeline.assign(timeline)
	_frames.assign(frames)
	_map_frame={}
	_floor.clear()
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
	_map_panel.hide()


func _toggle_mode() -> void:
	if _timeline.is_empty():
		return
	_stop()
	_replay=not _replay
	if _replay:
		_toggle.text="Return to recent journal"
		_controls.show()
		_map_panel.visible=not _frames.is_empty()
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
	_show_map(int(entry.get("event_end",0)))
	_changing=true
	_seek.value=_cursor
	_changing=false


func _show_map(event_end: int) -> void:
	if not _map_panel.visible:
		return
	var previous := str(_floor.get_item_metadata(_floor.selected)) if _floor.selected>=0 else ""
	_map_frame=BattleFrame.at_or_before(_frames,event_end)
	_floor.clear()
	_floor.add_item("All floors")
	_floor.set_item_metadata(0,"")
	var ids: Array[String]=[]
	for surface: Dictionary in _map_frame.get("floors",[]):
		ids.append(str(surface["id"]))
	for f: Dictionary in _map_frame.get("figures",[]):
		var id := str(f["surface"])
		if not id.is_empty() and not ids.has(id):
			ids.append(id)
	for id in ids:
		_floor.add_item(id.replace("_"," ").capitalize())
		_floor.set_item_metadata(_floor.item_count-1,id)
	_floor.select(0)
	for i in range(1,_floor.item_count):
		if str(_floor.get_item_metadata(i))==previous:
			_floor.select(i)
			break
	_floor.visible=_floor.item_count>1
	_map_label.text="No battlefield frame recorded yet." if _map_frame.is_empty() else ("Recorded action boundary" if int(_map_frame["event_end"])==event_end else "Last recorded action boundary")
	if not _map_frame.is_empty():
		_map_label.text+=" · Blue / Red / Creatures · Gold: loot · Labels: ID / height"
	_select_surface(_floor.selected)


func _select_surface(index: int) -> void:
	_map.show_frame(_map_frame,str(_floor.get_item_metadata(index)) if index>=0 else "")


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


func _reflow() -> void:
	if _nav!=null:
		_nav.columns=4 if size.x>=700 else 2
	if _review_body!=null:
		_review_body.vertical=size.x<size.y*1.25


func _latest() -> void:
	if visible and not _replay and _text.get_line_count()>0:
		_text.scroll_to_line(_text.get_line_count()-1)


static func record(entries: Array[String],line: String) -> void:
	if line.is_empty():
		return
	entries.append(line)
	if entries.size()>LIMIT:
		entries.pop_front()
