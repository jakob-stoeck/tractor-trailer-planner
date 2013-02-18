Vector::relativeAngleFrom = (vector) ->
	# only 2d angle support
	V = vector.toUnitVector().elements
	W = @toUnitVector().elements
	return null unless @elements.length is V.length
	angle = Math.atan2(V[1], V[0]) - Math.atan2(W[1], W[0])
	angle -= Math.PI * 2 if angle > Math.PI
	angle += Math.PI * 2 if angle < -Math.PI
	angle

# returns true if point lies in rectangle from origin and vector 1 and 2
Point::insideRectangle = (origin, v1, v2) ->
	v = @subtract corner
	0 <= v.dot(v1) <= v1.dot(v1) && 0<= v.dot(v2) <= v2.dot(v2)
