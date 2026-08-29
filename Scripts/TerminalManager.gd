extends Node

signal progress_updated(current_progress: float, max_progress: float)
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
@export var max_mitigation_points: float = 100.0
@export var points_per_success: float = 15.0
@export var flush_cooldown_time: float = 15.0
@export var flush_duration: float = 5.0

# State Variables
var current_mitigation: float = 0.0
var current_event: EventType
var expected_answer: String = ""
var current_display_prompt: String = ""
var input_buffer: Array[Dictionary] = []
var terminal_history: String = ""
var is_game_active: bool = true
var bluff_triggered: bool = false

# Timers & Sabotage States
var flush_cooldown_timer: float = 0.0
var flush_active_timer: float = 0.0
var is_sabotage_active: bool = false

# Standard Pools
var pool_standard: Array[String] = ["firewall", "block_port", "flush_dns", "kill_thread"]

func _ready() -> void:
	if terminal_display:
		terminal_display.focus_mode = Control.FOCUS_NONE
		terminal_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terminal_display.bbcode_enabled = true
		terminal_display.scroll_following = true

	if flush_button:
		flush_button.pressed.connect(_on_flush_button_pressed)

	terminal_log("=================================================================")
	terminal_log(" [SYSTEM]: SECURE CONNECTION ESTABLISHED. DEFENSE GRID ONLINE.   ")
	terminal_log("=================================================================")
	generate_new_event()

func _process(delta: float) -> void:
	if not is_game_active: return

	# Handle Hardware Flush Timers
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
	
	var progress_pct = (current_mitigation / max_mitigation_points) * 100.0
	var display_pct = progress_pct
	var status_color = "green"
	
	# MECHANIC 3: THE BLUFF (Visual Fake-out)
	if current_event == EventType.THE_BLUFF:
		display_pct = 12.4 # Fake critical drop
		status_color = "red"
	elif progress_pct < 50.0: status_color = "red"
	elif progress_pct < 85.0: status_color = "yellow"
		
	var status_bar = "[color=%s][DEFENSE INTEGRITY: %.1f%%][/color]" % [status_color, display_pct]
	
	var bbcode_input = ""
	for item in input_buffer: bbcode_input += item["bbcode"]
	
	var active_prompt = current_display_prompt
	
	terminal_display.text = terminal_history + "\n" + status_bar + "\n" + active_prompt + "\n> " + bbcode_input + "[color=white]█[/color]"

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

# MECHANIC 4: Localized Sabotage (Only active during Keylogger Events)
func process_input_sabotage(char_in: String) -> void:
	var actual_char = char_in
	var bbcode_char = char_in
	
	# If Sabotage is active AND the player hasn't pressed the Flush button
	if is_sabotage_active and flush_active_timer <= 0:
		# Vowel Swap
		if char_in in ["a", "e", "i", "o", "u"]:
			var swap_map = {"a":"e", "e":"i", "i":"o", "o":"u", "u":"a"}
			actual_char = swap_map[char_in]
			bbcode_char = "[color=red]" + actual_char + "[/color]"
			if game_controller: game_controller.playAudio("glitch")
			
		# Ghost Keys
		if randf() < 0.08:
			var ghost = ["-", "_", "*"].pick_random()
			input_buffer.append({"raw": ghost, "bbcode": "[color=red]" + ghost + "[/color]"})
			if game_controller: game_controller.playAudio("glitch")
			
	input_buffer.append({"raw": actual_char, "bbcode": bbcode_char})

# MECHANIC 2: Player Agency (Hardware Flush)
func _on_flush_button_pressed() -> void:
	if flush_cooldown_timer > 0: return
	
	if game_controller: game_controller.playAudio("success")
	flush_active_timer = flush_duration
	flush_cooldown_timer = flush_cooldown_time
	flush_button.disabled = true
	
	terminal_log("[color=cyan][SYSTEM]: HARDWARE OVERRIDE ENGAGED. CACHE CLEARED FOR 5 SECONDS.[/color]")

func verify_cipher(player_input: String) -> void:
	if player_input == expected_answer:
		current_mitigation = min(current_mitigation + points_per_success, max_mitigation_points)
		terminal_log("\n[STATUS: SUCCESS] Protocol accepted.")
		if game_controller: game_controller.playAudio("success")
			
		if current_mitigation >= max_mitigation_points:
			complete_defense_sequence()
			return
	else:
		var penalty = 15.0 if current_mitigation > 50.0 else 10.0
		current_mitigation = max(current_mitigation - penalty, 0.0)
		terminal_log("\n[STATUS: BREACH] Command rejected. Target was: " + expected_answer)
		if game_controller: game_controller.playAudio("beep")
			
	generate_new_event()

func generate_new_event() -> void:
	is_sabotage_active = false
	var pct = (current_mitigation / max_mitigation_points) * 100.0
	
	# Determine Event Type
	if pct >= 90.0 and not bluff_triggered:
		current_event = EventType.THE_BLUFF
		bluff_triggered = true
	elif pct >= 40.0 and randf() < 0.4:
		current_event = EventType.UI_CONTRADICTION
	elif pct >= 20.0 and randf() < 0.5:
		current_event = EventType.KEYLOGGER_ATTACK
	else:
		current_event = EventType.STANDARD_DEFENSE
		
	# Setup Specific Event Mechanics
	match current_event:
		EventType.STANDARD_DEFENSE:
			expected_answer = pool_standard.pick_random()
			current_display_prompt = "[TARGET]: " + expected_answer
			
		EventType.KEYLOGGER_ATTACK:
			is_sabotage_active = true
			expected_answer = pool_standard.pick_random()
			# VISUAL TELL: The prompt shakes slightly to indicate a localized attack
			current_display_prompt = "[color=orange][shake rate=20 level=5][KEYLOGGER DETECTED]: " + expected_answer + "[/shake][/color]"
			
		EventType.UI_CONTRADICTION:
			# MECHANIC 1: Competing Authorities
			# Terminal asks for reboot, but the true answer to survive is quarantine
			current_display_prompt = "[color=red][wave amp=20 freq=4][CRITICAL]: TYPE 'reboot_system' IMMEDIATELY.[/wave][/color]"
			expected_answer = "quarantine_drive"
			
			# Trigger your UI popup via GameController
			if game_controller and game_controller.has_method("show_fake_email"):
				game_controller.show_fake_email("DO NOT REBOOT! It's a trap. Type quarantine_drive!")
			else:
				# Fallback if method doesn't exist yet
				terminal_log("[MESSAGE FROM: SYS_ADMIN]: Do not trust the prompt! Type 'quarantine_drive'!")
				
		EventType.THE_BLUFF:
			# MECHANIC 3: The Fake-Out
			# The progress bar will artificially drop in render_terminal()
			terminal_log("[color=red][WARNING]: CRITICAL CORE FAILURE. DEFENSE COMPROMISED.[/color]")
			if game_controller: game_controller.playAudio("glitch") # Play a loud siren here in your actual game
			
			current_display_prompt = "[shake rate=50 level=10][color=red]TYPE 'factory_reset' TO PREVENT MELTDOWN[/color][/shake]"
			expected_answer = "ignore_warning" # If they type factory_reset, they fail the check and lose points
			
	render_terminal()

func complete_defense_sequence() -> void:
	is_game_active = false
	attack_mitigated.emit()
	terminal_log("\n=================================================================")
	terminal_log(" [SUCCESS]: THREAT NEUTRALIZED. GRID SECURE.                     ")
	terminal_log("=================================================================")
	render_terminal()
