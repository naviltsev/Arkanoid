extends Line2D

const MAX_LENGTH = 10

var points_queue : Array

func _ready():
	visible = false

func _process(delta):
	var pos = get_parent().position
	
	points_queue.push_front(pos)
	if points_queue.size() > MAX_LENGTH:
		points_queue.pop_back()
	
	clear_points()

	for point in points_queue:
		add_point(point)
