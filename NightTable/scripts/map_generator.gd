class_name RouteGenerator
extends RefCounted
## Consecutive layers use ordered edges, keeping the map readable.
## Every node has an incoming route and a route to the final node.

static func generate(run_seed: int, layer_count: int = 7) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var layers: Array = []
	var next_id := 0
	for row in range(maxi(3, layer_count)):
		var count := 1 if row == 0 or row == maxi(3, layer_count) - 1 else rng.randi_range(2, 3)
		var layer: Array = []
		for column in range(count):
			var kind: String = ["encounter", "encounter", "event", "shop", "rest"][rng.randi_range(0, 4)]
			if row == 0:
				kind = "encounter"
			elif row == maxi(3, layer_count) - 1:
				kind = "boss"
			layer.append({"id": next_id, "row": row, "column": column, "kind": kind, "next": []})
			next_id += 1
		layers.append(layer)
	for row in range(layers.size() - 1):
		var source: Array = layers[row]
		var destination: Array = layers[row + 1]
		# Monotonic nearest-neighbor mapping avoids crossing connections.
		for i in range(source.size()):
			var target := roundi(float(i) * (destination.size() - 1) / maxi(1, source.size() - 1))
			_connect(source[i], destination[target])
		for j in range(destination.size()):
			var origin := roundi(float(j) * (source.size() - 1) / maxi(1, destination.size() - 1))
			_connect(source[origin], destination[j])
	return layers

static func _connect(source: Dictionary, destination: Dictionary) -> void:
	if not destination.id in source.next:
		source.next.append(destination.id)

static func title(kind: String) -> String:
	return {"encounter": "牌桌", "event": "回声", "shop": "交换", "rest": "喘息", "boss": "最后一手"}.get(kind, kind)

static func symbol(kind: String) -> String:
	return {"encounter": "♠", "event": "?", "shop": "◇", "rest": "+", "boss": "♛"}.get(kind, "·")
