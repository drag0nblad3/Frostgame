class_name RedKingPotionHooks
extends RefCounted
## Optional potion source restrictions and special consumption outcomes.


static func source_allowed(f: Figure,item: Dictionary,target: Figure) -> Variant:
	var gear := str(item.get("gear",""))
	if gear not in [RedKingCampaignGear.POTION_STAFF,RedKingCampaignGear.GOLDEN_BOTTLE]:
		return null
	return not (MagicEquipment.suppressed(f) or (target!=null and target!=f) or (gear==RedKingCampaignGear.POTION_STAFF and f.destroyed_weapons.has("staff")) or (gear==RedKingCampaignGear.GOLDEN_BOTTLE and int(item.get("bottle_doses",0))<=0))


static func consume(c: GameController,f: Figure,index: int) -> Variant:
	var item: Dictionary=f.items[index]
	var gear := str(item.get("gear",""))
	if gear==RedKingCampaignGear.POTION_STAFF:
		item.erase("potion")
		return true
	if gear==RedKingCampaignGear.GOLDEN_BOTTLE:
		item["bottle_doses"]=int(item["bottle_doses"])-1
		if int(item["bottle_doses"])==0:
			item.erase("potion")
		var roll := c.dice.d20()
		var success := StatRoll.succeeds(roll,f.effective_will()+f.roll_penalty(),4)
		c.emit("creature_test",{"id":f.id,"trait":"golden_bottle","roll":roll,"success":success})
		if not success:
			c.poison(f)
		return success
	if item.get("enchanted",false):
		var roll := RedKingMaterials.use_potion(f.items,index,c.dice)
		c.emit("enchanted_vial",{"id":f.id,"roll":roll,"retained":roll>=19})
		return true
	return null
