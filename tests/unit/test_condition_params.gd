extends GutTest

func test_default_valid():
	var params = ConditionParams.new()
	assert_true(params.valid)
	assert_eq(params.placeholders, [])

func test_parse_editor_string_no_params():
	var params = ConditionParams.new()
	params.editor_string = ""
	assert_true(params.valid)
	assert_eq(params.placeholders, [])

func test_parse_editor_string_two_params():
	var params = ConditionParams.new()
	params.editor_string = "health {cmp} {int_value}"
	assert_true(params.valid)
	assert_eq(
		params.placeholders,
		[ConditionParams.PlaceholderId.CMP, ConditionParams.PlaceholderId.INT_VALUE]
	)

func test_parse_editor_string_non_existent():
	var params = ConditionParams.new()
	params.editor_string = "health {foo}"
	assert_false(params.valid)

func test_parse_editor_string_duplicate_param():
	var params = ConditionParams.new()
	params.editor_string = "health {cmp} {cmp}"
	assert_false(params.valid)
