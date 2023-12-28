extends TileMap

var original_position = Vector2.ZERO

func _ready():
	# save original position of the logo
	original_position = position

func _process(_delta):
	var pos_x_delta = randi_range(-5, 5)
	var pos_y_delta = randi_range(-5, 5)

	# randomly shake the logo
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(
		original_position.x + pos_x_delta,
		original_position.y + pos_y_delta
	), 0.2)
