extends GutTest

# TODO: Add tests that verify loading straight from resource correctly sets
# things up as it has bitten us in the past.
func test_default_valid():
	var params = SkillParams.new()
	assert_true(params.valid)
	assert_eq(params.placeholders, [])
	assert_eq(params.parts, [])

func test_parse_editor_string_no_params():
	var params = SkillParams.new()
	params.editor_string = ""
	params._parse()
	assert_true(params.valid)
	assert_eq(params.placeholders, [])
	assert_eq(params.parts, [])

func test_parse_editor_string_two_params():
	var params = SkillParams.new()
	params.editor_string = "health {cmp} {int_value}"
	assert_true(params.valid)
	assert_eq(
		params.placeholders,
		[SkillParams.PlaceholderId.CMP, SkillParams.PlaceholderId.INT_VALUE]
	)
	assert_eq(params.parts, [
		"health ",
		SkillParams.PlaceholderId.CMP,
		" ",
		SkillParams.PlaceholderId.INT_VALUE
	])

func test_set_values_and_interpolate_text():
	var params = SkillParams.new()
	params.editor_string = "health {cmp} {int_value}"
	assert_eq(params.interpolated_text(), "health {cmp} {int_value}")
	params.set_placeholder_value(SkillParams.PlaceholderId.CMP, SkillParams.CmpOp.LE)
	assert_eq(params.interpolated_text(), "health <= {int_value}")
	params.set_placeholder_value(SkillParams.PlaceholderId.INT_VALUE, 5)
	assert_eq(params.interpolated_text(), "health <= 5")

func test_parse_editor_string_non_existent():
	var params = SkillParams.new()
	params.editor_string = "health {foo}"
	assert_false(params.valid)

func test_parse_editor_string_duplicate_param():
	var params = SkillParams.new()
	params.editor_string = "health {cmp} {cmp}"
	assert_false(params.valid)
