class_name TestRunner
extends SceneTree

const EXPECTED_GODOT_ERRORS = [
	"ERROR: Could not create directory: /root/.local\n   at: make_dir_recursive (core/io/dir_access.cpp:180)\n",
	"ERROR: Error attempting to create data dir: /root/.local/share/godot/app_userdata/[unnamed project].\n   at: ensure_user_data_dir (core/os/os.cpp:344)\n",
	"ERROR: Could not create editor data directory: /root/.local/share/godot\n   at: EditorPaths (editor/editor_paths.cpp:183)\n",
	"ERROR: Could not create directory: /root/.config\n   at: make_dir_recursive (core/io/dir_access.cpp:180)\n",
	"ERROR: Could not create editor config directory: /root/.config/godot\n   at: EditorPaths (editor/editor_paths.cpp:198)\n",
	"ERROR: Could not create directory: /root/.cache\n   at: make_dir_recursive (core/io/dir_access.cpp:180)\n",
	"ERROR: Could not create editor cache directory: /root/.cache/godot\n   at: EditorPaths (editor/editor_paths.cpp:219)\n",
	"ERROR: Can't save resource to empty path. Provide non-empty path or a Resource with non-empty resource_path.\n   at: save (core/io/resource_saver.cpp:105)\n",
	"ERROR: Error saving editor settings to \n   at: save (editor/editor_settings.cpp:1013)\n",
]

class ArgParser:

	var solution_script_path: String = ""
	var test_suite_script_path: String = ""
	var run_all: bool = false
	var json: bool = false
	var json_file: String = ""

	func usage(message: String) -> void:
		print("Usage:")
		print("test_runner [--all] [--json filename.json] <slug> <solution_directory>")
		if message != "":
			print()
			print(message)

	func parse_args() -> Error:
		"""
		Validates the number of args passed to the script and sets values of the following
		global variables, based on the given args:
		* `solution_script_path`
		* `test_suite_script_path`
		"""
		var args = OS.get_cmdline_user_args()
		var positional: Array = []

		var idx := 0
		while idx < len(args):
			var arg = args[idx]
			if arg == "--all":
				run_all = true
			elif arg.begins_with("--json"):
				if arg.contains("="):
					var parts = arg.split("=", true, 1)
					if parts[0] == "--json":
						self.json = true
						self.json_file = parts[1]
					else:
						usage("Invalid flag %s" % arg)
						return ERR_INVALID_PARAMETER
				elif idx + 1 < len(args):
					self.json = true
					self.json_file = args[idx + 1]
					idx += 1
				else:
					usage("Flag %s is missing a filename" % arg)
					return ERR_INVALID_PARAMETER
			elif arg.begins_with("--"):
				usage("Invalid flag %s" % arg)
				return ERR_INVALID_PARAMETER
			else:
				positional.append(arg)
			idx += 1

		if len(positional) != 2:
			usage("Expecting 2 positional args but got %d" % len(positional))
			return ERR_INVALID_PARAMETER

		var slug = positional[0]
		var solution_dir_path = positional[1]

		# Test folders use dashes, but test files use underscores
		var gdscript_path = solution_dir_path.path_join(slug.replace("-", "_"))

		self.solution_script_path = gdscript_path + ".gd"
		self.test_suite_script_path = gdscript_path + "_test.gd"

		return OK

	func files() -> Array:
		return [self.solution_script_path, self.test_suite_script_path]


var error_output_already_processed_length: int = 0


func get_error_message() -> String:
	"""
	Checks the contents of the `/tmp/stderr` file, where error output from the
	currently running test suite should be stored. If there is any relevant output
	there, this method will return it. If the file is empty, an empty string is returned.

	This method will remove previously read output from the returned message. It should
	be called after executing every test, to ensure that the message contains only output
	relevant for the given test.

	NOTE: running a Godot instance without full access to certain folders in the
	home directory (`~/.config`, `~/.local`, `~/.cache`) will result in additional
	errors. This happens when GDScript test runner is executed in Docker. However,
	these errors do not stop the execution of the program, so they can be ignored.
	This method filters them out, leaving only the errors caused by the actual tests.
	"""

	# The default error message. If there are no errors in `/tmp/stderr`, chances are that the method
	# was called with the wrong number of arguments.
	var message = ""

	var error_output = FileAccess.get_file_as_string("/tmp/stderr")
	error_output = error_output.erase(0, error_output_already_processed_length)
	error_output_already_processed_length += len(error_output)

	# By default, Godot's error messages are printed with colors. To include the output in the
	# `results.json` file, color markers need to be removed first.
	var color_sequence = RegEx.new()
	color_sequence.compile("\\e\\[\\d[\\d;]*m")
	error_output = color_sequence.sub(error_output, "", true)

	# Filter out the expected error messages
	for expected_error in EXPECTED_GODOT_ERRORS:
		error_output = error_output.replace(expected_error, "")

	# If there is any error output left, include it in the final message
	if not error_output.is_empty():
		message = error_output

	return message


func output_results(results: Dictionary, output_file: String) -> Error:
	"""
	If output_dir_path is empty, outputs friendly-formatted test results to
	stdout.

	Otherwise, writes JSON results to results.json in the given path.
	"""
	if output_file == "":
		return print_friendly_results(results)
	else:
		return write_results_file(results, output_file)


func print_friendly_results(results: Dictionary) -> Error:
	"""
	Prints rich results to stdout.
	"""
	var rich_results = [""]
	if results.status == "pass":
		rich_results.push_back("[color=yellow]Exercise passed!  Nicely done![/color]")
	else:
		rich_results.push_back("Exercise has at least one failed test:")
		for test in results.tests:
			if test.status == "pass":
				rich_results.push_back(" %s [color=yellow]passed ✔[/color]" % test.name)
			else:
				rich_results.push_back(" %s [color=pink]failed: %s[/color]" % [test.name, test.message])
	print_rich("\n".join(rich_results))
	return OK


func write_results_file(results: Dictionary, output_file: String) -> Error:
	"""
	Saves a dictionary as a `results.json` file in the output directory. The file
	is indented with 4 spaces, keys are not sorted.

	The `results` dictionary represents the full output of a single exercise's
	test suite, according to the Test Runner Interface documentation:

	https://exercism.org/docs/building/tooling/test-runners/interface

	This method automatically adds `'version' = 2` to the results.
	"""
	# Due to keys not being sorted, `version` should be inserted first
	var full_results = {"version": 2}
	full_results.merge(results)

	var pretty_results = JSON.stringify(full_results, "  ", false)

	var results_json = FileAccess.open(output_file, FileAccess.WRITE)
	if results_json == null:
		var err = FileAccess.get_open_error()
		push_error("Failed to write the file: %s (%s)" % [output_file, error_string(err)])
		return err

	results_json.store_string(pretty_results + "\n")
	return OK


func extract_method(script: Object, method_name: String) -> String:
	"""Extract the source code of a method from a script."""
	var in_func: bool = false
	var parts = []
	for line in script.get_script().source_code.split("\n"):
		if not in_func:
			if line.begins_with("func %s(" % method_name):
				in_func = true
		elif not line.begins_with("\t") and not line.begins_with(" "):
			break
		else:
			parts.append(line)

	return "\n".join(parts)


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

	Otherwise, the `test_` method should return an Array of 2 elements: the actual value,
	and the expected value. The values will be compared and if they are the same, the test will
	pass. Otherwise, it will fail, with a relevant message being set by this method.
	"""
	var test_results = []

	for method in test_suite_script.get_method_list():
		if not method["name"].begins_with("test_"):
			continue
		var test_method_name = method["name"]
		print("-> " + test_method_name)
		var test_method = test_suite_script.get(test_method_name)

		var output = test_method.call(solution_script)
		var error_message = get_error_message()

		if output == null:
			test_results.append({
				"name": test_method_name,
				"status": "error",
				"message": error_message,
			})
		else:
			var actual = output[0]
			var expected = output[1]

			var passed = (
				typeof(actual) == typeof(expected) and
				actual == expected and
				error_message.is_empty()
			)

			var status = "error"
			if error_message.is_empty():
				status = "pass" if passed else "fail"
				error_message = null if passed else get_failed_test_message(
					actual, expected
				)

			var test_code = extract_method(test_suite_script, method["name"])
			# The code would be cleaner if the test suite actually checked the values.
			# Instead, the test suite returns an array with two values which are compared (above).
			# This `replace()` hides some of that implementation detail by communicating that the
			# array elements are being compared for equality.
			test_code = test_code.replace("return [", "assert_equal [")
			test_code = test_code.replace("\t", "    ")
			test_code = test_code.dedent().strip_edges()

			test_results.append({
				"name": test_method_name,
				"status": status,
				"message": error_message,
				"test_code": test_code,
			})

	return test_results


func get_failed_test_message(actual, expected) -> String:
	"""
	Generates a message for a failed test. If given values are strings,
	this method will wrap them in single quotes, to distinguish from
	other types, like integers (e.g. '3' vs 3).

	This method should be used if the actual and expected values for a
	given test are different, or if they have different types.
	"""
	var values = []

	for value in [actual, expected]:
		var formatted_value = str(value)
		if typeof(value) == TYPE_STRING:
			formatted_value = "'{0}'".format([formatted_value])
		values.append(formatted_value)

	return "Expected output was {1}, actual output was {0}.".format(values)



func _init():
	# Calling `quit(1)` doesn't stop the program immediately, so a `return` is necessary.
	# That's why errors are checked directly in `_init()`, instead of calling `quit(1)`
	# in each method.
	var args = ArgParser.new()
	if args.parse_args() != OK:
		quit(1)
		return
	if args.json:
		if check_stderr() != OK:
			quit(1)
			return
	if check_if_files_exist(args.files()) != OK:
		quit(1)
		return

	var r = load_solution_script(args.solution_script_path, args.json_file)
	if len(r) != 2 || r[1] != OK:
		quit(1)
		return
	var solution_script = r[0]

	var test_suite_script = load(args.test_suite_script_path).new()

	if clean_up_before_test(args.json_file) != OK:
		quit(1)
		return
	run_suite(solution_script, test_suite_script, args.json_file, args.run_all)
	quit()


func check_stderr() -> Error:
	if OS.get_stderr_type() != OS.STD_HANDLE_FILE:
		push_error("STDERR must be redirected to '/tmp/stderr' when using '--json'")
		return ERR_FILE_NOT_FOUND
	return OK


func check_if_files_exist(files: Array) -> Error:
	for file in files:
		if not ResourceLoader.exists(file):
			push_error("File %s not found." % file)
			return ERR_FILE_NOT_FOUND
	return OK


func clean_up_before_test(output_file: String) -> Error:
	"""
	Removes the previous `results.json` file, to ensure that the current test suite will not use it.
	"""
	if FileAccess.file_exists(output_file):
		DirAccess.remove_absolute(output_file)
	var error_message: String = get_error_message()
	if error_message != "":
		push_error(error_message)
		return FAILED
	return OK


func load_script(solution_script_path: String) -> Object:
	"""Load a script. This helper is needed to catch failures without aborting the error handling."""
	return load(solution_script_path).new()


func load_solution_script(solution_script_path: String, output_file) -> Array:
	"""
	Loads the solution script and saves it in a global variable. In case of any
	issues, this method will save the `results.json` file with `error` status.
	"""
	# Make sure the STDERR file is empty.
	get_error_message()
	var solution_script = load_script(solution_script_path)

	if solution_script == null:
		var message: String = "The solution file could not be parsed."
		# Extract the error message, up until the "Failed to load" line
		# which is specific to the test runner, not the user's solution.
		var error_message: String = get_error_message()
		if error_message != "":
			var msg = []
			var stop = 'ERROR: Failed to load script "%s" with error "Parse error".' % solution_script_path
			for line in error_message.split("\n"):
				if line == stop:
					break
				msg.append(line)
			message += "\n" + "\n".join(msg)
		var results = {
			"status": "error",
			"message": message,
			"tests": [],
		}
		output_results(results, output_file)
		return [null, ERR_PARSE_ERROR]

	return [solution_script, OK]


func run_suite(solution_script, test_suite_script, output_file: String, run_all: bool) -> void:
	"""
	Executes the current suite against the current solution. Stores the results in the
	`results.json` file in the output dir.
	"""
	var test_results = run_tests(solution_script, test_suite_script)
	var results = {}

	# Check if any tests were executed
	if len(test_results) == 0:
		results = {
			"status": "error",
			"message": "No tests were executed.",
			"tests": [],
		}
	else:
		results = {
			"status": "pass",
			"tests": test_results,
		}

		# If any of the tests failed, change the global status to `fail`
		for test_result in test_results:
			if test_result["status"] != "pass":
				results["status"] = "fail"
				break

		if not run_all and results["status"] != "pass":
			var success_count: int = 0
			for test_result in test_results:
				if test_result["status"] == "pass":
					success_count += 1

			var has_failure = false
			var filtered_results = []
			for test_result in test_results:
				if test_result["status"] == "pass":
					filtered_results.append(test_result)
				elif not has_failure:
					has_failure = true
					test_result["message"] = "Passes %d/%d tests. First failure: %s" % [
						success_count, len(test_results), test_result["message"],
					]
					filtered_results.append(test_result)
			results["tests"] = filtered_results

	output_results(results, output_file)
