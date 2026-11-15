extends Node

signal money_changed(value: int)
signal order_changed(items: Dictionary)
signal phase_changed(phase: String)
signal hint_changed(text: String)
signal prompt_changed(text: String)
signal dialogue(speaker: String, text: String)
signal toast(text: String)
signal bake_progress(value: float)
signal checks_changed(baked: int, bagged: int)
signal float_text(text: String, world_pos: Vector3)
signal day_changed(day: int, index: int, total: int)
signal order_timer_changed(left: float, total: float)
signal day_complete(served: int, earned: int, total_money: int)
signal time_changed(phase: String, clock: String, color: Color)

var money := 0
var order: Dictionary = {}
var phase := "menu"
var baked_count := 0
var bagged_count := 0

func add_money(value: int) -> void:
	money += value
	money_changed.emit(money)

func set_phase(p: String) -> void:
	phase = p
	phase_changed.emit(p)

func set_hint(text: String) -> void:
	hint_changed.emit(text)

func set_prompt(text: String) -> void:
	prompt_changed.emit(text)

func say(text: String) -> void:
	dialogue.emit("", text)

func say_as(speaker: String, text: String) -> void:
	dialogue.emit(speaker, text)

func set_order(items: Dictionary) -> void:
	order = items
	baked_count = 0
	bagged_count = 0
	order_changed.emit(items)
	checks_changed.emit(0, 0)

func set_baked(n: int) -> void:
	baked_count = n
	checks_changed.emit(baked_count, bagged_count)

func set_bagged(n: int) -> void:
	bagged_count = n
	checks_changed.emit(baked_count, bagged_count)
