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


func remove_results_file(output_dir_path: String) -> Error:
	"""
	Removes the `results.json` file from the output folder. This should be called
	before each test suite to ensure that the previous results file is not being
	compared with the expected results.
	"""
	var results_json_path = output_dir_path.path_join("results.json")
	return remove_file(results_json_path)


func remove_file(file_path: String) -> Error:
	"""
	Removes the given file if it exists. Pushes and returns an error if the operation failed.
	"""
	if FileAccess.file_exists(file_path):
		var err = DirAccess.remove_absolute(file_path)
		if err != OK:
			push_error("Failed to remove the file: %s" % file_path)
			return err
	
	return OK


func load_script(script_path: String) -> Object:
	"""
	Loads a script file.

	This has to be done in a separate method to allow proper detection of invalid files.
	If this method fails, it will return `null` instead of crashing the program.
	"""
	var script = load(script_path).new()
	return script


func write_results_file(results: Dictionary, output_dir_path: String) -> Error:
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
	var results_json_path = output_dir_path.path_join("results.json")

	var results_json = FileAccess.open(results_json_path, FileAccess.WRITE)
	if results_json == null:
		var err = FileAccess.get_open_error()
		push_error("Failed to write the file: %s (%s)" % [results_json_path, error_string(err)])
		return err
	
	results_json.store_string(pretty_results + "\n")
	return OK
