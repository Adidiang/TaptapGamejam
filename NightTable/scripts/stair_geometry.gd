class_name StairGeometry
extends RefCounted
const H := 6.5
const BASE := 0.1
const RUN_START := -3.0
const RUN_END := 2.8
const FRONT := Rect2(-3.0,0.5,5.8,1.7)
const BACK := Rect2(-3.0,-2.2,5.8,1.7)

static func surfaces() -> Array:
	return [
		{"rect":Rect2(-4.5,-3,1.5,6),"height":BASE},
		{"rect":Rect2(-4.5,-3,9,2.2),"height":BASE},
		{"rect":FRONT,"flight":0},
		{"rect":Rect2(2.8,-2.2,1.2,4.4),"height":BASE+H/2},
		{"rect":BACK,"flight":1},
		{"rect":Rect2(-4.5,-3,1.5,6),"height":BASE+H},
		{"rect":Rect2(-4.5,2.2,9,.8),"height":BASE+H},
		{"rect":Rect2(3.2,-3,1.3,6),"height":BASE+H}]

static func height_at(point: Vector2, previous: float) -> float:
	var best := NAN
	var distance := INF
	for surface in surfaces():
		if not surface.rect.grow(.001).has_point(point):continue
		var height: float=surface.get("height",BASE)
		if surface.has("flight"):
			var t := clampf((point.x-RUN_START)/(RUN_END-RUN_START),0,1)
			height=BASE+(t*H/2 if surface.flight==0 else H-t*H/2)
		var delta := absf(height-previous)
		if delta<distance and delta<=.18:
			best=height
			distance=delta
	return best
