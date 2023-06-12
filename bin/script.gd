extends SceneTree

const ERROR_MESSAGE = "Expected output was '{}', actual output was '{}'."


func run_tests(solution, method_name, test_cases):
	var test_results = []
	
	for test_case in test_cases:
		var test_name = test_case["test_name"]
		var args = test_case["args"]
		var expected = test_case["expected"]
		
		# TODO: check for errors
		# TODO: args.duplicate() fixes an error with callv, report it
		var output = solution.callv(method_name, args.duplicate())
		
		var status = run_single_test(solution, method_name, args.duplicate(), expected)
		var message = ERROR_MESSAGE.format([expected, output], "{}")
		
		test_results.append({
			"name": test_name,
			"status": "pass" if status == OK else "fail",
			"message": null if status == OK else message,
		})
	
	return test_results


func run_single_test(solution, method_name, args, expected):
	var output = solution.callv(method_name, args)
	if (output == expected):
		return OK
	else:
		return ERR_PARSE_ERROR


func _init():
	var args = OS.get_cmdline_user_args()
	# Using only 2 args, output is printed
	if len(args) < 2:
		# TODO: print error message
		print('{"version": 2, "status": "error"}')
		quit(1)
	
	var slug = args[0]
	var solution_folder = args[1]
	
	var gd_path = solution_folder.path_join(slug.replace("-", "_"))
	var solution_path = gd_path + ".gd"
	# TODO: allow multiple test files?
	var test_suite_path = gd_path + "_test.gd"
	
	if not (ResourceLoader.exists(solution_path) and ResourceLoader.exists(test_suite_path)):
		# TODO: print error message
		print('{"version": 2, "status": "error"}')
		quit(1)
	
	var solution = load(solution_path).new()
	var test_suite = load(test_suite_path).new()
	
	var method_name = test_suite.METHOD_NAME
	var test_cases = test_suite.TEST_CASES
	
	if not solution.has_method(method_name):
		# TODO improve the string formatting
		print(
			'{"version": 2, "status": "error", "message": ' +
			'"Method \'%s\' was not found.", "tests": []}' % method_name
		)
		quit(1)
	
	
	var test_results = run_tests(solution, method_name, test_cases)
	
	var results = {
		"version": 2,
		"status": "pass",
		"tests": test_results
	}
	
	for test_result in test_results:
		if test_result["status"] == "fail":
			results["status"] = "fail"
			break
	
	var pretty_results = JSON.stringify(results, "  ", false)
	print(pretty_results)
	quit(1)
