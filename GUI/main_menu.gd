extends Node2D

@onready var audio_button_focus : AudioStreamPlayer = $AudioButtonFocus
@onready var audio_button_click : AudioStreamPlayer = $AudioButtonClick

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	%StartButton.grab_focus()

func _on_start_button_pressed():
	audio_button_click.play()

	Globals.start_game()
	
	# work-around - wait for 1 sec before removing main menu
	# to give scene transitioner some time to fade in
	await get_tree().create_timer(1).timeout
	queue_free()

func _on_exit_button_pressed():
	audio_button_click.play()
	await audio_button_click.finished
	get_tree().quit()

func _on_start_button_focus_exited():
	audio_button_focus.play()
	await audio_button_focus.finished

func _on_exit_button_focus_exited():
	audio_button_focus.play()
	await audio_button_focus.finished
