class_name ScenarioTablePreview
extends SubViewportContainer
## One low-resolution static rendered table; no simulation, figures, or animated snow.
var _studio: SubViewport
var _view: BoardView
var _camera: Camera3D
var _board: Board
var _key := ""


func _ready() -> void:
	stretch=true
	stretch_shrink=2
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_studio=SubViewport.new()
	_studio.own_world_3d=true
	_studio.render_target_update_mode=SubViewport.UPDATE_ONCE
	add_child(_studio)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("182d3e")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("b6cfdf")
	env.ambient_light_energy=0.82
	world.environment=env
	_studio.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-35,0)
	light.light_energy=1.25
	light.light_color=Color("f7e2c0")
	_studio.add_child(light)
	_view=BoardView.new()
	_view.cinematic=true
	_studio.add_child(_view)
	_camera=Camera3D.new()
	_camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	_studio.add_child(_camera)
	_camera.make_current()
	resized.connect(_frame)
	visibility_changed.connect(_frame)


func setup(board_id: String,scenario_id: String) -> void:
	var key := board_id+":"+scenario_id
	if key!=_key:
		_key=key
		_board=BoardLoader.load_id(board_id,TerrainDb.load_file())
		_view.scenario_id=scenario_id
		_view.build(_board)
	_frame()


func _frame() -> void:
	if _board==null or _camera==null:
		return
	var center := TableSpace.to_world(_board.size*0.5,1.0)
	_camera.look_at_from_position(center+Vector3(20,36,-34),center)
	var span := maxf(_board.size.x,_board.size.y)
	var aspect := maxf(0.25,size.x/maxf(1.0,size.y))
	_camera.size=maxf(span*1.18,span*1.38/aspect)
	if is_visible_in_tree():
		_studio.render_target_update_mode=SubViewport.UPDATE_ONCE
