extends Label

func _ready():
	Events.connect("player_score_increment", increment_score)
	text = str(0)

func increment_score(delta: int):
	text = str(text.to_int() + delta)
