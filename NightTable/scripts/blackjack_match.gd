class_name BlackjackMatch
extends RefCounted
## Legacy v0.2 rules, retained for regression only. Active gameplay uses DuelEncounter.
enum Phase { PLAYER, BUST_WINDOW, HAND_OVER, MATCH_OVER }
var run: NightRun
var player: MemoryDeck
var dealer := MemoryDeck.new()
var phase := Phase.HAND_OVER
var boss := false
var stake := 0
var pool := 0
var reserve := 0
var base_bet := 1
var wins := 0
var losses := 0
var resolved := 0
var ties := 0
var outcome := ""
var hand_result := ""
var log_lines: Array[String] = []
var triggered: Dictionary = {}
var multipliers: Dictionary = {}
var next_multiplier := 1
var reduction := 0
var discount := 0
var extra_dealer := 0
var reveal := false
var peek_text := ""
var item_used := false
var boss_item_used := false
var swapped := false
var stolen := ""
var last_hit_id := ""

func start(state: NightRun) -> void:
	run = state
	boss = run.current_node.kind == "boss"
	stake = mini(run.hp,run.nominal_stake())
	pool = stake
	reserve = run.hp-stake
	base_bet = maxi(1,roundi(stake/10.0))
	player = run.profile.make_deck(run.rng.randi())
	run.deck = player
	dealer.setup(run.rng.randi())
	if boss and run.act == 1:
		var card: MemoryCard = player.draw_pile.pop_back()
		stolen = card.suit_text()+card.rank_text()
		_note("偷牌：本场失去 %s，永久牌库不受影响。" % stolen)
	deal_hand()

func _note(message: String) -> void:
	log_lines.append(message)
	if log_lines.size() > 8: log_lines.pop_front()

func deal_hand() -> void:
	if phase != Phase.HAND_OVER: return
	player.discard_hand()
	dealer.discard_hand()
	triggered.clear()
	multipliers.clear()
	next_multiplier = 1
	reduction = 0
	discount = 0
	extra_dealer = 0
	peek_text = ""
	item_used = false
	swapped = false
	last_hit_id = ""
	reveal = "sight" in run.relics and resolved == 0 and ties == 0
	hand_result = ""
	phase = Phase.PLAYER
	for i in range(2):
		player.draw_card()
		dealer.draw_card()
	_note("第 %d 手发牌。" % (resolved+1))
	for card in player.hand: _on_draw(card)
	if is_blackjack(player): _win("黑杰克")

func is_blackjack(deck: MemoryDeck) -> bool:
	return deck.hand.size() == 2 and deck.hand_points() == 21

func score() -> int:
	var value := 0
	var adjustments: Array[int] = []
	for card in player.hand:
		var multiplier: int = multipliers.get(card.id,1)
		value += card.points()*multiplier
		if card.rank == 1: adjustments.append(10*multiplier)
	adjustments.sort()
	adjustments.reverse()
	for adjustment in adjustments:
		if value-reduction > 21: value -= adjustment
	return maxi(0,value-reduction)

func _has(rank: int) -> bool:
	if rank not in run.profile.upgrades: return false
	for card in player.hand:
		if card.rank == rank: return true
	return false

func recover(amount: int) -> void:
	var recovered := mini(amount,stake-pool)
	pool += recovered
	if recovered > 0: _note("质押回复 %d。" % recovered)

func _on_draw(card: MemoryCard) -> void:
	if card.rank not in run.profile.upgrades or triggered.has(card.rank): return
	triggered[card.rank] = true
	match card.rank:
		2: recover(2)
		3: _peek()
		8: next_multiplier = 2
		9: discount += base_bet
		10: extra_dealer += 1
		11: reveal = true
	_note("%s · %s" % [card.rank_text(),GameCatalog.SKILLS[card.rank][0]])

func _peek() -> void:
	var names: Array[String] = []
	for i in range(mini(2,player.draw_pile.size())):
		var card: MemoryCard = player.draw_pile[player.draw_pile.size()-1-i]
		names.append(card.suit_text()+card.rank_text())
	peek_text = "牌顶 → " + " / ".join(names)

func hit() -> void:
	if phase != Phase.PLAYER or player.hand.size() >= 5: return
	var card := player.draw_card()
	if card == null:
		stand()
		return
	last_hit_id = card.id
	multipliers[card.id] = next_multiplier
	next_multiplier = 1
	peek_text = ""
	_note("要牌：%s%s" % [card.suit_text(),card.rank_text()])
	_on_draw(card)
	_check_score()

func _check_score() -> void:
	if score() > 21 and _has(12) and not triggered.has("saved_q"):
		reduction += score()-20
		triggered["saved_q"] = true
		_note("抱持：这一次，你停在20点。")
	if score() > 21:
		phase = Phase.BUST_WINDOW
		_note("超过21点。可用回溯救场，或确认爆牌。")
	elif player.hand.size() >= 5: _win("五龙")

func can_stand() -> bool:
	return phase == Phase.PLAYER and (not boss or run.act != 2 or player.hand.size() >= 3)

func stand() -> void:
	if not can_stand(): return
	if _has(6): recover(3)
	if "anchor" in run.relics: recover(2)
	reveal = true
	var threshold := 18 if boss and run.act == 0 else 17
	while dealer.hand_points() < threshold:
		if dealer.draw_card() == null: break
	for i in range(extra_dealer):
		if dealer.hand_points() > 21: break
		dealer.draw_card()
	var enemy := dealer.hand_points()
	if enemy > 21 or score() > enemy: _win("庄家爆牌" if enemy > 21 else "点数领先")
	elif score() < enemy: _lose(false)
	else:
		ties += 1
		if ties >= 3:
			if boss: _lose(false)
			else: _win("第三次平局，判你获胜")
		else:
			hand_result = "平局 · 不计手数，重新发牌（%d/2）" % ties
			phase = Phase.HAND_OVER
			_note(hand_result)

func confirm_bust() -> void:
	if phase == Phase.BUST_WINDOW: _lose(true)

func current_loss() -> int:
	var bet := base_bet*maxi(1,player.hand.size()-2)-discount
	if _has(4): bet -= 2
	if "shield" in run.relics: bet -= 1
	return maxi(0,bet)

func _win(reason: String) -> void:
	wins += 1
	resolved += 1
	reveal = true
	if reason == "黑杰克":
		recover(5)
		if _has(1): recover(5)
		if "ace" in run.relics: recover(5)
	if reason == "五龙" and "five" in run.relics: recover(5)
	if _has(7): recover(3)
	if _has(13): recover(5)
	hand_result = "赢下这一手 · " + reason
	_note(hand_result)
	_end_hand(false)

func _lose(busted: bool) -> void:
	losses += 1
	resolved += 1
	reveal = true
	var loss := mini(pool,current_loss())
	if not boss: pool -= loss
	hand_result = "爆牌" if busted else "点数落后"
	if boss: hand_result += " · 轮回结束" if busted else " · 留下1点生命"
	else: hand_result += " · 质押损失 %d" % loss
	_note(hand_result)
	_end_hand(busted)

func _end_hand(busted: bool) -> void:
	phase = Phase.HAND_OVER
	if boss:
		outcome = "success" if wins > 0 else ("disaster" if busted else "failure")
		run.hp = 100 if wins > 0 else (0 if busted else 1)
		phase = Phase.MATCH_OVER
	elif pool <= 0 or resolved >= 3:
		outcome = "disaster" if pool <= 0 or wins == 0 else ("success" if wins >= 2 else "failure")
		match outcome:
			"success": run.hp = mini(100,reserve+stake+5)
			"failure": run.hp = reserve+pool
			"disaster": run.hp = reserve
		phase = Phase.MATCH_OVER

func can_swap() -> bool:
	return phase == Phase.PLAYER and _has(5) and not swapped and not player.draw_pile.is_empty()

func swap_five() -> void:
	if not can_swap(): return
	swapped = true
	for i in range(player.hand.size()):
		if player.hand[i].rank == 5:
			var previous := player.hand[i]
			var replacement: MemoryCard = player.draw_pile.pop_back()
			player.hand[i] = replacement
			player.draw_pile.append(previous)
			last_hit_id = ""
			peek_text = ""
			_note("置换：5交换为%s。" % replacement.rank_text())
			_on_draw(replacement)
			_check_score()
			break

func can_use(id: String) -> bool:
	if id not in run.items or item_used or (boss and boss_item_used): return false
	if id == "undo":
		return phase in [Phase.PLAYER,Phase.BUST_WINDOW] and not last_hit_id.is_empty() and player.hand.size() > 2
	return phase == Phase.PLAYER and (id != "heal" or pool < stake)

func use_item(id: String) -> void:
	if not can_use(id): return
	run.items.erase(id)
	item_used = true
	boss_item_used = boss
	match id:
		"undo":
			var card: MemoryCard = player.hand.pop_back()
			player.discard_pile.append(card)
			multipliers.erase(card.id)
			last_hit_id = ""
			phase = Phase.PLAYER
			_note("回溯：撤回最后一张牌；已触发技能不重置。")
			_check_score()
		"peek":
			reveal = true
			_peek()
		"heal": recover(8)
