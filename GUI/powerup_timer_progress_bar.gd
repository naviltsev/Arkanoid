extends ProgressBar

# PowerupTimer timer is located on the level scene
@onready var powerup_timer : Timer = get_tree().current_scene.get_node("PowerupTimer")

# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("disable_powerup", reset)
	reset()

func _process(delta):
	visible = true
	if powerup_timer.get_time_left() > 0:
		var time_left = powerup_timer.get_time_left()
		var time_total = powerup_timer.get_wait_time()
		value = time_left / time_total

func reset():
	value = 0
	visible = false
