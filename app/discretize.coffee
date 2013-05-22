# floor absolute value preserving leading sign: -1.9 => -1; 1.9 => 1
absFloor = (x) ->
	if x < 0 then Math.ceil(x) else Math.floor(x)

manualObstacles =
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

window.map =
	ctx: ctxMap
	ctxBuffer: cnvs.create 800, 800
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
			center = [config.lat()-@vert*vertD,config.lon()+@hori*horiD].join()
			@img.onload = cb
			@img.crossOrigin = ''
			# @img.src = '/maps/' + 'style=feature:road|visibility:off&' + $.param(p) + '.png'
			@img.src = '/maps/'+center+'.png'
		else
			cb()
	drawImage: (deltaX, deltaY, x=0, y=0) ->
		@ctxBuffer.save()
		@ctxBuffer.fillStyle = 'rgb(223,219,212)'
		@ctxBuffer.fillRect x, y, config.canvasWidth, config.canvasHeight
		@ctxBuffer.translate center.x, center.y
		@ctxBuffer.rotate delta.theta
		@ctxBuffer.translate ~~(-center.x-deltaX), ~~(-center.y-deltaY)
		@ctxBuffer.drawImage @img, 0, 0
		# hide text to the bottom right and left (triggers wall detection)
		@ctxBuffer.fillRect 320, 625, @tileSize-320, @tileSize-625
		@ctxBuffer.fillRect 0, 610, 62, @tileSize-610
		@ctxBuffer.restore()
		@ctx.drawImage @ctxBuffer.canvas, 0, 0
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
			manualObstacles.draw()

app.on 'obstacle.lidar', (e, start, end) ->
	#eventInfo e
	manualObstacles.add start, end
	manualObstacles.draw()
