###
discretize:
	theta1
	real:
		real world data
	sim:
		google map at lat, lon rotated by some theta

edge detection
	ctxMap

	walls = interpolate raytrace ctxMap
	draw walls on ctxEdges

visibility detection
	walls

4.10.2012
Rauschen für Odometrie und generelle Sensoren simulieren mit Historie (über Zeit)
Ziel festhalten, an unbekannter Stelle, Weg dorthin finden
Fahrer fährt perfekt, Odometrie nicht
Play Button!

11.10.2012
Zielfixierung
Ziel Collision Detection
Mit Referenzpunkten
Truck Richtung festlegen
###

# LAUNCH
ko.applyBindings(config)

addLayer = (name) ->
	cnvs.append name, document.getElementById('container'), config.canvasWidth, config.canvasHeight

window.ctxMap = addLayer 'map1'
window.ctxTrajectory = addLayer 'trajectory'
window.ctxTruck = addLayer 'truck'
window.ctxPath = addLayer 'path'
window.ctxInput = addLayer 'input'
window.ctxBuffer = cnvs.create config.canvasWidth, config.canvasHeight

window.app = $(document)
window.eventInfo = (e) ->
	if config.debug >= 2
		delta = +new Date - config.startTime
		console.info e.type, "@ #{delta}ms from start"

$ ->
	if config.profile then console.profile()
	launchConf = {
		x: 0
		y: 0
		theta: -PIHALF
		theta1: -0.5
		r: 0
	}
	app.trigger 'angle.lidar', [launchConf.theta1]
	app.trigger 'launch.lidar', [launchConf, true]
