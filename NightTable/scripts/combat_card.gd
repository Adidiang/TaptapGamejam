class_name CombatCard
extends Resource
## Immutable definition during a duel. Each dealt dictionary owns its runtime value/load.
@export var key := ""
@export var title := ""
@export_enum("number", "function") var kind := "number"
@export_enum("effect", "bonus", "trap") var function_type := "effect"
@export var trigger := ""
@export_range(1, 5) var load_cost := 1
@export var number := 0
@export var description := ""
@export var effect := ""
@export var amount := 0
@export_enum("self", "opponent") var target := "self"

func instance(serial: int) -> Dictionary:
	return {"id":serial, "definition":self, "value":number, "load":load_cost}

func type_label() -> String:
	return {"effect":"效果","bonus":"加成","trap":"陷阱"}.get(function_type,"")
