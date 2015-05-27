function makeButton (index) {
  var btn = document.createElement("input");
  btn.type = "checkbox";
  btn.style.width = 24;
  btn.style.height = 18;
  btn.style.marginRight = 3;
  btn.addEventListener("change", function () {
    setState(btn.parentElement.id, index, btn.checked);
  })
  return btn;
}

function makeRow(instrument) {
  var row = document.createElement("div");
  row.id = instrument;
  row.style.marginBottom = 6;
  row.appendChild(makeButton(0));
  row.appendChild(makeButton(1));
  row.appendChild(makeButton(2));
  row.appendChild(makeButton(3));
  row.appendChild(makeButton(4));
  row.appendChild(makeButton(5));
  row.appendChild(makeButton(6));
  row.appendChild(makeButton(7));
  return row;
}

function setState(instrument, position, value) {
  var req = new XMLHttpRequest();
  req.open("post", "/state", true);
  req.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
  req.send(JSON.stringify([instrument, position, value]));
}

function getState() {
  var req = new XMLHttpRequest();
  req.open("get", "/state", true);
  req.onload = function () {
    var state = JSON.parse(this.responseText);
    Object.keys(state).map(function (key) {
      var row = document.getElementById(key);
      state[key].map(function (val, i) {
        row.children[i].checked = val;
      })
    })
  }
  req.send();
}

function init () {
  document.body.appendChild(makeRow("hihats"));
  document.body.appendChild(makeRow("snares"));
  document.body.appendChild(makeRow("kicks"));
  getState();
}

init();
