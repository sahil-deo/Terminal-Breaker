extends Node

# --- SIGNALS ---
signal progress_updated(current_progress: float, max_progress: float)
signal attack_mitigated()
signal system_compromised()

# --- ENUMS & EXPORTS ---
enum ChallengeType {
	SCRAMBLE_ONE_WORD,
	SCRAMBLE_TWO_WORDS,
	CUSTOM_RULE,
	ANAGRAM
}

@export_group("Progress & Defense Parameters")
@export var max_mitigation_points: float = 100.0
@export var points_per_success: float = 15.0
@export var points_lost_on_error: float = 10.0

@export_group("Sabotage Configuration")
@export var is_second_half: bool = false
@export var second_half_threshold_pct: float = 50.0

# Two-way key swaps for the second half (e <-> a, i <-> o, t <-> r, etc.)
@export var key_swap_map: Dictionary = {
	"e": "a",
	"a": "e",
	"i": "o",
	"o": "i",
	"t": "r",
	"r": "t"
}

@export_group("Data File Paths")
@export_file("*.txt") var custom_rules_file: String = "res://data/custom_rules.txt"
@export_file("*.txt") var scramble_one_file: String = "res://data/scramble_one.txt"
@export_file("*.txt") var scramble_two_file: String = "res://data/scramble_two.txt"
@export_file("*.txt") var anagrams_file: String = "res://data/anagrams.txt"

# --- STATE VARIABLES ---
var current_mitigation: float = 0.0
var current_challenge_type: ChallengeType
var current_prompt_text: String = ""
var expected_answer: String = ""
var simulated_input: String = ""
var is_game_active: bool = true

# Loaded data pools
var pool_custom_rules: Array[Dictionary] = []
var pool_scramble_one: Array[String] = []
var pool_scramble_two: Array[String] = []
var pool_anagrams: Array[String] = []

func _ready() -> void:
	load_all_data_files()
	print("=================================================================")
	print(" [SYSTEM ALERT]: INTRUSION DETECTED. INITIATING COUNTERMEASURES  ")
	print("=================================================================")
	generate_new_challenge()

# --- FILE LOADING & VERIFICATION ---
func load_all_data_files() -> void:
	pool_custom_rules = load_key_value_file(custom_rules_file)
	pool_scramble_one = load_line_by_line_file(scramble_one_file)
	pool_scramble_two = load_line_by_line_file(scramble_two_file)
	pool_anagrams = load_line_by_line_file(anagrams_file)
	
	print("[SYSTEM]: Loaded %d custom rules, %d single words, %d dual words, %d anagrams." % [
		pool_custom_rules.size(),
		pool_scramble_one.size(),
		pool_scramble_two.size(),
		pool_anagrams.size()
	])

func load_line_by_line_file(path: String) -> Array[String]:
	var result: Array[String] = []
	if not FileAccess.file_exists(path):
		push_warning("File not found: " + path)
		return result
		
	var file = FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "" and not line.begins_with("#"):
			result.append(line)
	file.close()
	return result

func load_key_value_file(path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		push_warning("File not found: " + path)
		return result
		
	var file = FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "" and not line.begins_with("#") and line.contains("|"):
			var parts = line.split("|")
			result.append({
				"prompt": parts[0].strip_edges(),
				"answer": parts[1].strip_edges()
			})
	file.close()
	return result

# --- INPUT HANDLING WITH BIDIRECTIONAL SABOTAGE ---
func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			print("\n>>> DISPATCHING: ", simulated_input)
			verify_cipher(simulated_input.strip_edges().to_lower())
			simulated_input = ""
			if is_game_active:
				print_current_state()
		elif event.keycode == KEY_BACKSPACE:
			if simulated_input.length() > 0:
				simulated_input = simulated_input.left(-1)
				_on_simulated_text_changed()
		elif event.unicode != 0:
			var typed_char = String.chr(event.unicode)
			# Apply bidirectional swap if active
			typed_char = apply_bidirectional_swap(typed_char)
			simulated_input += typed_char
			_on_simulated_text_changed()

func apply_bidirectional_swap(char_in: String) -> String:
	var current_pct = (current_mitigation / max_mitigation_points) * 100.0
	if not is_second_half and current_pct < second_half_threshold_pct:
		return char_in
		
	var lower_char = char_in.to_lower()
	if key_swap_map.has(lower_char):
		return key_swap_map[lower_char]
		
	return char_in

func _on_simulated_text_changed() -> void:
	trigger_display_scramble()
	print_current_state()

func print_current_state() -> void:
	var progress_pct = (current_mitigation / max_mitigation_points) * 100.0
	print("\r[DEFENSE: %.1f%%] | [PROMPT]: %s | [BUFFER]: %s" % [progress_pct, current_prompt_text, simulated_input])

# --- CHALLENGE GENERATOR ---
func generate_new_challenge() -> void:
	# Build a list of only valid categories that have loaded entries
	var available_types: Array[ChallengeType] = []
	if pool_scramble_one.size() > 0: available_types.append(ChallengeType.SCRAMBLE_ONE_WORD)
	if pool_scramble_two.size() > 0: available_types.append(ChallengeType.SCRAMBLE_TWO_WORDS)
	if pool_custom_rules.size() > 0: available_types.append(ChallengeType.CUSTOM_RULE)
	if pool_anagrams.size() > 0: available_types.append(ChallengeType.ANAGRAM)
	
	if available_types.is_empty():
		push_error("All data pools are empty! Please check your text files in res://data/")
		return
		
	current_challenge_type = available_types.pick_random()
	
	match current_challenge_type:
		ChallengeType.SCRAMBLE_ONE_WORD:
			expected_answer = pool_scramble_one.pick_random()
			current_prompt_text = "PATCH TARGET: " + expected_answer
			
		ChallengeType.SCRAMBLE_TWO_WORDS:
			expected_answer = pool_scramble_two.pick_random()
			current_prompt_text = "ISOLATE: " + expected_answer
			
		ChallengeType.CUSTOM_RULE:
			var rule = pool_custom_rules.pick_random()
			current_prompt_text = "RULE: " + rule["prompt"]
			expected_answer = rule["answer"]
				
		ChallengeType.ANAGRAM:
			var base_word = pool_anagrams.pick_random()
			expected_answer = base_word
			current_prompt_text = "DECRYPT ANAGRAM: " + scramble_string(base_word)
			
	print("\n--- INTRUSION VECTOR UPDATED ---")
	print_current_state()

# --- DISPLAY MUTATION ---
func trigger_display_scramble() -> void:
	if current_challenge_type in [ChallengeType.SCRAMBLE_ONE_WORD, ChallengeType.SCRAMBLE_TWO_WORDS]:
		if randf() > 0.9: # 25% chance per keystroke to shift prompt
			var char_index = randi() % expected_answer.length()
			if expected_answer[char_index] != " ":
				var random_char = String.chr(randi_range(97, 122))
				var char_array = expected_answer.split("")
				char_array[char_index] = random_char
				expected_answer = "".join(char_array)
				current_prompt_text = "TARGET: " + expected_answer

func scramble_string(word: String) -> String:
	var chars = word.split("")
	var scrambled = ""
	while chars.size() > 0:
		var index = randi() % chars.size()
		scrambled += chars[index]
		chars.remove_at(index)
	return scrambled

# --- VERIFICATION & PROGRESSION ---
func verify_cipher(player_input: String) -> void:
	var is_correct = false
	
	if current_challenge_type == ChallengeType.ANAGRAM:
		is_correct = verify_anagram(player_input, expected_answer)
	else:
		is_correct = (player_input == expected_answer)
		
	if is_correct:
		current_mitigation = min(current_mitigation + points_per_success, max_mitigation_points)
		progress_updated.emit(current_mitigation, max_mitigation_points)
		print("[STATUS: SUCCESS] Packet neutralized. Defense rating elevated.")
		
		if current_mitigation >= max_mitigation_points:
			complete_defense_sequence()
			return
			
		generate_new_challenge()
	else:
		current_mitigation = max(current_mitigation - points_lost_on_error, 0.0)
		progress_updated.emit(current_mitigation, max_mitigation_points)
		print("[STATUS: BREACH] Command syntax rejected! Defense compromised by -%.0f pts. Expected: %s" % [points_lost_on_error, expected_answer])

func verify_anagram(input_str: String, target_str: String) -> bool:
	if input_str.length() != target_str.length(): return false
	var input_arr = input_str.split("")
	var target_arr = target_str.split("")
	input_arr.sort()
	target_arr.sort()
	return input_arr == target_arr

func complete_defense_sequence() -> void:
	is_game_active = false
	attack_mitigated.emit()
	print("\n=================================================================")
	print(" [SUCCESS]: INTRUSION VECTOR FULLY NEUTRALIZED.                 ")
	print(" [STATUS]: SYSTEM INTEGRITY RESTORED TO 100.0%.                  ")
	print(" [LOG]: ALL MALICIOUS DAEMONS QUARANTINED. THREAT DEFENDED.     ")
	print("=================================================================")
