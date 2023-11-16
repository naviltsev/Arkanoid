extends Line2D

# points in trail for regular ball
const DEFAULT_POINTS_LENGTH = 10

# points in trail for heavy ball
const HEAVY_POINTS_LENGTH = 15

# trail width for regular ball
const DEFAULT_WIDTH = 20

# trail width for heavy ball
const HEAVY_WIDTH = 30

var length = DEFAULT_POINTS_LENGTH
var points_queue : Array

func _ready():
	visible = false
	width = DEFAULT_WIDTH

func _process(delta):
	var pos = get_parent().position

	points_queue.push_front(pos)

	#
	# FIXME points_queue don't get shrinked when ball turns from heavy to regular
	#
	if points_queue.size() > length:
		points_queue.pop_back()

	clear_points()

	for point in points_queue:
		add_point(point)

# A trail for regular ball
func regular_trail():
	width = DEFAULT_WIDTH
	length = DEFAULT_POINTS_LENGTH

	_shorten_trail_gradually()

func heavy_trail():
	width = HEAVY_WIDTH
	length = HEAVY_POINTS_LENGTH

# Shortens trail's visible length gradually
# by recursively calling itself and shortening trail length
# every 0.1 seconds
func _shorten_trail_gradually():
	await get_tree().create_timer(0.1).timeout

	if points_queue.size() > length:
		points_queue.pop_back()
		_shorten_trail_gradually()

