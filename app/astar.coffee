## Def Planner, Init Planner, GUI
class AStarPlanner
	constructor: () ->
		@graph = new Graph cnvs.mkgraph config.canvasWidth, config.canvasHeight
		@reset false
	reset: (resetGraph=true) ->
		@start = @getConf 400,400
		@start.data = {
			x: 400
			y: 400
			theta: -PIHALF
			theta1: -PIHALF
			xD: 0
			yD: 0
			thetaD: 0
			theta1D: 0
			r: 0
			inflections: 0
		}
		if (@path? and @path.length > 1)
			last = @path.slice(-1)[0].currentData
			@start.data.theta1 = last.theta1# - (last.theta + PIHALF)
		@goal = @getConf 400,400
	getConf: (x, y) ->
		@graph.nodes[x][y]
	setGoal: (pos=null) ->
		if (pos == null) then pos = @adjustGoal()
		if (pos != null)
			@goal = $.extend {}, @getConf pos.x, pos.y
			@goal.data = $.extend @goal.pos, {theta: -PIHALF, theta1: -PIHALF}
	adjustGoal: () ->
		# collision detection with borders and move goal if too off
		return null
	getGoal: ->
		pos = @path.slice(-1)[0]
		@getConf pos.x, pos.y
	distance: (pos, end) ->
		dist = euclid pos, end
		# rotDist = Math.abs(pos.theta1 - end.theta1)
		# if (rotDist > 0.5) then rotation = 1 else rotation = 0
		dist# + rotation
	deviate: (conf) ->
		for p in @path
			p.currentData.x += conf.x
			p.currentData.y += conf.y
			p.currentData.theta += conf.theta
			p.currentData.theta1 += conf.theta
	motion: () ->
		# start in the middle
		path = astar.search @graph.nodes, @start, @goal, @borders, @distance
		if path.length < 2
			$(ctxTruck.canvas).jiggle()
		else
			@path = path
		return path

planner = -> new AStarPlanner()
window.AStarPlanner = planner

# overwrite default astar neighbors function
astar.neighbors = (grid, node, borders) ->
	if isNaN node.data.x then throw 'something’s fishy'
	configs = truck.legalMoves node.data, borders, Math.max node.g/5, 1
	# ctxMap.rect node.pos.x, node.pos.y, 2, 2
	ret = []
	for c in configs
		coords = { x: parseInt(c.x, 10), y: parseInt(c.y, 10) }
		if grid[coords.x] && grid[coords.x][coords.y]
			grid[coords.x][coords.y].currentData = c
			ret.push grid[coords.x][coords.y]
		# else
		# 	console.warn "outside of grid: #{coords.x}, #{coords.y}"
	ret
