window.onload = function() {
  var $app = document.getElementById('app');
  var $loading = document.getElementById('loading');
  $app.removeChild($loading);
  var $button = document.createElement('button');
  var $h1 = document.createElement('h1');
  $app.appendChild($h1);
  $app.appendChild($button);

  $h1.textContent = '~Angel HTTP/2 server push~';

  $button.textContent = 'Change color';
  $button.onclick = function() {
    var color = Math.floor(Math.random() * 0xffffff);
    $h1.style.color = '#' + color.toString(16);
  };

  $button.onclick();

  window.setInterval($button.onclick, 2000);

  var rotation = 0;
  window.setInterval(function() {
    rotation += .6;
    $button.style.transform = 'rotate(' + rotation + 'deg)';
  }, 10);
};