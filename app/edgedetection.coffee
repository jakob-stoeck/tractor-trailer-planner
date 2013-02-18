# buildings are 2.5d until [0] is resolved
# [0] http://code.google.com/p/gmaps-api-issues/issues/detail?id=4459

isWebWorker = false
if typeof window == 'undefined'
	isWebWorker = true
	# if file is used as web worker
	self.window = self
	self.ko = { observable: (e) -> e }
	config =
		raytraceAngles: -> ko.observable 200
		wallNumber: -> ko.observable 0
		ed:
			maxDistance: -> ko.observable 60
			maxDistanceToLine: -> ko.observable 4
			minLength: -> ko.observable 3
			minR2: -> ko.observable 0.63
			frequency: -> ko.observable 150
	require = (name) -> importScripts "/build/#{name}.js"
	require 'helper/helpers'
else
	config = window.config

free = [
	# format is 32bit unsigned little-endian
	# (r | g << 8 | b << 16 | a << 24) >>> 0
	# a little bit faster http://jsperf.com/canvas-read-pixel-performance/3
	# '254,254,254' # street
	# '216,212,201' # sidewalk1
	# '208,205,209' # sidewalk2
	# '249,246,239' # sidewalk
	(223 | 219 << 8 | 212 << 16 | 255 << 24) >>> 0 # monsterTrucks
	(201 | 223 << 8 | 175 << 16 | 255 << 24) >>> 0 # grass
	(232 | 221 << 8 | 189 << 16 | 255 << 24) >>> 0 # TUM
	255 # nothing
	0
]

# returns a pointed rectangle
getBorderPoints = (n, width, height) ->
	points = []
	pos = 0
	circumference = 2*(width+height)
	distance = circumference / n
	for i in [0...n]
		if pos < width
			points.push [pos, 0]
		else if pos < width+height
			points.push [width, pos-width]
		else if pos < 2*width+height
			points.push [width-pos+width+height, height]
		else
			points.push [0, height-pos+2*width+height]
		pos += distance
	points

isFree = (x, y, data, width) ->
	offset = width*y+x
	# ctxTruck.fillRect x,y,1,1
	for f in free
		if f == data[offset]
			return true
	return false

bresenhamLine = (x0, y0, x1, y1, callback, data, width) ->
	dx = Math.abs(x1 - x0)
	dy = Math.abs(y1 - y0)
	sx = (if (x0 < x1) then 1 else -1)
	sy = (if (y0 < y1) then 1 else -1)
	err = dx - dy
	loop
		# Do what you need to for this
		success = callback x0, y0, data, width
		# drawPoint [x0, y0]
		if !success or ((x0 is x1) and (y0 is y1))
			return [x0, y0]
		e2 = 2 * err
		if e2 > -dy
			err -= dy
			x0 += sx
		if e2 < dx
			err += dx
			y0 += sy

slope = (p, q) ->
	s = (p[0] - q[0])
	if isNaN(s)
		0
	else
		Number ((p[1] - q[1]) / s).toFixed 2

# euclid w/o sqrt for performance
distance = (p, q) ->
	Math.pow(p[0]-q[0], 2) + Math.pow(p[1]-q[1], 2)

window.nearerThan = (p, q, maxDistance) ->
	distance(p, q) <= maxDistance

# http://trentrichardson.com/2010/04/06/compute-linear-regressions-in-javascript/
window.linearRegression = (points) ->
	x = points.map (e) -> e[0]
	y = points.map (e) -> e[1]
	lr = {}
	n = y.length
	sum_x = 0
	sum_y = 0
	sum_xy = 0
	sum_xx = 0
	sum_yy = 0
	i = 0

	while i < y.length
		sum_x += x[i]
		sum_y += y[i]
		sum_xy += (x[i] * y[i])
		sum_xx += (x[i] * x[i])
		sum_yy += (y[i] * y[i])
		i++

	lr.slope = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)
	lr.intercept = (sum_y - lr.slope * sum_x) / n
	dividend = (n * sum_xy - sum_x * sum_y)
	divisor = Math.sqrt((n * sum_xx - sum_x * sum_x) * (n * sum_yy - sum_y * sum_y))
	if divisor == dividend
		lr.r2 = 1
	else
		lr.r2 = Math.pow(dividend / divisor , 2)
	lr.vertical = isNaN lr.slope
	if lr.vertical
		lr.intercept = x[0]
		lr.slope = 0
	lr

# object with arrays of wall points
raytrace = (imageData, x, y, width, height) ->
	# get nearest pixel on line
	numAngles = config.raytraceAngles()
	maxDistance = Math.pow 50, 2 # our distance does not sqrt
	maxSlopeDiff = 0.1
	points = []
	for p,i in getBorderPoints numAngles, width, height
		# drawPoint p, '#ff0', 10 if i == 0
		newPoint = bresenhamLine x, y, p[0], p[1], isFree, imageData, width
		# skip canvas borders
		continue if newPoint[0] in [p[0], 0] or newPoint[1] in [p[1], 0]
		points.push newPoint
	# drawPoint p, '#ff0', 5 # last point
	points

detectWalls = (points, minLength, maxDistanceToLine, maxDistance) ->
	i = 0
	walls = []
	while i < points.length
		sample = samplePoints points.slice(i), minLength, maxDistance
		return unless sample? # discard remaining too small obstacles
		i += sample.index+sample.size
		wall = [points[i-sample.size], points[i-1]]
		# ctxTruck.moveTo 0, sample.intercept
		# ctxTruck.lineTo wall[1][0], wall[1][1]
		# ctxTruck.stroke()
		# add points which have a small epsilon and are near to the wall end
		while i < points.length
			p = points[i]
			near = nearerThan wall[1], p, maxDistance
			error = distanceToLine p, sample.slope, sample.intercept, sample.vertical
			if near && (error < maxDistanceToLine)
				wall[1] = p
				# drawPoint	wall[1], '#20f6e9', 4
				i++
			else
				i-- if near # next wall may start with previous wall end point
				break
		walls.push wall
	# check whether very last point connects with first wall
	if walls.length > 1
		firstPoint = walls[0][0]
		lastPoint = walls.last()[1]
		near = nearerThan firstPoint, lastPoint, maxDistance
		error = distanceToLine firstPoint, sample.slope, sample.intercept, sample.vertical
		if near && (error < maxDistanceToLine)
			walls[0][0] = walls.pop()[0]
	# walls.forEach (wall) ->
		# drawPoint wall[0], '#f00', 4
		# drawPoint wall[1], '#f00', 4
	config.wallNumber walls.length
	walls

# returns a good line out of n consecutive points which are removed from
# the open points
# returns index where
samplePoints = (points, minLength, maxDistance) ->
	minR2 = config.ed.minR2()
	i = 0
	while i < points.length
		slice = points.slice i, minLength+i++
		continue unless slice.every((e, j, slice) ->
			if j == 0 || nearerThan slice[j-1], e, maxDistance
				true
		)
		lr = linearRegression slice
		if lr.r2 >= minR2
			lr.index = i-1
			lr.size = slice.length
			return lr

# gets nearest point on line and measures distance
window.distanceToLine = (p, slope, intercept, vertical) ->
	# drawPoint p, '#000', 8
	if vertical then [y,x]=p else [x,y]=p
	if slope == 0 then return distance [x,y], [x, intercept]
	a0 = -1/slope
	b0 = y-a0*x
	px = (intercept-b0)/(a0-slope)
	py = ((a0*(intercept-b0)))/(a0-slope) + b0
	# drawPoint [px, py], '#eee', 4
	distance p, [px, py]

minLength = Number config.ed.minLength()
maxDistanceToLine = Math.pow config.ed.maxDistanceToLine(), 2
maxDistance = Math.pow config.ed.maxDistance(), 2 # distance does not sqrt

update = (imageData, cb) ->
	points = raytrace imageData, 400, 400, 800, 800
	walls = detectWalls points, minLength, maxDistanceToLine, maxDistance
	cb walls if walls.length > 0

if isWebWorker
	self.addEventListener 'message', (e) ->
		update e.data.imageData, (walls) ->
			self.postMessage {walls: walls}
	, false
else
	if typeof edgeDetection != 'undefined'
		edgeDetection.walls = walls
