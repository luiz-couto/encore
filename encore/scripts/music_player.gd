extends Node

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

@export var piano_c3: AudioStream
@export var piano_c4: AudioStream
@export var piano_c5: AudioStream

@export var rhodes_c4: AudioStream

@export var kick: AudioStream
@export var hihat_closed: AudioStream
@export var hihat_open: AudioStream
@export var clap: AudioStream
@export var snare: AudioStream
@export var shaker: AudioStream
@export var conga_open: AudioStream
@export var conga_slap: AudioStream
@export var woodblock: AudioStream
@export var bass: AudioStream
@export var lead_sax: AudioStream
@export var lead_organ: AudioStream
@export var lead_flute: AudioStream

var playback: AudioStreamPlaybackPolyphonic
var drumPlayback: AudioStreamPlaybackPolyphonic
var bass_playback: AudioStreamPlaybackPolyphonic
var melody_playback: AudioStreamPlaybackPolyphonic

var active_chord_streams: Array = []
var currentSection: int = 0
var currentIntensity: float = 0.2
var currentCycle: int = 0
var active_bass_id: int = 0

var active_melody_id: int = 0
var leads: Array = []
var currentLead: AudioStream = null
var leadIdx: int = 0

var currentBar: int = 0
var isFill: bool = false
var isStop: bool = false
var isBreakdown: bool = false
var isSnareRamp: bool = false

enum Genre { HOUSE = 0, TECH_HOUSE = 1, TECHNO = 2, MELODIC_HOUSE = 3, AFRO_HOUSE = 4, AFRO_TECHNO = 5 }
var currentGenre: int = Genre.TECHNO

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

# Markov chain state — reset at the start of each bar (subdiv_pos == 1)
var markov_kick_prev: bool = false
var markov_hihat_prev: bool = false

# 2-bar patterns generated once per section entry, repeat every 2 bars
var rhodesPattern: Array = []
var clapPattern: Array = []
var congaOpenPattern: Array = []
var congaSlapPattern: Array = []

var testWoodblockPattern: Array = []

var kickPattern: Array = []
var hihatOpenPattern: Array = []
var snarePattern: Array = []
var shakerPattern: Array = []
var chordStabPattern: Array = []

signal chordPlayed()
signal drumKickPlayed()
signal drumHiHatOpenPlayed()
signal drumHiHatClosedPlayed()
signal drumClapPlayed()
signal genreChanged(bpm: int)

func set_bar(bar: int, fill: bool) -> void:
	currentBar = bar
	isFill = fill
	isStop = fill and currentSection in [0, 1, 3] and randf() < 0.0


const KICK_VARIANTS: Array = [
	[[1]],                                  # INTRO
	[[1, 2, 3, 4], [1, 3, 4], [1, 2, 4]],  # BUILD
	[[1, 2, 3, 4]],                         # DROP — four-on-the-floor always
	[[1, 3], [1]],                          # BREAK
]

const CLAP_VARIANTS: Array = [
	[[]],             # INTRO
	[[4], [2, 4]],    # BUILD
	[[2, 4], [4], [2, 4, 6]],    # DROP
	[[], [4]],        # BREAK
]

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

# Atmospheric chord patterns for full breakdowns (no drums/bass)
const BREAKDOWN_CHORD_VARIANTS: Array = [
	[2, 6],       # off-beat, floating
	[1, 5],       # every half-bar, anchored
	[4, 8],       # syncopated — the "and" of each half
]

const BUILD_RAMP_STABS: Array = [
	[8],           # bars 0-1
	[4, 8],        # bars 2-3
	[4, 6, 8],     # bars 4-5
	[2, 4, 6, 8],  # bars 6-7
]

# Snare-only BUILD variant — kick/clap drop, snare gets denser every 2 bars
const BUILD_SNARE_RAMP: Array = [
	[7],                       # bar 0: one pickup hit (beat 4)
	[3, 5, 7],                    # bar 1: beats 3 and 4
	[2, 3, 5, 7],                 # bar 2: beats 2, 3, 4
	[2, 3, 5, 6, 7],              # bar 3: adding off-beat of 4
	[1, 2, 3, 5, 6, 7],           # bar 4: getting tighter
	[1, 2, 3, 4, 5, 6, 7, 8], # bar 5: full 8th note roll
	[1, 2, 3, 4, 5, 6, 7, 8], # bar 6: full roll
	[1, 2, 3, 4, 5, 6, 7, 8], # bar 7: full roll — right into drop
]

const BASS_BEATS: Dictionary = {
	0: [1],           # INTRO — root on beat 1 only
	1: [1, 3],        # BUILD — beats 1 and 3
	2: [1, 2, 3, 4],  # DROP — every beat
	3: [1],           # BREAK — beat 1 only
}

const MELODY_BEATS: Dictionary = {
	0: [1],           # INTRO — beat 1 only
	1: [1, 3],        # BUILD — beats 1 and 3
	2: [1, 2, 3, 4],  # DROP — every beat
	3: [1],           # BREAK — beat 1 only
}

const MELODY_REST_CHANCE: Dictionary = {
	0: 1.0,   # INTRO
	1: 0.8,   # BUILD
	2: 0.0,   # DROP
	3: 1.0,   # BREAK
}

func _pick_patterns() -> void:
	kickPattern = KICK_VARIANTS[currentSection][randi() % KICK_VARIANTS[currentSection].size()]
	hihatOpenPattern = HIHAT_OPEN_VARIANTS[currentSection][randi() % HIHAT_OPEN_VARIANTS[currentSection].size()]
	snarePattern = SNARE_VARIANTS[currentSection][randi() % SNARE_VARIANTS[currentSection].size()]
	shakerPattern = SHAKER_VARIANTS[currentSection][randi() % SHAKER_VARIANTS[currentSection].size()]
	chordStabPattern = CHORD_STAB_VARIANTS[currentSection][randi() % CHORD_STAB_VARIANTS[currentSection].size()]

func _markov_fire(table: Dictionary, subdiv_pos: int, prev_hit: bool, density: float) -> bool:
	var probs: Array = table["h"] if prev_hit else table["n"]
	return randf() < probs[subdiv_pos - 1] * density

const RHODES_MUTATION_CHANCE: Dictionary = {
	Genre.HOUSE:         0.15,
	Genre.TECH_HOUSE:   0.20,
	Genre.TECHNO:       0.15,
	Genre.MELODIC_HOUSE: 0.20,
	Genre.AFRO_HOUSE:   0.35,
	Genre.AFRO_TECHNO:  0.30,
}

func _generate_2bar_pattern(markov: Dictionary, density_table: Dictionary) -> Array:
	var density = density_table[currentSection]
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
	rhodesPattern    = _generate_2bar_pattern(RHODES_MARKOV,      RHODES_SECTION_DENSITY)
	clapPattern      = _generate_2bar_pattern(CLAP_MARKOV,        CLAP_SECTION_DENSITY)
	congaOpenPattern = _generate_2bar_pattern(CONGA_OPEN_MARKOV,  CONGA_SECTION_DENSITY)
	congaSlapPattern = _generate_2bar_pattern(CONGA_SLAP_MARKOV,  CONGA_SECTION_DENSITY)

func set_genre(genre: int) -> void:
	currentGenre = genre
	keyOffset = GENRE_KEY_OFFSET[currentGenre]
	genreChanged.emit(GENRE_BPM[currentGenre])
	print("Genre: ", Genre.find_key(currentGenre))

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
	isBreakdown = false
	isSnareRamp = false
	if section == 1:  # BUILD — start of a new cycle, pick new genre
		set_genre(randi() % Genre.values().size())
	_pick_patterns()
	_generate_patterns()
	if section == 1 and leads.size() > 0:  # BUILD — new cycle, new lead
		leadIdx = randi() % leads.size()
		currentLead = leads[leadIdx]
	if section == 1:  # BUILD — 50% chance of snare-roll variant
		isSnareRamp = false # Force no snare ramp for now
	if section == 3 and randf() < 0.5:  # BREAK — 50% chance of full breakdown
		isBreakdown = true
		chordStabPattern = BREAKDOWN_CHORD_VARIANTS[randi() % BREAKDOWN_CHORD_VARIANTS.size()]


func _play_drum(stream: AudioStream, volume: float, pitch: float = 1.0) -> void:
	var volumeRnd = volume + randf_range(-1.5, 1.5)
	drumPlayback.play_stream(stream, 0, volumeRnd, pitch)

func play_on_beat(chord_idx: int, beat_pos: int) -> void:
	if isBreakdown:
		return
	if isStop:
		if beat_pos == 3:
			if bass_playback.is_stream_playing(active_bass_id):
				bass_playback.stop_stream(active_bass_id)
			if melody_playback.is_stream_playing(active_melody_id):
				melody_playback.stop_stream(active_melody_id)
		return
	if beat_pos in BASS_BEATS[currentSection]:
		_play_bass(chord_idx)
	if beat_pos in MELODY_BEATS[currentSection]:
		play_melody(chord_idx)

func play_on_subdivision(subdiv_pos: int, chord_idx: int) -> void:
	if subdiv_pos == 1:
		markov_kick_prev = false
		markov_hihat_prev = false

	if isFill:
		_play_drum(hihat_closed, -2.0)
		drumHiHatClosedPlayed.emit()
		if subdiv_pos == 7 or subdiv_pos == 8:
			_play_drum(kick, 8.0)
			drumKickPlayed.emit()
	elif isSnareRamp:
		if snare != null:
			var rampIdx = min(currentBar, BUILD_SNARE_RAMP.size() - 1)
			if subdiv_pos in BUILD_SNARE_RAMP[rampIdx]:
				_play_drum(snare, -5.0, 0.85)
	elif isBreakdown:
		if subdiv_pos in chordStabPattern:
			play_chord(chord_idx)
			chordPlayed.emit()
	else:
		# Kick — Markov chain
		var kick_fires = _markov_fire(KICK_MARKOV[currentGenre], subdiv_pos, markov_kick_prev, KICK_SECTION_DENSITY[currentSection])
		markov_kick_prev = kick_fires
		if kick_fires:
			_play_drum(kick, -3.0)
			drumKickPlayed.emit()

		# Hihat open takes priority; closed uses Markov chain
		if subdiv_pos in hihatOpenPattern:
			_play_drum(hihat_open, -16.0)
			drumHiHatOpenPlayed.emit()
			markov_hihat_prev = true
		else:
			var hihat_fires = _markov_fire(HIHAT_CLOSED_MARKOV[currentGenre], subdiv_pos, markov_hihat_prev, HIHAT_SECTION_DENSITY[currentSection])
			markov_hihat_prev = hihat_fires
			if hihat_fires:
				_play_drum(hihat_closed, -8.0)
				drumHiHatClosedPlayed.emit()

		if snare != null and subdiv_pos in snarePattern:
			_play_drum(snare, -8.0, 0.85)
		if shaker != null and subdiv_pos in shakerPattern:
			_play_drum(shaker, -20.0)

		var perc_idx = (currentBar % 2) * 8 + (subdiv_pos - 1)

		if clap != null and clapPattern.size() > 0 and clapPattern[perc_idx]:
			_play_drum(clap, -5.0)
			drumClapPlayed.emit()
		if conga_open != null and congaOpenPattern.size() > 0 and congaOpenPattern[perc_idx]:
			_play_drum(conga_open, 0.0)
		if conga_slap != null and congaSlapPattern.size() > 0 and congaSlapPattern[perc_idx]:
			_play_drum(conga_slap, -2.0)
		if woodblock != null and subdiv_pos in testWoodblockPattern:
			_play_drum(woodblock, -12.0)

		# Rhodes — sound plays at the scheduled subdivision
		if rhodesPattern.size() > 0 and rhodesPattern[perc_idx]:
			play_chord(chord_idx)
		# Note spawns 5 subdivisions early: button is at Y=713, note travels 729/1216 of full path ≈ 4.8 subdivisions
		var lookahead_idx = (perc_idx + 5) % 16
		if rhodesPattern.size() > 0 and rhodesPattern[lookahead_idx]:
			chordPlayed.emit()


func play_melody(chord_idx: int) -> void:
	if currentLead == null: return
	if randf() < MELODY_REST_CHANCE[currentSection]: return
	#if melody_playback.is_stream_playing(active_melody_id):
		#melody_playback.stop_stream(active_melody_id)
	var note_idx = randi() % 3 + 1
	var semitones = CHORD_NOTES[chord_idx][note_idx] + keyOffset
	var pitch = pow(2.0, float(semitones) / 12.0)
	active_melody_id = melody_playback.play_stream(currentLead, 0, 2.0, pitch)


func _get_chord_stream(semitones: int) -> Array:
	while semitones < -6:
		semitones += 12
	return [rhodes_c4, semitones]

func _ready() -> void:
	$Player.stream = AudioStreamPolyphonic.new()
	$Player.play()
	playback = $Player.get_stream_playback()

	$DrumPlayer.stream = AudioStreamPolyphonic.new()
	$DrumPlayer.play()
	drumPlayback = $DrumPlayer.get_stream_playback()

	$BassPlayer.stream = AudioStreamPolyphonic.new()
	$BassPlayer.play()
	bass_playback = $BassPlayer.get_stream_playback()

	$MelodyPlayer.stream = AudioStreamPolyphonic.new()
	$MelodyPlayer.play()
	melody_playback = $MelodyPlayer.get_stream_playback()

	for lead in [lead_sax, lead_organ, lead_flute]:
		if lead != null:
			leads.append(lead)
	if leads.size() > 0:
		currentLead = leads[0]

	set_genre(randi() % Genre.values().size())
	_pick_patterns()
	_generate_patterns()


func _get_stream(semitones: int) -> Array:
	if semitones < -6:
		return [piano_c3, semitones + 12]
	elif semitones > 6:
		return [piano_c5, semitones - 12]
	else:
		return [piano_c4, semitones]

func play_chord(chord_idx: int) -> void:
	for id in active_chord_streams:
		if playback.is_stream_playing(id):
			playback.stop_stream(id)

	active_chord_streams.clear()

	for i in 4:
		var selectedStream = _get_chord_stream(CHORD_NOTES[chord_idx][i] + keyOffset)
		var pitch = pow(2.0, float(selectedStream[1]) / 12.0)
		var stream_id = playback.play_stream(selectedStream[0], 0, 1.0, pitch)
		active_chord_streams.append(stream_id)

func play_note(chord_idx: int, lane: int) -> void:
	var selectedStream = _get_stream(CHORD_NOTES[chord_idx][lane])
	var pitch = pow(2.0, float(selectedStream[1]) / 12.0)
	playback.play_stream(selectedStream[0], 0, -4.0, pitch)
