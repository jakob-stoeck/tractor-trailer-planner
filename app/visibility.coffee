size = 800
gridMargin = 0
blocks = []
walls = []
g = cnvs.append 'visibility', document.getElementById('container'), size, size
window.visib = g

interpretSvg = (g, path) ->
	i = 0
	while i < path.length
		if path[i] is "M"
			g.moveTo path[i + 1], path[i + 2]
			i += 2
		if path[i] is "L"
			g.lineTo path[i + 1], path[i + 2]
			i += 2
		i++
svgToCoords = (path) ->
	for i in [0...path.length] by 6
		[{ x: path[i + 1], y: path[i + 2] }, { x: path[i + 4], y: path[i + 5] }]
computeVisibleAreaPaths = (center, output) ->
	path1 = []
	path2 = []
	path3 = []
	path4 = []
	i = 0

	while i < output.length
		p1 = output[i]
		p2 = output[i + 1]

		# These are collinear points that Visibility.hx
		# doesn't output properly. The triangle has zero area
		# so we can skip it.
		continue	if isNaN(p1.x) or isNaN(p1.y) or isNaN(p2.x) or isNaN(p2.y)
		path1.push "L", p1.x, p1.y, "L", p2.x, p2.y
		path2.push "M", center.x, center.y, "L", p1.x, p1.y, "M", center.x, center.y, "L", p2.x, p2.y
		path3.push "M", p1.x, p1.y, "L", p2.x, p2.y
		for p in [p1,p2]
			# TODO some lines are not needed because they lay between two others
			inter = intersectWithAxis g, center, {x: p.x, y: p.y}, size
			path4.push "M", p.x, p.y, "L", inter.x, inter.y
		i += 2
	floor: path1
	triangles: path2
	walls: path3
	unknown: path4
drawFloorTriangles = (g, path) ->
	g.save()
	g.strokeStyle = "hsl(80, 30%, 25%)"
	g.beginPath()
	interpretSvg g, path
	g.stroke()
	g.restore()
intersectWithAxis = (g, p1, p2, size) ->
	if p2.x < p1.x # left
		vp3 = {x:0,y:0}
		vp4 = {x:0,y:1}
	else # right
		vp3 = {x:size,y:0}
		vp4 = {x:size,y:1}
	if p2.y < p1.y # top
		hp3 = {x:0,y:0}
		hp4 = {x:1,y:0}
	else # bottom
		hp3 = {x:0,y:size}
		hp4 = {x:1,y:size}
	v = visibility.lineIntersection p1, p2, vp3, vp4
	h = visibility.lineIntersection p1, p2, hp3, hp4
	if 0 <= v.x <= size then v else h
drawUnknownBorders = (g, path) ->
	g.save()
	g.strokeStyle = "hsl(60, 100%, 40%)"
	g.beginPath()
	interpretSvg g, path
	g.stroke()
	g.restore()
drawFloor = (g, path, solidStyle=false) ->
	g.save()
	g.fillStyle = 'hsl(210, 50%, 25%)'
	g.fillRect 0, 0, size, size
	if solidStyle
		g.fillStyle = "hsla(60, 75%, 60%, 0.2)"
	else
		gradient = g.createRadialGradient(
			center.x, center.y, 0,
			center.x, center.y, size * 0.75
		)
		gradient.addColorStop 0.0, "hsla(60, 100%, 75%, 0.6)"
		gradient.addColorStop 0.5, "hsla(60, 50%, 50%, 0.4)"
		gradient.addColorStop 1.0, "hsla(60, 60%, 30%, 0.2)"
		g.fillStyle = gradient
	g.beginPath()
	g.moveTo center.x, center.y
	interpretSvg g, path
	g.lineTo center.x, center.y
	g.fill()
	g.restore()
# Draw the walls lit up by the light
drawWalls = (g, path) ->
  g.save()
  g.strokeStyle = "hsl(60, 100%, 90%)"
  g.lineWidth = 5
  g.beginPath()
  interpretSvg g, path
  g.stroke()
  g.restore()
	# TODO: there's a corner case bug: if a wall is collinear
	# with the player, the wall isn't marked as being visible. An
	# alternative would be to draw all the walls and use the
	# floor area as a mask.
# drawBlocks = (g, blocks) ->
# 	g.beginPath()
# 	for b in blocks
# 		g.rect b.x-b.r, b.y-b.r, b.r*2, b.r*2
# 	g.stroke()
# _needsRedraw = true

visibility = new Visibility()
window.shadows = {
	update: ->
		visibility.loadMap size, gridMargin, [], edgeDetection.walls.map formatWall
		visibility.setLightLocation center.x, center.y
		visibility.sweep Math.PI
		paths = computeVisibleAreaPaths center, visibility.output
		borders = paths.walls
		if (treatUnknownAsBorder?)
			borders = borders.concat paths.unknown
		app.trigger 'visibilityDetected.lidar', [svgToCoords borders]
	draw: ->
		g.clearRect 0,0,size,size
		drawFloor g, paths.floor
		# drawFloorTriangles g, paths.triangles
		drawWalls g, paths.walls
		# drawUnknownBorders g, paths.unknown
}

formatWall = (wall) ->
	return unless wall.length > 0
	{
		p1: {x: wall[0][0], y: wall[0][1]}
		p2: {x: wall[1][0], y: wall[1][1]}
	}
