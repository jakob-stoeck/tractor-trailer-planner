## Driving Car
preventScrolling = (e) ->
	if arrows.left <= e.keyCode <= arrows.down
		e.preventDefault()

arrows = { left: 37, up: 38, right: 39, down: 40 }
window.u_s = 0
window.u_phi = 0

app.on 'keydown', (e) ->
	preventScrolling e
	switch e.keyCode
		when arrows.up
			window.u_s = config.speed()
		when arrows.down
			window.u_s = -config.speed()
		when arrows.left
			window.u_phi = Math.min window.u_phi+config.steeringRate(), config.steer()
		when arrows.right
			window.u_phi = Math.max window.u_phi-config.steeringRate(), -config.steer()

app.on 'keyup', (e) ->
	preventScrolling e
	switch e.keyCode
		when arrows.up, arrows.down
			window.u_s = 0

frameRate = {
	lastTime: +new Date
	frames: 0
	i: 0
	draw: ->
		now = +new Date
		d = 1000/(now-@lastTime+1)
		@frames += d
		@lastTime = now
		if @i++ >= 10
			config.frameRate (@frames/@i).toFixed 0
			@i = 0
			@frames = 0
}

# Game Loop

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
