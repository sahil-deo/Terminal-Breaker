extends Node2D

const POP_UP = preload("uid://q2a3umx2s1ny")
@onready var os: CanvasLayer = $os

@onready var terminalWindow: TextureRect = $os/Terminal/Window
@onready var terminalTaskbarIcon: TextureRect = $os/Terminal/TaskbarIcon

@onready var startWindow: TextureRect = $os/Start/Window
@onready var startTaskbarIcon: TextureRect = $os/Start/TaskbarIcon

@onready var settingsWindow: TextureRect = $os/Settings/Window
@onready var settinsTaskbarIcon: TextureRect = $os/Settings/TaskbarIcon

@onready var readmeWindow: TextureRect = $os/Readme/Window
@onready var readmeTaskbarIcon: TextureRect = $os/Readme/TaskbarIcon

@onready var successAudio: AudioStreamPlayer = $vfx/Success
@onready var beepAudio: AudioStreamPlayer = $vfx/Beep

var windowList 

func _ready():
	windowList = [terminalWindow, terminalTaskbarIcon, startWindow, startTaskbarIcon, settingsWindow, settinsTaskbarIcon, settingsWindow, settinsTaskbarIcon, readmeWindow, readmeTaskbarIcon]
	instantiatePopUp("Hello")
	pass

func showWindow(window, icon) -> void:
	for w in windowList:
		if(w == window or w == icon):
			w.visible = true
			continue
		w.visible=false

func playAudio(case: String):
	match case: 
		"beep":
			beepAudio.play()
			instantiatePopUp("WRONG!!!")
		"success":
			successAudio.play()
			instantiatePopUp("CORRECT!!!")
	
func instantiatePopUp(message: String):
	var newPopup: Control = POP_UP.instantiate();
	os.add_child(newPopup);
	newPopup.setMessage(message)
	pass
