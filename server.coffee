port = 8080
querystring = require 'querystring'
fs = require 'fs'
http = require 'http'
connect = require 'connect'
config = require './config'

convertToApiUrl = (path) ->
	p = {
		center: path.substring('/maps/'.length, path.length-'.png'.length)
		zoom: 21
		size: [640,640].join('x')
		maptype: 'roadmap'
		sensor: false
		style: 'feature:all|element:labels|visibility:off'
		key: config.googleMapsKey
	}
	'/maps/api/staticmap?style=feature:road|visibility:off&'+querystring.stringify(p)
download = (host, path, saveTo, finishCb, errorCb) ->
	options =
		host: host
		path: path
		method: 'GET'
		port: 80
	data = ''
	writeFinishedCb = (err) ->
		if (err) then throw err
		finishCb data
		# console.log 'File saved.  path: '+saveTo
	receivingCb = (res) ->
		res.setEncoding 'binary'
		res.on 'data', (chunk) ->
			data += chunk
		res.on 'end', ->
			fs.writeFile saveTo, data, 'binary', writeFinishedCb
	http.get(options, receivingCb).on 'error', errorCb

app = connect()
	# serve static files if they exist
	.use(connect.static(__dirname))
	.use(connect.static(__dirname + '/maps'))
	# proxy to google maps if path matches
	.use((request, response) ->
		path = request.originalUrl
		if !path.match /^\/maps/
			response.writeHead 404, {'Content-Type': 'text/plain'}
			response.end()
		else
			# get from api
			downCb = (data) ->
				response.write data
				response.end()
			downErr = (error) ->
				response.writeHead 500, {'Content-Type': 'text/plain'}
				response.end()
			download 'maps.google.com', convertToApiUrl(path), __dirname+path, downCb, downErr
	)
	.listen port
