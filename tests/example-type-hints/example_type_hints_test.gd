func test_return_string_correct(solution_script):
	return ["Hello!", solution_script.return_string("Hello!")]


func test_return_string_incorrect(solution_script):
	return [1, solution_script.return_string(1)]


func test_accept_int_correct(solution_script):
	return [1, solution_script.accept_int(1)]


func test_accept_int_incorrect(solution_script):
	return ["Hello!", solution_script.accept_int("Hello!")]
