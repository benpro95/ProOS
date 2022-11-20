// globals
var vol_mode = 1;
var relax_mode = 1;
var load_bar = 0;
var console_data = "";
var servercmd_data = "";

// on-page-load
window.onload = function() {
  const host1 = "http://"+location.hostname+"/"
  // load volume mode support on main page only
  if (window.location.href == host1) {
    volMode();
  }else{
    vol_mode = 0;  
  }
  // load relax mode support on bedroom page only
  const host2 = "http://"+location.hostname+"/room.html"
  if (window.location.href == host2) {
    relaxMode();
  }else{    
    relax_mode = 0;  
  }
  // set loading bar text
  var elem = document.getElementById("load__bar");
  elem.textContent = "Automate";  
};

// transmit command
function sendCmd(act, arg1, arg2) {
  // adjust API syntax for different functions
  if (vol_mode == 1) {  
    arg2 = "subs";
  }
  if (relax_mode == 1) {  
    arg2 = arg2+"-hifi";
  } 
  // construct API string
  let url = "http://"+location.hostname+"/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
  // display API string on page
  document.getElementById("bottom").innerHTML = url;
  // send data
  fetch(url, {
      method: 'GET',
    })
  loadBar();
};

// back to home page 
function GoToHomePage() {
  window.location = '/';   
};

// load text file
async function loadLog(url) {
  try {
    const response = await fetch(url);
    console_data = await response.text(); 
    document.getElementById("logTextBox").value = console_data;
//  console.log(console_data);
  } catch (err) {
    console.error(err);
  }
  console_data = "";
  hideSpinner();
};

// load server action 
function serverAction(cmd) {
  servercmd_data = cmd;
  document.getElementById("logTextBox").value = "Click send to request action.";
};

// send server action
function serverSend() {
  if (servercmd_data == "") {
    document.getElementById("logTextBox").value = "Select an action.";
  } else {
    document.getElementById("logTextBox").value = "Please wait one-minute, transmitted the command ("+servercmd_data+")";
    showSpinner();
    // request server data
    sendCmd('main','server',servercmd_data);
  }  
  servercmd_data = "";
};

function openLogWindow() {
  // open server log window
  closePopup();
  // help message 
  document.getElementById("logTextBox").value = " (Load) - Display server log\r\n (New) - Request current system log data";
  // show log form window
  document.getElementById("logForm").style.display = "block";
};

function closePopup() {
  // close all popup windows
  hideSpinner();
  document.getElementById("logForm").style.display = "none";
};

function showSpinner() {
  // hide button before drawing spinner
  document.getElementById("closeButton").style.display = "none";  
  // show apple spinner
  document.getElementById("formSpinner").style.display = "inline-block";   
};

function hideSpinner() {
  // hide apple spinner
  document.getElementById("formSpinner").style.display = "none";
  // re-enable close button
  document.getElementById("closeButton").style.display = "inline-block";  
};

// switch volume controls on main page
function volMode() {   
	let id = document.getElementById("sub__text");
    if (vol_mode == 0) {
       id.textContent = "Subwoofers";
       vol_mode = 1;
    } else {	
       id.textContent = "Bedroom";
       vol_mode = 0;
    }
};

// switch volume controls on bedroom page
function relaxMode() {   
  let id = document.getElementById("relax__text");
    if (relax_mode == 0) {
       id.textContent = "HiFi";
       relax_mode = 1;
    } else {  
       id.textContent = "Bedroom";
       relax_mode = 0;
    }
};

// disable a button example
function disableButton() {
	document.getElementById("sub__text").disabled = true;
};	

// loading bar animation 
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


