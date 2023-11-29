extends TextureRect


# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("enable_powerup", display_powerup_icon)
	Events.connect("disable_powerup", reset)

func display_powerup_icon(powerup_type: int):
	# no need to display Clear Level powerup as this immediately
	# switches to the next level
	if Globals.is_powerup_active(Globals.POWERUP_CLEAR_LEVEL):
		return

	visible = true
	texture.region = Rect2(Globals.POWERUP_COORDS[powerup_type].x * 16, 0, 16, 16)

func reset(powerup_type: int):
	visible = false
