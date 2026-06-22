extends Node

const ButtonScript = preload("res://scripts/button.gd")
const NoteScript = preload("res://scripts/note.gd")
const ConductorScript = preload("res://scripts/conductor.gd")

# Semitone offsets from C4 for each chord (root, third, fifth, seventh)
const CHORD_NOTES: Dictionary = {
	0: [0,  4,  7, 11],
	1: [-10, -7, -3,  0],
	2: [-8, -5, -1,  2],
	3: [-7, -3,  0,  4],
	4: [-5, -1,  2,  5],
	5: [-3,  0,  4,  7],
	6: [-1,  2,  5,  8],
}

@export var rhodes_c4: AudioStream

@export var kick: AudioStream
@export var hihat_closed: AudioStream
@export var hihat_open: AudioStream
@export var clap: AudioStream
@export var snare: AudioStream
@export var shaker: AudioStream
@export var conga_open: AudioStream
@export var conga_slap: AudioStream
@export var bass: AudioStream

var playback: AudioStreamPlaybackPolyphonic
var drumPlayback: AudioStreamPlaybackPolyphonic
var bass_playback: AudioStreamPlaybackPolyphonic

var active_chord_streams: Array = []
var currentSection: int = 0
var currentIntensity: float = 0.2
var currentCycle: int = 0
var active_bass_id: int = 0

var currentBar: int = 0
var isFill: bool = false

enum Genre { HOUSE = 0, TECH_HOUSE = 1, TECHNO = 2, MELODIC_HOUSE = 3, AFRO_HOUSE = 4, AFRO_TECHNO = 5 }
var currentGenre: int = Genre.TECHNO

enum Instrument { RHODES, KICK, HIHAT_CLOSED, HIHAT_OPEN, CLAP, SNARE, SHAKER, CONGA_OPEN, CONGA_SLAP, CHORD_STAB }
enum SoundState { PENDING, HIT }

const MISS_VOLUME_DB_OFFSET: float = -20.0

# Computed in _ready() from geometry constants — not hardcoded
var lookaheadSubdivs: int = 0

# Key offset per genre (semitones from C4)
const GENRE_KEY_OFFSET: Dictionary = {
	Genre.HOUSE:         0,
	Genre.TECH_HOUSE:   -3,
	Genre.TECHNO:       -5,
	Genre.MELODIC_HOUSE: 5,
	Genre.AFRO_HOUSE:   -3,
	Genre.AFRO_TECHNO:  -5,
}
var keyOffset: int = -5

const GENRE_BPM: Dictionary = {
	Genre.HOUSE:         122,
	Genre.TECH_HOUSE:   128,
	Genre.TECHNO:       135,
	Genre.MELODIC_HOUSE: 123,
	Genre.AFRO_HOUSE:   122,
	Genre.AFRO_TECHNO:  132,
}

# Section density multipliers per instrument (INTRO/BUILD/DROP/BREAK)
const KICK_SECTION_DENSITY: Dictionary   = { 0: 0.70, 1: 0.85, 2: 1.00, 3: 0.60 }
const HIHAT_SECTION_DENSITY: Dictionary  = { 0: 0.50, 1: 0.75, 2: 1.00, 3: 0.25 }
const RHODES_SECTION_DENSITY: Dictionary = { 0: 0.40, 1: 0.70, 2: 1.00, 3: 0.20 }
const CLAP_SECTION_DENSITY: Dictionary   = { 0: 0.30, 1: 0.70, 2: 1.00, 3: 0.40 }
const CONGA_SECTION_DENSITY: Dictionary  = { 0: 0.40, 1: 0.70, 2: 1.00, 3: 0.50 }

# Markov probability tables per genre.
# Arrays are indexed 0–7 (subdivision positions 1–8).
# "h" = probability of firing given previous position fired.
# "n" = probability of firing given previous position did NOT fire.
const KICK_MARKOV: Dictionary = {
	Genre.HOUSE:         {"h": [0.85, 0.15, 0.85, 0.15, 0.85, 0.15, 0.85, 0.15],
						  "n": [0.90, 0.10, 0.90, 0.10, 0.90, 0.10, 0.90, 0.10]},
	Genre.TECH_HOUSE:    {"h": [0.85, 0.20, 0.85, 0.20, 0.85, 0.35, 0.85, 0.15],
						  "n": [0.90, 0.15, 0.90, 0.15, 0.90, 0.30, 0.90, 0.10]},
	Genre.TECHNO:        {"h": [0.95, 0.05, 0.95, 0.05, 0.95, 0.05, 0.95, 0.05],
						  "n": [0.95, 0.05, 0.95, 0.05, 0.95, 0.05, 0.95, 0.05]},
	Genre.MELODIC_HOUSE: {"h": [0.85, 0.10, 0.85, 0.10, 0.85, 0.10, 0.85, 0.10],
						  "n": [0.90, 0.05, 0.90, 0.05, 0.90, 0.05, 0.90, 0.05]},
	Genre.AFRO_HOUSE:    {"h": [0.80, 0.25, 0.80, 0.25, 0.80, 0.40, 0.75, 0.20],
						  "n": [0.85, 0.20, 0.85, 0.20, 0.85, 0.45, 0.80, 0.15]},
	Genre.AFRO_TECHNO:   {"h": [0.90, 0.10, 0.90, 0.15, 0.90, 0.30, 0.85, 0.10],
						  "n": [0.90, 0.10, 0.90, 0.15, 0.90, 0.35, 0.90, 0.10]},
}

const HIHAT_CLOSED_MARKOV: Dictionary = {
	Genre.HOUSE:         {"h": [0.80, 0.80, 0.80, 0.80, 0.80, 0.80, 0.80, 0.80],  # dense all subdivisions
						  "n": [0.85, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85]},
	Genre.TECH_HOUSE:    {"h": [0.10, 0.15, 0.10, 0.15, 0.10, 0.15, 0.10, 0.15],  # tight off-beat
						  "n": [0.10, 0.85, 0.10, 0.85, 0.10, 0.85, 0.10, 0.85]},
	Genre.TECHNO:        {"h": [0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05],  # strict off-beat
						  "n": [0.05, 0.92, 0.05, 0.92, 0.05, 0.92, 0.05, 0.92]},
	Genre.MELODIC_HOUSE: {"h": [0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05],  # sparse [2,6]
						  "n": [0.05, 0.80, 0.05, 0.05, 0.05, 0.80, 0.05, 0.05]},
	Genre.AFRO_HOUSE:    {"h": [0.30, 0.20, 0.40, 0.15, 0.70, 0.15, 0.25, 0.20],  # syncopated
						  "n": [0.70, 0.20, 0.70, 0.15, 0.65, 0.75, 0.20, 0.75]},
	Genre.AFRO_TECHNO:   {"h": [0.10, 0.15, 0.10, 0.15, 0.10, 0.20, 0.10, 0.15],  # off-beat tribal
						  "n": [0.10, 0.88, 0.10, 0.88, 0.10, 0.88, 0.10, 0.88]},
}

const RHODES_MARKOV: Dictionary = {
	Genre.HOUSE:         {"h": [0.05, 0.20, 0.05, 0.30, 0.05, 0.20, 0.05, 0.30],  # warm stabs
						  "n": [0.25, 0.40, 0.15, 0.55, 0.25, 0.40, 0.15, 0.55]},
	Genre.TECH_HOUSE:    {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],  # silent
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
	Genre.TECHNO:        {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],  # silent
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
	Genre.MELODIC_HOUSE: {"h": [0.05, 0.10, 0.05, 0.10, 0.05, 0.10, 0.05, 0.10],  # downbeat warmth
						  "n": [0.40, 0.15, 0.20, 0.20, 0.40, 0.15, 0.20, 0.20]},
	Genre.AFRO_HOUSE:    {"h": [0.05, 0.15, 0.05, 0.20, 0.10, 0.25, 0.05, 0.15],  # syncopated clusters
						  "n": [0.15, 0.30, 0.20, 0.45, 0.25, 0.50, 0.15, 0.40]},
	Genre.AFRO_TECHNO:   {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],  # silent
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
}

# pos 3 = beat 2, pos 7 = beat 4 in subdivision space
const CLAP_MARKOV: Dictionary = {
	Genre.HOUSE:         {"h": [0.05, 0.05, 0.95, 0.05, 0.05, 0.05, 0.95, 0.05],  # classic beats 2+4
						  "n": [0.05, 0.05, 0.92, 0.05, 0.05, 0.05, 0.92, 0.05]},
	Genre.TECH_HOUSE:    {"h": [0.05, 0.10, 0.80, 0.10, 0.05, 0.15, 0.80, 0.05],  # 2+4 with variation
						  "n": [0.05, 0.10, 0.75, 0.10, 0.05, 0.15, 0.75, 0.05]},
	Genre.TECHNO:        {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],  # silent
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
	Genre.MELODIC_HOUSE: {"h": [0.05, 0.05, 0.90, 0.05, 0.05, 0.05, 0.90, 0.05],  # clean 2+4
						  "n": [0.05, 0.05, 0.88, 0.05, 0.05, 0.05, 0.88, 0.05]},
	Genre.AFRO_HOUSE:    {"h": [0.05, 0.15, 0.85, 0.15, 0.05, 0.20, 0.85, 0.10],  # 2+4 + syncopation
						  "n": [0.05, 0.15, 0.80, 0.15, 0.05, 0.20, 0.80, 0.10]},
	Genre.AFRO_TECHNO:   {"h": [0.00, 0.05, 0.00, 0.05, 0.00, 0.05, 0.60, 0.05],  # mostly beat 4
						  "n": [0.00, 0.05, 0.00, 0.05, 0.00, 0.05, 0.55, 0.05]},
}

const CONGA_OPEN_MARKOV: Dictionary = {
	Genre.HOUSE:         {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
	Genre.TECH_HOUSE:    {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
	Genre.TECHNO:        {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
	Genre.MELODIC_HOUSE: {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
	Genre.AFRO_HOUSE:    {"h": [0.20, 0.30, 0.50, 0.20, 0.60, 0.30, 0.40, 0.20],  # groove anchor
						  "n": [0.40, 0.30, 0.60, 0.20, 0.65, 0.35, 0.45, 0.25]},
	Genre.AFRO_TECHNO:   {"h": [0.10, 0.20, 0.40, 0.15, 0.50, 0.25, 0.35, 0.15],  # sparser
						  "n": [0.25, 0.20, 0.50, 0.15, 0.60, 0.30, 0.40, 0.20]},
}

const CONGA_SLAP_MARKOV: Dictionary = {
	Genre.HOUSE:         {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
	Genre.TECH_HOUSE:    {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
	Genre.TECHNO:        {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
	Genre.MELODIC_HOUSE: {"h": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
						  "n": [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]},
	Genre.AFRO_HOUSE:    {"h": [0.10, 0.35, 0.15, 0.40, 0.10, 0.50, 0.15, 0.35],  # syncopated fills
						  "n": [0.15, 0.45, 0.20, 0.50, 0.15, 0.55, 0.20, 0.45]},
	Genre.AFRO_TECHNO:   {"h": [0.05, 0.25, 0.10, 0.30, 0.05, 0.40, 0.10, 0.25],  # sparser fills
						  "n": [0.10, 0.35, 0.15, 0.40, 0.10, 0.45, 0.15, 0.35]},
}

# Markov chain state
var markov_hihat_prev: bool = false

# 2-bar patterns generated once per section entry, repeat every 2 bars
var kickPattern: Array = []
var rhodesPattern: Array = []
var clapPattern: Array = []
var congaOpenPattern: Array = []
var congaSlapPattern: Array = []

var hihatOpenPattern: Array = []
var snarePattern: Array = []
var shakerPattern: Array = []
var chordStabPattern: Array = []

# Scheduled sound buffer
class ScheduledSound:
	var id: int
	var instrument: int
	var chord_idx: int
	var state: int
	var play_subdiv: int

	func _init(p_id: int, p_instrument: int, p_chord_idx: int, p_play_subdiv: int, p_state: int) -> void:
		id = p_id
		instrument = p_instrument
		chord_idx = p_chord_idx
		state = p_state
		play_subdiv = p_play_subdiv

var scheduledSounds: Array = []
var nextSoundId: int = 0
var absoluteSubdivCounter: int = 0
var playerControlledInstruments: Dictionary = {}
var instrumentHandlers: Dictionary = {}

signal noteScheduled(instrument: int, chord_idx: int, sound_id: int)
signal genreChanged(bpm: int)

func set_bar(bar: int, fill: bool) -> void:
	currentBar = bar
	isFill = fill

const HIHAT_OPEN_VARIANTS: Array = [
	[[]],                          # INTRO
	[[8], []],         # BUILD
	[[8], [4, 8], [2, 6, 8]],      # DROP
	[[], [8]],                     # BREAK
]

# Syncopated snare hits — "and-of-3" (pos 6) gives a pre-shifted rushed feel
const SNARE_VARIANTS: Array = [
	[[]],                    # INTRO — no snare
	[[6], [4, 6], []],       # BUILD — sparse, anticipating
	[[6], [2, 6], [4, 6]],   # DROP — more active
	[[6], []],               # BREAK — occasional
]

# Off-beat shaker/rim fills — quiet background groove texture
const SHAKER_VARIANTS: Array = [
	[[]],                     # INTRO — silent
	[[2, 6], [], [4, 8]],     # BUILD — sparse off-beats
	[[2, 4, 6, 8], [2, 6, 8]],  # DROP — full groove
	[[2, 6], []],             # BREAK — minimal
]

const CHORD_STAB_VARIANTS: Array = [
	[[1], [1, 3]],                                   # INTRO
	[[4, 8], [8], [6, 8], [2, 8]],                   # BUILD
	[[2, 4, 6, 8], [4, 8], [2, 6, 8], [4, 6, 8]],   # DROP
	[[4], [8], []],                                  # BREAK
]


const BASS_BEATS: Dictionary = {
	0: [1],           # INTRO — root on beat 1 only
	1: [1, 3],        # BUILD — beats 1 and 3
	2: [1, 2, 3, 4],  # DROP — every beat
	3: [1],           # BREAK — beat 1 only
}


func _pick_patterns() -> void:
	hihatOpenPattern = HIHAT_OPEN_VARIANTS[currentSection][randi() % HIHAT_OPEN_VARIANTS[currentSection].size()]
	snarePattern = SNARE_VARIANTS[currentSection][randi() % SNARE_VARIANTS[currentSection].size()]
	shakerPattern = SHAKER_VARIANTS[currentSection][randi() % SHAKER_VARIANTS[currentSection].size()]
	chordStabPattern = CHORD_STAB_VARIANTS[currentSection][randi() % CHORD_STAB_VARIANTS[currentSection].size()]

func _markov_fire(table: Dictionary, subdiv_pos: int, prev_hit: bool, density: float) -> bool:
	var probs: Array = table["h"] if prev_hit else table["n"]
	var prob = min(probs[subdiv_pos - 1], 1.0 - novelty)
	return randf() < prob * density

const RHODES_MUTATION_CHANCE: Dictionary = {
	Genre.HOUSE:         0.15,
	Genre.TECH_HOUSE:   0.20,
	Genre.TECHNO:       0.15,
	Genre.MELODIC_HOUSE: 0.20,
	Genre.AFRO_HOUSE:   0.35,
	Genre.AFRO_TECHNO:  0.30,
}

func _generate_2bar_pattern(markov: Dictionary, density_table: Dictionary) -> Array:
	var density = density_table[currentSection] * densityMultiplier
	var mutation = RHODES_MUTATION_CHANCE[currentGenre]
	var bar1: Array = []
	var prev = false
	for i in 8:
		var fires = _markov_fire(markov[currentGenre], i + 1, prev, density)
		bar1.append(fires)
		prev = fires
	var genre_table = markov[currentGenre]
	var bar2: Array = []
	for i in 8:
		if randf() < mutation:
			var can_fire = genre_table["h"][i] > 0.0 or genre_table["n"][i] > 0.0
			bar2.append((not bar1[i]) if can_fire else bar1[i])
		else:
			bar2.append(bar1[i])
	return bar1 + bar2

func _generate_patterns() -> void:
	kickPattern      = _generate_2bar_pattern(KICK_MARKOV,        KICK_SECTION_DENSITY)
	rhodesPattern    = _generate_2bar_pattern(RHODES_MARKOV,      RHODES_SECTION_DENSITY)
	clapPattern      = _generate_2bar_pattern(CLAP_MARKOV,        CLAP_SECTION_DENSITY)
	congaOpenPattern = _generate_2bar_pattern(CONGA_OPEN_MARKOV,  CONGA_SECTION_DENSITY)
	congaSlapPattern = _generate_2bar_pattern(CONGA_SLAP_MARKOV,  CONGA_SECTION_DENSITY)

func set_genre(genre: int) -> void:
	currentGenre = genre
	keyOffset = GENRE_KEY_OFFSET[currentGenre]
	genreChanged.emit(GENRE_BPM[currentGenre])
	var instrument_names = GENRE_PLAYER_INSTRUMENTS[currentGenre].map(func(i): return Instrument.find_key(i))
	print("Genre: ", Genre.find_key(currentGenre), " | Player instruments: ", instrument_names)

func _play_bass(chord_idx: int) -> void:
	if bass_playback.is_stream_playing(active_bass_id):
		bass_playback.stop_stream(active_bass_id)
	var semitones = CHORD_NOTES[chord_idx][0] + keyOffset
	var pitch = pow(2.0, float(semitones) / 12.0)
	active_bass_id = bass_playback.play_stream(bass, 0, -10.0, pitch)


func set_section(section: int, intensity: float, cycle: int):
	currentSection = section
	currentIntensity = intensity
	currentCycle = cycle
	if section == 1 and cycle >= 2:  # BUILD after first cycle — introduce next genre
		_set_random_genre()
	_pick_patterns()
	_generate_patterns()


func _play_drum(stream: AudioStream, volume: float, pitch: float = 1.0) -> void:
	var volumeRnd = volume + randf_range(-1.5, 1.5)
	drumPlayback.play_stream(stream, 0, volumeRnd, pitch)

func play_on_beat(chord_idx: int, beat_pos: int) -> void:
	if beat_pos in BASS_BEATS[currentSection]:
		_play_bass(chord_idx)

func _setup_instrument_handlers() -> void:
	var no_schedule = func(_l: int, _s: int) -> bool: return false

	var rhodes_schedule = func(lookahead_idx: int, _s: int) -> bool:
		return not isFill and rhodesPattern.size() > 0 and rhodesPattern[lookahead_idx]
	var rhodes_play = func(perc_idx: int, _s: int) -> bool:
		return not isFill and rhodesPattern.size() > 0 and rhodesPattern[perc_idx]
	var rhodes_func = func(chord_idx: int, vol: float) -> void:
		play_chord(chord_idx, 1.0 + vol)

	var kick_schedule = func(lookahead_idx: int, _s: int) -> bool:
		return not isFill and kickPattern.size() > 0 and kickPattern[lookahead_idx]
	var kick_play = func(perc_idx: int, _s: int) -> bool:
		return not isFill and kickPattern.size() > 0 and kickPattern[perc_idx]
	var kick_func = func(_c: int, vol: float) -> void:
		_play_drum(kick, -3.0 + vol)

	var hihat_closed_play = func(_p: int, subdiv_pos: int) -> bool:
		if subdiv_pos in hihatOpenPattern:
			markov_hihat_prev = true
			return false
		var fires = _markov_fire(HIHAT_CLOSED_MARKOV[currentGenre], subdiv_pos, markov_hihat_prev, HIHAT_SECTION_DENSITY[currentSection])
		markov_hihat_prev = fires
		return fires
	var hihat_closed_func = func(_c: int, vol: float) -> void:
		_play_drum(hihat_closed, -8.0 + vol)

	var hihat_open_play = func(_p: int, subdiv_pos: int) -> bool:
		return subdiv_pos in hihatOpenPattern
	var hihat_open_func = func(_c: int, vol: float) -> void:
		_play_drum(hihat_open, -16.0 + vol)

	var clap_schedule = func(lookahead_idx: int, _s: int) -> bool:
		return clapPattern.size() > 0 and clapPattern[lookahead_idx]
	var clap_play = func(perc_idx: int, _s: int) -> bool:
		return clap != null and clapPattern.size() > 0 and clapPattern[perc_idx]
	var clap_func = func(_c: int, vol: float) -> void:
		_play_drum(clap, -5.0 + vol)

	var snare_play = func(_p: int, subdiv_pos: int) -> bool:
		return snare != null and subdiv_pos in snarePattern
	var snare_func = func(_c: int, vol: float) -> void:
		_play_drum(snare, -8.0 + vol, 0.85)

	var shaker_play = func(_p: int, subdiv_pos: int) -> bool:
		return shaker != null and subdiv_pos in shakerPattern
	var shaker_func = func(_c: int, vol: float) -> void:
		_play_drum(shaker, -20.0 + vol)

	var conga_open_schedule = func(lookahead_idx: int, _s: int) -> bool:
		return conga_open != null and congaOpenPattern.size() > 0 and congaOpenPattern[lookahead_idx]
	var conga_open_play = func(perc_idx: int, _s: int) -> bool:
		return conga_open != null and congaOpenPattern.size() > 0 and congaOpenPattern[perc_idx]
	var conga_open_func = func(_c: int, vol: float) -> void:
		_play_drum(conga_open, 0.0 + vol)

	var conga_slap_schedule = func(lookahead_idx: int, _s: int) -> bool:
		return conga_slap != null and congaSlapPattern.size() > 0 and congaSlapPattern[lookahead_idx]
	var conga_slap_play = func(perc_idx: int, _s: int) -> bool:
		return conga_slap != null and congaSlapPattern.size() > 0 and congaSlapPattern[perc_idx]
	var conga_slap_func = func(_c: int, vol: float) -> void:
		_play_drum(conga_slap, -2.0 + vol)

	var chord_stab_schedule = func(_l: int, _s: int) -> bool: return false
	var chord_stab_play = func(_p: int, _s: int) -> bool: return false
	var chord_stab_func = func(chord_idx: int, vol: float) -> void:
		play_chord(chord_idx, 1.0 + vol)

	instrumentHandlers = {
		Instrument.RHODES:       { "schedule_check": rhodes_schedule,      "play_check": rhodes_play,       "play_func": rhodes_func      },
		Instrument.KICK:         { "schedule_check": kick_schedule,         "play_check": kick_play,          "play_func": kick_func         },
		Instrument.HIHAT_CLOSED: { "schedule_check": no_schedule,           "play_check": hihat_closed_play,  "play_func": hihat_closed_func },
		Instrument.HIHAT_OPEN:   { "schedule_check": no_schedule,           "play_check": hihat_open_play,    "play_func": hihat_open_func   },
		Instrument.CLAP:         { "schedule_check": clap_schedule,         "play_check": clap_play,          "play_func": clap_func         },
		Instrument.SNARE:        { "schedule_check": no_schedule,           "play_check": snare_play,         "play_func": snare_func        },
		Instrument.SHAKER:       { "schedule_check": no_schedule,           "play_check": shaker_play,        "play_func": shaker_func       },
		Instrument.CONGA_OPEN:   { "schedule_check": conga_open_schedule,   "play_check": conga_open_play,    "play_func": conga_open_func   },
		Instrument.CONGA_SLAP:   { "schedule_check": conga_slap_schedule,   "play_check": conga_slap_play,    "play_func": conga_slap_func   },
		Instrument.CHORD_STAB:   { "schedule_check": chord_stab_schedule,   "play_check": chord_stab_play,    "play_func": chord_stab_func   },
	}

func _create_scheduled_sound(instrument: int, chord_idx: int) -> ScheduledSound:
	var entry = ScheduledSound.new(nextSoundId, instrument, chord_idx, absoluteSubdivCounter + lookaheadSubdivs, SoundState.PENDING)
	nextSoundId += 1
	scheduledSounds.append(entry)
	return entry

func _run_resolver(current_chord_idx: int) -> void:
	var to_remove: Array = []
	for entry in scheduledSounds:
		if entry.play_subdiv == absoluteSubdivCounter:
			var volume_offset = 0.0 if entry.state == SoundState.HIT else MISS_VOLUME_DB_OFFSET
			instrumentHandlers[entry.instrument].play_func.call(current_chord_idx, volume_offset)
			to_remove.append(entry)
	for entry in to_remove:
		scheduledSounds.erase(entry)

func set_player_controlled(instrument: int, controlled: bool) -> void:
	playerControlledInstruments[instrument] = controlled

func register_hit(sound_id: int) -> void:
	for entry in scheduledSounds:
		if entry.id == sound_id and entry.state == SoundState.PENDING:
			entry.state = SoundState.HIT
			return

func play_on_subdivision(subdiv_pos: int, chord_idx: int) -> void:
	if subdiv_pos == 1:
		markov_hihat_prev = false

	absoluteSubdivCounter += 1
	_run_resolver(chord_idx)

	if isFill:
		_play_drum(hihat_closed, -2.0)
		if subdiv_pos == 7 or subdiv_pos == 8:
			_play_drum(kick, 8.0)
		return

	var perc_idx = (currentBar % 2) * 8 + (subdiv_pos - 1)
	var lookahead_idx = (perc_idx + lookaheadSubdivs) % 16

	for instrument in instrumentHandlers:
		var handler = instrumentHandlers[instrument]
		if playerControlledInstruments.get(instrument, false):
			if handler.schedule_check.call(lookahead_idx, subdiv_pos):
				var entry = _create_scheduled_sound(instrument, chord_idx)
				noteScheduled.emit(instrument, chord_idx, entry.id)
		else:
			if handler.play_check.call(perc_idx, subdiv_pos):
				handler.play_func.call(chord_idx, 0.0)


func _get_chord_stream(semitones: int) -> Array:
	while semitones < -6:
		semitones += 12
	return [rhodes_c4, semitones]

func _ready() -> void:
	lookaheadSubdivs = ceili(
		(ButtonScript.HIT_BUTTON_Y - NoteScript.SPAWN_Y) /
		(NoteScript.TARGET_Y - NoteScript.SPAWN_Y) *
		ConductorScript.SUBDIVISIONS_PER_MEASURE
	)

	$Player.stream = AudioStreamPolyphonic.new()
	$Player.play()
	playback = $Player.get_stream_playback()

	$DrumPlayer.stream = AudioStreamPolyphonic.new()
	$DrumPlayer.play()
	drumPlayback = $DrumPlayer.get_stream_playback()

	$BassPlayer.stream = AudioStreamPolyphonic.new()
	$BassPlayer.play()
	bass_playback = $BassPlayer.get_stream_playback()

	_setup_instrument_handlers()

	_set_random_genre()
	_pick_patterns()
	_generate_patterns()

const GENRE_PLAYER_INSTRUMENTS: Dictionary = {
	Genre.HOUSE:         [Instrument.RHODES,     Instrument.CLAP],
	Genre.TECH_HOUSE:    [Instrument.CLAP,        Instrument.HIHAT_CLOSED],
	Genre.TECHNO:        [Instrument.KICK],
	Genre.MELODIC_HOUSE: [Instrument.RHODES,     Instrument.CONGA_OPEN],
	Genre.AFRO_HOUSE:    [Instrument.CONGA_SLAP, Instrument.RHODES],
	Genre.AFRO_TECHNO:   [Instrument.KICK,       Instrument.CONGA_SLAP],
}

var densityMultiplier: float = 1.0
var novelty: float = 0.0

func _set_random_genre() -> void:
	var genres = Genre.values()
	set_genre(genres[randi() % genres.size()])


func play_chord(chord_idx: int, volume_db: float = 1.0) -> void:
	for id in active_chord_streams:
		if playback.is_stream_playing(id):
			playback.stop_stream(id)

	active_chord_streams.clear()

	for i in 4:
		var selectedStream = _get_chord_stream(CHORD_NOTES[chord_idx][i] + keyOffset)
		var pitch = pow(2.0, float(selectedStream[1]) / 12.0)
		var stream_id = playback.play_stream(selectedStream[0], 0, volume_db, pitch)
		active_chord_streams.append(stream_id)
