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
	setBorders: (borders) ->
		@borders = borders
	rotationalDistance: (q,v) -> 0
	nearestVertex: (q,G) ->
	randConf: () ->
	newConf: (qNear, qRand, deltaQ) -> # moves into direction of qRand by deltaQ

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
				r = @rotationalDistance q, v
			else if d_i == d
				r_i = @rotationalDistance q, v
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
	rotationalDistance: (q, v) ->
		rotational = Math.abs(q.theta-v.theta)/Math.PI
		rotational2 = Math.abs(q.theta1-v.theta1)/Math.PI
		dist = rotational + rotational2
		dist
	draw: (q) ->
		m_canvas = document.createElement 'canvas'
		m_canvas.width = 800
		m_canvas.height = 800
		m_ctx = m_canvas.getContext '2d'
		renderCar m_ctx, new Conf q.x, q.y, q.theta, q.theta1

grow = (G, deltaQ, qGoal, growRandom, useActionPath=true) ->
	qRand = if growRandom then planner.randConf() else qGoal
	iNear = planner.nearestVertex qRand, G
	qNear = G.V[iNear]
	# check for trivial path first
	path = []
	if useActionPath
		path = planner.actionPath qNear, qGoal, planner.borders
	if path.length > 0
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
	qNear

window.equals = (q0, q1, translationalDistance=0, rotationalDistance=0) ->
	dist = planner.distance(q0, q1)
	if q0.theta? and q0.theta1? and q1.theta? and q1.theta1?
		rot = planner.rotationalDistance(q0, q1)
	else
		# rotation is undefined
		rot = 0
	if dist <= translationalDistance && rot <= rotationalDistance
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
		if equals qNew, @goal, rrtConfig.translationalDistance, rrtConfig.rotationalDistance
			# found path without the need to concatenate the second one
			found = true
			unidirectional = true
			break
		# connecting the two branches is not supported.  the second branch is only
		# used, when no unidirectional way is found
		if equals qNew, qNewR, rrtConfig.translationalDistance, rrtConfig.rotationalDistance
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

# todo
# searchAngles = [truck.U_PHI_MAX[0]..truck.U_PHI_MAX[1]] by accuracy
# orderByNearestAngle = (phi) ->
# 	for angle, i in searchAngles
# 		if phi >= angle then break
# 	# i now is the index of the nearest angle, interweave left and right


# trivial path search
window.bfs = (start, goal, translationalDistance=rrtConfig.translationalDistance*10, rotationalDistance=rrtConfig.rotationalDistance*2) ->
	rotDist = Infinity
	startpoints = []
	steps = 20
	i = 0
	j = 0
	best = null
	accuracy = 0.01
	lengthOfPath = 40
	maxGrowth = lengthOfPath * steps * Math.abs(truck.U_PHI_MAX[1]-truck.U_PHI_MAX[0])/accuracy
	# from start in all possible directions
	# preferring angles near to the current on
	searchAngles = []
	for angle in [truck.U_PHI_MAX[0]..truck.U_PHI_MAX[1]] by accuracy
		searchAngles.push angle
	# for angle in [start.phi..truck.U_PHI_MAX[0]] by -accuracy
		# searchAngles.push angle
	# for angle in [start.phi..truck.U_PHI_MAX[1]] by accuracy
		# searchAngles.push angle
	for s in [1,-1]
		for phi in searchAngles
			startpoints.push
				x: start.x
				y: start.y
				theta: start.theta
				theta1: start.theta1
				s: s
				phi: phi
	while i < startpoints.length
		if i > maxGrowth
			console.info i, 'nodes reached'
			break
		s = startpoints[i]
		# grow chosen configuration
		next = truck.legalMoves(s, planner.borders, steps, [s.s], [s.phi])
		if next.length > 0
			conf = next[0]
			# memorize best config so far
			if equals conf, goal, translationalDistance, rotationalDistance
				best = conf
				# exits on first best, probably not optimal
				break
			startpoints.push conf
		i++
	if best
		conf =
			x: start.x
			y: start.y
			theta: start.theta
			theta1: start.theta1
			s: best.s
			phi: best.phi
		path = []
		path.push conf
		for i in [0..100]
			conf = truck.legalMoves(conf, planner.borders, steps, [conf.s], [conf.phi])[0]
			if conf
				path.push conf
				break if equals conf, goal, translationalDistance, rotationalDistance
			else
				break
		console.info 'something found!'
		return path.reverse()
	return null

rrt = (K, deltaQ, goalBias) ->
	G = new Graph()
	G.addVertex @start
	path = []
	k = 0
	# ctxTruck.beginPath()
	while k < K
		qNew = grow G, deltaQ, @goal, k%goalBias
		# renderCar ctxTruck, qNew
		if equals qNew, @goal, rrtConfig.translationalDistance, rrtConfig.rotationalDistance
			path = G.traverseUp().reverse()
			break
		k++
	# ctxTruck.stroke()
	path

window.rrtConfig = {
	deltaQ: window.config.steps() # how far to move with each step
	K: window.config.searchMax() # number of steps
	bigIsGreedy: true
	collisionDetectionTries: 1
	goalBias: 10 # ever n-th time use goal as qRand;
	rotationalDistance: 0.5
	showAllPaths: true
	showCollisionDetection: true
	showTruckPosition: true
	stopWhenFound: true
	translationalDistance: 10000
	rounds: 20 # optimum planning rounds to search to compare paths
	maxRounds: 10 # if no path is found stop after n rounds
	bidirectional: window.config.advanced()
	tryTrivial: true
}
# ko.applyBindings(rrtConfig)

window.planner = new Nonholomonic if rrtConfig.bidirectional then rrtBalancedBidirectional else rrt

# TODO
# max inflections hinzufügen
# use actual starting point √
# make goal angle choosable √
# Point Flooding bei schwer zugänglichen Goals
# Knoten flaggen -> Brücke
# Trailer Formel Doppel-Integral?

# Collision detection
# Karte bauen, Use Case realistisch, mit dm
# Smooth Paths

# Ziel ist ungenau definiert, +- ein Meter macht nichts, bi-direktional fängt aber an genauem qGoal an. Vereinbar?
# Odometrie nehmen, Karte bleibt stehen
# Parkgeschwindigkeit: Wie viel Drift gibt es, LKW, Actros
# 0.5s Geschwindigkeitsvektor

# Marcus und Chao Audi, Roboterplanung

# TODO
# bfs should run in O(1)
