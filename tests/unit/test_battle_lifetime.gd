extends TestCase


func test_controller_helpers_do_not_retain_discarded_battle() -> void:
	var c:=make_game(make_board(),[fig("thug",0,Vector2(5,5))],Dice.new(19))
	var controller_ref:=weakref(c)
	var state_ref:=weakref(c.state)
	var magic_ref:=weakref(c._magic)
	var movement_ref:=weakref(c._magic.movement)
	var deployment:=c.begin_deployment()
	var deployment_ref:=weakref(deployment)
	deployment=null
	c=null
	check(controller_ref.get_ref()==null,"discarded controller must be released")
	check(state_ref.get_ref()==null,"discarded game state must be released")
	check(magic_ref.get_ref()==null,"spell helper must be released")
	check(movement_ref.get_ref()==null,"nested rule helper must be released")
	check(deployment_ref.get_ref()==null,"deployment helper must be released")


func test_retained_rule_helper_does_not_own_controller() -> void:
	var c:=make_game(make_board(),[fig("thug",0,Vector2(5,5))],Dice.new(19))
	var movement:=c._magic.movement
	check(movement.c==c)
	var controller_ref:=weakref(c)
	c=null
	check(controller_ref.get_ref()==null)
	check(movement.c==null)
