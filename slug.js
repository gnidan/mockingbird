var hem = new (require('hem'));
var command = process.argv.slice(2)[0];
var less = require('hem-less');

var options = {
  "server": {
    compress: false
  },
  "build": {
    compress: true
  }
};

less.setOptions(options[command]);
hem.compilers.less = less.compiler;

hem.exec(command);
