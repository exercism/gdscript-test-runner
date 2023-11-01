func test_add_1_and_2(solution_script):
	return [3, solution_script.add_2_numbers(1, 2)]


func test_add_10_and_20(solution_script):
	return [30, solution_script.add_2_numbers(10, 20)]


func test_add_0_and_3(solution_script):
	return [3, solution_script.add_2_numbers(0, 3)]


func test_add_0_and_0(solution_script):
	return [0, solution_script.add_2_numbers(0, 0)]
