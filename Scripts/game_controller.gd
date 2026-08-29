extends Node2D

const POP_UP = preload("uid://q2a3umx2s1ny")
@onready var os: CanvasLayer = $os

@onready var terminalWindow: TextureRect = $os/Terminal/Window
@onready var _terminalTaskbarIcon: TextureRect = $os/Terminal/TaskbarIcon

@onready var startWindow: TextureRect = $os/Start/Window
@onready var _startTaskbarIcon: TextureRect = $os/Start/TaskbarIcon

@onready var settingsWindow: TextureRect = $os/Settings/Window
@onready var _settinsTaskbarIcon: TextureRect = $os/Settings/TaskbarIcon

@onready var readmeWindow: TextureRect = $os/Readme/Window
@onready var _readmeTaskbarIcon: TextureRect = $os/Readme/TaskbarIcon

@onready var progressWindow: TextureRect = $os/Progress/Window
@onready var _progressTaskbarIcon: TextureRect = $os/Progress/TaskbarIcon

@onready var successAudio: AudioStreamPlayer = $sfx/Success
@onready var beepAudio: AudioStreamPlayer = $sfx/Beep
@onready var glitchAudio: AudioStreamPlayer = $sfx/Glitch
@onready var progressBar: ProgressBar = $os/Progress/Window/Progress/BreachProgress

var popUpOpen: bool = false
var windowList 
var keyList

func _ready():
	windowList = [terminalWindow, _terminalTaskbarIcon, startWindow, _startTaskbarIcon, settingsWindow, _settinsTaskbarIcon, settingsWindow, _settinsTaskbarIcon, readmeWindow, _readmeTaskbarIcon, progressWindow, _progressTaskbarIcon]
	keyList = [$sfx/keystrokes/Key1, $sfx/keystrokes/Key2, $sfx/keystrokes/Key3, $sfx/keystrokes/Key4, $sfx/keystrokes/Key5, $sfx/keystrokes/Key6, $sfx/keystrokes/Key7]

func _process(delta: float) -> void:
	if(progressBar.value < 100):
		progressBar.value += delta * 1;
	else:
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
		"key":
			var i = randi_range(0, 5)
			keyList[i].play()
		"backspace":
			keyList[6].play()
		"enter":
			keyList[6].play()
		"glitch":
			glitchAudio.play()
	
func instantiatePopUp(message: String):
	popUpOpen = true
	var newPopup: Control = POP_UP.instantiate();
	os.add_child(newPopup);
	newPopup.setMessage(message)
	
func sendChat(message: String):
	pass
	
func showChatWindow(state: bool):
	pass

func addProgress(progress: float):
	progressBar.value += progress

func getProgress():
	print("Got progress")

func gameOver():
	print("Game Over")
