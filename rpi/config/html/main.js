// globals
var load_bar = 0;

// on-page-load
window.onload = function() {
  // set loading bar text
  var elem = document.getElementById("load__bar");
  elem.textContent = "RaspberryPi";  
};

// transmit command
function sendCmd(act, arg1, arg2) {
  // adjust API syntax for different functions
  // construct API string
	let url = "http://"+location.hostname+"/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
	document.getElementById("bottom").innerHTML = url;
  // send data
	fetch(url, {
      method: 'GET',
    })
  loadBar();
};

// back to home page 
function GoToHomePage() {
  window.location = 'http://automate.home/';   
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
        elem.textContent = "RaspberryPi";  
      }
    }
  }
};
