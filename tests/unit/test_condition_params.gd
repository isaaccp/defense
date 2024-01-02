extends GutTest

func test_default_valid():
	var params = ConditionParams.new()
	assert_true(params.valid)
	assert_eq(params.placeholders, [])
	assert_eq(params.parts, [])

func test_parse_editor_string_no_params():
	var params = ConditionParams.new()
	params.editor_string = ""
	assert_true(params.valid)
	assert_eq(params.placeholders, [])
	assert_eq(params.parts, [])

func test_parse_editor_string_two_params():
	var params = ConditionParams.new()
	params.editor_string = "health {cmp} {int_value}"
	assert_true(params.valid)
	assert_eq(
		params.placeholders,
		[ConditionParams.PlaceholderId.CMP, ConditionParams.PlaceholderId.INT_VALUE]
	)
	assert_eq(params.parts, [
		"health ",
		ConditionParams.PlaceholderId.CMP,
		" ",
		ConditionParams.PlaceholderId.INT_VALUE
	])

func test_set_values_and_interpolate_text():
	var params = ConditionParams.new()
	params.editor_string = "health {cmp} {int_value}"
	assert_eq(params.interpolated_text(), "health {cmp} {int_value}")
	params.set_placeholder_value(ConditionParams.PlaceholderId.CMP, ConditionParams.CmpOp.LE)
	assert_eq(params.interpolated_text(), "health <= {int_value}")
	params.set_placeholder_value(ConditionParams.PlaceholderId.INT_VALUE, 5)
	assert_eq(params.interpolated_text(), "health <= 5")

func test_parse_editor_string_non_existent():
	var params = ConditionParams.new()
	params.editor_string = "health {foo}"
	assert_false(params.valid)

func test_parse_editor_string_duplicate_param():
	var params = ConditionParams.new()
	params.editor_string = "health {cmp} {cmp}"
	assert_false(params.valid)
