extends Label

func _ready():
	Events.connect("player_lives_updated", update_lives)

	# reset lives counter
	update_lives(Globals.lives)

func update_lives(lives: int):
	text = str(lives)
