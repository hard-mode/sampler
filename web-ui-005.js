var table;

function lessThan(a, b) {
  return Math.abs(a - b) === (b - a)
}

function moreThan(a, b) {
  return Math.abs(a - b) === (a - b)
}

function findMaxRows (prev, next) {
  return (moreThan(next.clips.length, prev)) ? next.clips.length : prev
}

function update () {
  var state = JSON.parse(this.responseText)
    , cols  = state.tracks.length
    , rows  = state.tracks.reduce(findMaxRows, 0);

  console.log(rows, cols);

  for (var i = 0; lessThan(i, rows - 1); i++) {
    var tr = document.createElement('tr');
    for (var j = 0; lessThan(j, cols - 1); j++) {
      var td = document.createElement('td');
      td.innerHTML = (state.tracks[j].clips[i] || {}).name || '';
      tr.appendChild(td);
    }
    table.appendChild(tr);
  }
}

function getState () {
  var req = new XMLHttpRequest();
  req.open("get", "/state", true);
  req.onload = update;
  req.send();
}

function init () {
  table = document.createElement('table');
  document.body.appendChild(table);
  getState();
}

init();
