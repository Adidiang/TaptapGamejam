class_name CastleGenerator
extends RefCounted
const ROOM_WIDTH := 10.0
const FLOOR_HEIGHT := 6.5
const FLOOR_NAMES := ["一层","二层","三层","四层","五层"]
const ROUTE = preload("res://art/exploration/route.tres")

static func roll_kind(rng: RandomNumberGenerator) -> String:
	var total: int = ROUTE.battle_weight+ROUTE.shop_weight+ROUTE.event_weight
	if total<=0:return "event"
	var roll := rng.randi_range(0,total-1)
	if roll<ROUTE.battle_weight:return "encounter"
	if roll<ROUTE.battle_weight+ROUTE.shop_weight:return "shop"
	return "event"

static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed=seed_value
	var floors := rng.randi_range(4,5)
	var width := rng.randi_range(9,11)
	var spawn_floor := rng.randi_range(0,1)
	var spans: Array=[Vector2i(0,width-1)]
	for floor_index in range(1,floors-1):
		var previous: Vector2i=spans[-1]
		var target_width := rng.randi_range(3,5) if floor_index==floors-2 else maxi(5,previous.y-previous.x-rng.randi_range(0,1))
		target_width=mini(target_width,previous.y-previous.x)
		var slack := previous.y-previous.x+1-target_width
		var centered := (width-target_width)/2+rng.randi_range(-1,1)
		var left := clampi(centered,previous.x,previous.x+slack)
		spans.append(Vector2i(left,left+target_width-1))
	var crown: Vector2i=spans[-1]
	var boss_column := rng.randi_range(crown.x+1,crown.y-1)
	spans.append(Vector2i(boss_column,boss_column))
	var layout := {"seed":seed_value,"width":width,"floors":floors,"rooms":[],"rows":[],"stairs":[],"ladders":[],"spawn":-1,"boss":-1,"linear":false,"spans":spans}
	var reserved: Dictionary={}
	var shafts: Array=[]
	# Reserve actual two-storey footprints, from the crown downwards.
	for floor_index in range(floors-2,-1,-1):
		var low: Vector2i=spans[floor_index]
		var high: Vector2i=spans[floor_index+1]
		var candidates: Array=[]
		if floor_index==floors-2:
			candidates=[boss_column-1]
		else:
			for column in range(maxi(low.x,high.x),mini(low.y,high.y)+1):
				if (floor_index==spawn_floor and column==low.x) or (floor_index+1==spawn_floor and column==high.x):continue
				if not reserved.has(Vector2i(column,floor_index)) and not reserved.has(Vector2i(column,floor_index+1)):
					candidates.append(column)
		# Stair halls sharing either storey must have a normal room between them.
		candidates = candidates.filter(func(column):
			return not shafts.any(func(shaft):
				return absi(shaft.y-floor_index)<=1 and absi(shaft.x-column)<=1))
		var count := mini(candidates.size(),rng.randi_range(1,2) if floor_index==0 else 1)
		for index in count:
			if candidates.is_empty():break
			var column: int=candidates.pop_at(rng.randi_range(0,candidates.size()-1))
			reserved[Vector2i(column,floor_index)]=true
			reserved[Vector2i(column,floor_index+1)]=true
			shafts.append(Vector2i(column,floor_index))
			candidates = candidates.filter(func(other):return absi(other-column)>1)
	var cells: Dictionary={}
	for floor_index in floors:
		layout.rows.append([])
		var span: Vector2i=spans[floor_index]
		for column in range(span.x,span.y+1):
			if reserved.has(Vector2i(column,floor_index)):continue
			var kind := roll_kind(rng)
			var spec: ExplorationRoomDefinition=ROUTE.whitebox
			if kind=="encounter":spec=ROUTE.battle
			elif kind=="event":spec=ROUTE.events[rng.randi_range(0,ROUTE.events.size()-1)]
			if floor_index==spawn_floor and column==span.x:kind="spawn";spec=ROUTE.bedroom
			if floor_index==floors-1:kind="boss";spec=ROUTE.queen
			var id := _add_room(layout,column,floor_index,kind,spec)
			cells[Vector2i(column,floor_index)]=id
			if kind=="spawn":layout.spawn=id;layout.rooms[id].seen=true
			if kind=="boss":layout.boss=id
	for shaft in shafts:
		var id := _add_room(layout,shaft.x,shaft.y,"stairs",ROUTE.stairwell)
		layout.rooms[id].height_floors=2
		cells[shaft]=id
		cells[shaft+Vector2i(0,1)]=id
		layout.stairs.append({"room":id,"floor":shaft.y,"column":shaft.x})
	for cell in cells:
		var next: Vector2i=cell+Vector2i(1,0)
		if cells.has(next):
			var a: int=cells[cell]
			var b: int=cells[next]
			_connect(layout,a,b,cell.y)
	return layout

static func _add_room(layout: Dictionary,column: int,floor_index: int,kind: String,spec: ExplorationRoomDefinition) -> int:
	var id: int=layout.rooms.size()
	layout.rooms.append({"id":id,"floor":floor_index,"column":column,"kind":kind,"neighbors":[],"ports":[],"stairs":[],"height_floors":1,"ladders":[],"cleared":kind not in ["encounter","boss"],"triggered":false,"seen":false,"style":0,"definition":spec})
	layout.rows[floor_index].append(id)
	return id

static func _connect(layout: Dictionary,a: int,b: int,floor_index: int) -> void:
	for pair in [[a,b,1],[b,a,-1]]:
		var source: Dictionary=layout.rooms[pair[0]]
		var target: Dictionary=layout.rooms[pair[1]]
		if pair[1] not in source.neighbors:source.neighbors.append(pair[1])
		source.ports.append({"to":pair[1],"side":pair[2],"level":floor_index-source.floor,"to_level":floor_index-target.floor})
