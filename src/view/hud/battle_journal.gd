class_name BattleJournal
extends ExpeditionScreen
## Read-only recent battle history. No controller access or state changes.
const LIMIT := 160
var _text: RichTextLabel


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


func open(entries: Array[String]) -> void:
	subtitle.text="Recent events and resolved rolls · %d entries"%entries.size()
	_text.text="No events recorded yet." if entries.is_empty() else "\n\n".join(entries)
	show_screen()
	call_deferred("_latest")


func _latest() -> void:
	if visible and _text.get_line_count()>0:
		_text.scroll_to_line(_text.get_line_count()-1)


static func record(entries: Array[String],line: String) -> void:
	if line.is_empty():
		return
	entries.append(line)
	if entries.size()>LIMIT:
		entries.pop_front()
