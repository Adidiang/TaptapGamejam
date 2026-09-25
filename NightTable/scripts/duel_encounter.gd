class_name DuelEncounter
extends RefCounted
## Compatibility boundary: new duels feed the unchanged outer stake/reward system.
enum Phase { PLAYING, HAND_OVER, MATCH_OVER }
var duel := LoadDuel.new()
var run: NightRun
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

func start(state: NightRun) -> void:
	run = state
	boss = run.current_node.kind == "boss"
	stake = mini(run.hp,run.nominal_stake())
	pool = stake
	reserve = run.hp-stake
	base_bet = maxi(1,roundi(stake/10.0))
	deal_hand()

func deal_hand() -> void:
	if phase != Phase.HAND_OVER: return
	phase = Phase.PLAYING
	hand_result = ""
	duel = LoadDuel.new()
	duel.start(CombatCatalog.from_profile(run.profile),CombatCatalog.from_profile(MemoryProfile.new()),run.rng.randi())
	resolve_if_finished()

func resolve_if_finished() -> void:
	if phase != Phase.PLAYING or duel.phase != LoadDuel.Phase.OVER: return
	var won := duel.winner == 0
	if duel.winner == -1:
		ties += 1
		if ties < 3:
			phase = Phase.HAND_OVER
			hand_result = "平局 · 重新发牌（%d/2），不计手数" % ties
			return
		won = not boss
	resolved += 1
	if won: wins += 1
	else:
		losses += 1
		if not boss: pool = maxi(0,pool-current_loss())
	hand_result = ("本局获胜" if won else "本局落败") + " · " + duel.reason
	if duel.winner == -1: hand_result += " 第三次平局按原遭遇规则判定。"
	phase = Phase.HAND_OVER
	if boss:
		outcome = "success" if won else ("disaster" if duel.overloaded == 0 else "failure")
		run.hp = 100 if won else (0 if duel.overloaded == 0 else 1)
		phase = Phase.MATCH_OVER
	elif pool == 0 or resolved >= 3:
		outcome = "disaster" if pool == 0 or wins == 0 else ("success" if wins >= 2 else "failure")
		run.hp = mini(100,reserve+stake+5) if outcome == "success" else (reserve+pool if outcome == "failure" else reserve)
		phase = Phase.MATCH_OVER

func current_loss() -> int:
	var count: int = duel.sides[0].numbers.size()+duel.sides[0].functions.size()
	return base_bet*clampi(count-2,1,3)
