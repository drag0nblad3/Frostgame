class_name BattleCameraDirector
extends RefCounted
## Frames visible combatants only. A manual camera gesture always wins.
var rig: CameraRig
var enabled := false
var _saved: Dictionary={}
var _revision := 0
var _interrupted := false


func before(event: GameEvent,views: Dictionary) -> void:
	if not enabled or rig==null or ModalInput.blocked():
		finish()
		return
	var beat := BattlePresentation.beat(event)
	if beat=="movement" or (beat=="context" and event.type in ["activate","end_activation","phase","turn_start","game_over"]):
		finish()
	if beat!="action" or _interrupted:
		return
	var a: FigureView=views.get(event.data.get("id",-1))
	var b: FigureView=views.get(event.data.get("target",-1))
	if not is_instance_valid(a) or not is_instance_valid(b) or not a.is_visible_in_tree() or not b.is_visible_in_tree():
		return
	if not _saved.is_empty() and rig.manual_revision!=_revision:
		_saved.clear()
		_interrupted=true
		return
	if _saved.is_empty():
		_saved=rig.presentation_pose()
		_revision=rig.manual_revision
	var center := (a.global_position+b.global_position)*0.5+Vector3.UP*0.7
	var distance := maxf(12.0,a.global_position.distance_to(b.global_position)*1.8+8.0)
	rig.present_pose({"position":center,"distance":minf(distance,rig.max_distance),"pitch":rig.pitch})


func finish() -> void:
	if rig!=null and not _saved.is_empty() and rig.manual_revision==_revision:
		rig.present_pose(_saved)
	_saved.clear()
	_interrupted=false
