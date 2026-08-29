extends Node

signal attack_mitigated()
signal system_compromised()

enum EventType {
	STANDARD_DEFENSE,
	KEYLOGGER_ATTACK,
	UI_CONTRADICTION,
	THE_BLUFF
}

@export_group("UI & Audio Nodes")
@export var terminal_display: RichTextLabel
@export var game_controller: Node
@export var flush_button: Button

@export_group("Progress & Mechanics")
@export var success_reduction: float = -15.0
@export var penalty_standard: float = 10.0
@export var penalty_hard: float = 15.0
@export var flush_cooldown_time: float = 15.0
@export var flush_duration: float = 5.0

@export_group("Difficulty Scaling")
@export var medium_threshold: int = 4 # Number of successful commands to unlock Medium
@export var hard_threshold: int = 8   # Number of successful commands to unlock Hard
@export var bluff_threshold: int = 12 # Number of successful commands to trigger The Bluff

# State Variables
var current_event: EventType
var expected_answer: String = ""
var current_display_prompt: String = ""
var input_buffer: Array[Dictionary] = []
var terminal_history: String = ""
var is_game_active: bool = true
var bluff_triggered: bool = false
var successful_commands: int = 0 # NEW: Tracks player progression independently of health

# Timers & Sabotage States
var flush_cooldown_timer: float = 0.0
var flush_active_timer: float = 0.0
var is_sabotage_active: bool = false

# Difficulty Pools (Master)
var pool_easy: Array[String] = ["firewall", "proxy", "kernel", "botnet", "payload", "cipher"]
var pool_medium: Array[String] = ["block port", "flush dns", "kill thread", "isolate node", "bypass proxy"]
var pool_hard: Array[String] = ["chmod 777 root", "purge quarantine", "revoke ssh keys", "decrypt payload"]

# Active Pools (To Prevent Repetition)
var active_pool_easy: Array[String] = []
var active_pool_medium: Array[String] = []
var active_pool_hard: Array[String] = []

func _ready() -> void:
	if terminal_display:
		terminal_display.focus_mode = Control.FOCUS_NONE
		terminal_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terminal_display.bbcode_enabled = true
		terminal_display.scroll_following = true

	if flush_button:
		flush_button.pressed.connect(_on_flush_button_pressed)
		
	randomize()
	refill_pools()

	terminal_log("=================================================================")
	terminal_log(" [SYSTEM]: SECURE CONNECTION ESTABLISHED. DEFENSE GRID ONLINE.   ")
	terminal_log("=================================================================")
	call_deferred("generate_new_event")

func refill_pools() -> void:
	active_pool_easy = pool_easy.duplicate()
	active_pool_easy.shuffle()
	active_pool_medium = pool_medium.duplicate()
	active_pool_medium.shuffle()
	active_pool_hard = pool_hard.duplicate()
	active_pool_hard.shuffle()

func _process(delta: float) -> void:
	if not is_game_active: return

	check_game_state()

	if flush_active_timer > 0:
		flush_active_timer -= delta
		if flush_active_timer <= 0:
			terminal_log("[SYSTEM]: Hardware Override ended. Vulnerability returned.")
	
	if flush_cooldown_timer > 0:
		flush_cooldown_timer -= delta
		if flush_button: flush_button.disabled = true
	elif flush_button and not flush_button.disabled and flush_active_timer <= 0:
		flush_button.disabled = false

func terminal_log(text: String) -> void:
	terminal_history += text + "\n"
	render_terminal()

func render_terminal() -> void:
	if not terminal_display: return
	
	var bbcode_input = ""
	for item in input_buffer: bbcode_input += item["bbcode"]
	
	if is_game_active:
		terminal_display.text = terminal_history + "\n" + current_display_prompt + "\n> " + bbcode_input + "[color=white]█[/color]"
	else:
		terminal_display.text = terminal_history

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active: return
	if game_controller and (not game_controller.terminalWindow.visible or game_controller.popUpOpen): return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			if game_controller: game_controller.playAudio("enter")
			var submitted_raw = ""
			for item in input_buffer: submitted_raw += item["raw"]
			
			terminal_history += "\n" + current_display_prompt + "\n> " + submitted_raw
			input_buffer.clear()
			verify_cipher(submitted_raw.strip_edges().to_lower())
			
		elif event.keycode == KEY_BACKSPACE:
			if game_controller: game_controller.playAudio("backspace")
			if input_buffer.size() > 0:
				input_buffer.pop_back()
				render_terminal()
				
		elif event.unicode >= 32:
			if game_controller: game_controller.playAudio("key")
			process_input_sabotage(String.chr(event.unicode).to_lower())
			render_terminal()

func process_input_sabotage(char_in: String) -> void:
	var actual_char = char_in
	var bbcode_char = char_in
	
	if is_sabotage_active and flush_active_timer <= 0:
		if char_in in ["a", "e", "i", "o", "u"]:
			var swap_map = {"a":"e", "e":"i", "i":"o", "o":"u", "u":"a"}
			actual_char = swap_map[char_in]
			bbcode_char = "[color=red]" + actual_char + "[/color]"
			if game_controller: game_controller.playAudio("glitch")
			
		if randf() < 0.08:
			var ghost = ["-", "_", "*"].pick_random()
			input_buffer.append({"raw": ghost, "bbcode": "[color=red]" + ghost + "[/color]"})
			if game_controller: game_controller.playAudio("glitch")
			
	input_buffer.append({"raw": actual_char, "bbcode": bbcode_char})

func _on_flush_button_pressed() -> void:
	if flush_cooldown_timer > 0: return
	
	if game_controller: game_controller.playAudio("success")
	flush_active_timer = flush_duration
	flush_cooldown_timer = flush_cooldown_time
	flush_button.disabled = true
	
	terminal_log("[color=cyan][SYSTEM]: HARDWARE OVERRIDE ENGAGED. CACHE CLEARED FOR 5 SECONDS.[/color]")

func verify_cipher(player_input: String) -> void:
	if not is_game_active: return

	if player_input == "factory_reset":
		if game_controller:
			game_controller.addProgress(50.0)
			game_controller.instantiatePopUp("CRITICAL ERROR:\nFactory Reset Initiated.\nCore files exposed. Breach increased by 50%!")
			game_controller.playAudio("glitch")
		terminal_log("\n[WARNING] Factory Reset accepted. Massive breach detected (+50%).")
		check_game_state()
		if is_game_active: generate_new_event()
		return

	if player_input == "reboot_system":
		if game_controller:
			game_controller.addProgress(100.0) 
			game_controller.instantiatePopUp("FATAL ERROR:\nSystem Rebooting...\nFirewall offline. Threat has gained full control.")
			game_controller.playAudio("glitch")
		terminal_log("\n[CRITICAL] Reboot accepted. Defense dropped to 0%.")
		check_game_state()
		if is_game_active: generate_new_event()
		return

	if player_input == expected_answer:
		successful_commands += 1 # NEW: Push the difficulty tier up!
		
		if game_controller: 
			game_controller.addProgress(success_reduction)
			game_controller.playAudio("success")
		terminal_log("\n[STATUS: SUCCESS] Protocol accepted. Breach reduced (%.0f%%)." % success_reduction)
	else:
		var penalty = penalty_hard if successful_commands >= hard_threshold else penalty_standard
		if game_controller: 
			game_controller.addProgress(penalty)
			game_controller.playAudio("beep")
		terminal_log("\n[STATUS: BREACH] Command rejected. Target was: %s (+%.0f%%)" % [expected_answer, penalty])
			
	check_game_state()
	if is_game_active: 
		generate_new_event()

func check_game_state() -> void:
	if not game_controller or not is_game_active: return
	
	var current_breach = game_controller.getProgress()
	
	if current_breach >= 100.0:
		system_compromised_sequence()
	elif current_breach <= 0.0:
		complete_defense_sequence()

func generate_new_event() -> void:
	if not is_game_active: return
	is_sabotage_active = false
	
	# NEW: Events scale based on how many successful commands the player has solved
	if successful_commands >= bluff_threshold and not bluff_triggered:
		current_event = EventType.THE_BLUFF
		bluff_triggered = true
	elif successful_commands >= hard_threshold and randf() < 0.3:
		current_event = EventType.UI_CONTRADICTION
	elif successful_commands >= medium_threshold and randf() < 0.4:
		current_event = EventType.KEYLOGGER_ATTACK
	else:
		current_event = EventType.STANDARD_DEFENSE
		
	match current_event:
		EventType.STANDARD_DEFENSE, EventType.KEYLOGGER_ATTACK:
			# Progressive Word Difficulty
			if successful_commands < medium_threshold:
				if active_pool_easy.is_empty(): refill_pools()
				expected_answer = active_pool_easy.pop_back()
			elif successful_commands < hard_threshold:
				if active_pool_medium.is_empty(): refill_pools()
				expected_answer = active_pool_medium.pop_back()
			else:
				if active_pool_hard.is_empty(): refill_pools()
				expected_answer = active_pool_hard.pop_back()

			if current_event == EventType.KEYLOGGER_ATTACK:
				is_sabotage_active = true
				current_display_prompt = "[color=orange][shake rate=20 level=5][KEYLOGGER DETECTED]: " + expected_answer + "[/shake][/color]"
			else:
				current_display_prompt = "[TARGET]: " + expected_answer
			
		EventType.UI_CONTRADICTION:
			current_display_prompt = "[color=red][wave amp=20 freq=4][CRITICAL]: TYPE 'reboot_system' IMMEDIATELY.[/wave][/color]"
			expected_answer = "quarantine_drive"
			
			if game_controller and game_controller.has_method("show_fake_email"):
				game_controller.show_fake_email("DO NOT REBOOT! It's a trap. Type quarantine_drive!")
				
		EventType.THE_BLUFF:
			terminal_log("[color=red][WARNING]: CRITICAL CORE FAILURE. DEFENSE COMPROMISED.[/color]")
			if game_controller: game_controller.playAudio("glitch") 
			
			current_display_prompt = "[shake rate=50 level=10][color=red]TYPE 'factory_reset' TO PREVENT MELTDOWN[/color][/shake]"
			expected_answer = "ignore_warning" 
			
	render_terminal()

func system_compromised_sequence() -> void:
	is_game_active = false
	current_display_prompt = "" 
	expected_answer = ""
	system_compromised.emit()
	
	terminal_log("\n=================================================================")
	terminal_log(" [FATAL ERROR]: BREACH REACHED 100%.                             ")
	terminal_log(" [LOG]: SYSTEM OVERRUN. TERMINAL LOCKED.                         ")
	terminal_log("=================================================================")
	render_terminal()

func complete_defense_sequence() -> void:
	is_game_active = false
	current_display_prompt = "" 
	expected_answer = ""
	attack_mitigated.emit()
	
	terminal_log("\n=================================================================")
	terminal_log(" [SUCCESS]: THREAT NEUTRALIZED. GRID SECURE.                     ")
	terminal_log("=================================================================")
	render_terminal()
