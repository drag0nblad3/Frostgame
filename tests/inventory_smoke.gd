extends SceneTree
## Exercise the actual campaign inventory and deployment with a temporary in-memory draft.

var scene: Node
var started := false


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	if started:
		return false
	started = true
	if not scene.has_method("_open_campaign"):
		quit(1)
		return true
	var draft := WarbandDraft.new(scene._figures)
	draft.choose_defaults()
	scene._campaign.start(draft.as_warband())
	scene._campaign.data["gold"] = 1000
	CampaignInventory.buy(scene._campaign.data, "healing")
	CampaignInventory.buy(scene._campaign.data, "gear_hand_weapon_damage")
	scene._open_campaign()
	var hq: CampaignPanel=scene._campaign_dialog
	if hq._sections.size()!=6 or not hq._sections[0].visible or hq._sections[2].visible or hq.begin.get_parent()!=hq._sections[0]:
		printerr("Campaign section navigation missing")
		quit(1)
		return true
	hq._show_section(2)
	if not hq.inventory.is_visible_in_tree() or hq._sections[0].visible:
		printerr("Equipment page navigation failed")
		quit(1)
		return true
	hq._show_section(0)
	var banner: BaseBanner = scene._campaign_dialog.base_banner
	if banner._art.texture == null or not banner._caption.text.contains("Expedition camp"):
		printerr("Headquarters art unavailable")
		quit(1)
		return true
	scene._campaign.data["resources"] = ["crystal_ball","scriptorium"]
	banner.refresh(scene._campaign.data)
	if banner._resources.get_child_count() != 2:
		printerr("Headquarters resource badges missing")
		quit(1)
		return true
	scene._campaign.data["resources"] = []
	banner.refresh(scene._campaign.data)
	var panel: InventoryPanel = scene._campaign_dialog.inventory
	if panel.loot.item_count != 2 or panel.recipient_choice.item_count < 4:
		printerr("Inventory controls failed")
		quit(1)
		return true
	if not CampaignInventory.assign_item(scene._campaign.data, 1, 2, scene._figures):
		quit(1)
		return true
	panel.refresh()
	scene._begin_campaign_battle()
	var s: GameState = scene.controller.state
	var found := false
	for f in s.figures:
		if f.campaign_id == 2:
			found = MagicEquipment.bonus(f, "damage", "hand_weapon") == 1
	if not found:
		printerr("Inventory deployment failed")
		quit(1)
		return true
	print("Inventory smoke passed")
	quit(0)
	return true
