extends RefCounted

class_name ConditionEvaluator

var def: ConditionDef
# Set by Behavior.choose() before each evaluation. Evaluators that need to
# read action-level params (max_distance, aoe_shape, etc.) or query the
# world by side use these. Most evaluators ignore them.
var action: Action
var side_component: SideComponent
