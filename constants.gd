extends Object

class_name Constants

const GameplayStateMachineName = &"gameplay"
const RunStateMachineName = &"run"
const LevelStateMachineName = &"level"

# Those skills will always be available to characters. They'll also be automatically added
# as unlocked when starting a new run.
const base_acquired_skills: Array[StringName] = [&"Always", &"Enemy", &"Ally", &"Tower", &"Move To", &"Closest First"]
