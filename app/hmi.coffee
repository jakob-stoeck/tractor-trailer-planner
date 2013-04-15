# save absolute coordinates of obstacles and path
# deviate on sensor fusion
# draw on buffer with relative coordinates
# draw buffer on ctxPath with deviation
ctxDraft = cnvs.append 'draft', container, config.canvasWidth, config.canvasHeight
ctxBuffer = cnvs.create config.canvasWidth, config.canvasHeight

window.relativeToAbsolute = (p) ->
	# bring relative goal coordinates in current absolute coordinates
	# which are based on deltas from the last known starting point
	# convert artboard context into map context
	# center on current car
	x = p.x-center.x
	y = p.y-center.y
	# rotate around car
	s = Math.sin delta.theta
	c = Math.cos delta.theta
	px = (x * c + y * s)+delta.x+center.x
	py = (x * -s + y * c)+delta.y+center.y
	new Conf px, py, p.theta-delta.theta, p.theta1-delta.theta, p.s, p.phi, p.theta2-delta.theta
# todo use for obstacles
window.absoluteToRelative = (p) ->
	x = p.x+delta.x+center.x
	y = p.y+delta.y+center.y
	s = Math.sin delta.theta
	c = Math.cos delta.theta
	px = (x * c + y * s)+delta.x+center.x
	py = (x * -s + y * c)+delta.y+center.y
	new Conf x, y, -PIHALF, p.theta1+center.theta+delta.theta

window.joystick = {
	conf: {
		phi: 0
		s: 0
		u_s: 0
		u_phi: 0
	}
	maxSteps: 10
	dirty: true
	ctx: ctxInput
	ctxBuffer: cnvs.create 800, 800
	imgIs: new Image()
	imgShould: new Image()
	init: () ->
		@imgIs.src = '/images/joystick-is.png'
		@imgShould.src = '/images/joystick-should.png'
	setConf: (conf) ->
		if conf
			@conf.phi = conf.phi
			@conf.s = conf.s
		else
			@conf.s = 0
		@dirty = true
	update: ->
		return unless waypoints.isActive()
		# find next best waypoint
		absoluteConfig = relativeToAbsolute truck.conf
		if equals absoluteConfig, waypoints.current(), 200, 0.2
			# arrived at one waypoint
			if equals absoluteConfig, waypoints.path.last(), 1000, 0.2
				waypoints.init()
			else
				waypoints.next()
		if waypoints.current()
			@setConf waypoints.current()
		else
			# no waypoint anymore, arrived at goal
			@setConf @conf.phi = 0
			@setConf @conf.s = 0
			waypoints.init()
	draw: ->
		# draw user config
		size = 367
		margin = 450
		@ctxBuffer.clearRect margin-1,margin-1,size+1, size/2
		if (@conf.s != 0)
			@drawJoystick @conf.phi, @conf.s, true
		@drawJoystick -window.u_phi, window.u_s
		# return unless @dirty
		# @dirty = false
		# draw wanted config
	drawJoystick: (phi, s, wanted=false) ->
		size = 367
		margin = 450
		steeringPercent = phi/truck.U_PHI_MAX[1]
		@ctxBuffer.save()
		@ctxBuffer.translate size/2+margin, size/2+margin
		@ctxBuffer.rotate phi
		@ctxBuffer.translate -size/2, -size/2
		img = if wanted then @imgShould else @imgIs
		@ctxBuffer.drawImage img, 0, 0
		@ctxBuffer.restore()
		@ctx.clearRect margin-1,margin-1,size+1, size/2
		@ctx.drawImage @ctxBuffer.canvas, 0, 0
}
joystick.init()

window.waypoints = {
	path: []
	cursor: 0
	ctx: ctxPath
	running: false
	init: (path=[], goal=null) ->
		@path = []
		@goal = goal
		length = path.length
		# smoothes phi for the next step.  random planners may have small spikes
		# which are smoothed that way
		for p,i in path
			if i < length-3
				avg = (path[i].phi+path[i+1].phi+path[i+2].phi)/3
				p.phi = avg
			p.phi = -p.phi # we have a wrong leading sign in the path planner
			@path.push p
		@cursor = 0
		@ctx.clearRect 0, 0, 800, 800
		return
	reset: () ->
		@cursor = 0
	current: ->	@path[@cursor]
	next: ->
		if @cursor < @path.length
			@cursor++
			if @cursor == @path.length
				@reset()
			else
				@current()
	autopilot: () ->
		if @running
			@stopAutopilot()
		else
			@stopAutopilot()
			@running = true
			ms = 80
			@running = setInterval ->
				conf = waypoints.next()
				# that's not working because borders are relative, waypoints absolute
				# outlines = truck.outlines conf
				# length = outlines.length-1
				# valid = truck.validMove conf, planner.borders, outlines, length
				# if !valid
				# 	console.info 'crash!'
				# 	waypoints.stopAutopilot()
			, ms
			# setTimeout ->
			# 	clearInterval waypoints.running,
			# 	waypoints.running = false
			# , ms*(waypoints.path.length)
		return
	stopAutopilot: () ->
		@reset()
		clearInterval @running
		@running = false
	isActive: -> @path.length > 0 && @current()
	draw: ->
		return unless @isActive()
		@ctx.clearRect 0, 0, config.canvasWidth, config.canvasHeight
		@ctx.save()
		@ctx.translate center.x, center.y
		@ctx.rotate delta.theta
		@ctx.translate -center.x-delta.x, -center.y-delta.y
		@ctx.strokeStyle = '#000'
		@drawPath @path, 10
		# show real goal.  that might differ from the path end point if easier
		# paths are preferred over exact goal arrival.
		# @ctx.beginPath()
		# @ctx.strokeStyle = '#00f'
		# renderCar @ctx, @goal if @goal
		# @ctx.stroke()
		@ctx.restore()
	drawPath: (path, every=20, lock=false) ->
		from = 0
		to = path.length-1
		@ctx.beginPath()
		@ctx.moveTo path[from].x, path[from].y
		i = from
		if (to - from > 0)
			while i < to
				curr = path[i]
				@ctx.lineTo curr.x, curr.y
				if (!every or i % every == 0)
					renderCar @ctx, curr
				i++
		renderCar @ctx, path[from] if (!every)
		renderCar @ctx, @current()
		renderCar @ctx, path[to]
		@ctx.stroke()
}

window.trajectory = {
	ctx: ctxTrajectory
	ctxBuffer: cnvs.create 800, 800
	tmpPhi: 0
	tmpX: -1
	tmpY: -1
	draw: ->
		conf = truck.conf
		# return unless @tmpX != delta.x || @tmpY != delta.y || @tmpPhi != u_phi
		@ctxBuffer.clearRect 0, 0, 800, 800
		@tmpPhi = u_phi
		@tmpX = delta.x
		@tmpY = delta.y
		multiplier = 1
		steps = 80
		color = {}
		if conf.s == 0
			direction = [config.speed()*multiplier, -config.speed()*multiplier]
		else
			direction = [conf.s*multiplier]
		# draw all trajectories
		if config.showAllFeasiblePaths()
			for s in direction
				# step in every direction and many turning rates
				@ctxBuffer.beginPath()
				for phi in [truck.U_PHI_MAX[0]..truck.U_PHI_MAX[1]] by 0.05
					# reset to start config
					newConf = conf
					for i in [0..20]
						r = if s < 0 then 93 else 0
						g = if s < 0 then 98 else 200
						b = if s < 0 then 98 else 0
						a = 0.1#1/(1+i*0.4)
						@ctxBuffer.strokeStyle = "rgba(#{r}, #{g}, #{b}, #{a})"
						nextMove = truck.legalMoves(newConf, edgeDetection.walls, steps, [s], [phi])
						if nextMove.length > 0
							# if no collision detected move on
							newConf = nextMove[0]
						else
							break
						renderCar @ctxBuffer, newConf
				@ctxBuffer.stroke()

		# draw current trajectory
		for s in direction
			newConf = conf
			@ctxBuffer.beginPath()
			for i in [0..20]
				r = if s < 0 then 255 else 255
				g = if s < 0 then 255 else 255
				b = if s < 0 then 0 else 0
				a = 0.4#1/(1+i*0.4)
				@ctxBuffer.strokeStyle = "rgba(#{r}, #{g}, #{b}, #{a})"
				nextMove = truck.legalMoves(newConf, edgeDetection.walls, steps, [s], [newConf.phi])
				if nextMove.length > 0
					# if no collision detected move on
					newConf = nextMove[0]
				else
					break
				renderCar @ctxBuffer, newConf
			@ctxBuffer.stroke()
		@ctx.clearRect 0, 0, 800, 800
		@ctx.drawImage @ctxBuffer.canvas, 0, 0
}

window.artboard = {
	ctx: ctxDraft
	drawManualObstacle: (start, end) ->
		@ctx.beginPath()
		@ctx.moveTo start.x, start.y
		@ctx.lineTo end.x, end.y
		@ctx.stroke()
}

MODE_GOAL = 'goal'
MODE_OBS = 'obstacle'
mode = MODE_GOAL
$('#input-mode').on 'click', (e) ->
	mode = e.target.id

$('#play').on 'click', (e) ->
	waypoints.autopilot()

updateDrag = (dragPosition) ->
	ctxDraft.clearRect 0, 0, config.canvasWidth, config.canvasHeight
	artboard.drawManualObstacle startDrag, dragPosition

startDrag = null
endDrag = null
canvas = $ ctxTruck.canvas

canvas.on 'mousedown touchstart', (e) ->
	document.body.style.cursor = 'crosshair'
	startDrag = @relMouseCoords e
	ctxDraft.strokeStyle = '#333'
	ctxDraft.lineWidth = 5
	canvas.on 'mousemove touchmove', (e) ->
		updateDrag {x: e.offsetX, y: e.offsetY}
	e.preventDefault()

canvas.on 'mouseup touchend', (e) ->
	document.body.style.cursor = 'default'
	endDrag = @relMouseCoords e
	if euclid(startDrag, endDrag) > 20
		switch mode
			when MODE_OBS
				app.trigger 'obstacle.lidar', [startDrag, endDrag].map (e) -> relativeToAbsolute e
			when MODE_GOAL
				rotation = -Math.atan2 -(startDrag.y-endDrag.y), startDrag.x-endDrag.x
				rotation -= PI2 if rotation > 0
				start = new Conf center.x, center.y, center.theta, sensorSystem.angle, u_s, u_phi, sensorSystem.angle2
				goal = new Conf startDrag.x, startDrag.y, rotation, rotation
				path = planner.motion(start, goal, edgeDetection.walls).
				map (e) -> relativeToAbsolute e
				waypoints.init path, goal
	ctxDraft.clearRect 0, 0, config.canvasWidth, config.canvasHeight
	canvas.off 'mousemove touchmove'
	e.preventDefault()

# triggered by knockout
window.drawManual = () ->
	ctx = ctxTruck
	ctx.clearRect 0, 0, config.canvasWidth, config.canvasHeight
	conf = center
	steps = config.steps()
	every = parseInt steps/10, 10
	ctx.beginPath()
	for i in [0..steps]
		if Math.abs(conf.theta-conf.theta1) > PIHALF
			ctx.stroke()
			ctx.strokeStyle = '#f00'
		conf = truck.step conf.x, conf.y, conf.theta, conf.theta1, config.direction(), config.steer()
		renderCar ctx, conf unless i % every
	ctx.stroke()
	ctx.strokeStyle = '#000'
	return
