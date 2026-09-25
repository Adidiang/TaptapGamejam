extends SceneTree
var checks := 0
var serial := 1000

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		push_error("FAIL: "+message)
		quit(1)
		assert(condition,message)

func memory() -> MemoryProfile:
	var p := MemoryProfile.new()
	p.persistence = false
	return p

func fresh(boss_act: int = -1) -> BlackjackMatch:
	var run := NightRun.new()
	run.begin(217,memory())
	run.enter(run.available_ids()[0])
	if boss_act >= 0:
		run.act = boss_act
		run.current_node.kind = "boss"
	var b := BlackjackMatch.new()
	b.start(run)
	return b

func cards(ranks: Array) -> Array[MemoryCard]:
	var result: Array[MemoryCard] = []
	for rank in ranks:
		var card := MemoryCard.new(rank,0)
		serial += 1
		card.id = str(serial)
		result.append(card)
	return result

func rig(b: BlackjackMatch,hand: Array,dealer_hand: Array,draws: Array = [],dealer_draws: Array = []) -> void:
	b.player.hand.assign(cards(hand))
	b.dealer.hand.assign(cards(dealer_hand))
	b.player.draw_pile.assign(cards(draws))
	b.player.draw_pile.reverse()
	b.dealer.draw_pile.assign(cards(dealer_draws))
	b.dealer.draw_pile.reverse()
	b.player.discard_pile.clear()
	b.dealer.discard_pile.clear()
	b.phase = BlackjackMatch.Phase.PLAYER
	b.reduction = 0
	b.multipliers.clear()
	b.triggered.clear()
	b.discount = 0
	b.extra_dealer = 0
	b.next_multiplier = 1
	b.item_used = false
	b.last_hit_id = ""
	b.hand_result = ""

func _run() -> void:
	_test_maps()
	_test_cards()
	_test_hands()
	_test_effects()
	_test_results()
	_test_persistence()
	_simulate_runs()
	load("res://tests/load_duel_test.gd").new().test(check)
	load("res://tests/passive_test.gd").new().test(check)
	await _test_ui()
	print("PASS: %d checks; new load duels, legacy regression, economy, persistence and UI flow" % checks)
	quit(0)

func _test_maps() -> void:
	for seed_value in range(100):
		var layers := RouteGenerator.generate(seed_value)
		check(layers == RouteGenerator.generate(seed_value),"deterministic map")
		var reachable: Array = [layers[0][0].id]
		for row in range(layers.size()):
			var next_reachable: Array = []
			for node in layers[row]:
				check(node.id in reachable,"reachable node")
				if row < layers.size()-1: check(not node.next.is_empty(),"no dead end")
				next_reachable.append_array(node.next)
			reachable = next_reachable
	var run := NightRun.new()
	run.begin(1,memory())
	check(not run.enter(999),"invalid node blocked")
	check(run.enter(0),"start accessible")
	check(run.available_ids().is_empty(),"pending node blocks progression")

func _test_cards() -> void:
	var p := memory()
	check(p.add_card(1,0),"duplicate faces allowed")
	var keys: Dictionary = {}
	for card in p.cards: keys[card.id] = true
	check(keys.size() == 53,"unique instance ids")
	var d := p.make_deck(10)
	for i in range(53): check(d.draw_card() != null,"draw all cards")
	check(d.draw_card() == null,"exhausted hand has no cards")
	d.discard_hand()
	check(d.draw_card() != null,"recycle discard")
	check(d.draw_pile.size()+d.hand.size()+d.discard_pile.size() == 53,"conservation")
	d.hand.assign(cards([1,1,13]))
	check(d.hand_points() == 12,"multiple ace scoring")
	while p.cards.size() > 20: p.remove_card(p.cards[0].id)
	check(not p.remove_card(p.cards[0].id),"minimum deck enforced")
	while p.cards.size() < 60: p.add_card(2,0)
	check(not p.add_card(2,0),"maximum deck enforced")

func _test_hands() -> void:
	var b := fresh()
	rig(b,[10,7],[1,6])
	b.stand()
	check(b.ties == 1 and b.resolved == 0,"soft17 stands, tie doesn't count")
	for i in range(2):
		rig(b,[10,7],[1,6])
		b.stand()
	check(b.wins == 1 and b.resolved == 1,"third tie wins ordinary")
	b = fresh(0)
	rig(b,[10,7],[10,7],[],[2])
	b.stand()
	check(b.dealer.hand.size() == 3 and b.run.hp == 1,"boss18 draws on17")
	b = fresh(2)
	rig(b,[10,8],[10,7],[2])
	check(not b.can_stand(),"boss3 minimum cards")
	b.hit()
	check(b.can_stand(),"boss3 third card permits stand")
	b = fresh()
	rig(b,[2,2],[10,7],[2,2,2])
	for i in range(3): b.hit()
	check(b.wins == 1 and b.hand_result.contains("五龙"),"five card win")
	var before := b.player.hand.size()
	b.hit()
	check(b.player.hand.size() == before,"settled hand locks input")
	b = fresh()
	rig(b,[10,8],[10,7],[10])
	b.hit()
	check(b.phase == BlackjackMatch.Phase.BUST_WINDOW and b.pool == 50,"bust grace before losses")
	b.use_item("undo")
	check(b.score() == 18 and b.player.hand.size() == 2,"undo saves bust")
	check(not b.can_use("undo"),"item consumed")
	b = fresh()
	rig(b,[1,12],[1,13])
	check(b.is_blackjack(b.player),"face card natural")
	b._win("黑杰克")
	check(b.wins == 1,"player natural wins even dealer natural")
	for act in range(3):
		b = fresh(act)
		rig(b,[10,10],[10,9],[10])
		b.hit()
		b.confirm_bust()
		check(b.run.hp == 0 and b.outcome == "disaster","boss bust ends run")
	b = fresh(1)
	check(b.player.draw_pile.size()+b.player.hand.size() == 51,"stolen card excluded")
	check(b.run.profile.cards.size() == 52,"steal not permanent")

func _test_effects() -> void:
	var b := fresh()
	b.run.profile.upgrades.assign([2,3,5,8,9,10,11,12])
	rig(b,[10,8],[10,7],[12,10])
	b.hit()
	check(b.score() == 20 and b.triggered.has("saved_q"),"Q saves once")
	b.hit()
	check(b.phase == BlackjackMatch.Phase.BUST_WINDOW,"second bust not saved")
	rig(b,[8,2],[10,7],[1])
	b._on_draw(b.player.hand[0])
	b.hit()
	check(b.score() == 12,"double ace uses2 instead of22")
	rig(b,[5,7],[10,7],[9])
	b.swapped = false
	b.swap_five()
	check(b.score() == 16 and b.discount == b.base_bet,"swap triggers replacement")
	check(not b.can_swap(),"swap once")
	rig(b,[2,2],[10,7],[3,11])
	b.pool = 40
	b._on_draw(b.player.hand[0])
	b._on_draw(b.player.hand[1])
	check(b.pool == 42,"same rank skill once")
	b.hit()
	check(b.peek_text.contains("J"),"peek top info")
	b.hit()
	check(b.reveal,"J reveals dealer")
	b = fresh()
	b.run.profile.upgrades.assign([4,9])
	b.run.relics.assign(["shield"])
	rig(b,[4,9],[10,10])
	b._on_draw(b.player.hand[1])
	check(b.current_loss() == 0,"loss floors at zero")
	b.stand()
	check(b.pool == 50,"zero loss doesn't become heal")
	b = fresh(0)
	b.run.items.assign(["peek","undo"])
	rig(b,[10,8],[10,8])
	b.use_item("peek")
	b.stand()
	check(b.phase == BlackjackMatch.Phase.HAND_OVER,"boss tie reopens")
	b.deal_hand()
	check(b.boss_item_used,"boss item limit survives tie")

func _test_results() -> void:
	for win_count in range(4):
		var b := fresh()
		b.wins = 0
		b.losses = 0
		b.resolved = 0
		for i in range(3):
			rig(b,[10,9] if i < win_count else [10,6],[10,8])
			b.stand()
		check(b.phase == BlackjackMatch.Phase.MATCH_OVER,"three hand end")
		var expected := 50 if win_count == 0 else (90 if win_count == 1 else 100)
		check(b.run.hp == expected,"match settlement %d" % win_count)
	var b := fresh()
	b.pool = 1
	rig(b,[10,6],[10,8])
	b.stand()
	check(b.outcome == "disaster" and b.resolved == 1,"pool exhaustion early end")

func _test_persistence() -> void:
	var p := memory()
	p.persistence = true
	p.save_path = "user://qa_profile_roundtrip.json"
	p.upgrade(6)
	p.add_card(2,1)
	p.remove_card(p.cards[0].id)
	check(p.save_error.is_empty(),"atomic save replace")
	var loaded := memory()
	loaded.persistence = true
	loaded.save_path = p.save_path
	loaded.load_profile()
	check(loaded.cards == p.cards and loaded.upgrades == p.upgrades and loaded.removed_old == 1,"profile roundtrip")
	check(loaded.next_id == p.next_id,"restore next unique id")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p.save_path))

func _simulate_runs() -> void:
	var victories := 0
	var completed := 0
	for seed_value in range(120):
		var run := NightRun.new()
		var p := memory()
		for rank in [2,4,6,7,12]: p.upgrade(rank)
		run.begin(seed_value,p)
		var steps := 0
		while run.active and steps < 30:
			steps += 1
			check(run.enter(run.available_ids()[0]),"simulation node entry")
			if run.current_node.kind in ["encounter","boss"]:
				var b := BlackjackMatch.new()
				b.start(run)
				var actions := 0
				while b.phase != BlackjackMatch.Phase.MATCH_OVER and actions < 100:
					actions += 1
					match b.phase:
						BlackjackMatch.Phase.PLAYER:
							if b.score() < 17 or not b.can_stand(): b.hit()
							else: b.stand()
						BlackjackMatch.Phase.BUST_WINDOW:
							if b.can_use("undo"): b.use_item("undo")
							else: b.confirm_bust()
						BlackjackMatch.Phase.HAND_OVER: b.deal_hand()
					check(b.pool >= 0 and b.pool <= b.stake,"pool bound")
				check(actions < 100,"no deadlocked hand")
			else: run.heal(18)
			run.finish_node()
			check(run.hp in range(101),"health bounds")
		check(not run.active,"run terminates")
		completed += 1
		if run.ending != "again": victories += 1
	print("SIM: %d / %d victories, simple stand-at17 policy with 5 upgrades" % [victories,completed])

func _test_ui() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	# --smoke suppresses real-profile load/writes in _ready.
	root.add_child(app)
	await process_frame
	check(not app.profile.persistence,"UI tests never modify real profile")
	app.start_run(217)
	check(app.screen == "reward","opening upgrade choice")
	app.choose_reward(0)
	check(app.screen == "map","opening choice goes to map")
	app.enter_node(app.run.available_ids()[0])
	check(app.screen == "stake","stake disclosure")
	app.begin_battle()
	check(app.screen == "encounter","actual battle screen")
	var secret := CombatCatalog.function_card(0)
	secret.title = "PRIVATE_SENTINEL"
	secret.description = "PRIVATE_SENTINEL"
	app.battle.duel.sides[1].functions.assign([secret.instance(99999)])
	app.show_encounter()
	check(not _ui_contains(app.page,"PRIVATE_SENTINEL"),"opponent secret absent from UI labels and tooltips")
	for passive_index in [7,10]:
		var passive := CombatCatalog.function_card(passive_index)
		passive.title = "HIDDEN_PASSIVE"
		passive.description = "HIDDEN_PASSIVE"
		app.battle.duel.sides[1].functions.assign([passive.instance(99998)])
		app.show_encounter()
		check(not _ui_contains(app.page,"HIDDEN_PASSIVE"),"opponent passive identity absent from labels/tooltips")
	app.battle.duel.sides[1].functions.assign([secret.instance(99999)])
	app.duel_action("end_turn")
	check(app.battle.duel.active == 1,"UI end turn hands off to AI")
	var before_turns: int = app.battle.duel.turns
	var before_functions: int = app.battle.duel.sides[1].functions.size()
	await app._opponent_tick(app.ai_generation)
	check(app.battle.duel.turns > before_turns or app.battle.duel.sides[1].functions.size() < before_functions,"timed AI action executes")
	var stale: int = app.ai_generation
	app.show_encounter()
	before_turns = app.battle.duel.turns
	await app._opponent_tick(stale)
	check(app.battle.duel.turns == before_turns,"stale UI timer ignored")
	var iterations := 0
	while app.battle.phase != DuelEncounter.Phase.MATCH_OVER and iterations < 2000:
		iterations += 1
		if app.battle.phase == DuelEncounter.Phase.HAND_OVER: app.battle.deal_hand()
		else:
			load("res://tests/load_duel_test.gd").step(app.battle.duel)
			app.battle.resolve_if_finished()
	check(iterations < 2000,"new UI encounter terminates")
	app.show_encounter()
	app.settle_battle()
	check(app.screen == "reward","battle offers reward")
	app._finish_reward()
	check(app.screen == "map","reward advances route")
	app._make_goods()
	app.show_shop()
	var before: int = app.run.hp
	app.buy_good(0)
	check(app.run.hp == before-6,"shop payment")
	app.buy_good(0)
	check(app.run.hp == before-6,"shop purchase idempotent")
	app._open_reward("disaster",2)
	app.choose_reward(0)
	check(app.screen == "deck","delete selector opens")
	var size_before: int = app.profile.cards.size()
	app.delete_card(app.profile.cards[0].id)
	check(app.profile.cards.size() == size_before-1 and app.reward_left == 1,"first of two removals")
	app.run.finish_run(false)
	var loops: int = app.profile.loops
	app.run.finish_run(false)
	check(app.profile.loops == loops,"ending reward once")
	app.show_ending()
	app.show_rules(app.show_menu)
	app.show_menu()
	await process_frame
	app.queue_free()
	await process_frame

func _ui_contains(node: Node, value: String) -> bool:
	if (node is Label or node is Button) and value in node.text: return true
	if node is Control and value in node.tooltip_text: return true
	for child in node.get_children():
		if _ui_contains(child,value): return true
	return false
