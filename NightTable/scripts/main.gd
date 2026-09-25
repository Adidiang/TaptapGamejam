extends "res://scripts/ui_base.gd"

var profile := MemoryProfile.new()
var run := NightRun.new()
var battle: DuelEncounter
var ai_generation := 0
var choices: Array = []
var reward_context := ""
var reward_left := 0
var goods: Array = []
var notice := ""
var deck_return: Callable
var selecting_remove := false
var remove_cost := 0

func _ready() -> void:
	profile.persistence = not ("--capture" in OS.get_cmdline_user_args() or "--smoke" in OS.get_cmdline_user_args())
	profile.load_profile()
	_build_theme()
	show_menu()
	if "--capture" in OS.get_cmdline_user_args(): await _capture_screens()

func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	parent.add_child(row)
	return row

func _text(parent: Node,text: String,size_value: int = 18,color: Color = MUTED) -> Label:
	var label := _label(parent,text,size_value,color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _status() -> void:
	var row := _row(page)
	_label(row,"生命 %d / 100   ·   第 %d 幕 %s" % [run.hp,run.act+1,GameCatalog.ACTS[run.act]],20,GOLD).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(row,"牌库 %d   /   已升级 %d   /   放下旧记忆 %d / 8" % [profile.cards.size(),profile.upgrades.size(),profile.removed_old],16,MUTED)
	if not profile.save_error.is_empty(): _text(page,profile.save_error,15,Color("df8b79"))

func show_menu() -> void:
	_new_page("menu","","一张牌，一段记忆。")
	var body := _row(page)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 460
	body.add_child(left)
	_spacer(left)
	_label(left,"余 夜",92,GOLD)
	_label(left,"N I G H T   T A B L E",22,MUTED)
	_label(left,"你又回到了那一夜。\n桌上的牌，还记得你。",24)
	_spacer(left)
	if run.active: _button(left,"继续本轮     →",show_map)
	else: _button(left,"开始轮回     →",start_run)
	_button(left,"记忆牌库",func(): open_deck(show_menu))
	_button(left,"玩法说明",func(): show_rules(show_menu))
	_button(left,"退出",func(): get_tree().quit())
	_spacer(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	_spacer(right)
	var stage := TableStage.new()
	stage.custom_minimum_size = Vector2(400,300)
	right.add_child(stage)
	_label(right,"轮回 %d    /    已放下 %d 段旧记忆" % [profile.loops,profile.removed_old],18,GOLD)
	_text(right,"永久保存牌库、升级与删牌记录。当前路线不跨退出保存。",16)
	_spacer(right)
	_text(page,"题材提示：创伤记忆、入室犯罪与死亡。当前使用静态占位表现，无闪烁与血腥。",15)
	if not profile.save_error.is_empty(): _text(page,profile.save_error,15,Color("df8b79"))

func start_run(seed_override: int = -1) -> void:
	if run.active: return
	run.begin(seed_override if seed_override >= 0 else int(Time.get_unix_time_from_system()*1000)%2147483647,profile)
	_open_reward("opening",1)

func show_map() -> void:
	_new_page("map","夜的路径","选择一条路线。未选择的记忆，将留在这一夜。")
	_status()
	var map_panel := PanelContainer.new()
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.add_theme_stylebox_override("panel",_style(Color("132127"),Color("304147")))
	page.add_child(map_panel)
	var route := RouteView.new()
	route.configure(run)
	route.node_selected.connect(enter_node)
	map_panel.add_child(route)
	_label(page,"♠  牌桌     ?  回声     ◇  交换     +  喘息     ♛  最后一手",18,MUTED)
	var row := _row(page)
	_button(row,"记忆牌库",func(): open_deck(show_map))
	_button(row,"玩法说明",func(): show_rules(show_map))
	_button(row,"主界面",show_menu)
	_text(page,"本幕 Boss · %s    |    种子 %d" % [GameCatalog.BOSSES[run.act],run.run_seed],16)
	if not run.relics.is_empty(): _text(page,"遗物："+_relic_names(),16,GOLD)

func _relic_names() -> String:
	var names: Array[String] = []
	for id in run.relics: names.append(GameCatalog.RELICS[id][0])
	return " · ".join(names)

func enter_node(node_id: int) -> void:
	if not run.enter(node_id): return
	notice = ""
	match run.current_node.kind:
		"encounter","boss": show_stake()
		"shop":
			_make_goods()
			show_shop()
		_: show_event()

func show_stake() -> void:
	var boss: bool = run.current_node.kind == "boss"
	_new_page("stake","最后一手" if boss else "落座之前","你能承受多少，便带多少上桌。")
	_status()
	_spacer(page)
	var content := _panel(page)
	var amount := mini(run.hp,run.nominal_stake())
	_label(content,"质押  %d  /  生命 %d" % [amount,run.hp],42,GOLD)
	if boss:
		_text(content,"新版负荷牌局 · 单局全押",24,TEXT)
		_text(content,"单手全押：赢则回满生命，未爆但输则留1血；爆牌结束轮回。最终Boss必须赢下才能离开。",20)
	else:
		_text(content,"固定打满三手。2胜：质押全返并回复5生命；1胜：收回余量；0胜或质押耗尽：质押全失。",20)
		_text(content,"基础注 %d。在场牌1–3张损失1份，第4张2份，5张及以上3份。" % maxi(1,roundi(amount/10.0)),18)
	_text(content,"新版对战：旧技能、遗物、道具与Boss特殊能力暂不生效；局外获得与存档仍保留。",16)
	_button(content,"质押并发牌     →",begin_battle,260)
	_spacer(page)
	_text(page,"生命不足时使用全部剩余生命。普通遭遇失败也可继续，并获得整理牌库的机会。",16)

func begin_battle() -> void:
	if screen != "stake": return
	battle = DuelEncounter.new()
	battle.start(run)
	show_encounter()

func show_encounter() -> void:
	ai_generation += 1
	DuelView.render(self)
	if battle.phase == DuelEncounter.Phase.PLAYING and battle.duel.active == 1 and not ("--smoke" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_user_args()):
		_opponent_tick(ai_generation)

func _opponent_tick(generation: int) -> void:
	await get_tree().create_timer(0.65).timeout
	if not is_inside_tree() or screen != "encounter" or generation != ai_generation: return
	if battle.phase != DuelEncounter.Phase.PLAYING: return
	battle.duel.opponent_step()
	battle.resolve_if_finished()
	show_encounter()

func duel_action(action: String) -> void:
	if screen != "encounter" or battle.phase != DuelEncounter.Phase.PLAYING: return
	match action:
		"draw": battle.duel.draw(0)
		"stop": battle.duel.stop(0)
		"end_turn": battle.duel.end_turn(0)
	battle.resolve_if_finished()
	show_encounter()

func play_function(index: int) -> void:
	if screen != "encounter" or battle.phase != DuelEncounter.Phase.PLAYING: return
	battle.duel.play(0,index)
	battle.resolve_if_finished()
	show_encounter()

func discard_function(index: int) -> void:
	if screen != "encounter" or battle.phase != DuelEncounter.Phase.PLAYING: return
	battle.duel.discard_function(0,index)
	show_encounter()

func next_duel() -> void:
	if screen != "encounter": return
	battle.deal_hand()
	show_encounter()

func settle_battle() -> void:
	if screen != "encounter" or battle.phase != DuelEncounter.Phase.MATCH_OVER: return
	if run.hp <= 0:
		run.finish_run(false)
		show_ending()
	elif battle.boss:
		if battle.outcome == "success": _open_reward("boss",1)
		else: _finish_node()
	else: _open_reward(battle.outcome,2 if battle.outcome == "disaster" else 1)

func _open_reward(context: String,count: int) -> void:
	reward_context = context
	reward_left = count
	choices.clear()
	if context == "boss":
		var candidates: Array = []
		for id in GameCatalog.RELICS:
			if id not in run.relics: candidates.append(id)
		while not candidates.is_empty() and choices.size() < 3 and run.relics.size() < 6:
			var i := run.rng.randi_range(0,candidates.size()-1)
			choices.append({"type":"relic","id":candidates[i]})
			candidates.remove_at(i)
		if choices.is_empty(): choices.append({"type":"heal","amount":15})
	else:
		if context in ["opening","success","event","rest"]:
			for rank in profile.upgrade_choices(run.rng): choices.append({"type":"upgrade","rank":rank})
		if context != "opening": choices.append({"type":"remove"})
		if context in ["success","failure"]:
			choices.append({"type":"add","rank":run.rng.randi_range(10,13) if context == "success" else run.rng.randi_range(2,6),"suit":run.rng.randi_range(0,3)})
		if context in ["event","rest"] or choices.is_empty(): choices.append({"type":"heal","amount":18 if context == "rest" else 12})
	show_reward()

func _choice_text(choice: Dictionary) -> String:
	match choice.type:
		"upgrade": return "升级  "+GameCatalog.skill_text(choice.rank)
		"remove": return "放下一段记忆\n永久移除一张牌；旧记忆会推进真正的出口。"
		"add": return "收下一张 %s%s\n%s" % [MemoryCard.new(choice.rank,choice.suit).suit_text(),GameCatalog.rank_name(choice.rank),"旧记忆 · 接近21的捷径" if choice.rank>=10 else "新未来 · 更容易凑成五龙"]
		"relic": return GameCatalog.RELICS[choice.id][0]+"\n"+GameCatalog.RELICS[choice.id][1]
		"heal": return "稳定呼吸\n回复%d点生命。" % choice.amount
	return ""

func show_reward() -> void:
	var titles := {"opening":"带上一份力量","success":"你赢过了思绪","failure":"失去一些，留下选择","disaster":"整理破碎的记忆","boss":"从歹徒手中带走","event":"熟悉的回声","rest":"灯下喘息"}
	_new_page("reward",titles.get(reward_context,"选择"),"选择一项。牌库改造会永久保留；遗物只陪伴这一轮。")
	_status()
	if reward_context == "disaster": _label(page,"可删除最多 %d 张牌，也可以直接离开。" % reward_left,18,GOLD)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",18)
	grid.add_theme_constant_override("v_separation",14)
	page.add_child(grid)
	for index in range(choices.size()):
		var choice: Dictionary = choices[index]
		var button := _button(grid,_choice_text(choice),func(): choose_reward(index),600)
		button.custom_minimum_size.y = 100
		button.add_theme_font_size_override("font_size",18)
		button.disabled = (choice.type == "remove" and profile.cards.size() <= 20) or (choice.type == "add" and profile.cards.size() >= 60)
	_spacer(page)
	_button(page,"跳过 / 继续",_finish_reward,240)

func choose_reward(index: int) -> void:
	if screen != "reward" or reward_left <= 0 or index not in range(choices.size()): return
	var choice: Dictionary = choices[index]
	match choice.type:
		"remove":
			selecting_remove = true
			remove_cost = 0
			open_deck(show_reward,true)
			return
		"upgrade":
			if not profile.upgrade(choice.rank): return
		"add":
			if not profile.add_card(choice.rank,choice.suit): return
		"relic":
			if not run.add_relic(choice.id): return
		"heal": run.heal(choice.amount)
	_finish_reward()

func _finish_reward() -> void:
	if reward_left <= 0: return
	reward_left = 0
	if reward_context == "opening": show_map()
	else: _finish_node()

func _finish_node() -> void:
	run.finish_node()
	if run.active: show_map()
	else: show_ending()

func show_event() -> void:
	_open_reward("rest" if run.current_node.kind == "rest" else "event",1)

func _make_goods() -> void:
	goods = [{"type":"item","id":"undo","cost":6},{"type":"item","id":"peek","cost":5},{"type":"item","id":"heal","cost":5},{"type":"remove","cost":8}]
	var upgrades := profile.upgrade_choices(run.rng,1)
	if not upgrades.is_empty(): goods.append({"type":"upgrade","rank":upgrades[0],"cost":10})
	for id in GameCatalog.RELICS:
		if id not in run.relics:
			goods.append({"type":"relic","id":id,"cost":14})
			break

func show_shop() -> void:
	_new_page("shop","以记忆交换","这里不收进门费。每件货物限买一次；购买后至少保留1点生命。")
	_status()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",16)
	grid.add_theme_constant_override("v_separation",14)
	page.add_child(grid)
	for i in range(goods.size()):
		var good: Dictionary = goods[i]
		var description := ""
		if good.type == "item": description = GameCatalog.ITEMS[good.id][0]+"\n"+GameCatalog.ITEMS[good.id][1]
		else: description = _choice_text(good)
		var button := _button(grid,"%s\n代价：%d 生命%s" % [description,good.cost," · 已购买" if good.get("sold",false) else ""],func(): buy_good(i),600)
		button.add_theme_font_size_override("font_size",16)
		button.custom_minimum_size.y = 115
		button.disabled = good.get("sold",false) or run.hp <= good.cost or (good.type == "item" and run.items.size() >= 3) or (good.type == "remove" and profile.cards.size() <= 20) or (good.type == "relic" and run.relics.size() >= 6)
	_spacer(page)
	_label(page,notice if not notice.is_empty() else "道具 %d / 3 · 遗物 %d / 6" % [run.items.size(),run.relics.size()],18,GOLD)
	_button(page,"离开，继续前进     →",_finish_node,280)

func buy_good(index: int) -> void:
	if screen != "shop" or index not in range(goods.size()): return
	var good: Dictionary = goods[index]
	if good.get("sold",false) or run.hp <= good.cost: return
	match good.type:
		"remove":
			remove_cost = good.cost
			selecting_remove = true
			open_deck(show_shop,true)
			return
		"item":
			if run.items.size() >= 3: return
			run.items.append(good.id)
		"upgrade":
			if not profile.upgrade(good.rank): return
		"relic":
			if not run.add_relic(good.id): return
	run.hp -= good.cost
	good.sold = true
	notice = "交换完成。"
	show_shop()

func open_deck(return_action: Callable,remove_mode: bool = false) -> void:
	deck_return = return_action
	selecting_remove = remove_mode
	_new_page("deck","放下一张牌" if remove_mode else "记忆牌库","点击一张牌将永久删除，无法撤销。" if remove_mode else "金色技能名表示该点数已升级，所有花色共享。")
	_label(page,"%d / 60 张 · 最少保留20张 · 累计放下旧记忆 %d / 8" % [profile.cards.size(),profile.removed_old],20,GOLD)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	for entry in profile.cards:
		var card := MemoryCard.new(entry.rank,entry.suit)
		var text := "%s %s\n%s\n%s" % [card.suit_text(),card.rank_text(),card.memory_text(),GameCatalog.SKILLS[card.rank][0] if card.rank in profile.upgrades else "未升级"]
		var button := _button(grid,text,func(): delete_card(entry.id),143)
		button.custom_minimum_size.y = 113
		button.add_theme_font_size_override("font_size",16)
		button.disabled = not remove_mode or profile.cards.size() <= 20
		button.tooltip_text = GameCatalog.skill_text(card.rank)
		if card.rank in profile.upgrades: button.add_theme_color_override("font_disabled_color",GOLD)
	_button(page,"取消" if remove_mode else "返回",return_action,200)

func delete_card(id: String) -> void:
	if screen != "deck" or not selecting_remove or run.hp <= remove_cost: return
	if not run.remove_memory(id): return
	selecting_remove = false
	if remove_cost > 0:
		run.hp -= remove_cost
		for good in goods:
			if good.type == "remove": good.sold = true
		notice = "已放下一张牌。"
		show_shop()
	else:
		reward_left -= 1
		if reward_left > 0: show_reward()
		else:
			reward_left = 1
			_finish_reward()

func show_ending() -> void:
	var title: String = {"release":"终于，天亮了","dawn":"你走出了那扇门","again":"再次醒来"}.get(run.ending,"再次醒来")
	_new_page("ending",title,"记忆没有消失，但你已经不同。")
	_spacer(page)
	var story: String = {"release":"你不再回头确认门锁。\n清晨的空气里，有陌生而真实的声音。","dawn":"你赢了最后一手。\n那些旧记忆仍在，但你已经看见了出口。","again":"那盏灯还亮着。\n这一次失败，也留下了改变的机会。"}.get(run.ending,"")
	_label(page,story,34,GOLD)
	_label(page,"到达：%s · 经过 %d 个节点\n剩余生命 %d · 牌库 %d 张\n已放下旧记忆 %d / 8" % [GameCatalog.ACTS[run.act],run.total_visited,run.hp,profile.cards.size(),profile.removed_old],22)
	_text(page,run.legacy_text,22,TEXT)
	_spacer(page)
	var row := _row(page)
	_button(row,"开始下一轮",start_run,240)
	_button(row,"主界面",show_menu,200)
	_spacer(page)

func show_rules(back_action: Callable) -> void:
	_new_page("rules","数字与负荷","局内规则 · 新版试作")
	var content := _panel(page)
	for text in ["数字牌明置，功能牌自己可见、对方只见牌背。每张牌负荷1–5，总负荷上限21。","开局各抽2张，你先操作，不额外摸牌。之后回合开始选择摸一张或停牌。","效果牌主动使用；加成牌留到结算；陷阱自动触发一次。三类牌均可主动弃掉释放负荷。","摸牌后负荷超过21立即判负，没有爆牌救场。功能槽3格，满槽摸到功能牌直接弃掉，不增加负荷。","自己停牌后陷阱仍响应对方行动。双方停牌比较结算点数：先加固定值，再加百分比，最后向下取整。","初始发牌不触发陷阱，摸牌超限先判负。弃牌不回收，牌库空后下次回合自动停牌。","局外暂保留：普通遭遇三局、Boss一局，前两次平局重开、第三次普通判胜/Boss判负。","过渡说明：A–9映射数字牌，10/J/Q/K映射功能牌。旧点数技能、道具、遗物及Boss特殊能力暂不作用于新版牌局。"]:
		_text(content,text,18,TEXT)
	_spacer(page)
	_button(page,"返回",back_action,220)

func _capture_screens() -> void:
	for target in ["menu","map","encounter","encounter_full","encounter_settlement","reward","shop","deck","ending"]:
		match target:
			"menu": show_menu()
			"map":
				start_run(217)
				choose_reward(0)
			"encounter":
				enter_node(run.available_ids()[0])
				begin_battle()
			"encounter_full":
				battle.duel.sides[0].functions.clear()
				for i in [0,7,10]: battle.duel.sides[0].functions.append(CombatCatalog.function_card(i).instance(900+i))
				battle.duel.sides[0].numbers.clear()
				for i in range(8): battle.duel.sides[0].numbers.append(CombatCatalog.number_card(i+1,1).instance(950+i))
				show_encounter()
			"encounter_settlement":
				battle.duel.sides[0].stopped = true
				battle.duel.sides[1].functions.assign([CombatCatalog.function_card(8).instance(999)])
				battle.duel.sides[1].stopped = true
				battle.duel._advance()
				battle.resolve_if_finished()
				show_encounter()
			"reward": _open_reward("success",1)
			"shop":
				_make_goods()
				show_shop()
			"deck": open_deck(show_map)
			"ending":
				run.finish_run(false)
				show_ending()
		for frame in range(8): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://captures/"+target+".png")
	get_tree().quit()
