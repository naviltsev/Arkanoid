extends Node2D

@onready var progress_bar : ProgressBar = $PanelContainer/MarginContainer/VBoxContainer/ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready():
	print(progress_bar.value)
	progress_bar.value = 100


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
