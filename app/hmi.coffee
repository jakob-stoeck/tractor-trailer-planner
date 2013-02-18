# Mikrobewegungen am Ziel
# Velocity Vector aus Laser
# Anweisungen an Fahrer mit Joystick
# Trennung zwischen Gas geben und lenken
# 1. Schick + Simulierte Daten
# -Collision detection in RRT-
# -Drive mode in RRT-
# sensor input from laser and odometrics
# show future trajectory
# endless map
# smooth paths, foremost between bi-directional paths
# smooth input
# manual obstacles im unbekannten raum
# 2. No-go-areas, virtuelle obstacles
# 3. Joystick Unterstützung wichtig, relative Anzeige, Progress bar
# 4. Lernmodus
# 5. Menschen simulieren, geschlossene Parkplätze, Höfe
# sticky keys
# wand schliessen


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
	c = new Conf px, py, p.theta-delta.theta, p.theta1-delta.theta
	c.s = p.s
	c.phi = p.phi
	c
# todo use for obstacles
window.absoluteToRelative = (p) ->
	x = p.x+delta.x+center.x
	y = p.y+delta.y+center.y
	s = Math.sin delta.theta
	c = Math.cos delta.theta
	px = (x * c + y * s)+delta.x+center.x
	py = (x * -s + y * c)+delta.y+center.y
	c = new Conf x, y, -PIHALF, p.theta1+center.theta+delta.theta

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
		if equals absoluteConfig, waypoints.current(), 100, 0.2
			# arrived at one waypoint
			waypoints.next()
	updateSlow: ->
		return unless waypoints.isActive()
		# find best action to active waypoint
		absoluteConfig = relativeToAbsolute truck.conf
		if waypoints.current()
			# which action to take for the next waypoint
			absoluteConfig.phi = waypoints.current().phi
			# FIXME joystick
			nextActions = bfs absoluteConfig, waypoints.current(), 100, 0.2
			if nextActions
				nextConf = nextActions.last()
			else
				# truck is off from path, recalculate a path and disable waypoints
				# planner.motion absoluteToRelative(waypoints.path.last()), truck.conf
				# alert 'off path'
				# waypoints.init()
		else
			# no waypoint anymore, arrived at goal
			waypoints.init()
		@setConf nextConf
	draw: ->
		@ctx.clearRect 500, 500, 210, 200
		@ctx.strokeRect 500, 500, 210, 200
		# draw user config
		@drawJoystick -window.u_phi, window.u_s
		# return unless @dirty
		# @dirty = false
		# draw wanted config
		if (@conf.s != 0)
			@drawJoystick @conf.phi, @conf.s, true
	drawJoystick: (phi, s, wanted=false) ->
		steeringPercent = phi/truck.U_PHI_MAX[1]
		width = 200
		@ctx.fillStyle = if wanted then '#f00' else '#000'
		@ctx.fillRect 500 + width/2 + steeringPercent * width/2, 500 + (if wanted then 50 else 0), 10, 100
		@ctx.fillRect 500 + (if s < 0 then 0 else width/2), 500 + (if wanted then 10 else 0), width/2, 10
}

window.waypoints = {
	path: []
	cursor: 0
	ctx: ctxPath
	running: false
	init: (path=[]) ->
		@path = path
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
		@drawPath @path
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
		if (!every) then renderCar @ctx, path[from]
		renderCar @ctx, @current()
		# @ctx.rect @current().x-20, @current().y-20, 40, 40
		@ctx.stroke()
		renderCar @ctx, path[to]
		@ctx.stroke()
}

window.trajectory = {
	ctx: ctxTrajectory
	tmpPhi: 0
	tmpX: -1
	tmpY: -1
	draw: ->
		conf = truck.conf
		# return unless @tmpX != delta.x || @tmpY != delta.y || @tmpPhi != u_phi
		@ctx.clearRect 0, 0, 800, 800
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
				@ctx.beginPath()
				for phi in [truck.U_PHI_MAX[0]..truck.U_PHI_MAX[1]] by 0.05
					# reset to start config
					newConf = conf
					for i in [0..20]
						r = if s < 0 then 93 else 0
						g = if s < 0 then 98 else 200
						b = if s < 0 then 98 else 0
						a = 0.1#1/(1+i*0.4)
						@ctx.strokeStyle = "rgba(#{r}, #{g}, #{b}, #{a})"
						nextMove = truck.legalMoves(newConf, edgeDetection.walls, steps, [s], [phi])
						if nextMove.length > 0
							# if no collision detected move on
							newConf = nextMove[0]
						else
							break
						renderCar @ctx, newConf
				@ctx.stroke()

		# draw current trajectory
		for s in direction
			newConf = conf
			@ctx.beginPath()
			for i in [0..20]
				r = if s < 0 then 255 else 255
				g = if s < 0 then 255 else 255
				b = if s < 0 then 0 else 0
				a = 0.4#1/(1+i*0.4)
				@ctx.strokeStyle = "rgba(#{r}, #{g}, #{b}, #{a})"
				nextMove = truck.legalMoves(newConf, edgeDetection.walls, steps, [s], [newConf.phi])
				if nextMove.length > 0
					# if no collision detected move on
					newConf = nextMove[0]
				else
					break
				renderCar @ctx, newConf
			@ctx.stroke()
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
				start = new Conf center.x, center.y, center.theta, sensorSystem.angle, u_s, u_phi
				goal = new Conf startDrag.x, startDrag.y, rotation, rotation
				path = planner.motion(start, goal, edgeDetection.walls).
				map (e) -> relativeToAbsolute e
				waypoints.init path
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
