extends TestCase


func test_imported_corner_icons_have_dimensions() -> void:
	for key: String in MenuSymbols.ICONS:
		var icon: Texture2D=MenuSymbols.ICONS[key]
		check(icon!=null,key)
		check_eq(icon.get_width(),40,key)
		check_eq(icon.get_height(),40,key)
		var button:=Button.new()
		MenuSymbols.apply(button,key,"test",true)
		check_eq(button.icon,icon)
		check_eq(button.text,"")
		check(button.custom_minimum_size.x>=64 and button.custom_minimum_size.y>=64)
		button.free()
	var theme:=BattleTheme.create()
	for key: String in ["close","close_pressed"]:
		var texture:=theme.get_icon(key,"Window")
		check(texture!=null,key)
		check_eq(texture.get_width(),42,key)
		check_eq(texture.get_height(),42,key)
