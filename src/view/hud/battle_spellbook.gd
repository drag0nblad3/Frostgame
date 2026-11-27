class_name BattleSpellbook
extends ExpeditionScreen
## Read before committing to targeting. Uses the controller's already computed legal options.
signal chosen(key: String)

var _split: BoxContainer
var _list: ItemList
var _detail: VBoxContainer
var _rows: Array[Dictionary]=[]
var _index := 0


func _ready() -> void:
	build("CHOOSE SPELL","Select targets",_choose)
	_split=BoxContainer.new()
	_split.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override("separation",12)
	body.add_child(_split)
	_list=ItemList.new()
	_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_list.size_flags_stretch_ratio=0.9
	_list.custom_minimum_size.y=130
	_list.add_theme_font_size_override("font_size",25)
	_list.add_theme_constant_override("v_separation",16)
	_split.add_child(_list)
	_list.item_selected.connect(_inspect)
	_detail=WorkshopUI.scroll(_split)
	_detail.get_parent().size_flags_stretch_ratio=1.8


func open(state: GameState,options: Array[String]) -> void:
	_list.clear()
	_rows.clear()
	var caster := state.active()
	if caster==null:
		return
	subtitle.text="%s · Health %d/%d · %d actions remaining"%[caster.label(),caster.health,caster.def.health,caster.actions_left]
	var all: Array[String]=options.duplicate()
	for id: String in state.spellbooks.get(caster.side,{}):
		if not all.has(id):
			all.append(id)
	for key in all:
		var id := "enchant_weapon" if key=="enchant_ammo" else key
		if not state.spell_catalog.has(id):
			continue
		var spec: Dictionary=state.spell_catalog[id]
		var known: bool=state.spellbooks.get(caster.side,{}).has(id)
		var tn := int(state.spellbooks.get(caster.side,{}).get(id,spec["number"]))
		var available := options.has(key)
		var name_text := "Enchant Ammunition" if key=="enchant_ammo" else str(spec["name"])
		var mod := caster.roll_penalty()+WordMagic.modifier(state,id)+ActiveGear.casting_bonus(caster,id)+BaseRules.casting_bonus(caster.campaign_base,id)+RealityCracks.casting_modifier(state,id)+RedKingSinkhole.casting_modifier(state,caster)
		mod+=-2 if caster.spell_effects.has("furious_quill") else 0
		mod+=-2 if caster.affected_by_insects() else 0
		mod+=-2 if caster.def.role=="apprentice" else 0
		mod+=4 if caster.spell_effects.has("potion_empowerment") else 0
		mod+=5 if caster.next_cast_gear=="gear_gloves_casting" else 0
		mod+=PlaneWalk.penalty(caster,state.turn) if id=="plane_walk" else 0
		var chance := SpellReference.chance(id,tn,mod)
		if caster.next_cast_gear=="gear_wand_light":
			chance=roundi(100.0*(1.0-pow(1.0-chance/100.0,2)))
		_rows.append({"key":key,"id":id,"spec":spec,"name":name_text,"tn":tn,"known":known,"available":available,"chance":chance,"mod":mini(mod,10)})
		_list.add_item(("%s · TN %d"%[name_text,tn])+("" if available else " · —"),ActionArt.school(str(spec["school"])))
		if not available:
			_list.set_item_custom_fg_color(_list.item_count-1,WorkshopUI.MUTED)
	if _rows.is_empty():
		return
	_list.select(0)
	_inspect(0)
	show_screen()


func _inspect(i: int) -> void:
	_index=i
	var r := _rows[i]
	WorkshopUI.clear(_detail)
	WorkshopUI.label(_detail,r["name"],34,WorkshopUI.GOLD)
	WorkshopUI.label(_detail,"%s · TN %d"%[str(r["spec"]["school"]).capitalize(),r["tn"]],24)
	if r["known"] and r["spec"]["kind"]!="ritual":
		WorkshopUI.label(_detail,"%d%% CAST SUCCESS · Roll modifier %+d"%[r["chance"],r["mod"]],27,Color("a7d6da"))
		WorkshopUI.label(_detail,"Before empowerment, Fate Stone, scroll rescue and any subsequent resistance or attack roll.",19,WorkshopUI.MUTED)
	elif not r["known"]:
		WorkshopUI.label(_detail,"Scroll or Scroll Shield · Uses stored casting result.",22,WorkshopUI.GOLD)
	if not r["available"]:
		WorkshopUI.label(_detail,"Not castable now. No legal target, placement or action; campaign-only spells are prepared at headquarters.",22,Color("edaa91"))
	SpellReference.populate(_detail,r["id"],r["spec"],r["key"]=="enchant_ammo")
	action.text="Select targets · "+str(r["name"]) if r["available"] else "Unavailable now"
	action.disabled=not r["available"]


func _reflow() -> void:
	if _split!=null:
		_split.vertical=size.x<size.y


func _choose() -> void:
	if _rows.is_empty() or not _rows[_index]["available"]:
		return
	var key := "spell_"+str(_rows[_index]["key"])
	hide()
	chosen.emit(key)


func navigate_back() -> void:
	hide()
	chosen.emit("spell_cancel")
