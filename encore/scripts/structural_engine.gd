extends Node

enum Section { INTRO, BUILD, DROP, BREAK };

const SECTION_BARS: Dictionary[Section, int] = {
	Section.INTRO: 8,
	Section.BUILD: 8,
	Section.DROP: 16,
	Section.BREAK: 8
}

const NEXT_SECTION: Dictionary[Section, Section] = {
	Section.INTRO: Section.BUILD,
	Section.BUILD: Section.DROP,
	Section.DROP: Section.BREAK,
	Section.BREAK: Section.BUILD
}

const SECTION_INTENSITY: Dictionary[Section, float] = {
	Section.INTRO: 0.2,
	Section.BUILD: 0.6,
	Section.DROP: 1.0,
	Section.BREAK: 0.3
}

var currentSection: Section = Section.INTRO
var barsInSection: int = 0
var intensity: float = 0.2
var cycleCount: int = 0

signal sectionChanged(section, intensity)

func advance_bar():
	barsInSection += 1
	if barsInSection >= SECTION_BARS[currentSection]:
		_transition()

func _transition():
	currentSection = NEXT_SECTION[currentSection]
	barsInSection = 0
	intensity = SECTION_INTENSITY[currentSection]
	if currentSection == Section.BUILD:
		cycleCount += 1

	sectionChanged.emit(currentSection, intensity)
