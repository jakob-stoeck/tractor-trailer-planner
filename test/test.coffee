describe "Truck", ->
	describe "step()", ->
		it "should steer continously", ->
			steer = PIHALF-0.1
			direction = 1
			ret = {
				x: 0
				y: 0
				theta: 0
				theta1: 0
			}
			for i in [0...3]
				ret = truck.step ret.x, ret.y, ret.theta, ret.theta1, direction, steer
		return
		it "should return coordinates", ->
			ret = truck.step 0, 0, 0, 0, 1, 0, 1
			expect(ret.x).equal 1
			expect(ret.y).equal 0

		it "should repeat as defined", ->
			ret = truck.step 0, 0, 0, 0, 1, 0, 5
			expect(ret.x).equal 5
			expect(ret.y).equal 0

		it "should change direction with enough steps", ->
			# without repeats theta-change is not taken into account for x-y-change
			ret = truck.step 0, 0, 0, 0, 1, PIHALF-0.1, 5
			expect(ret.x).gt 4
			expect(ret.y).gt 1

	describe "outline()", ->
		it "should return all tractor, trailer sides", ->
			o = truck.outlines new Conf 0, 0, 0, 0
			expect(o).length 4+4+4 # tractor, trailer, nose

	describe "legalMoves", ->
		it "should move in all directions without walls", ->
			conf = new Conf 10, 10, 0, 0
			legal = truck.legalMoves conf
			expect(legal).length 6
		it "should collide with walls", ->
			conf = new Conf 40, 40, 0, 0
			frontOfTruck = conf.x+1+truck.L
			borders = [
				[[frontOfTruck, 10], [frontOfTruck, 60]]
			]
			legal = truck.legalMoves conf, borders, 1
			expect(legal).length 3

describe "Computer Graphics", ->
	describe "lineSegmentIntersect()", ->
		it "should detect intersects", ->
			p = lineSegmentIntersect [2, 0], [2, 4], [0, 2], [4, 2]
			expect(p).true
		it 'should detect intersects with outlines', ->
			outlines = truck.outlines new Conf 15, 0, 0, 0
			b = [
				[20, 0], [20, 20]
			]
			i = 0
			collides = false
			while i < 7
				i++ if i == 3 # don’t connect two outlines from different trailers
				if lineSegmentIntersect outlines[i], outlines[++i], b[0], b[1]
					collides = true
			expect(collides).true

		it "should react on intersects of the segment", ->
			p = lineSegmentIntersect [2, 0], [2, 4], [0, 5], [4, 5]
			expect(p).false

	describe "mkgraphfromcanvas()", ->
		it "should output a discretized canvas image array", ->
			c = document.createElement("canvas")
			c.width = 2
			c.height = 1
			d = c.discretize 2
			expect(d[0]).equal 0
			expect(d[1]).equal 0

	describe "multidimarray()", ->
		it "should output an empty multi-dimensional array of the specified size", ->
			expect(cnvs.mkgraph(2, 2)).eql [[0, 0], [0, 0]]
			expect(cnvs.mkgraph(4, 1)).eql [[0], [0], [0], [0]]

	describe 'linearRegression()', ->
		it 'should recognize slope, intercept and r^2', ->
			f = (x) -> 2*x + 3
			l = linearRegression [2,3,4].map (e) -> [e, f(e)]
			expect(l.slope).equal 2
			expect(l.intercept).equal 3
			expect(l.r2).equal 1
		it 'should recognize x-axis', ->
			points = [2,3,4].map (e) -> [e, 0]
			l = linearRegression points
			expect(l.slope).equal 0
			expect(l.intercept).equal 0
			expect(l.r2).equal 1
		it 'should recognize horizontals', ->
			points = [2,3,4].map (e) -> [e, 1]
			l = linearRegression points
			expect(l.slope).equal 0
			expect(l.intercept).equal 1
			expect(l.r2).equal 1
		it 'should recognize verticals', ->
			xIntercept = 1
			points = [2,3,4].map (e) -> [xIntercept, e]
			l = linearRegression points
			expect(l.slope).equal 0
			expect(l.intercept).equal xIntercept
			expect(l.r2).equal 1
	describe 'nearerThan()', ->
		it 'should measure right', ->
			expect(nearerThan [0,0], [0,10], 100).true
			expect(nearerThan [0,0], [0,10], 99).false
			expect(nearerThan [10,0], [0,0], 100).true
			expect(nearerThan [10,0], [0,0], 99).false
			expect(nearerThan [117,604], [260,495], 60).false
	describe 'distanceToLine()', ->
		it 'should return perpendicular distance for a point on the line', ->
			p = [1,2]
			slope = 2
			intercept = 0
			d = distanceToLine p, slope, intercept
			expect(d).equal 0
		it 'should return perpendicular distance for a point off the line', ->
			p = [1,2]
			slope = 1
			intercept = 0
			d = distanceToLine p, slope, intercept
			expect(d).equal 0.5
		it 'should return perpendicular distance for a vertical', ->
			p = [640,543]
			slope = 0
			intercept = 640
			d = distanceToLine p, slope, intercept, true
			expect(d).equal 0
		it 'should return perpendicular distance for a vertical', ->
			p = [3,1]
			slope = 0
			intercept = 1
			d = distanceToLine p, slope, intercept, true
			expect(d).equal 4
		it 'should return perpendicular distance for a horizontal', ->
			p = [1,2]
			slope = 0
			intercept = 0
			d = distanceToLine p, slope, intercept
			expect(d).equal 4
			p = [1,3]
			intercept = 1
			d = distanceToLine p, slope, intercept
			expect(d).equal 4
describe 'Planner', ->
	describe 'equals', ->
		it 'should see the same nodes as equal', ->
			p1 = new Conf 400, 400, -PIHALF, -PIHALF
			p2 = new Conf 400, 400, -PIHALF, -PIHALF
			expect(equals p1, p2).true
		it 'should see different translational nodes as not equal', ->
			p1 = new Conf 400, 400, -PIHALF, -PIHALF
			p2 = new Conf 400, 401, -PIHALF, -PIHALF
			expect(equals p1, p2).false
		it 'should see different rotational nodes as not equal', ->
			p1 = new Conf 400, 400, -PIHALF, -PIHALF
			p2 = new Conf 400, 400, -PIHALF+0.01, -PIHALF
			expect(equals p1, p2).false
		it 'should support nearly equals', ->
			p1 = new Conf 400, 400, -PIHALF, -PIHALF
			p2 = new Conf 400+30, 400-10, -PIHALF+0.2, -PIHALF-0.2
			expect(equals p1, p2, 1600, 0.2).true
		it 'should see nodes as equal were information is missing', ->
			p1 = new Conf 400, 400, -PIHALF, -PIHALF
			p2 = new Conf 400, 400
			expect(equals p1, p2).true
	describe 'lookupTable', ->
		it 'should round correctly', ->
			expect(lookupTable.round 10, 10).equal 10
			expect(lookupTable.round 12, 10).equal 10
			expect(lookupTable.round 19, 10).equal 20
			expect(lookupTable.round 245, 10).equal 250
			expect(lookupTable.round 245, 100).equal 200
		it 'should hash correctly', ->
			hash = lookupTable.hash new Conf 400, 400, -PIHALF, -PIHALF
			expect(hash).eql {
				x: 400
				y: 400
				theta: -1.55
				theta1: -1.55
			}
		it 'should build', ->
			expect(lookupTable.table).null
			lookupTable.build()
			expect(Object.keys lookupTable.table).length 64
		it 'should be correct', ->
			steps = 10
			goal = new Conf 400, 200, -1.55, -1.55
			goalGet = lookupTable.get lookupTable.startConf, goal
			goalDirect = lookupTable.table[-1.55][400][200][-1.55]
			expect(equals goalGet, goalDirect).true
			expect(goalGet.step).equal steps
			lastConf = lookupTable.startConf
			for i in [0...steps]
				nextMove = truck.legalMoves lastConf, [], null, [goalGet.s], [goalGet.phi]
				if nextMove.length > 0 then lastConf = nextMove[0]
			# small differences are due to the bucketing of start theta1 angles
			expect(equals goalGet, lastConf, 100, 0.05).true
		it 'should normalize rotations out of [0,-pi]', ->
			goal = new Conf 400, 200, -1.55, -1.55
			goal1 = new Conf 400, 200, -1.55-2*Math.PI, -1.55-2*Math.PI
			goalGet = lookupTable.get lookupTable.startConf, goal
			goalGet1 = lookupTable.get lookupTable.startConf, goal1
			expect(goalGet).eql goalGet1
		it 'should lookup straight correctly', ->
			newPos = new Conf 400, 200, -PIHALF, -PIHALF
			straightSteps = lookupTable.get center, newPos
			expect([
				straightSteps.x
				straightSteps.y
				straightSteps.step
				Number straightSteps.theta.toFixed 2
				Number straightSteps.theta1.toFixed 2
				]).eql [
					newPos.x
					newPos.y
					10
					-1.57
					-1.57
				]
		it 'should lookup straight correctly when theta1 differs', ->
			 start = new Conf 400, 400, -PIHALF, -0.5
			 goal = new Conf 400, 200
			 found = lookupTable.get start, goal
			 # theta1 will not be already at -pi/2 again, but theta must be
			 expect([found.x, found.y, Number found.theta.toFixed 2]).eql [goal.x, goal.y, -PIHALF.toFixed 2]
		it 'should give back solutions when no end rotation is chosen', ->
			goal = new Conf 400, 200 # vertical movement
			found = lookupTable.get center, goal
			expect([found.x, found.y]).eql [goal.x, goal.y]
		it 'should give back no solution if move impossible', ->
			goal = new Conf 450, 400 # horizontal movement
			found = lookupTable.get center, goal
			expect(found).empty
		it 'should normalize the goal position with y-deviation', ->
			# found goal in lookup table is nearer because the start position is
			# positively deviated from it's y axis center
			goal = new Conf 400, 300, -PIHALF, -PIHALF
			start = new Conf 400, 350, -PIHALF, -PIHALF
			newGoal = lookupTable.normalize start, goal
			expect(newGoal).eql new Conf 400, goal.y+50, -PIHALF, -PIHALF
		it 'should normalize the goal position with x-deviation', ->
			xDev = 50
			goal = new Conf 400, 300, -PIHALF, -PIHALF
			start = new Conf 300+xDev, 400, -PIHALF, -PIHALF
			newGoal = lookupTable.normalize start, goal
			expect(newGoal).eql new Conf goal.x-xDev, 300, -PIHALF, -PIHALF
		it 'should normalize the goal position with theta-deviation', ->
			goal = new Conf 400, 300, -PIHALF, -PIHALF
			start = new Conf 400, 400, 0, -PIHALF
			newGoal = lookupTable.normalize start, goal
			expect(newGoal).eql new Conf goal.y, goal.x, -PIHALF+goal.theta1, -PIHALF+goal.theta1

	describe 'actionPath()', ->
		it 'should find straight action paths', ->
			goal = new Conf 400, 300, -PIHALF, -PIHALF
			start = new Conf 400, 400, -PIHALF, -PIHALF
			path = planner.actionPath start, goal
			expect(path.length).gt 0
			pathGoal = path.last()
			expect([pathGoal.x, pathGoal.y]).eql [goal.x, goal.y]
		it 'should find straight action paths with different start angle', ->
			goal = new Conf 400, 200
			start = new Conf 400, 400, -PIHALF, -0.5
			path = planner.actionPath start, goal
			expect(path.length).gt 0
			pathGoal = path.last()
			expect([pathGoal.x, pathGoal.y]).eql [goal.x, goal.y]
		it 'should find straight action paths with different start position', ->
			goal = new Conf 400, 200, -PIHALF, -PIHALF
			start = new Conf 400, 350, -PIHALF, -PIHALF
			path = planner.actionPath start, goal
			expect(path.length).gt 0
			pathGoal = path.last()
			expect([pathGoal.x, pathGoal.y]).eql [goal.x, goal.y+10]
	describe 'rrt', ->
		it 'should use an action path when feasible', ->
			goal = new Conf 400, 300, -PIHALF, -PIHALF
			start = new Conf 400, 400, -PIHALF, -PIHALF
			actionPath = planner.actionPath start, goal
			rrtPath = planner.motion start, goal
			console.info rrtPath, actionPath
			# expect(rrtPath).length 6
			expect(rrtPath).eql actionPath
		# it 'should find goals where action paths are not feasible', ->
		# 	goal = new Conf 500, 200, 0, 0
		# 	start = new Conf 400, 400, -PIHALF, -PIHALF
		# 	rrtPath = planner.motion start, goal
		# 	expect(rrtPath.length).gt 0
		# 	last = rrtPath.last()
		# 	same = equals goal, last, rrtConfig.translationalDistance, rrtConfig.rotationalDistance
		# 	# FIXME very strange, why is the goal sometimes only near the real goal?
		# 	# it should always be equal
		# 	expect(same).true
