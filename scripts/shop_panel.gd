class_name ShopPanel
extends ColorRect
## Dropship console shop: one randomly offered upgrade per category per asteroid.
## Built in code; runs while the tree is paused.

signal purchased(id: String)
signal closed

var _credits_label := Label.new()
var _cards := HBoxContainer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.0, 0.02, 0.05, 0.75)
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var title := _label("SUPPLY CONSOLE", 36, Color(0.5, 1.0, 0.85))
	box.add_child(title)
	_credits_label = _label("", 22, Color(1.0, 0.9, 0.4))
	box.add_child(_credits_label)
	_cards.add_theme_constant_override("separation", 18)
	box.add_child(_cards)
	var close := Button.new()
	close.text = "Close  [Esc / E]"
	close.custom_minimum_size = Vector2(220, 40)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func() -> void: closed.emit())
	box.add_child(close)


func open() -> void:
	refresh()
	show()


func refresh() -> void:
	_credits_label.text = "Credits: %d" % GameState.credits
	for child in _cards.get_children():
		child.queue_free()
	for category: Upgrades.Category in Upgrades.CATEGORY_NAMES:
		_cards.add_child(_card(category))


func _card(category: Upgrades.Category) -> Control:
	var color: Color = Upgrades.CATEGORY_COLORS[category]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 230)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(_label(Upgrades.CATEGORY_NAMES[category], 16, color))
	var id: String = GameState.shop_offers.get(category, "")
	if id.is_empty():
		box.add_child(_label("Fully upgraded", 20, Color.WHITE))
		return panel
	var info: Dictionary = Upgrades.CATALOG[id]
	var owned := GameState.upgrade_level(id)
	box.add_child(_label(info.name, 22, Color.WHITE))
	box.add_child(_label("Level %d / %d" % [owned, info.max], 14, Color(0.7, 0.75, 0.8)))
	var desc := _label(info.desc, 15, Color(0.85, 0.88, 0.92))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 220
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc)
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(0, 40)
	var price := Upgrades.cost(id, owned)
	if GameState.shop_bought.has(category):
		buy.text = "Purchased"
		buy.disabled = true
	else:
		buy.text = "Buy - %d cr" % price
		buy.disabled = GameState.credits < price
		buy.pressed.connect(func() -> void: purchased.emit(id))
	box.add_child(buy)
	return panel


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
