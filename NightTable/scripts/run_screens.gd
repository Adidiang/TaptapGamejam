class_name RunScreens
extends RefCounted
## Inventory and room UI delegate all transactions to NightRun / RunInventory.
var ui

func _init(host) -> void:
	ui = host

func _scroll(parent: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	return column

func card_text(card: CombatCard) -> String:
	return "%s · %s · 负荷%d%s" % [card.title,card.type_label(),card.load_cost,"\n"+card.description if not card.description.is_empty() else ""]

func inventory(back: Callable, replace_offer: int = -1, show_relics: bool = false) -> void:
	var inv: RunInventory = ui.run.inventory
	ui._new_page("inventory","本轮行囊","本轮携带 · I 打开行囊 · 安全房间可删牌，最低2张")
	ui._label(ui.page,"牌组 %d / 20   ·   质押点 %d   ·   遗物 %d" % [inv.cards.size(),inv.points,inv.relics.size()],22,ui.GOLD)
	if replace_offer>=0:
		ui._text(ui.page,"新牌："+card_text(ui.run.room_offers()[replace_offer].card)+"\n选择要替换的旧牌；确认后同时领取 / 付款，取消不消耗。",18)
	else:
		var tabs = ui._row(ui.page)
		ui._button(tabs,"牌组",func(): inventory(back),150)
		ui._button(tabs,"遗物",func(): inventory(back,-1,true),150)
	var column := _scroll(ui.page)
	for i in range(0 if show_relics else inv.cards.size()):
		var index := i
		var row = ui._row(column)
		ui._text(row,card_text(inv.cards[i]),17,ui.TEXT).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button = ui._button(row,"替换这张" if replace_offer>=0 else "移除",func():
			if replace_offer>=0:
				confirm("用新牌替换「%s」？" % inv.cards[index].title,func(): commit(replace_offer,index),func(): inventory(back,replace_offer))
			else:
				confirm("本轮移除「%s」？无法从备用库取回。" % inv.cards[index].title,func():
					if ui.run.can_manage_inventory(): inv.remove(index)
					inventory(back)
				,func(): inventory(back))
		,130)
		button.disabled = not ui.run.can_manage_inventory() or (replace_offer<0 and inv.cards.size()<=2)
	if show_relics:
		ui._label(column,"遗物",24,ui.GOLD)
		if inv.relics.is_empty(): ui._text(column,"尚未获得遗物。",18)
		for id in inv.relics: ui._text(column,RelicCatalog.text(id),18,ui.TEXT)
		if "R08" in inv.relics: ui._text(column,"铜锁："+("已开启" if ui.run.castle.layout.copper.open else "未开启"),17)
		if "R09" in inv.relics: ui._text(column,"钟机："+("已启动" if ui.run.castle.layout.clock_started else "未启动"),17)
	ui._button(ui.page,"返回",back,180)

func confirm(message: String, yes: Callable, back: Callable) -> void:
	ui._new_page("confirm","确认取舍",message)
	ui._spacer(ui.page)
	ui._button(ui.page,"确认",yes,200)
	ui._button(ui.page,"取消",back,200)

func room() -> void:
	var state: CastleExploration = ui.run.castle
	var entry := state.room()
	if entry.kind not in ["event","shop"]: return
	ui._new_page("room_content","","",true)
	var holder := Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.page.add_child(holder)
	var background := CastleView.new()
	background.configure(state)
	holder.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.process_mode = Node.PROCESS_MODE_DISABLED
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",ui._style(Color("17252bf5"),ui.GOLD))
	holder.add_child(panel)
	panel.anchor_left = 0.06
	panel.anchor_top = 0.08
	panel.anchor_right = 0.94
	panel.anchor_bottom = 0.94
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",14)
	panel.add_child(body)
	ui._label(body,entry.get("title","旅人的商店" if entry.kind=="shop" else "遗落的赠礼"),32,ui.GOLD)
	ui._label(body,"质押点 %d · 牌组 %d / 20" % [ui.run.inventory.points,ui.run.inventory.cards.size()],20)
	ui._text(body,"库存重访保留。交易只使用质押点。" if entry.kind=="shop" else "选择一项；可以暂时离开，或明确放弃本房奖励。",17)
	var column := _scroll(body)
	var offers: Array = ui.run.room_offers()
	for i in range(offers.size()):
		var offer: Dictionary = offers[i]
		var index := i
		var text := card_text(offer.card) if offer.type=="card" else (RelicCatalog.text(offer.id) if offer.type=="relic" else "质押点 +%d" % offer.amount)
		var owned: bool = offer.type=="relic" and offer.id in ui.run.inventory.relics
		var unavailable: bool = offer.get("sold",false) or owned or (entry.kind=="event" and entry.completed)
		var button = ui._button(column,text+"\n"+("已领取 / 售罄" if unavailable else ("%d 质押点" % offer.get("cost",0) if entry.kind=="shop" else "领取")),func(): select_offer(index),400)
		button.add_theme_font_size_override("font_size",17)
		button.add_theme_color_override("font_disabled_color",ui.MUTED)
		button.disabled = unavailable or ui.run.inventory.points<offer.get("cost",0)
	var actions = ui._row(body)
	ui._button(actions,"行囊 / 牌组",func(): inventory(room),180)
	if entry.kind=="event" and not entry.completed:
		ui._button(actions,"放弃奖励",func(): confirm("放弃后本房不会再次发奖。",func():
			ui.run.skip_event()
			ui.show_map()
		,room),180)
	ui._button(actions,"暂时离开" if entry.kind=="event" and not entry.completed else "离开",ui.show_map,180)

func select_offer(index: int) -> void:
	var offers: Array = ui.run.room_offers()
	if index not in range(offers.size()): return
	var offer: Dictionary = offers[index]
	if offer.type!="card":
		confirm(RelicCatalog.text(offer.id) if offer.type=="relic" else "领取质押点？",func(): commit(index),room)
		return
	ui._new_page("card_offer","收下新牌",card_text(offer.card))
	var add = ui._button(ui.page,"加入牌组",func(): commit(index),240)
	add.disabled = ui.run.inventory.cards.size()>=20
	ui._button(ui.page,"替换一张现有牌",func(): inventory(room,index),240)
	ui._button(ui.page,"返回 / 不选这张",room,240)

func commit(index: int, replacement: int = -1) -> void:
	if ui.run.claim_offer(index,replacement) and ui.run.castle.room().kind=="event": ui.show_map()
	else: room()
