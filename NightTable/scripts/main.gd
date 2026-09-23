extends "res://scripts/ui_base.gd"

var profile := MemoryProfile.new()
var run := NightRun.new()
var battle: BlackjackMatch
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
		_text(content,GameCatalog.BOSSES[run.act],24,TEXT)
		_text(content,"单手全押：赢则回满生命，未爆但输则留1血；爆牌结束轮回。最终Boss必须赢下才能离开。",20)
	else:
		_text(content,"固定打满三手。2胜：质押全返并回复5生命；1胜：收回余量；0胜或质押耗尽：质押全失。",20)
		_text(content,"基础注 %d。手牌1–3张损失1份，第4张2份，第5张3份。技能与遗物可减损。" % maxi(1,roundi(amount/10.0)),18)
	_button(content,"质押并发牌     →",begin_battle,260)
	_spacer(page)
	_text(page,"生命不足时使用全部剩余生命。普通遭遇失败也可继续，并获得整理牌库的机会。",16)

func begin_battle() -> void:
	if screen != "stake": return
	battle = BlackjackMatch.new()
	battle.start(run)
	show_encounter()

func _cards(parent: Node,cards: Array[MemoryCard],hidden_index: int = -1,small: bool = false) -> void:
	var row := _row(parent)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(cards.size()):
		var card := cards[i]
		var hidden := i == hidden_index
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(76 if small else 125,103 if small else 151)
		panel.add_theme_stylebox_override("panel",_style(Color("283f49") if hidden else Color("e4ddc9"),GOLD,8))
		row.add_child(panel)
		var content := VBoxContainer.new()
		panel.add_child(content)
		var color := Color("9e4d46") if card.suit in [1,3] else Color("293c43")
		_label(content,"?" if hidden else card.rank_text(),24 if small else 31,GOLD if hidden else color)
		_label(content,"◇" if hidden else card.suit_text(),23 if small else 30,GOLD if hidden else color).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if not small:
			var upgraded: bool = card.rank in profile.upgrades
			_label(content,GameCatalog.SKILLS[card.rank][0] if upgraded else card.memory_text(),13,Color("655e50"))
			panel.tooltip_text = GameCatalog.skill_text(card.rank) if upgraded else "未升级 · "+card.memory_text()
			if battle.multipliers.get(card.id,1) == 2: _label(content,"点数 ×2",12,Color("9e4d46"))

func show_encounter() -> void:
	_new_page("encounter","最后一手" if battle.boss else "灯下的牌桌",GameCatalog.BOSSES[run.act] if battle.boss else "思绪：你又要抽一张吗？")
	var top := _row(page)
	_label(top,"质押 %d / %d   ·   桌外生命 %d" % [battle.pool,battle.stake,battle.reserve],22,GOLD).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(top,"第 %d 手  /  %d 胜 %d 负" % [mini(battle.resolved+1,3) if battle.phase <= BlackjackMatch.Phase.BUST_WINDOW else battle.resolved,battle.wins,battle.losses],18)
	var body := _row(page)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var board := Control.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(740,410)
	body.add_child(board)
	var stage := TableStage.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.decorative_cards = false
	board.add_child(stage)
	var overlay := MarginContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["top","bottom","left","right"]: overlay.add_theme_constant_override("margin_"+edge,16)
	board.add_child(overlay)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	overlay.add_child(column)
	var dealer_caption := "庄家 · %d 点" % battle.dealer.hand_points() if battle.reveal else "庄家 · 一张暗牌"
	_label(column,dealer_caption,18).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cards(column,battle.dealer.hand,-1 if battle.reveal else 1,true)
	_spacer(column)
	var state_text := "耐受区" if battle.score() in range(17,22) else ("失控" if battle.score()>21 else "继续或停下")
	_label(column,"你的手牌 · %d 点 · %s" % [battle.score(),state_text],24,GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cards(column,battle.player.hand)
	var sidebar := _panel(body)
	sidebar.custom_minimum_size.x = 280
	sidebar.add_theme_constant_override("separation",6)
	_label(sidebar,"这一手",24,GOLD)
	_label(sidebar,"全押 · 爆牌将结束轮回" if battle.boss else "基础注 %d · 输牌预计损失 %d" % [battle.base_bet,battle.current_loss()],16)
	_label(sidebar,"你的牌库 %d · 弃牌 %d" % [battle.player.draw_pile.size(),battle.player.discard_pile.size()],16,MUTED)
	if not battle.peek_text.is_empty(): _text(sidebar,battle.peek_text,17,GOLD)
	if not battle.stolen.is_empty(): _text(sidebar,"临时被偷："+battle.stolen,16)
	_label(sidebar,"随身道具",18,GOLD)
	if run.items.is_empty(): _text(sidebar,"暂无道具",16)
	for index in range(run.items.size()):
		var id: String = run.items[index]
		var button := _button(sidebar,GameCatalog.ITEMS[id][0],func(): _battle_action(func(): battle.use_item(id)))
		button.disabled = not battle.can_use(id)
		button.tooltip_text = GameCatalog.ITEMS[id][1]
	if battle.can_swap(): _button(sidebar,"发动 5 · 置换",func(): _battle_action(battle.swap_five))
	_spacer(sidebar)
	_text(sidebar,"每手限用1件；Boss整场限1件。\n五张未爆直接获胜。",15)
	for child in sidebar.get_children():
		if child is Button:
			child.custom_minimum_size.y = 38
			for state in ["normal","hover","pressed","disabled","focus"]:
				var compact := child.get_theme_stylebox(state).duplicate() as StyleBox
				compact.content_margin_top = 6
				compact.content_margin_bottom = 6
				child.add_theme_stylebox_override(state,compact)
	var feedback := battle.hand_result if not battle.hand_result.is_empty() else ("爆牌了：使用回溯，或确认结算。" if battle.phase == BlackjackMatch.Phase.BUST_WINDOW else "选择要牌或停牌。")
	_label(page,feedback,22,GOLD)
	var actions := _row(page)
	if battle.phase == BlackjackMatch.Phase.PLAYER:
		_button(actions,"要牌     +",func(): _battle_action(battle.hit),210)
		var stand_button := _button(actions,"停牌     →",func(): _battle_action(battle.stand),210)
		stand_button.disabled = not battle.can_stand()
		if stand_button.disabled: _label(actions,"低语：至少抽到第3张。",16,MUTED)
	elif battle.phase == BlackjackMatch.Phase.BUST_WINDOW:
		_button(actions,"确认爆牌",func(): _battle_action(battle.confirm_bust),230)
	elif battle.phase == BlackjackMatch.Phase.HAND_OVER:
		_button(actions,"下一手     →",func(): _battle_action(battle.deal_hand),260)
	else: _button(actions,"查看遭遇结果     →",settle_battle,260)
	_button(actions,"规则",func(): show_rules(show_encounter),100)
	var recent: Array[String] = battle.log_lines.slice(maxi(0,battle.log_lines.size()-2))
	_text(page," / ".join(recent),15)

func _battle_action(action: Callable) -> void:
	if screen != "encounter": return
	action.call()
	show_encounter()

func settle_battle() -> void:
	if screen != "encounter" or battle.phase != BlackjackMatch.Phase.MATCH_OVER: return
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
	_new_page("rules","停在失控之前","规则速查 · 余夜 0.2")
	var content := _panel(page)
	for text in ["双方独立牌库。庄家一明一暗；要牌接近21，停牌后比较大小。A自动按1/11计算。","起手A+任意10点牌为黑杰克，直接获胜；5张未爆为五龙，直接获胜。","庄家16及以下必抽，17及以上停。平局不扣质押，前两次重开，第三次普通局判胜、Boss判负。","普通遭遇固定三手：2胜全额返还质押并回5血；1胜返还余量；0胜失去全部质押。","战斗中的所有回血只恢复质押池；场外治疗恢复生命，上限100。","技能按点数共享升级。牌库、升级、删除记录永久保存；遗物与道具仅本轮有效。","要牌爆牌后可以使用回溯救场；每手道具限1件，Boss整场限1件。","三幕分支路线，各有一场Boss。最后Boss赢下且累计删8张旧记忆，触发放下结局。"]:
		_text(content,text,19,TEXT)
	_spacer(page)
	_button(page,"返回",back_action,220)

func _capture_screens() -> void:
	for target in ["menu","map","encounter","encounter_full","reward","shop","deck","ending"]:
		match target:
			"menu": show_menu()
			"map":
				start_run(217)
				choose_reward(0)
			"encounter":
				enter_node(run.available_ids()[0])
				begin_battle()
			"encounter_full":
				run.items.assign(["undo","peek","heal"])
				profile.upgrades.append(5)
				battle.player.hand[0].rank = 5
				battle.peek_text = "接下来：红桃 3、黑桃 K"
				battle.stolen = "黑桃 A"
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
