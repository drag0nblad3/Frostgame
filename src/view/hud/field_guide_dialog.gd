class_name FieldGuideDialog
extends ExpeditionScreen
## Read-only, shared reference accessible without instantiating a battle.
var _topics: ItemList
var _index := 0
var _split: BoxContainer
var _body: RichTextLabel
var _pages: Array[Dictionary]=[]
var _heading: Label


func _ready() -> void:
	build("FIELD GUIDE","Return",navigate_back)
	title="Field guide"
	subtitle.text="Rules, controls and scenario reference"
	_split=BoxContainer.new()
	_split.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override("separation",12)
	body.add_child(_split)
	_topics=ItemList.new()
	_topics.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_topics.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_topics.size_flags_stretch_ratio=0.9
	_topics.custom_minimum_size.y=135
	_topics.add_theme_font_size_override("font_size",24)
	_topics.add_theme_constant_override("v_separation",17)
	_split.add_child(_topics)
	var col := WorkshopUI.column(_split)
	col.size_flags_stretch_ratio=2.2
	for block in FieldGuide.OVERVIEW.split("\n\n",false):
		var lines := block.split("\n",false,1)
		if lines.size()==2:
			_pages.append({"title":lines[0].capitalize(),"text":lines[1]})
	_pages.append({"title":"Warbands & campaign","text":"Create and save a wizard, spellbook and recruits from the home screen. Select the warband slot before starting a battle. Each slot keeps separate campaign and battle progress. Starting rosters have a 400 gc budget, up to eight soldiers and up to four specialists. Apprentice recruitment costs 100 gc. Campaign headquarters handles recruitment, treasure, injuries, equipment, experience and improvements."})
	_pages.append({"title":"Scenarios","text":"Choose a battlefield from New Skirmish. Each scenario has its own treasure and special rules. Read its briefing before playing. The Scenarios section below describes the current digital implementation."})
	var profile := WarbandSlots.content_profile()
	if profile.enabled.has("red_king") and profile.allows("campaigns","red_king"):
		_pages.append({"title":"The Red King campaign","text":"Select the book under Rulebook content on Home. Start its ordered storyline in a fresh campaign. The Expedition page shows the next encounter and any departure blockers. Resolve treasure, prepare rituals, recruit and assign gear before leaving. The optional Veil and rescue-linked Mindscape can be skipped. In Act III, regular hiring and the base are unavailable; roll replacements and carry or discard new loot. The chronicle shows chapter progress."})
		_pages.append({"title":"Red King equipment","text":"Select an item in Equipment to read its implemented effects and available recipients. Artefacts must be studied before equipping; some items require a permanent spell or animal binding. Look for contextual battle actions and preparation options. Equipment in a sealed vault or carried by separated figures cannot be reassigned until reconciliation."})
	for id: String in ScenarioBriefing.available_entries(profile):
		_pages.append({"title":ScenarioBriefing.title(id),"text":ScenarioBriefing.description(id)})
	for page in _pages:
		_topics.add_item(str(page["title"]))
	_heading=Label.new()
	_heading.add_theme_font_size_override("font_size",34)
	_heading.add_theme_color_override("font_color",WorkshopUI.GOLD)
	_heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_heading)
	_body=RichTextLabel.new()
	_body.fit_content=false
	_body.scroll_active=true
	_body.add_theme_font_size_override("normal_font_size",27)
	_body.add_theme_constant_override("line_separation",10)
	_body.add_theme_constant_override("line_separation",7)
	_body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	col.add_child(_body)
	var row := HBoxContainer.new()
	col.add_child(row)
	var prev := Button.new()
	prev.text="Previous"
	prev.custom_minimum_size.y=64
	prev.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(prev)
	prev.pressed.connect(func() -> void:_show(posmod(_index-1,_pages.size())))
	var next := Button.new()
	next.text="Next"
	next.custom_minimum_size.y=64
	next.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(next)
	next.pressed.connect(func() -> void:_show(posmod(_index+1,_pages.size())))
	_topics.item_selected.connect(_show)
	_show(0)


func open(close_label: String="Close") -> void:
	action.text=close_label
	show_screen()


func _reflow() -> void:
	if _split!=null:
		_split.vertical=size.x<size.y


func _show(index: int) -> void:
	if index<0 or index>=_pages.size():
		return
	_index=index
	_topics.select(index)
	_heading.text=str(_pages[index]["title"])
	_body.text=str(_pages[index]["text"])
	_body.scroll_to_line(0)
