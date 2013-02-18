class CanvasHelper
	resize: (c, w=window.innerWidth, h=window.innerHeight) ->
		c.width = w
		c.height = h
	append: (id, to=document.body, width=150, height=150) ->
		c = document.createElement 'canvas'
		c.id = id
		c.width = width
		c.height = height
		to.appendChild(c).getContext '2d'
	create: (width=150, height=150) ->
		c = document.createElement 'canvas'
		c.width = width
		c.height = height
		c.getContext '2d'
	mkgraph: (rows, cols) ->
		graph = []
		for r in [0...rows]
			graph[r] = []
			for c in [0...cols]
				graph[r][c] = 0
		graph

@cnvs = new CanvasHelper

HTMLCanvasElement::discretize = (levels=2) ->
	ctx = @getContext '2d'
	a = new Uint32Array ctx.getImageData(0,0,@width,@height).data.buffer
	for i in [0...a.length]
		if a[i] > 0 then a[i] = 1
	a

# extends canvas with relative mouse coordinates
HTMLCanvasElement::relMouseCoords = (event) ->
  totalOffsetX = 0
  totalOffsetY = 0
  canvasX = 0
  canvasY = 0
  currentElement = this
  loop
    totalOffsetX += currentElement.offsetLeft
    totalOffsetY += currentElement.offsetTop
    break unless currentElement = currentElement.offsetParent
  canvasX = event.pageX - totalOffsetX
  canvasY = event.pageY - totalOffsetY
  x: canvasX
  y: canvasY
