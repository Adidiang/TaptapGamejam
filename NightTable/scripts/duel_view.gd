class_name DuelView
extends RefCounted
## Table presentation only. Hidden cards never reach the card face.
const CARD = preload("res://scripts/duel_card_art.gd")
const TABLE = preload("res://scripts/duel_table_view.gd")
const GOLD := Color("d3b783")
const QUIET := Color("a28d70")

static func render(ui) -> void:
	var battle: DuelEncounter = ui.battle
	var duel := battle.duel
	ui._new_page("encounter","","",true)
	var stage := Control.new()
	stage.name = "DuelTableUI"
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.page.add_child(stage)
	var backdrop = TABLE.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,55)
	margin.add_theme_constant_override("margin_top",25)
	margin.add_theme_constant_override("margin_bottom",24)
	stage.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",14)
	margin.add_child(layout)
	var header = ui._row(layout)
	ui._label(header,"余 夜  /  赌 桌",23,GOLD).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui._label(header,"质押 %d / %d   ·   桌外生命 %d   ·   第 %d / %d 局" % [battle.pool,battle.stake,battle.reserve,mini(battle.resolved+1,1 if battle.boss else 3),1 if battle.boss else 3],16,GOLD)
	var darkness := Label.new()
	darkness.text = "—  桌对面，只有沉默  —"
	darkness.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	darkness.add_theme_color_override("font_color",QUIET)
	darkness.add_theme_font_size_override("font_size",15)
	darkness.custom_minimum_size.y = 90
	layout.add_child(darkness)
	var body = ui._row(layout)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",25)
	var decks := VBoxContainer.new()
	decks.custom_minimum_size.x = 125
	decks.add_theme_constant_override("separation",10)
	body.add_child(decks)
	ui._spacer(decks)
	ui._label(decks,"自有牌堆",16,GOLD)
	var deck = CARD.new()
	deck.name = "OwnDeck"
	deck.face_down = true
	deck.custom_minimum_size = Vector2(112,153)
	deck.disabled = not (battle.phase==DuelEncounter.Phase.PLAYING and duel.active==0 and duel.phase==LoadDuel.Phase.DECIDE and not duel.sides[0].pile.is_empty())
	deck.tooltip_text = "摸一张自有牌；仅限回合开始时。"
	deck.pressed.connect(func(): ui.duel_action("draw"))
	decks.add_child(deck)
	ui._label(decks,"剩余 %d / 弃牌 %d" % [duel.sides[0].pile.size(),duel.sides[0].discard.size()],14,QUIET)
	ui._label(decks,"公共牌堆",16,GOLD)
	var public_button = action(ui,decks,"冒险摸牌",func(): ui.duel_action("draw"),120)
	public_button.disabled = not (battle.phase==DuelEncounter.Phase.PLAYING and duel.active==0 and duel.phase==LoadDuel.Phase.DECIDE and duel.public_enabled and duel.sides[0].pile.is_empty())
	ui._text(decks,"下次风险 %d%%\n已摸 %d 次" % [duel.public_risk(0),duel.sides[0].public_draws],14,Color("c98a65"))
	ui._spacer(decks)
	var banks := VBoxContainer.new()
	banks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banks.add_theme_constant_override("separation",20)
	body.add_child(banks)
	bank(ui,banks,battle,1)
	var divider := HSeparator.new()
	divider.modulate = Color(0.65,0.45,0.22,0.35)
	banks.add_child(divider)
	bank(ui,banks,battle,0)
	var notes := VBoxContainer.new()
	notes.custom_minimum_size.x = 185
	notes.add_theme_constant_override("separation",10)
	body.add_child(notes)
	ui._spacer(notes)
	ui._label(notes,"负 荷",20,GOLD)
	ui._label(notes,"%02d / %02d" % [duel.load_total(0),duel.load_limit(0)],32,Color("e2b579") if duel.load_total(0)<17 else Color("da7458"))
	var gauge := ProgressBar.new()
	gauge.max_value = duel.load_limit(0)
	gauge.value = duel.load_total(0)
	gauge.show_percentage = false
	gauge.custom_minimum_size = Vector2(180,9)
	gauge.add_theme_stylebox_override("background",ui._style(Color("241b17"),Color("614a31"),1))
	gauge.add_theme_stylebox_override("fill",ui._style(Color("9d6239"),Color("d0a46e"),1))
	notes.add_child(gauge)
	ui._text(notes,"数字 %d · 预计结算 %d" % [duel.score(0),duel.projected_score(0)],14,GOLD)
	ui._text(notes,"超负荷立即落败",13,QUIET)
	ui._label(notes,"— 桌边记事 —",16,GOLD)
	for event in duel.events.slice(maxi(0,duel.events.size()-3)): ui._text(notes,event,13,QUIET)
	if not duel.sides[0].peek.is_empty(): ui._text(notes,"预见："+" → ".join(duel.sides[0].peek),14,GOLD)
	for line in relic_notes(duel.sides[0]): ui._text(notes,line,12,QUIET)
	ui._spacer(notes)
	var status := battle.hand_result
	if battle.phase==DuelEncounter.Phase.PLAYING:
		status = "对方正在行动……" if duel.active==1 else ("摸一张，或停牌锁定。" if duel.phase==LoadDuel.Phase.DECIDE else "点击效果牌使用 · 加成与陷阱留在桌上 · 也可主动弃牌")
	var status_label = ui._text(layout,status,16,GOLD)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var actions = ui._row(layout)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	if battle.phase==DuelEncounter.Phase.HAND_OVER: action(ui,actions,"下一局",ui.next_duel,190)
	elif battle.phase==DuelEncounter.Phase.MATCH_OVER: action(ui,actions,"查看遭遇结果",ui.settle_battle,220)
	elif duel.active==0:
		if duel.phase==LoadDuel.Phase.DECIDE:
			action(ui,actions,"公共摸牌 · 风险%d%%" % duel.public_risk(0) if duel.public_enabled and duel.sides[0].pile.is_empty() else "摸自有牌",func(): ui.duel_action("draw"),220)
			action(ui,actions,"停牌 · 锁定",func(): ui.duel_action("stop"),170)
		else: action(ui,actions,"结束回合",func(): ui.duel_action("end_turn"),190)
	action(ui,actions,"对战规则",func(): ui.show_rules(ui.show_encounter),140)
	if ui.run.castle!=null: action(ui,actions,"查看遗物",func(): ui.run_screens.inventory(ui.show_encounter,-1,true),140)

static func action(ui,parent: Node,title: String,callback: Callable,width: float) -> Button:
	var button: Button = ui._button(parent,title,callback,width)
	button.add_theme_stylebox_override("normal",ui._style(Color("30251e"),Color("987544"),2))
	button.add_theme_stylebox_override("hover",ui._style(Color("57412a"),GOLD,2))
	button.add_theme_stylebox_override("pressed",ui._style(Color("201711"),GOLD,2))
	button.add_theme_stylebox_override("disabled",ui._style(Color("211b16"),Color("50412e"),2))
	button.add_theme_color_override("font_color",GOLD)
	button.add_theme_font_size_override("font_size",16)
	return button

static func bank(ui,parent: Node,battle: DuelEncounter,owner: int) -> void:
	var duel = battle.duel
	var side: Dictionary = duel.sides[owner]
	var bank_root := VBoxContainer.new()
	bank_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_root.add_theme_constant_override("separation",8)
	parent.add_child(bank_root)
	var heading = ui._row(bank_root)
	ui._label(heading,"对 方" if owner==1 else "你 的 牌",19,GOLD).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui._label(heading,"数字 %d · %s" % [duel.score(owner),"已停牌" if side.stopped else ("行动中" if duel.active==owner else "等待")],16,GOLD)
	if owner==1 and duel.public_enabled:
		ui._label(bank_root,"公共摸牌 %d 次 · 下次风险 %d%%" % [side.public_draws,duel.public_risk(owner)],12,QUIET)
	var zones = ui._row(bank_root)
	zones.add_theme_constant_override("separation",15)
	var numbers := VBoxContainer.new()
	numbers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zones.add_child(numbers)
	ui._label(numbers,"数 字 区 / 明 牌",12,QUIET)
	var scroll := ScrollContainer.new()
	scroll.name = "Numbers"+str(owner)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(200,180 if owner==0 else 160)
	numbers.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",7)
	scroll.add_child(row)
	if side.numbers.is_empty(): ui._label(row,"尚未落牌",15,QUIET)
	for card in side.numbers:
		var face = CARD.new()
		face.title = "数 字"
		face.value = str(card.value)
		face.load_text = "负荷 %d" % card.load
		face.custom_minimum_size = Vector2(104,168 if owner==0 else 148)
		face.small = owner==1
		face.disabled = true
		face.tooltip_text = "数字 %d · 负荷 %d" % [card.value,card.load]
		row.add_child(face)
	var functions := VBoxContainer.new()
	zones.add_child(functions)
	ui._label(functions,"功 能 槽" if owner==0 else "暗 牌 / 总负荷隐藏 · 余牌 %d" % side.pile.size(),12,QUIET)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation",7)
	var slot_scroll := ScrollContainer.new()
	slot_scroll.name = "Functions"+str(owner)
	slot_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	slot_scroll.custom_minimum_size = Vector2(365,225 if owner==0 else 160)
	functions.add_child(slot_scroll)
	slot_scroll.add_child(slots)
	for index in range(duel.slot_limit(owner)):
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override("separation",2)
		slots.add_child(slot)
		var face = CARD.new()
		face.custom_minimum_size = Vector2(116,168 if owner==0 else 148)
		face.disabled = true
		slot.add_child(face)
		if index>=side.functions.size():
			face.vacant = true
			continue
		var reveal: bool = owner==0 or (not duel.final_scores.is_empty() and side.functions[index].definition.function_type=="bonus")
		if not reveal:
			face.face_down = true
			face.tooltip_text = "对方未公开的功能牌"
			continue
		var definition: CombatCard = side.functions[index].definition
		face.title = definition.title
		face.sigil = definition.function_type
		face.subtitle = definition.type_label()
		face.load_text = "负荷 %d" % side.functions[index].load
		face.tooltip_text = definition.description
		if owner==0:
			face.disabled = battle.phase!=DuelEncounter.Phase.PLAYING or not duel.can_play(0,index)
			var selected := index
			face.pressed.connect(func(): ui.play_function(selected))
			var discard := action(ui,slot,"弃掉",func(): ui.discard_function(selected),110)
			discard.custom_minimum_size.y = 28
			discard.add_theme_font_size_override("font_size",13)
			discard.disabled = battle.phase!=DuelEncounter.Phase.PLAYING or not duel.can_discard(0,index)
	if not duel.final_scores.is_empty():
		var summary: Dictionary = duel.final_scores[owner]
		ui._text(bank_root,"结算 (%d + %d) × %d%% = %d · %s" % [summary.base,summary.flat,100+summary.percent,summary.total,"、".join(summary.names)],14,GOLD)

static func relic_notes(side: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if "R03" in side.relics: result.append("磨损砝码："+("已用" if side.weight_used else "可用"))
	if "R04" in side.relics: result.append("静默怀表："+("+4" if side.watch_bonus>0 else "未触发"))
	if "R05" in side.relics: result.append("织线梭："+("+3" if side.trap_bonus>0 else "可用"))
	return result
