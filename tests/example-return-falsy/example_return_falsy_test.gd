func test_zero(solution_script):
	return [0, solution_script.return_0()]


func test_false(solution_script):
	return [false, solution_script.return_false()]


func test_empty_array(solution_script):
	return [[], solution_script.return_empty_array()]


func test_empty_string(solution_script):
	return ["", solution_script.return_empty_string()]


func test_null(solution_script):
	return [null, solution_script.return_null()]


func test_nothing(solution_script):
	return [null, solution_script.return_nothing()]
