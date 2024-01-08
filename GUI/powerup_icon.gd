extends TextureRect

func _ready():
	Events.connect("info_panel_powerup_icon_display", display)
#
func display(powerup_type: int):
	if get_parent().get_meta("powerup_type", 0) != powerup_type:
		return

	texture.region = Rect2(Globals.POWERUP_COORDS[powerup_type].x * 16, 0, 16, 16)
