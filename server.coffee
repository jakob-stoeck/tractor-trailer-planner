port = 8080
http = require 'http'
connect = require 'connect'
options =
	host: 'maps.google.com'
	port: 80
	method: 'GET'

app = connect()
	# serve static files if they exist
	.use(connect.static(__dirname))
	# proxy to google maps if path matches
	.use((request, response) ->
		path = request.originalUrl
		if !path.match /^\/maps/
			response.writeHead 404, {'Content-Type': 'text/plain'}
			response.end()
		options.path = path
		http.get(options, (res) ->
			res.on 'data', (d) -> response.write d
			res.on 'end', -> response.end()
		).on 'error', (e) ->
			response.writeHead 500, {'Content-Type': 'text/plain'}
			response.end()
	)
	.listen port
