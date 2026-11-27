class_name FieldGuideDialog
extends AcceptDialog
## Read-only, shared reference accessible without instantiating a battle.
var _topics: OptionButton
var _body: RichTextLabel
var _pages: Array[Dictionary]=[]
var _heading: Label


func _ready() -> void:
	title="Field guide"
	theme=BattleTheme.create()
	exclusive=true
	var col := VBoxContainer.new()
	add_child(col)
	var intro := Label.new()
	intro.text="Rules & controls • choose a topic"
	intro.modulate=Color("c6b17d")
	col.add_child(intro)
	_topics=OptionButton.new()
	_topics.fit_to_longest_item=false
	_topics.custom_minimum_size.y=52
	col.add_child(_topics)
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
	_heading.add_theme_font_size_override("font_size",24)
	_heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_heading)
	_body=RichTextLabel.new()
	_body.fit_content=false
	_body.scroll_active=true
	_body.add_theme_font_size_override("normal_font_size",22)
	_body.add_theme_constant_override("line_separation",7)
	_body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	col.add_child(_body)
	var row := HBoxContainer.new()
	col.add_child(row)
	var prev := Button.new()
	prev.text="Previous"
	prev.custom_minimum_size.y=50
	prev.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(prev)
	prev.pressed.connect(func() -> void:_show(posmod(_topics.selected-1,_pages.size())))
	var next := Button.new()
	next.text="Next"
	next.custom_minimum_size.y=50
	next.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(next)
	next.pressed.connect(func() -> void:_show(posmod(_topics.selected+1,_pages.size())))
	_topics.item_selected.connect(_show)
	_show(0)


func open(close_label: String="Close") -> void:
	get_ok_button().text=close_label
	var bounds := PhoneSafeArea.safe_rect(get_parent().get_viewport(),14).size
	_body.custom_minimum_size=Vector2(minf(760,bounds.x*0.86),minf(410,bounds.y*0.56))
	PhoneSafeArea.popup_dialog(self)


func _show(index: int) -> void:
	if index<0 or index>=_pages.size():
		return
	_topics.select(index)
	_heading.text=str(_pages[index]["title"])
	_body.text=str(_pages[index]["text"])
	_body.scroll_to_line(0)
