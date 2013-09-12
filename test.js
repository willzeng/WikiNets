var fs = require('fs');

var goodWords = "Yet today I consider myself the luckiest man on the face of this earth.";

fs.writeFileSync('lou.json', goodWords);