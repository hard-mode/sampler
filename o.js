var o = require('osc');
var Long = require('./node_modules/osc/node_modules/long');
var p = new o.UDPPort({localAddress:'0.0.0.0', localPort:'44444'});
p.on('osc', function () { console.log(arguments) });
p.open();
p.send({address:'/receive', args:[Long.fromString("FFFFFFF",false,16)]}, "127.0.0.1", 55555);

//var n = require('node-osc');
//var c = new n.Client('127.0.0.1', 55555);
//var s = new n.Server('127.0.0.1', 55556);
//s.on("message", function () { console.log(arguments) });
//c.send('/receive_at', 1, 55556, '127.0.0.1');
