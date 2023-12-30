extends CenterContainer

@onready var audio_button_focus : AudioStreamPlayer = $AudioButtonFocus
@onready var audio_button_click : AudioStreamPlayer = $AudioButtonClick

func _ready():
	%BackButton.grab_focus()

func _on_back_button_pressed():
	audio_button_click.play()
	await audio_button_click.finished
	Events.game_paused.emit()

func _on_exit_button_pressed():
	audio_button_click.play()
	await audio_button_click.finished

	# we're in paused mode on game paused screen - unpause and load main menu
	Events.game_paused.emit()
	Globals.main_menu()

func _on_back_button_focus_exited():
	audio_button_focus.play()

func _on_exit_button_focus_exited():
	audio_button_focus.play()
