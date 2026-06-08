# Encore — Algorithmic Music Generation Plan

Rhythm game music generated via a Markov chain over chord progressions, implemented purely in Godot 4.

---

## Step 0 — Assets to download from freesound.org

Search for **"piano single note C"** and filter by License: Creative Commons 0 (CC0).

You need one sample per octave to keep pitch-shifting natural. The chord notes in this plan span C4–F5, so download:

| File to save as | What to search on freesound.org |
|---|---|
| `assets/audio/piano_c3.wav` | `piano C3 single note` |
| `assets/audio/piano_c4.wav` | `piano C4 single note` |
| `assets/audio/piano_c5.wav` | `piano C5 single note` |


**Tips:**
- Pick mono `.wav` files, 44100 Hz if possible.
- Avoid samples with reverb tails — you want a dry, clean attack.
- The three players (Voice1/2/3) will all use `piano_c4.wav` initially; C3 and C5 let you improve quality later by loading the nearest octave per note.
- C4 note link: https://freesound.org/people/nanliu_music/sounds/847227/

---

## Architecture Overview

```
Conductor  ──(measure signal)──►  Game
                                    ├── ChordGenerator  (Markov chain)
                                    │       └──(chord_changed signal)──► MusicPlayer
                                    └── spawns visual notes whose lanes map to chord tones
```

---

## Step 1 — `scripts/chord_generator.gd`

New file. Holds both transition matrices from the paper, a `mode` float that blends between them, and a `advance()` method that samples the next chord.

```gdscript
extends Node

enum Chord { C_MAJ, D_MIN, E_MIN, F_MAJ, G_MAJ, A_MIN, B_DIM }

# From the paper: Table 3.2
const MAJOR_MATRIX = [
    [0,    0,    0,    0.44, 0.44, 0,    0.11], # C maj (I)
    [0.31, 0,    0,    0.31, 0.31, 0,    0.08], # D min (II)
    [0.31, 0,    0,    0.31, 0.31, 0,    0.08], # E min (III)
    [0.44, 0,    0,    0,    0.44, 0,    0.11], # F maj (IV)
    [0.8,  0,    0,    0.16, 0,    0,    0.04], # G maj (V)
    [0.31, 0,    0,    0.31, 0.31, 0,    0.08], # A min (VI)
    [0.71, 0,    0,    0.14, 0.14, 0,    0   ], # B dim (VII)
]

const MINOR_MATRIX = [
    [0, 0.31, 0.31, 0,    0,    0.31, 0.08], # C maj (III)
    [0, 0,    0.44, 0,    0,    0.44, 0.11], # D min (IV)
    [0, 0.16, 0,    0,    0,    0.8,  0.04], # E min (V)
    [0, 0.31, 0.31, 0,    0,    0.31, 0.08], # F maj (VI)
    [0, 0.31, 0.31, 0,    0,    0.31, 0.08], # G maj (VII)
    [0, 0.44, 0.44, 0,    0,    0,    0.11], # A min (I)
    [0, 0.14, 0.71, 0,    0,    0.14, 0   ], # B dim (II)
]

## 0.0 = fully C major, 1.0 = fully A minor
@export var mode: float = 0.0

var current_chord: int = Chord.C_MAJ

signal chord_changed(chord_idx: int)

func advance() -> int:
    var row = _blended_row(current_chord)
    current_chord = _weighted_sample(row)
    chord_changed.emit(current_chord)
    return current_chord

func _blended_row(idx: int) -> Array:
    var result = []
    for i in 7:
        result.append(lerp(MAJOR_MATRIX[idx][i], MINOR_MATRIX[idx][i], mode))
    return result

func _weighted_sample(weights: Array) -> int:
    var r = randf()
    var cumulative = 0.0
    for i in weights.size():
        cumulative += weights[i]
        if r <= cumulative:
            return i
    return weights.size() - 1
```

---

## Step 2 — `scripts/music_player.gd`

New file. Three `AudioStreamPlayer2D` children (Voice1, Voice2, Voice3), each loaded with `piano_c4.wav`. `pitch_scale` shifts them to the right note using the formula `2^(semitones / 12)`.

```gdscript
extends Node

# Semitone offsets from C4 for each chord (root, third, fifth)
const CHORD_NOTES: Dictionary = {
    0: [0,  4,  7],  # C maj: C4, E4, G4
    1: [2,  5,  9],  # D min: D4, F4, A4
    2: [4,  7,  11], # E min: E4, G4, B4
    3: [5,  9,  12], # F maj: F4, A4, C5
    4: [7,  11, 14], # G maj: G4, B4, D5
    5: [9,  12, 16], # A min: A4, C5, E5
    6: [11, 14, 17], # B dim: B4, D5, F5
}

func play_chord(chord_idx: int) -> void:
    var notes = CHORD_NOTES[chord_idx]
    for i in 3:
        var player: AudioStreamPlayer2D = get_child(i)
        player.pitch_scale = pow(2.0, notes[i] / 12.0)
        player.play()
```

**Scene setup for MusicPlayer:**
- Add node `MusicPlayer` (script: `music_player.gd`)
- Add 3 children: `Voice1`, `Voice2`, `Voice3` — all `AudioStreamPlayer2D`
- Assign `piano_c4.wav` as the stream on each

---

## Step 3 — Modify `scripts/game.gd`

Wire the conductor's measure signal through `ChordGenerator` and into `MusicPlayer`.

```gdscript
extends Node2D

const NoteScene := preload("res://scenes/note.tscn")

func _on_conductor_measure(position: int) -> void:
    var chord = $ChordGenerator.advance()
    $MusicPlayer.play_chord(chord)
    spawnNote(chord)

func spawnNote(chord: int) -> void:
    var noteInstance = NoteScene.instantiate()
    # Pick a random lane from the 4 chord tones (see Step 4)
    var lane = randi() % 4
    noteInstance.initialize(lane, chord)
    add_child(noteInstance)
```

---

## Step 4 — Extra idea: tie visual lanes to chord tones

Instead of random lanes, map each of the 4 lanes to one note of the chord. That way every note the player hits *is* a chord tone — the gameplay becomes the music.

Add a fourth note per chord (the seventh or octave) for the fourth lane:

```gdscript
# In music_player.gd — extend to 4 notes per chord
const CHORD_NOTES: Dictionary = {
    0: [0,  4,  7,  12], # C maj: C4, E4, G4, C5
    1: [2,  5,  9,  14], # D min: D4, F4, A4, D5
    2: [4,  7,  11, 16], # E min: E4, G4, B4, E5
    3: [5,  9,  12, 17], # F maj: F4, A4, C5, F5
    4: [7,  11, 14, 19], # G maj: G4, B4, D5, G5
    5: [9,  12, 16, 21], # A min: A4, C5, E5, A5
    6: [11, 14, 17, 23], # B dim: B4, D5, F5, B5
}
```

Then in `note.gd`, trigger `MusicPlayer` to play just that lane's voice when the player hits the note — so a perfect hit sounds the note, a miss is silence. The `lane` index maps directly to `CHORD_NOTES[chord][lane]`.

This also lets you generate notes with musical intent: spawn the chord root on lane 0 more frequently, or arpeggiate up the lanes over consecutive beats.

---

## Step 5 — Tempo parameter (rewrite `scripts/conductor.gd`)

Tempo is BPM. The paper treats it as the primary driver of **arousal** (energy/excitement), while `mode` drives **valence** (happy/sad). They are independent parameters.

The original conductor extended `AudioStreamPlayer2D` and used `get_playback_position()` as its clock — meaning it had to be actively playing audio to emit beats at all. Since `MusicPlayer` now owns all audio output, the conductor can become a pure beat clock using `Time.get_ticks_msec()` instead. This also means `$Conductor.play()` can be removed from `game.gd`.

Two changes are needed:
- Change `extends AudioStreamPlayer2D` → `extends Node`
- Replace `get_playback_position()` with `Time.get_ticks_msec()`
- Add a setter on `bpm` so `secondsPerBeat` stays in sync when tempo changes at runtime

Full rewrite:

```gdscript
extends Node

@export var bpm: float = 115:
    set(value):
        bpm = value
        secondsPerBeat = 60.0 / bpm

@export var measures: float = 4

var secondsPerBeat: float = 60.0 / 115
var startTime: float = 0.0
var lastReportedBeat: float = 0
var currMeasure: float = 1

signal beat(position)
signal measure(position)

func _ready() -> void:
    startTime = Time.get_ticks_msec() / 1000.0

func _physics_process(_delta: float) -> void:
    var elapsed = (Time.get_ticks_msec() / 1000.0) - startTime
    var currBeat = int(floor(elapsed / secondsPerBeat))
    if lastReportedBeat < currBeat:
        if currMeasure > measures:
            currMeasure = 1
        beat.emit(currBeat)
        measure.emit(currMeasure)
        lastReportedBeat = currBeat
        currMeasure += 1
```

Now you can change tempo from anywhere at runtime:

```gdscript
$Conductor.bpm = 140  # faster = more energetic
```

**Emotional axes summary:**

| Parameter | Affects | Range |
|---|---|---|
| `bpm` on Conductor | Arousal (energy) | any positive float; ~60–180 is musical |
| `mode` on ChordGenerator | Valence (happy ↔ sad) | 0.0 (major) → 1.0 (minor) |

---

## Scene tree after all steps

```
Game (Node2D)
├── Conductor (Node)                  ← was AudioStreamPlayer2D, now a pure beat clock
├── ChordGenerator (Node)             ← new
├── MusicPlayer (Node)                ← new
│   ├── Voice1 (AudioStreamPlayer2D)
│   ├── Voice2 (AudioStreamPlayer2D)
│   ├── Voice3 (AudioStreamPlayer2D)
│   └── Voice4 (AudioStreamPlayer2D)
└── [spawned Note instances]
```
