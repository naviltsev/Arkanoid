extends CenterContainer

func _ready():
	%BackButton.grab_focus()

func _on_back_button_pressed():
	Events.game_paused.emit()

func _on_exit_button_pressed():
	# we're in paused mode on game paused screen - unpause and load main menu
	Events.game_paused.emit()
	Globals.main_menu()
