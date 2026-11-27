class_name BattleCommandScreen
extends ExpeditionScreen
## Large grouped command choices; modal so battle actions cannot leak behind.
signal chosen(id: int)

var _grid: GridContainer
var _buttons := {}
const GROUPS := [
	["EXPEDITION",[[0,"Campaign headquarters"],[1,"Warband workshop"],[2,"New skirmish"],[14,"Return to home"]]],
	["BATTLE & SAVES",[[3,"Save battle"],[4,"Resume saved battle"],[5,"Scenario briefing"],[6,"Combat log"],[16,"Battle journal"],[19,"Resume expedition checkpoint"]]],
	["GUIDANCE",[[7,"Field guide"],[8,"Extra rules tips"],[9,"Training yard"]]],
	["VIEW & PERFORMANCE",[[11,"Frame battlefield"],[12,"Overhead view"],[13,"Focus active figure"],[10,"Toggle snowfall"],[15,"Graphics quality"],[17,"Playback speed"],[18,"Action camera"]]]
]


func _ready() -> void:
	build("BATTLE COMMANDS","Return to battle",navigate_back)
	var col := WorkshopUI.scroll(body)
	_grid=GridContainer.new()
	_grid.columns=2
	_grid.add_theme_constant_override("h_separation",12)
	_grid.add_theme_constant_override("v_separation",12)
	col.add_child(_grid)
	for group: Array in GROUPS:
		var section := WorkshopUI.section_card(_grid)
		WorkshopUI.label(section,str(group[0]),22,WorkshopUI.GOLD)
		for command: Array in group[1]:
			var id := int(command[0])
			var b := WorkshopUI.button(section,str(command[1]),_select.bind(id))
			b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			b.custom_minimum_size.y=64
			b.tooltip_text=b.text
			_buttons[id]=b


func open(status: String,objective: String,log_on: bool,tips_on: bool,pace: String="Normal",cinematic: bool=false) -> void:
	subtitle.text=status+"\n"+objective
	_buttons[6].text="Hide combat log" if log_on else "Show combat log"
	_buttons[8].text="Disable extra rules tips" if tips_on else "Enable extra rules tips"
	_buttons[6].tooltip_text=_buttons[6].text
	_buttons[8].tooltip_text=_buttons[8].text
	_buttons[17].text="Playback: "+pace
	_buttons[18].text="Action camera: "+("On" if cinematic else "Off")
	_buttons[17].tooltip_text=_buttons[17].text
	_buttons[18].tooltip_text=_buttons[18].text
	show_screen()


func _reflow() -> void:
	if _grid!=null:
		_grid.columns=clampi(floori(float(size.x)/390.0),1,4)


func _select(id: int) -> void:
	hide()
	chosen.emit(id)
