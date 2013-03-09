# floor absolute value preserving leading sign: -1.9 => -1; 1.9 => 1
absFloor = (x) ->
	if x < 0 then Math.ceil(x) else Math.floor(x)

manualObstacles = {
	obstacles: []
	ctx: ctxMap
	add: (start, end) ->
		@obstacles.push [start, end]
	draw: () ->
		@ctx.save()
		@ctx.translate center.x, center.y
		@ctx.rotate delta.theta
		@ctx.translate -center.x-delta.x, -center.y-delta.y
		@ctx.beginPath()
		@ctx.strokeStyle = '#333'
		for obs in @obstacles
			@ctx.lineWidth = 5
			@ctx.moveTo obs[0].x, obs[0].y
			@ctx.lineTo obs[1].x, obs[1].y
		@ctx.stroke()
		@ctx.restore()
}

window.map = {
	img: new Image()
	jumpAt: 220
	tileSize: 640
	tmpVert: -1
	tmpHori: -1
	vert: 0
	hori: 0
	dirty: true
	tmpX: 1
	tmpY: 1
	tmpTheta: 0
	loadImage: (cb) ->
			# jump between two 640px 21 zoom images
		vertD = (0.000286*@jumpAt)/@tileSize
		horiD = (0.00043*@jumpAt)/@tileSize
		# flag to check whether the current tile matches the one in the last step
		if @vert != @tmpVert || @hori != @tmpHori
			@tmpVert = @vert
			@tmpHori = @hori
			p = {
				center: [config.lat()-@vert*vertD,config.lon()+@hori*horiD].join()
				zoom: 21
				size: [@tileSize,@tileSize].join('x')
				maptype: 'roadmap'
				sensor: false
				style: 'feature:all|element:labels|visibility:off'
				key: config.googleMaps.key
			}
			@img.onload = cb
			@img.crossOrigin = ''
			@img.src = config.googleMaps.url + '?style=feature:road|visibility:off&' + $.param(p)
		else
			cb()
	drawImage: (deltaX, deltaY, x=0, y=0) ->
		ctxMap.save()
		ctxMap.fillStyle = 'rgb(223,219,212)'
		ctxMap.fillRect x, y, config.canvasWidth, config.canvasHeight
		ctxMap.translate center.x, center.y
		ctxMap.rotate delta.theta
		ctxMap.translate -center.x-deltaX, -center.y-deltaY
		ctxMap.drawImage @img, 0, 0
		# hide text to the bottom right and left (triggers wall detection)
		ctxMap.fillRect 320, 625, @tileSize-320, @tileSize-625
		ctxMap.fillRect 0, 610, 62, @tileSize
		ctxMap.restore()
	draw: ->
		return unless @tmpX != delta.x || @tmpY != delta.y || @tmpTheta != delta.theta
		@tmpX = delta.x
		@tmpY = delta.y
		@tmpTheta = delta.theta
		# on which tile counting from the center 0 0
		@hori = delta.x/@jumpAt
		@vert = delta.y/@jumpAt
		@hori = absFloor @hori
		@vert = absFloor @vert
		@loadImage =>
			# center new tiles
			@drawImage delta.x-@jumpAt*@hori, delta.y-@jumpAt*@vert
			# manualObstacles.draw()
}

app.on 'obstacle.lidar', (e, start, end) ->
	#eventInfo e
	manualObstacles.add start, end
	manualObstacles.draw()
