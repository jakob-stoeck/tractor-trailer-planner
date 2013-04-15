# update
setInterval ->
	sensorSystem.update()
	delta.update()
	truck.update()
, 10

# draw
draw = ->
	truck.draw()
	waypoints.draw()
	# trajectory.draw()
	requestAnimFrame draw
draw()
