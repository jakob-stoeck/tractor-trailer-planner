window.edgeDetection =
	walls: []
	init: ->
		@worker = new Worker '/build/app/edgedetection.js'
		@worker.addEventListener 'message', (e) =>
			data = e.data
			config.wallNumber data.walls.length
			@walls = data.walls
		, false
	update: ->
		@worker.postMessage { imageData: get32BitImageData ctxMap }

window.sensorSystem =
	conf: new Conf 0, 0, 0, 0
	angle: -PIHALF
	angle2: -PIHALF
	update: ->
		# uses global sensors for speed and steer
		@updateManual u_s, u_phi
	updateManual: (u_s, u_phi) ->
		conf = truck.step 0, 0, -PIHALF, @angle, u_s, u_phi, config.steps(), @angle2
		@angle = conf.theta + conf.theta1 + PIHALF
		@angle2 = conf.theta + conf.theta2 + PIHALF
		@conf = conf

window.delta = {
	x: 0
	y: 0
	theta: 0
	update: () ->
		# deltas build up a global positioning, useful in simulation mode
		@theta += sensorSystem.conf.theta+PIHALF
		s = Math.sin @theta
		c = Math.cos @theta
		@x += sensorSystem.conf.x * c + sensorSystem.conf.y * s
		@y += sensorSystem.conf.x * -s + sensorSystem.conf.y * c
}

app.on 'angle.lidar', (e, angle) ->
	#eventInfo e
	sensorSystem.angle = angle
