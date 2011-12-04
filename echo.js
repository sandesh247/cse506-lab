var net = require('net');


var other = null;

var server = net.createServer(function (socket) {
	console.log("Someone connected on port 10091");
	socket.pipe(other);
	other.pipe(socket);
	socket.on('error', function() {
		console.log("error event on client socket");
		other = null;
	    });
    });

server.listen(10091, "0.0.0.0");

var server = net.createServer(function (socket) {
	console.log("Someone connected on port 10092");
	other = socket;
	socket.on('error', function() {
		console.log("error event on migrated socket");
		other = null;
	    });
    });

server.listen(10092, "0.0.0.0");

