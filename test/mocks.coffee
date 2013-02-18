addLayer = (name) -> false
init = ->
	window.ctxMap = addLayer 'map1'
	window.ctxTrajectory = addLayer 'trajectory'
	window.ctxTruck = addLayer 'truck'
	window.ctxPath = addLayer 'path'
	window.ctxInput = addLayer 'input'
	window.ctxBuffer = false
init()
