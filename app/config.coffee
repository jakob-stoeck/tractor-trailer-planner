# 21.09.
# HMI dreht sich mit, verwirrend?
# Sensor Data Flow, Sensoren emulieren
# Odometrie, perfekt annehmen
# Szenario:  Ziel wählen, welches noch nicht erreichbar ist, Truck fährt hin und zeigt erreichbares

# Entwicklungsprozess dokumentieren inkl. Tools
# Alternativen
# Feldversuche -> LIDAR aussuchen

window.config =
	wallNumber: ko.observable 0
	frameRate: ko.observable 0
	debug: 0
	canvasWidth: 800
	canvasHeight: 800
	steer: ko.observable 0.55
	steeringRate: ko.observable 0.012
	steps: ko.observable 20
	speed: ko.observable 0.2
	direction: ko.observable 1
	searchMax: ko.observable 5000
	goalMin: ko.observable 10
	rChangePenalty: ko.observable 10
	raytraceAngles: ko.observable 200
	lat: ko.observable 48.162945
	lon: ko.observable 11.59515
	advanced: ko.observable false
	showAllFeasiblePaths: ko.observable false
	ed:
		maxDistance: ko.observable 60
		maxDistanceToLine: ko.observable 4
		minLength: ko.observable 3
		minR2: ko.observable 0.63
		frequency: ko.observable 50
		maxTime: ko.observable 1000
	truck:
		tractor:
			# those are axle lengths and widths
			length: ko.observable 45
			width: ko.observable 24
			body:
				# additional sizes for collision detection
				lengthFront: ko.observable 0
				lengthRear: ko.observable 0
				width: ko.observable 0
		trailer:
			length: ko.observable 110
			body:
				lengthFront: ko.observable 0
				lengthRear: ko.observable 0
				width: ko.observable 0
	scale: 1
	# profile: true
	computeVisibility: true
	 # 1px is _scale_ cm
	# lat: ko.observable 48.148955
	# lon: ko.observable 11.567
	# http://webhelp.esri.com/arcgisserver/9.3/java/index.htm#designing_overlay_gm_mve.htm
	# Google Zoom scale
	# 20 : 1128.497220
	# 19 : 2256.994440
	# 18 : 4513.988880
	# 17 : 9027.977761
	# 16 : 18055.955520
	googleMaps:
		key: ''
		url: '/maps/api/staticmap'
