extends ProgressBar

# a reference to a power-up timer
# Timer node is instantiated by globals.gd and added to the main scene
var timer : Timer

func _ready():
	value = 0
	Events.info_panel_powerup_timer_init.connect(init)

func init(powerup_type: int):
	if get_parent().get_meta("powerup_type") != powerup_type:
		return

	timer = Globals.get_powerup_timer_node(powerup_type)

func _process(_delta):
	if !timer:
		return

	if timer.get_time_left() > 0:
		var time_left = timer.get_time_left()
		var time_total = timer.get_wait_time()
		value = time_left / time_total
