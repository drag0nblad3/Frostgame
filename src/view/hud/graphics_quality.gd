class_name GraphicsQuality
extends RefCounted
## Persist a graphics profile, without altering rules or save slots.
const PATH := "user://frostgame_graphics.cfg"
const NAMES := ["Performance","Balanced","High"]
static var _mode := -1


static func mode() -> int:
	if _mode<0:
		var config := ConfigFile.new()
		_mode=1 if OS.has_feature("mobile") else 2
		if config.load(PATH)==OK:
			_mode=clampi(int(config.get_value("graphics","quality",_mode)),0,2)
	return _mode


static func select_mode(value: int) -> bool:
	var config := ConfigFile.new()
	_mode=clampi(value,0,2)
	config.set_value("graphics","quality",_mode)
	return config.save(PATH)==OK


static func apply(viewport: Viewport) -> void:
	viewport.scaling_3d_scale=[0.68,0.82,1.0][mode()]
	viewport.msaa_3d=Viewport.MSAA_DISABLED if mode()<2 else Viewport.MSAA_2X


static func shadow_distance() -> float:
	return [0.0,38.0,65.0][mode()]


static func snow_count(count: int) -> int:
	return 0 if mode()==0 else (mini(36,count) if mode()==1 else count)


static func city_rings() -> int:
	return 2 if mode()==2 else 1
