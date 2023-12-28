extends Label

func _ready():
	Events.connect("player_score_increment", increment_score)
	text = str(Globals.player_score)

func increment_score(delta: int):
	var multiplier = 1
	if Globals.is_powerup_active(Globals.POWERUP_DOUBLE_SCORE):
		multiplier = 2

	text = str(text.to_int() + delta * multiplier)
