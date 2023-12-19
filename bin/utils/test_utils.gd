var file_utils: Object = null


func run_tests(solution_script: Object, test_suite_script: Object) -> Array:
	"""
	Runs the given test suite agains the given solution script. Returns an Array
	representing the results of each test case, in the same order that they are defined
	in the test suite. Each test result is a Dictionary containing 3 values:
	
	* `name`: the name of the test case
	* `status`: 'pass', 'fail', or 'error'
	* `message`: null if the test passed, otherwise it contains the details of the failure/error
	
	This method will look for methods starting with `test_` in the test script, and
	then call them with the solution script as the only argument. The `test_` method's
	name will be used as the `name` value for each test result.
	
	If any stderr output was generated during the execution of the `test_` method,
	`status` will be set to 'error'. The test will also receive an 'error' status
	if calling the `test_` method returned null (which indicates execution issues).
	
	Otherwise, the `test_` method should return an Array of 2 elements: the expected value,
	and the actual value. The values will be compared and if they are the same, the test will
	pass. Otherwise, it will fail, with a relevant message being set by this method.
	"""
	var test_results = []

	for method in test_suite_script.get_method_list():
		if method["name"].begins_with("test_"):
			var test_method_name = method["name"]
			print("-> " + test_method_name)
			var test_method = test_suite_script.get(test_method_name)
			
			var output = test_method.call(solution_script)
			var error_message = file_utils.get_error_message()
			
			if output == null:
				test_results.append({
					"name": test_method_name,
					"status": "error",
					"message": error_message,
				})
			else:
				var expected = output[0]
				var actual = output[1]
				
				var passed = (
					typeof(actual) == typeof(expected) and
					actual == expected and
					error_message.is_empty()
				)
				
				var status = "error"
				if error_message.is_empty():
					status = "pass" if passed else "fail"
					error_message = null if passed else get_failed_test_message(
						expected, actual
					)
				
				test_results.append({
					"name": test_method_name,
					"status": status,
					"message": error_message,
				})
	
	return test_results


func get_failed_test_message(expected, actual) -> String:
	"""
	Generates a message for a failed test. If given values are strings,
	this method will wrap them in single quotes, to distinguish from
	other types, like integers (e.g. '3' vs 3).
	
	This method should be used if the expected and actual values for a
	given test are different, or if they have different types.
	"""
	var values = []
	
	for value in [expected, actual]:
		var formatted_value = str(value)
		if typeof(value) == TYPE_STRING:
			formatted_value = "'{0}'".format([formatted_value])
		values.append(formatted_value)
	
	return "Expected output was {0}, actual output was {1}.".format(values)

