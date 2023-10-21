func test_too_few_args(solution_script):
	return [null, solution_script.add_numbers(1)]


func test_too_many_args(solution_script):
	return [null, solution_script.add_numbers(10, 20, 40)]
