# update
setInterval ->
	sensorSystem.update()
	delta.update()
	truck.update()
	joystick.update()
, 10

# slow updates
setInterval ->
	edgeDetection.update()
, 1000

# draw
draw = ->
	map.draw()
	truck.draw()
	waypoints.draw()
	trajectory.draw()
	joystick.draw()
	frameRate.draw()
	requestAnimFrame draw
draw()
