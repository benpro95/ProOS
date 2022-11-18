// globals
var vol_mode = 1;
var load_bar = 0;

// on-page-load
window.onload = function() {
  const host = "http://"+location.hostname+"/"
  // load volume mode support on main page only
  if (window.location.href == host) {
    volMode();
  }else{
    vol_mode = 0;  
  }
  var elem = document.getElementById("load__bar");
  elem.textContent = "Automate";  
};

// transmit command
function sendCmd(act, arg1, arg2) {
	if (vol_mode == 1) {  
      arg2 = "subs"
    }
	let url = "http://"+location.hostname+"/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
//	document.getElementById("bottom").innerHTML = url;
	fetch(url, {
      method: 'GET',
    })
  loadBar();
};

// back to home page 
function GoToHomePage() {
  window.location = '/';   
};

function volMode() {   
	let id = document.getElementById("sub__text");
    if (vol_mode == 0) {
       id.textContent = "Subs";
       vol_mode = 1;
    } else {	
       id.textContent = "Bedroom";
       vol_mode = 0;
    }
};

function disableButton() {
	document.getElementById("sub__text").disabled = true;
};	

function loadBar() {
  if (load_bar == 0) {
    load_bar = 1;
    var elem = document.getElementById("load__bar");
    elem.textContent = " ";  
    var width = 1;
    var id = setInterval(frame, 0.4);
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
