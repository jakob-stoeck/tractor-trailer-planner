Array::last = -> this.slice(-1)[0]

window.get32BitImageData = (ctx, width=800, height=800) ->
	return new Uint32Array ctx.getImageData(0, 0, width, height).data.buffer

window.clone = (obj) ->
  return obj if null is obj or "object" isnt typeof obj
  copy = obj.constructor()
  for attr of obj
    copy[attr] = obj[attr] if obj.hasOwnProperty(attr)
  copy

window.drawPoint = (p, color, size=1, ctx=ctxTruck) ->
	if color then ctx.fillStyle = color
	offset = if size > 1 then size/2 else 0
	ctx.fillRect p[0]-offset, p[1]-offset, size, size
	if color then ctx.fillStyle = '#000'

window.sleep = (ms) ->
	ms += new Date().getTime()
	while (new Date() < ms)
		null

window.roundNumber = (num, dec) ->
	Math.round(num * Math.pow 10, dec) / Math.pow 10, dec

window.multiDimArray = (cols, rows) ->
	array = []
	for r in [0...rows]
		array[r] = []
		for c in [0...cols]
			array[r][c] = 0
	array

window.pad = (number, length) ->
  (if (number + "").length >= length then number + "" else pad("0" + number, length))

window.getRandomInt = (min, max) ->
	Math.floor(Math.random() * (max-min+1)) + min

window.getRandomArbitrary = (min, max) ->
	Math.random() * (max-min) + min

window.matrix = {
	multiply: (A, B) ->
		[
			A[0]*B[0] + A[2]*B[1]
			A[1]*B[0] + A[3]*B[1]
			A[0]*B[2] + A[2]*B[3]
			A[1]*B[2] + A[3]*B[3]
			A[0]*B[4] + A[2]*B[5] + A[4]
			A[1]*B[4] + A[3]*B[5] + A[5]
		]
	multiplyCoords: (V, A) ->
		@multiply A, [V[0], 0, 0, V[1], 0, 0]
	reset: () ->
		[1,0,0,1,0,0]
	rotate: (A, rad) ->
		c = Math.cos rad
		s = Math.sin rad
		[
			A[0]*c + A[2]*s
			A[1]*c + A[3]*s
		  - A[0]*s + A[2]*c
		  - A[1]*s + A[3]*c
			A[4]
			A[5]
		]
	translate: (A, x, y) ->
		[
			A[0]
			A[1]
			A[2]
			A[3]
			A[0]*x + A[2]*y
			A[1]*x + A[3]*y
		]
	getCoords: (A) ->
		[
			Math.round A[0]+A[2]
			Math.round A[1]+A[3]
		]
}

# http://stackoverflow.com/questions/644378/drawing-a-rotated-rectangle
window.rotateRect = (rad, x, y, L, W) ->
	# move pivot point
	W = W/2
	c = Math.cos rad
	s = Math.sin rad
	# order is important since we’re building borders around them for col. det.
	[
		[-W*s+x,    W*c+y]
		[L*c-W*s+x, L*s+W*c+y]
		[L*c+W*s+x, L*s-W*c+y]
		[W*s+x,     -W*c+y]
	]
