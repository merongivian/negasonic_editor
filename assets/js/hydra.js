const Hydra = require('hydra-synth')
const Canvas = require('./canvas.js')

window.onload = function () {
  var canvas = Canvas(document.getElementById('hydra-canvas'))
  canvas.size();
  const hydra = new Hydra({canvas: canvas.element});
}
