// globals
var vol_mode = 1;
var relax_mode = 1;
var load_bar = 0;
var console_data;

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

// display server logs
async function loadLog(url) {
  try {
    const response = await fetch(url);
    console_data = await response.text(); 
    document.getElementById("logTextBox").value = console_data;
//  console.log(console_data);
  } catch (err) {
    console.error(err);
  }
  hideSpinner();
};

function newLog() {
  // generate a new server log
  document.getElementById("logTextBox").value = "Please wait one-minute, then click load.";
  showSpinner();
  sendCmd('main','serverlog','');
};  

function openLog() {
  // open text file on page
  hideSpinner();
  document.getElementById("logTextBox").value = " (Load) - Display server log\r\n (New) - Request current system log data";
  document.getElementById("logForm").style.display = "block";
};

function closeLog() {
  // close log window
  hideSpinner();
  document.getElementById("logForm").style.display = "none";
};

function showSpinner() {
  // show apple spinner
  document.getElementById("logFormSpinner").style.display = "inline-block";
};

function hideSpinner() {
  // hide apple spinner
  document.getElementById("logFormSpinner").style.display = "none";
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
	//document.getElementById("bottom").innerHTML = url;
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
