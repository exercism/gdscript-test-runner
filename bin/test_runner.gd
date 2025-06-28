extends SceneTree

# Utils
var file_utils: Object = null
var test_utils: Object = null

# Paths
var output_dir_path: String = ""
var solution_script_path: String = ""
var test_suite_script_path: String = ""

# Scripts
var solution_script: Object = null
var test_suite_script: Object = null


func _init():
	load_utils_scripts()

	# Calling `quit(1)` doesn't stop the program immediately, so a `return` is necessary.
	# That's why errors are checked directly in `_init()`, instead of calling `quit(1)`
	# in each method.
	for setup_step in [
		parse_args,
		check_if_required_files_exist,
		load_solution_script
	]:
		if setup_step.call() != OK:
			quit(1)
			return
	
	load_test_suite_script()
	
	clean_up_before_test()
	run_tests()
	quit()


func load_utils_scripts() -> void:
	"""
	Loads all utils scripts required by the test runner, storing them in corresponding
	global variables.
	"""
	file_utils = load_utils_script("file_utils.gd")
	test_utils = load_utils_script("test_utils.gd")
	test_utils.file_utils = file_utils


func load_utils_script(file_name: String) -> Object:
	"""
	Loads a utils script. Those scripts should be stored in the `utils` directory
	(relative to this script's location). The parameter `file_name` is the name of
	the script, including the extension, but excluding the path (e.g. `file_utils.gd`).
	"""
	var current_dir = get_script().get_path().get_base_dir()
	var utils_file_path = current_dir.path_join("utils").path_join(file_name)
	return load(utils_file_path).new()


func parse_args() -> Error:
	"""
	Validates the number of args passed to the script and sets values of the following
	global variables, based on the given args:
	* `solution_script_path`
	* `test_suite_script_path`
	* `output_dir_path` (optional for local test runner, required for standard JSON test runner behaviour)
	"""
	var args = OS.get_cmdline_user_args()
	
	# This script still conforms to [1] but allows 2 arguments for a local test
	# runner with non-JSON output to eliminate dependence on 'jq'
	#
	# [1] https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md#execution
	if len(args) not in [2,3]:
		push_error(
			"The script needs exactly 2 or exactly 3 arguments, was called with %s: %s" % [
				len(args), str(args)
			]
		)
		return ERR_INVALID_PARAMETER
	
	var slug = args[0]
	var solution_dir_path = args[1]
	if len(args) == 3:
		output_dir_path = args[2]
	
	# Test folders use dashes, but test files use underscores
	var gdscript_path = solution_dir_path.path_join(slug.replace("-", "_"))
	
	solution_script_path = gdscript_path + ".gd"
	test_suite_script_path = gdscript_path + "_test.gd"
	
	return OK


func check_if_required_files_exist() -> Error:
	"""
	Checks if the solution file and test suite file exist. If not, pushes an error
	and quits the program.
	"""
	if not (
		ResourceLoader.exists(solution_script_path) and
		ResourceLoader.exists(test_suite_script_path)
	):
		push_error(
			"Required files %s and %s were not found." % [
				solution_script_path, test_suite_script_path
			]
		)
		return ERR_FILE_NOT_FOUND
	
	return OK


func clean_up_before_test() -> void:
	"""
	Removes the previous `results.json` file, to ensure that the current test suite will not use it.
	"""
	file_utils.remove_results_file(output_dir_path)


func load_solution_script() -> Error:
	"""
	Loads the solution script and saves it in a global variable. In case of any
	issues, this method will save the `results.json` file with `error` status.
	"""
	solution_script = file_utils.load_script(solution_script_path)
	
	if solution_script == null:
		var results = {
			"status": "error",
			"message": "The solution file could not be parsed.",
			"tests": [],
		}
		file_utils.output_results(results, output_dir_path)
		return ERR_PARSE_ERROR
	
	return OK


func load_test_suite_script() -> void:
	"""
	Loads the test suite script and saves it in a global variable.

	This method doesn't involve any error handling, assuming that the
	test suite script is readable and has the correct format.
	"""
	test_suite_script = load(test_suite_script_path).new()


func run_tests() -> void:
	"""
	Executes the current suite against the current solution. Stores the results in the
	`results.json` file in the output dir.
	"""
	var test_results = test_utils.run_tests(solution_script, test_suite_script)
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
	
	file_utils.output_results(results, output_dir_path)
