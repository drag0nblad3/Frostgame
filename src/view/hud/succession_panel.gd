class_name SuccessionPanel
extends VBoxContainer
## Explicit succession or confirmed new campaign; never discard a save automatically.


var campaign: CampaignProgress
var changed: Callable
var restart: Callable
var message: Label
var new_name: LineEdit
var promote_button: Button
var reset_button: Button
var confirmation: ConfirmationDialog


func setup(p: CampaignProgress, callback: Callable, reset: Callable) -> void:
	campaign = p
	changed = callback
	restart = reset
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(message)
	new_name = LineEdit.new()
	new_name.placeholder_text = "Successor's name"
	add_child(new_name)
	promote_button = Button.new()
	promote_button.text = "Promote apprentice to wizard"
	add_child(promote_button)
	promote_button.pressed.connect(func() -> void:
		if CampaignSuccession.promote(campaign.data, new_name.text):
			changed.call())
	reset_button = Button.new()
	reset_button.text = "Start a new campaign…"
	add_child(reset_button)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Replace campaign?"
	confirmation.dialog_text = "The saved campaign will be replaced by the current drafted warband. This cannot be undone."
	confirmation.get_ok_button().text = "Replace campaign"
	add_child(confirmation)
	reset_button.pressed.connect(func() -> void: confirmation.popup_centered())
	confirmation.confirmed.connect(func() -> void: restart.call())


func refresh(in_battle: bool, deciding: bool) -> void:
	var d := campaign.data
	visible = not d.is_empty() and not in_battle and not deciding
	if not visible:
		return
	var fallen := not CampaignSuccession.living_wizard(d)
	var candidate := CampaignSuccession.candidate(d)
	message.visible = fallen
	new_name.visible = candidate >= 0
	promote_button.visible = new_name.visible
	if fallen:
		message.text = "Your wizard has died. Restore them if possible, promote an eligible apprentice, or begin a new campaign."
		if candidate >= 0:
			message.text += " Succession level: %d." % (int(d["level"]) - 6)
		else:
			message.text += " No eligible successor (requires a living apprentice and wizard level 6 or higher)."
