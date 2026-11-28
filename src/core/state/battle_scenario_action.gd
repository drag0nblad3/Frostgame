class_name BattleScenarioAction
extends RefCounted
## Scenario choices use the same command recorder as ordinary battle actions.
## The expansion owns validation, side effects and continuation of turn flow.


static func execute(c: GameController,key: String,args: Dictionary={}) -> bool:
	if not BattleSnapshot.plain(args):
		return false
	return BattleRecord.run(c,"scenario_command",{"key":key,"args":args},func() -> bool:
		if key=="core_choice":
			return CoreScenarioChoice.choose(c,int(args.get("index",-1)))
		var result: Variant=RuleHooks.first("scenario_command",[c,key,args])
		return result!=null and bool(result))
