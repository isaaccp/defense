extends Object

class_name Groups

enum GroupType {
	UNSPECIFIED,
	CHARACTERS,
	ENEMIES,
	TOWERS,
}

const CHARACTERS = "characters"
const ENEMIES = "enemies"
const TOWERS = "towers"

const group_names = {
	GroupType.CHARACTERS: CHARACTERS,
	GroupType.ENEMIES: ENEMIES,
	GroupType.TOWERS: TOWERS,
}

static func group_name(group_type: GroupType) -> String:
	return group_names[group_type]
	
