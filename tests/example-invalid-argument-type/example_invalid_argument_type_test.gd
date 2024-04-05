func test_string_something(solution_script):
	return [solution_script.check_something("something"), true]


func test_string_nothing(solution_script):
	return [solution_script.check_something("nothing"), false]


func test_integer(solution_script):
	return [solution_script.check_something(10), false]
