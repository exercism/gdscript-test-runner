func test_too_few_args(solution_script):
	return [solution_script.add_numbers(1), null]


func test_too_many_args(solution_script):
	return [solution_script.add_numbers(10, 20, 40), null]
