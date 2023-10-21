func test_string_something(solution_script):
	return [true, solution_script.check_something("something")]


func test_string_nothing(solution_script):
	return [false, solution_script.check_something("nothing")]


func test_integer(solution_script):
	return [false, solution_script.check_something(10)]
