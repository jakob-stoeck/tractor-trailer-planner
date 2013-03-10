# see http://paulbourke.net/geometry/pointlineplane/
# this is a naïve implementation.  should use sweep line algo instead
window.lineSegmentIntersect = (p1, p2, p3, p4) ->
	div = (p4[1]-p3[1]) * (p2[0]-p1[0])-(p4[0]-p3[0]) * (p2[1]-p1[1])
	return false if div == 0
	ua = ((p4[0]-p3[0]) * (p1[1]-p3[1])-(p4[1]-p3[1]) * (p1[0]-p3[0])) / div
	ub = ((p2[0]-p1[0]) * (p1[1]-p3[1])-(p2[1]-p1[1]) * (p1[0]-p3[0])) / div
	(0 <= ua <= 1 && 0 <= ub <= 1)

window.euclid = (p, q) ->
	Math.sqrt(Math.pow(p.x-q.x, 2) + Math.pow(p.y-q.y, 2))

window.PIHALF = Math.PI/2
window.PI2 = Math.PI*2
window.Conf = (x, y, theta, theta1, s, phi) ->
	x: x
	y: y
	theta: theta
	theta1: theta1
	s: s
	phi: phi

window.center = new Conf 400, 400, -PIHALF, -PIHALF

# builds up a lookup table in with this structure
# theta0_start:
# 	x0:
# 		y0:
# 			theta1_goal:
# 				Conf
window.lookupTable =
	table: null
	startConf:
		x: 400
		y: 400
		theta: -PIHALF
		theta1: -PIHALF
	round: (number, power=10, precision=0) ->
		Number (power * Math.round number/power).toFixed precision
	normalizeAngle: (angle) ->
		angle % PI2
	hash: (conf) ->
		x: @round conf.x, 20
		y: @round conf.y, 20
		theta: @round conf.theta, 0.05, 2
		theta1: @round conf.theta1, 0.05, 2
	normalize: (start, goal) ->
		# bring relative goal coordinates in current absolute coordinates
		# which are based on deltas from the last known starting point
		# convert artboard context into map context
		# center on current car
		if typeof goal == 'undefined' then throw new Error 'goal not defined'
		if typeof goal.theta == 'undefined' then return goal
		delta =
			x: @startConf.x-start.x
			y: @startConf.y-start.y
			theta: (@startConf.theta-start.theta)*(-1)
		x = goal.x-@startConf.x
		y = goal.y-@startConf.y
		# rotate around car
		s = Math.sin delta.theta
		c = Math.cos delta.theta
		px = x* c + y*s - delta.x + @startConf.x
		py = x*-s + y*c + delta.y + @startConf.y
		c = new Conf px, py, goal.theta-delta.theta, goal.theta1-delta.theta
		c
	get: (start, goal) ->
		@build() if @table == null
		# normalize goal with the start position, relative to @startConf
		start.theta = @normalizeAngle start.theta
		start.theta1 = @normalizeAngle start.theta1
		goal.theta = @normalizeAngle goal.theta
		goal.theta1 = @normalizeAngle goal.theta1
		startingAngle = @round start.theta1, 0.05, 2
		normGoal = @normalize start, goal
		bucket = @hash normGoal
		if isNaN bucket.theta1
			# happens when no goal angle is specified, take the first available
			# value ignoring angle
			value = @table[startingAngle]?[bucket.x]?[bucket.y]
			if typeof value != 'undefined'
				keys = Object.keys value
				value[keys[0]]
		else
			@table[startingAngle]?[bucket.x]?[bucket.y]?[bucket.theta1]
	draw: (theta) ->
		@build() if @table == null
		ctxTruck.save()
		ctxTruck.clearRect 0,0,800,800
		ctxTruck.beginPath()
		startingAngle = @round @normalizeAngle(theta), 0.05, 2
		for x,rest of @table[startingAngle]
			for y,rest1 of rest
				for theta1,conf of rest1
					renderCar ctxTruck, conf
		ctxTruck.stroke()
		ctxTruck.beginPath()
		ctxTruck.strokeStyle='#0f0'
		renderCar ctxTruck, new Conf 400,400,-PIHALF,startingAngle
		ctxTruck.stroke()
		ctxTruck.restore()
	build: () ->
		# theta is always -pi/2, theta1 varies depending on the starting position
		@table = {}
		maxSteps = 50
		direction = [1, -1]
		# every tractor starting angle between [0,-pi]
		for theta1 in [-3.15...0] by 0.05
			theta1 = Number theta1.toFixed 2
			# step in every direction and many turning rates
			for s in direction
				for phi in [-0.55...0.55] by 0.05
					phi = Number phi.toFixed 2
					# reset to start config
					newConf =
						x: @startConf.x
						y: @startConf.y
						theta: @startConf.theta
						theta1: theta1
					for i in [0..maxSteps]
						nextMove = truck.legalMoves newConf, [], null, [s], [phi]
						if nextMove.length > 0
							# if feasible move detected
							newConf = nextMove[0]
							newConf.step = i+1
						else
							break
						bucket = @hash newConf
						@table[theta1] ? @table[theta1] = {}
						@table[theta1][bucket.x] ? @table[theta1][bucket.x] = {}
						@table[theta1][bucket.x][bucket.y] ? @table[theta1][bucket.x][bucket.y] = {}
						@table[theta1][bucket.x][bucket.y][bucket.theta1] = newConf
		return

window.nearestNumber = (myNumber, numbers) ->
	diff = Infinity
	nearest = null
	for n in numbers
		localDiff = Math.abs myNumber - n
		if localDiff < diff
			diff = localDiff
			nearest = n
	nearest
