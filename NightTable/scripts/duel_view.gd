class_name DuelView
extends RefCounted
## Rendering only. Never put opponent hidden card definitions into labels or tooltips.
static func render(ui) -> void:
	var battle: DuelEncounter = ui.battle
	var duel := battle.duel
	ui._new_page("encounter","负荷牌局","数字＋结算加成决定胜负 · 效果 / 加成 / 陷阱共享3格 · 负荷上限21")
	ui.page.add_theme_constant_override("separation",10)
	ui._label(ui.page,"质押 %d/%d  ·  桌外生命 %d  ·  已结算 %d/ %d 局  ·  %d胜%d负" % [battle.pool,battle.stake,battle.reserve,battle.resolved,1 if battle.boss else 3,battle.wins,battle.losses],18,ui.GOLD)
	var body = ui._row(ui.page)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var board := PanelContainer.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.add_theme_stylebox_override("panel",ui._style(Color("17352f"),Color("7d7957")))
	body.add_child(board)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",6)
	scroll.add_child(column)
	for owner in [1,0]:
		var side: Dictionary = duel.sides[owner]
		var state := "已停牌 · 不可被影响" if side.stopped else ("行动中" if duel.active == owner else "等待")
		ui._label(column,"%s · 数字 %d · %s" % [duel.label_for(owner),duel.score(owner),state],21,ui.GOLD)
		if owner == 0:
			ui._label(column,"负荷 %d / %d    牌库 %d · 弃牌 %d" % [duel.load_total(owner),duel.limit,side.pile.size(),side.discard.size()],17,Color("f0aa87") if duel.load_total(owner)>16 else ui.TEXT)
			if duel.phase != LoadDuel.Phase.OVER: ui._label(column,"若现在结算：%d 点（含自己的加成）" % duel.projected_score(owner),15,ui.GOLD)
		else: ui._label(column,"功能牌及总负荷隐藏 · 剩余牌库 %d" % side.pile.size(),15,ui.MUTED)
		if not duel.final_scores.is_empty():
			var summary: Dictionary = duel.final_scores[owner]
			ui._text(column,"结算：(%d + %d) × %d%% → %d 点 · 加成：%s" % [summary.base,summary.flat,100+summary.percent,summary.total,"、".join(summary.names) if not summary.names.is_empty() else "无"],16,ui.GOLD)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation",8)
		flow.add_theme_constant_override("v_separation",6)
		column.add_child(flow)
		if side.numbers.is_empty(): ui._label(flow,"数字区暂无牌",16,ui.MUTED)
		for card in side.numbers:
			var tile := PanelContainer.new()
			tile.custom_minimum_size = Vector2(90,68)
			tile.add_theme_stylebox_override("panel",ui._style(Color("e4ddc9"),ui.GOLD,6))
			flow.add_child(tile)
			ui._label(tile,"%d\n负荷 %d" % [card.value,card.load],18,Color("293c43"))
		var functions := HFlowContainer.new()
		functions.add_theme_constant_override("h_separation",8)
		column.add_child(functions)
		for index in range(duel.slots):
			if index >= side.functions.size():
				ui._label(functions,"〔空槽〕",16,ui.MUTED)
			elif owner == 1:
				var back := PanelContainer.new()
				back.custom_minimum_size = Vector2(110,54)
				back.add_theme_stylebox_override("panel",ui._style(Color("273941"),ui.GOLD,6))
				functions.add_child(back)
				var known_bonus: bool = not duel.final_scores.is_empty() and side.functions[index].definition.function_type == "bonus"
				ui._label(back,side.functions[index].definition.title if known_bonus else "◇ 暗牌",17,ui.GOLD)
			else:
				var definition: CombatCard = side.functions[index].definition
				var selected := index
				var slot := VBoxContainer.new()
				functions.add_child(slot)
				ui._label(slot,definition.type_label(),14,ui.GOLD)
				var button = ui._button(slot,"%s · 负荷%d" % [definition.title,side.functions[index].load],func(): ui.play_function(selected),150)
				button.disabled = battle.phase != DuelEncounter.Phase.PLAYING or not duel.can_play(0,index)
				button.tooltip_text = definition.description+"\n"+{"effect":"主动使用后释放负荷。","bonus":"不能主动使用，保留至结算生效。","trap":"响应对方行动，自动触发一次；自己停牌后仍有效。"}[definition.function_type]
				if definition.function_type != "effect": button.add_theme_color_override("font_disabled_color",ui.GOLD)
				var discard = ui._button(slot,"弃掉",func(): ui.discard_function(selected),150)
				discard.visible = battle.phase == DuelEncounter.Phase.PLAYING
				discard.disabled = battle.phase != DuelEncounter.Phase.PLAYING or not duel.can_discard(0,index)
				discard.tooltip_text = "不触发效果，释放负荷和槽位。仅限自己的操作阶段。"
		column.add_child(HSeparator.new())
	var side_panel = ui._panel(body)
	side_panel.custom_minimum_size.x = 275
	side_panel.add_theme_constant_override("separation",8)
	ui._label(side_panel,"行动记录",20,ui.GOLD)
	for event in duel.events.slice(maxi(0,duel.events.size()-5)): ui._text(side_panel,event,16,ui.TEXT)
	if not duel.sides[0].peek.is_empty(): ui._text(side_panel,"预见："+" → ".join(duel.sides[0].peek),16,ui.GOLD)
	ui._spacer(side_panel)
	ui._text(side_panel,"摸牌超负荷立即输，不能救场。\n满槽摸到功能牌：弃掉且不增加负荷。",15)
	var status := battle.hand_result
	if battle.phase == DuelEncounter.Phase.PLAYING:
		status = "对方正在行动…" if duel.active == 1 else ("回合开始：摸一张，或停牌锁定。" if duel.phase == LoadDuel.Phase.DECIDE else "使用效果牌；保留加成与陷阱，或弃掉任意功能牌。")
	ui._text(ui.page,status,20,ui.GOLD)
	var actions = ui._row(ui.page)
	if battle.phase == DuelEncounter.Phase.HAND_OVER: ui._button(actions,"下一局",ui.next_duel,190)
	elif battle.phase == DuelEncounter.Phase.MATCH_OVER: ui._button(actions,"查看遭遇结果",ui.settle_battle,220)
	elif duel.active == 0:
		if duel.phase == LoadDuel.Phase.DECIDE:
			ui._button(actions,"摸一张",func(): ui.duel_action("draw"),190)
			ui._button(actions,"停牌 · 锁定",func(): ui.duel_action("stop"),190)
		else: ui._button(actions,"结束回合",func(): ui.duel_action("end_turn"),190)
	ui._button(actions,"对战规则",func(): ui.show_rules(ui.show_encounter),150)
