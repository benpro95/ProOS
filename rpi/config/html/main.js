// globals
var load_bar = 0;

// on-page-load
window.onload = function() {
  // disable show menu on hover
  hideDropdowns();
  // set loading bar text
  var elem = document.getElementById("load__bar");
  elem.textContent = "Automate";  
};

// hide all drop down menus
function hideDropdowns() {
  var _itr;
  var _class = document.getElementsByClassName("dropdown-content");
  for (_itr = 0; _itr < _class.length; _itr++) {
      _class[_itr].style.display = 'none';
  }
};

// toggle a menu
function showMenu(_menu) {
  var _elem = document.getElementById(_menu);
  if (_elem.style.display == 'block') {
    _elem.style.display = 'none';
  } else {
    hideDropdowns();
    _elem.style.display = 'block';
  }
};

// transmit command
function sendCmd(act, arg1, arg2) {
  hideDropdowns();
  // construct API string
	let url = "http://"+location.hostname+"/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
	//document.getElementById("bottom").innerHTML = url;
  // send data
	fetch(url, {
      method: 'GET',
    })
  loadBar();
};

// back to home page 
function GoToHomePage() {
  window.location = 'https://automate.home/';   
};

function loadBar() {
  if (load_bar == 0) {
    load_bar = 1;
    var elem = document.getElementById("load__bar");
    elem.textContent = " ";  
    var width = 1;
    var id = setInterval(frame, 0.5);
    function frame() {
      if (width >= 100) {
        clearInterval(id);
        load_bar = 0;
      } else {
        width++;
        elem.style.width = width + "%";
      }
      if (width >= 100) {
        elem.style.width = 0;  
        elem.textContent = "Automate";  
      }
    }
  }
};
