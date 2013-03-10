window.truck = {
	L: config.truck.tractor.length() * config.scale
	L1: config.truck.trailer.length() * config.scale
	W: config.truck.tractor.width() * config.scale
	U_PHI_MAX: [-config.steer(), config.steer()]
	U_S_MAX: [-config.speed(),0,config.speed()]
	conf: new Conf center.x, center.y, center.theta, center.theta, 0, 0
	dirty: true
	ctx: ctxTruck
	update: ->
		conf = sensorSystem.conf
		@conf.phi = -conf.phi
		@conf.s = conf.s
		return unless sensorSystem.angle != @conf.theta1
		@dirty = true
		@conf.theta1 = sensorSystem.angle
	draw: ->
		return unless @dirty
		@dirty = false
		renderCar3d @ctx, @conf
	step: (x, y, theta, theta1, u_s=1, u_phi=0, runs=1) ->
		while runs-- > 0
			x += u_s * Math.cos theta
			y += u_s * Math.sin theta
			theta += (u_s/@L) * Math.tan u_phi
			theta1 += (u_s/@L1) * Math.sin theta-theta1
		# normalize rotation so that it is always counter-clockwise (could also be
		# clockwise, but not both at the same time)
		theta %= PI2
		theta1 %= PI2
		theta -= PI2 if (theta > 0)
		theta1 -= PI2 if (theta1 > 0)
		x: Math.round x
		y: Math.round y
		theta: theta
		theta1: theta1
		s: u_s
		phi: u_phi
	outlines: (conf) ->
		tractor = rotateRect conf.theta, conf.x, conf.y, @L, @W
		trailer = rotateRect conf.theta1, conf.x, conf.y, -@L1, @W
		trailerArrow = rotateRect conf.theta1, conf.x, conf.y, @L-5, @W
		tractor.concat trailer, trailerArrow
	legalMoves: (conf, borders=[], repeatStep=config.steps(), directions=[config.direction(), -config.direction()], steers=[-config.steer(), 0, config.steer()]) ->
		# step repeat must be  large enough to change x-y-values based on steer
		ret = []
		# move in all six directions, make collision detection and return the neighbors
		for direction in directions
			for steer in steers
				nextConf = @step conf.x, conf.y, conf.theta, conf.theta1, direction, steer, repeatStep
				# FIXME this is not correct. e.g. -5π/4+π is not feasible
				angle = Math.abs(nextConf.theta1-nextConf.theta)
				if angle < PIHALF || angle-PI2 < PIHALF
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
tractor.src = '/images/tractor.png'
trailer = new Image()
trailer.src = '/images/trailer.png'

# to render without drawing side-effects (such as changing the current drawing position), this method should be placed into beginPath()and stroke() calls.  We do not do this here for performant batch drawing
window.renderCar = (ctx, conf) ->
	outlines = truck.outlines conf
	i = 0
	while i < outlines.length-1
		i++ if i == 3 # don’t connect two outlines from different trailers
		ctx.moveTo outlines[i][0], outlines[i][1]
		ctx.lineTo outlines[++i][0], outlines[i][1]
	ctx.moveTo conf.x, conf.y

window.renderCar3d = (ctx, conf) ->
	ctx.clearRect 280, 355, 300, 190
	ctx.save()
	ctx.translate center.x, center.y
	ctx.rotate conf.theta
	ctx.translate -center.x, -center.y
	ctx.drawImage tractor, conf.x-truck.L/2, conf.y-truck.W/2
	ctx.restore()
	ctx.save()
	ctx.translate center.x, center.y
	ctx.rotate conf.theta1
	ctx.translate -center.x, -center.y
	ctx.drawImage trailer, conf.x-truck.L1+truck.L/14, conf.y-truck.W/2
	ctx.restore()

window.renderCar2d = (ctx, conf) ->
	ctx.save()
	ctx.translate center.x, center.y
	ctx.rotate conf.theta
	ctx.translate -center.x, -center.y
	ctx.drawImage tractor, conf.x-truck.L/2, conf.y-truck.W/2
	ctx.restore()
	ctx.save()
	ctx.translate center.x, center.y
	ctx.rotate conf.theta1
	ctx.translate -center.x, -center.y
	ctx.drawImage trailer, conf.x-truck.L1+truck.L/14, conf.y-truck.W/2
	ctx.restore()
