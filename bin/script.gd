extends SceneTree


func _init():
	# TODO: read and use 3 args
	var args = OS.get_cmdline_user_args()
	
	var results = {
		"version": 2,
		"status": "pass",
	}
	var pretty_results = JSON.stringify(results, "  ", false)
	print(pretty_results)
	quit(1)
