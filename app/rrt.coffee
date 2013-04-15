class Graph
	constructor: () ->
		@V=[]
		@E=[]
	addVertex: (q) ->
		i = (@V.push q)-1
		i
	size: ->
		j = @E.length-1
		e = []
		tail = @V.length-1
		length = 0
		while j >= 0
			# traversing grid
			if @E[j][1] == tail
				length++
				tail = @E[j][0]
			j--
		length
	addEdge: (i, j) ->
		@E.push [i,j]
	traverseUp: (reverse=false) ->
		# edges are saved as vector indexes of [pre,post]
		j = @E.length-1
		path = []
		# since we stop search on the first result, the last vertex is the tail of the path FIXME: why?
		# path.push @V[@V.length-1]
		tail = @V.length-1
		# search for every parent whole grid
		while j >= 0
			# traversing grid
			if @E[j][1] == tail
				# FIXME there is a mismatch between left and right in some component
				@V[@E[j][1]].phi *= -1
				if reverse
					# bi-directional tree, second one drives backwards
					@V[@E[j][1]].s *= -1
				path.push @V[@E[j][1]]
				tail = @E[j][0]
			j--
		if tail != 0
			console.error "tail is #{tail}, something went wrong"
		path

class Planner
	constructor: (sampling) ->
		@sampling = sampling
		@start = new Conf 400,400,-PIHALF,-PIHALF
		@goal = new Conf 400,400,-PIHALF,-PIHALF
		@borders = []
	distance: (q,v) ->
	setGoal: (conf) ->
	setBorders: (borders) -> @borders = borders
	distRot: (q,v) -> 0
	nearestVertex: (q,G) ->
	randConf: () ->
	newConf: (qNear, qRand, deltaQ) -> # moves into direction of qRand by deltaQ
	beforeSearch: () ->
	afterStep: (step, qNear, qRand) ->
	afterSearch: (qGoal) ->

class Holonomic extends Planner
	# two-dimensional euclid
	setStart: (conf) ->
		@start = conf
	setStartAngle: (angle) ->
		@start.theta1 = angle
	setGoal: (conf) ->
		@goal = new Conf conf.x, conf.y, conf.theta, conf.theta1
	distance: (q, v) ->
		Math.pow(q.x-v.x, 2) + Math.pow(q.y-v.y, 2)
	nearestVertex: (q, G) ->
		d = Number.MAX_VALUE
		r = Number.MAX_VALUE
		for v,i in G.V
			d_i = @distance q, v
			if d_i < d
				vNear = i
				d = d_i
				r = @distRot q, v
			else if d_i == d
				r_i = @distRot q, v
				if r_i < r
					vNear = i
		vNear
	randConf: () ->
		x: getRandomArbitrary @start.x-400, @start.x+400
		y: getRandomArbitrary @start.y-400, @start.y+400
	newConf: (qNear, qRand, deltaQ) ->
		dRand = @distance qNear, qRand
		if dRand > deltaQ
			k = deltaQ/dRand
			qRand = (Math.floor(qNear[i] + k * (qRand[i]-qNear[i])) for i in [0,1])
	draw: (q) ->
		ctx.rect q.x-2, q.y-2, 4, 4
	motion: (start, goal, borders=[]) ->
		@borders = borders
		@goal = goal
		@start = start
		path = []
		dist = Infinity
		found = 0
		# loop path finding and take the best path
		for r in [0...rrtConfig.maxRounds]
			pathFound = false
			newPath = @sampling rrtConfig.K, rrtConfig.deltaQ, rrtConfig.goalBias
			if newPath.length > 0
				pathFound = true
				newDist = @distance newPath.last(), goal
			# prefer path if smaller and nearer to the goal
			if (pathFound && newPath.length <= path.length && newDist <= dist) || path.length == 0
				dist = newDist
				path = newPath
				if ++found == rrtConfig.rounds
					# minimum amount of paths found
					break
		path
	actionPath: (start, goal, borders=[]) ->
		found = lookupTable.get start, goal
		path = []
		if found
			# the found node is normalized from the lookup table.  to get to the
			# real goal and to check for collisions we repeat the steering movements
			# like saved in the lookup table.
			path.push start
			# generate path from start to goal
			for i in [0...found.step]
				nextMove = truck.legalMoves path.last(), borders, null, [found.s], [found.phi]
				if nextMove.length > 0
					path.push nextMove[0]
				else
					# actionPath collides with a border
					return []
		path

class Nonholomonic extends Holonomic
	distRot: (q, v) ->
		rotational = Math.abs(q.theta-v.theta)/Math.PI
		rotational2 = Math.abs(q.theta1-v.theta1)/Math.PI
		dist = rotational + rotational2
		dist
	draw: (q) ->
		m_canvas = document.createElement 'canvas'
		m_canvas.width = 800
		m_canvas.height = 800
		m_ctx = m_canvas.getContext '2d'
		renderCar m_ctx, new Conf q.x, q.y, q.theta, q.theta1, q.theta2

grow = (G, deltaQ, qGoal, growRandom, useActionPath=true) ->
	qRand = if growRandom then planner.randConf() else qGoal
	iNear = planner.nearestVertex qRand, G
	qNear = G.V[iNear]
	# check for trivial path first
	path = []
	if useActionPath
		path = planner.actionPath qNear, qGoal, planner.borders
	if path.length > 0 && equals path.last(), qGoal, rrtConfig.distTrans, rrtConfig.distRot
		# action path to goal exists
		vertex1 = iNear
		qNear = path.last()
		for q in path
			vertex2 = G.addVertex q
			G.addEdge vertex1, vertex2
			vertex1 = vertex2
		# add path to graph
	else
		# grow one step
		qNews = truck.legalMoves qNear, planner.borders
		for q in qNews
			G.addEdge iNear, G.addVertex q
	planner.afterStep qNear, qRand, path
	qNear

window.equals = (q0, q1, distTrans=0, distRot=0) ->
	dist = planner.distance q0, q1
	if q0.theta? && q0.theta1? && q1.theta? && q1.theta1?
		rot = planner.distRot q0, q1
	else
		# rotation is undefined
		rot = 0
	if dist <= distTrans && rot <= distRot
		true
	else
		false

getPercent = (x, max) -> Math.floor x*100/max

rrtBalancedBidirectional = (K, deltaQ, goalBias) ->
	G = new Graph()
	G.addVertex @start
	H = new Graph()
	H.addVertex @goal
	k = 0
	path = []
	found = false
	unidirectional = false
	while k < K
		target = if k%goalBias then null else @goal
		qNew = grow G, deltaQ, @goal, k%goalBias
		qNewR = grow H, deltaQ, qNew, 0, false
		if equals qNew, @goal, rrtConfig.distTrans, rrtConfig.distRot
			# found path without the need to concatenate the second one
			found = true
			unidirectional = true
			break
		# connecting the two branches is not supported.  the second branch is only
		# used, when no unidirectional way is found
		if equals qNew, qNewR, rrtConfig.distTrans, rrtConfig.distRot
			found = true
			break
		# balance
		# if @bigIsGreedy && (H.E.length < G.E.length)
		# 	[G,H] = [H,G]
		k++
	# from goal to intercept point

	if found
		one = H.traverseUp(true).reverse()
		# from intercept point to start
		two = G.traverseUp()
		# drawPath one, color
		# drawPath two, '#0f0'
		if unidirectional
			path = two.reverse()
		else
			path = one.concat(two).reverse()
	path

drawPath = (path, color) ->
	ctx = ctxPath
	ctx.save()
	ctx.strokeStyle = color
	ctx.lineWidth = 5
	to = path.length-1
	from = 0
	ctx.beginPath()
	ctx.moveTo path[from].x, path[from].y
	i = from
	if (to - from > 0)
		while i < to
			curr = path[i]
			ctx.lineTo curr.x, curr.y
			i++
	ctx.stroke()
	ctx.restore()

rrt = (K, deltaQ, goalBias) ->
	G = new Graph()
	G.addVertex @start
	path = []
	k = 0
	@beforeSearch()
	while k < K
		qNew = grow G, deltaQ, @goal, k%goalBias
		if equals qNew, @goal, rrtConfig.distTrans, rrtConfig.distRot
			path = G.traverseUp().reverse()
			break
		k++
	@afterSearch @goal
	path

rrtConfig = {
	bidirectional: window.config.advanced()
	bigIsGreedy: true
	collisionDetectionTries: 1
	deltaQ: window.config.steps() # how far to move with each step
	distRot: 0.5
	distTrans: 1000
	goalBias: 10 # ever n-th time use goal as qRand;
	K: window.config.searchMax() # number of steps
	maxRounds: 1 # if no path is found stop after n rounds
	rounds: 20 # optimum planning rounds to search to compare paths
	showAllPaths: true
	showCollisionDetection: true
	showTruckPosition: false
	stopWhenFound: true
	tryTrivial: true
}
# ko.applyBindings(rrtConfig)

window.planner = new Nonholomonic rrt

rectCenter = (ctx,x,y,size) ->
	ctx.rect x-size/2, y-size/2, size, size

if rrtConfig.showTruckPosition
	planner.beforeSearch = ->
		ctxTruck.clearRect 0,0,800,800
		ctxTruck.beginPath()
		ctxTruck.fillStyle = '#0f0'
	planner.afterStep = (qNear, qRand, path) ->
		# growth step
		# found with an action path
		ctxTruck.strokeStyle = if path.length > 0 then '#f00' else '#000'
		ctxTruck.beginPath()
		renderCar ctxTruck, path[0] if path.length > 0
		renderCar ctxTruck, qNear
		ctxTruck.stroke()
		# intermediary goal
		ctxPath.clearRect 0,0,800,800
		rectCenter ctxPath, qRand.x, qRand.y, 15
		ctxPath.fill()
		debugger
	planner.afterSearch = (qGoal) ->
		ctxTruck.beginPath()
		ctxTruck.strokeStyle = '#00f'
		renderCar ctxTruck, qGoal
		console.info 'goal', @goal
		ctxTruck.stroke()
