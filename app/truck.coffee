window.truck = {
	L: config.truck.tractor.length() * config.scale
	L1: config.truck.trailer.length() * config.scale
	W: config.truck.tractor.width() * config.scale
	U_PHI_MAX: [-config.steer(), config.steer()]
	U_S_MAX: [-config.speed(),0,config.speed()]
	conf: new Conf center.x, center.y, center.theta, center.theta, 0, 0, center.theta
	dirty: true
	ctx: ctxTruck
	update: ->
		conf = sensorSystem.conf
		@conf.phi = -conf.phi
		@conf.s = conf.s
		return unless sensorSystem.angle != @conf.theta1
		@dirty = true
		@conf.theta1 = sensorSystem.angle
		@conf.theta2 = sensorSystem.angle2
	draw: ->
		return unless @dirty
		@dirty = false
		renderCar3d @ctx, @conf
	step: (x, y, theta, theta1, u_s=1, u_phi=0, runs=1, theta2) ->
		while runs-- > 0 and absDiff(theta, theta1) <= PIHALF
			x += u_s * Math.cos theta
			y += u_s * Math.sin theta
			theta += (u_s/@L) * Math.tan u_phi
			theta1 += (u_s/@L1) * Math.sin theta-theta1
			theta2 += (u_s/@L1) * Math.cos(theta-theta1) * Math.sin(theta1-theta2)
		# normalize rotation so that it is always counter-clockwise (could also be
		# clockwise, but not both at the same time)
		theta %= PI2
		theta -= PI2 if (theta > 0)
		theta1 %= PI2
		theta1 -= PI2 if (theta1 > 0)
		theta2 %= PI2
		theta2 -= PI2 if (theta2 > 0)
		x: Math.round x
		y: Math.round y
		theta: theta
		theta1: theta1
		theta2: theta2
		s: u_s
		phi: u_phi
	outlines: (conf) ->
		tractor = rotateRect conf.theta, conf.x, conf.y, @L, @W
		trailer = rotateRect conf.theta1, conf.x, conf.y, -@L1, @W
		anglePoint = rotateRect conf.theta1, conf.x, conf.y, -@L1, 0
		trailer2 = rotateRect conf.theta2, anglePoint[1][0], anglePoint[1][1], -@L1, @W
		trailerArrow = rotateRect conf.theta1, conf.x, conf.y, @L-5, @W
		tractor.concat trailerArrow, trailer, trailer2
	legalMoves: (conf, borders=[], repeatStep=config.steps(), directions=[config.direction(), -config.direction()], steers=[-config.steer(), 0, config.steer()]) ->
		# step repeat must be  large enough to change x-y-values based on steer
		ret = []
		# move in all six directions, make collision detection and return the neighbors
		for direction in directions
			for steer in steers
				nextConf = @step conf.x, conf.y, conf.theta, conf.theta1, direction, steer, repeatStep, conf.theta2
				# FIXME this is not correct. e.g. -5π/4+π is not feasible
				if absDiff(nextConf.theta, nextConf.theta1) <= PIHALF
					if borders.length > 0
						outlines = @outlines nextConf
					else
						outlines = []
					length = outlines.length-1
					ret.push nextConf if @validMove conf, borders, outlines, length
		ret
	validMove: (conf, borders, outlines, length) ->
		for b in borders
			i = 0
			while i < length
				i++ if i == 3 # outlines from different trailers
				if lineSegmentIntersect outlines[i], outlines[++i], b[0], b[1]
					return false
		return true
}

tractor = new Image()
trailer = new Image()
trailer2 = new Image()
tractor.src = '/images/tractor.png'
trailer.src = '/images/trailer.png'
trailer2.src = '/images/trailer2.png'
tractor.onload = -> truck.dirty = true
trailer.onload = -> truck.dirty = true
trailer2.onload = -> truck.dirty = true

# to render without drawing side-effects (such as changing the current drawing position), this method should be placed into beginPath()and stroke() calls.  We do not do this here for performant batch drawing
window.renderCar = (ctx, conf) ->
	outlines = truck.outlines conf
	i = 0
	while i < outlines.length-1
		i++ if i==3 or i==11 # don’t connect two outlines from different trailers
		ctx.moveTo outlines[i][0], outlines[i][1]
		ctx.lineTo outlines[++i][0], outlines[i][1]
	ctx.moveTo conf.x, conf.y

window.renderCar3d = (ctx, conf) ->
	pos =
		x: conf.x-center.x
		y: conf.y-center.y
	ctx.clearRect 120, 300, 540, 330
	ctx.save()
	ctx.translate center.x, center.y
	ctx.save()
	ctx.rotate conf.theta
	ctx.drawImage tractor, pos.x-truck.L/2, pos.y-truck.W/2
	ctx.restore()
	ctx.save()
	ctx.rotate conf.theta1
	ctx.drawImage trailer, pos.x-truck.L1+truck.L/14, pos.y-truck.W/2
	ctx.translate -truck.L1, 0
	ctx.rotate -conf.theta1+conf.theta2
	ctx.fillRect -truck.L1, 0, truck.L1, 2
	ctx.drawImage trailer2, -truck.L1, -truck.W/2
	ctx.restore()
	ctx.restore()
