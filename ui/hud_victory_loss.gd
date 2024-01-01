extends Control

@onready var conditions_text: RichTextLabel = %Text

var victory_loss: VictoryLossConditionComponent

func initialize(victory_loss_condition_compoment: VictoryLossConditionComponent):
	victory_loss = victory_loss_condition_compoment
	victory_loss.level_finished.connect(_on_level_finished)
	victory_loss.level_failed.connect(_on_level_failed)
	_initialize_text()
	
func _initialize_text(
		victory_type: VictoryLossConditionComponent.VictoryType = VictoryLossConditionComponent.VictoryType.UNSPECIFIED,
		loss_type: VictoryLossConditionComponent.LossType = VictoryLossConditionComponent.LossType.UNSPECIFIED):
	var text = ""
	text += "Win Conditions\n"
	text += "[ul]\n"
	var victory_text = ""
	for type in victory_loss.victory:
		var triggered = "( )"
		if type == victory_type:
			triggered = "(*)"
		victory_text += "%s %s\n" % [triggered, victory_loss.get_text_victory_condition(type)]
	if victory_text.is_empty():
		text += "None"
	else:
		text += victory_text
	text += "[/ul]\n"
	text += "Loss Conditions\n"
	text += "[ul]"
	var loss_text = ""
	for type in victory_loss.loss:
		var triggered = "( )"
		if type == loss_type:
			triggered = "(*)"
		loss_text += "%s %s\n" % [triggered, victory_loss.get_text_loss_condition(type)]
	if loss_text.is_empty():
		text += "None"
	else:
		text += loss_text
	text += "[/ul]\n"
	print(text)
	conditions_text.text = text
	
func show_text(visible: bool = true):
	%PanelContainer.visible = visible

func _on_level_finished(victory_type: VictoryLossConditionComponent.VictoryType):
	_initialize_text(victory_type)

func _on_level_failed(loss_type: VictoryLossConditionComponent.LossType):
	_initialize_text(VictoryLossConditionComponent.VictoryType.UNSPECIFIED, loss_type)
	
func _on_button_pressed():
	%PanelContainer.visible = not %PanelContainer.visible
