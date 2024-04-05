func test_return_string_correct(solution_script):
	return [solution_script.return_string("Hello!"), "Hello!"]


func test_return_string_incorrect(solution_script):
	return [solution_script.return_string(1), 1]


func test_accept_int_correct(solution_script):
	return [solution_script.accept_int(1), 1]


func test_accept_int_incorrect(solution_script):
	return [solution_script.accept_int("Hello!"), "Hello!"]
