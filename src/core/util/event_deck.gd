class_name EventDeck
extends RefCounted
## Seeded, serializable draw-without-replacement event pool.
## Keep the returned plain dictionary in GameState.scenario_data.
static func create(cards: Array, dice: Dice) -> Dictionary:
	var pile := cards.duplicate(true)
	for i in range(pile.size()-1,0,-1):
		var j := dice.pick(i+1)
		var card: Variant=pile[i]
		pile[i]=pile[j]
		pile[j]=card
	return {"remaining":pile,"discard":[]}


static func draw(deck: Dictionary) -> Variant:
	var remaining: Array=deck.get("remaining",[])
	if remaining.is_empty():
		return null
	var card: Variant=remaining.pop_back()
	var discarded: Array=deck["discard"]
	discarded.append(card)
	return card


static func reshuffle(deck: Dictionary,dice: Dice) -> void:
	var cards: Array=deck.get("remaining",[]).duplicate(true)
	cards.append_array(deck.get("discard",[]))
	var fresh := create(cards,dice)
	deck["remaining"]=fresh["remaining"]
	deck["discard"]=fresh["discard"]
