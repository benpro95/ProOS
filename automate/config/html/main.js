// globals
var vol_mode = 1;
var relax_mode = 1;
var load_bar = 0;
var console_data = null;
var servercmd_data = null;
var promptCount = 0;

// on-page-load
window.onload = function() {
  const mainpg = "http://"+location.hostname+"/"
  // load volume mode support on main page only
  if (window.location.href == mainpg) {
    volMode();
  }else{
    vol_mode = 0;  
  }
  // load relax mode support on bedroom page only
  const roompg = "http://"+location.hostname+"/room.html"
  if (window.location.href == roompg) {
    relaxMode();
  }else{    
    relax_mode = 0;  
  }
  // set loading bar text
  var elem = document.getElementById("load__bar");
  elem.textContent = "Automate"; 
};

// timer
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
};

// back to home page 
function GoToHomePage() {
  window.location = '/';   
};


function GoToCamera() {
  closePopup();
  window.location = 'http://aptcam.home:8081';
};

// transmit command
async function sendCmd(act, arg1, arg2) {
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
  // animation
  loadBar();
};

// load entire text file
async function loadLog(file) {
  try {
    const err = null;
    // build url and force cache reload
    const time = new Date();
    const timestamp = (time.getTime());   
    const url = "http://"+location.hostname+"/ram/sysout.txt"+"?ver="+timestamp;
    // parse incoming text file
    const response = await fetch(url);
    console_data = await response.text(); 
    // display text on page 
    document.getElementById("logTextBox").value = console_data;
    // scroll to bottom of page
    var txtArea = document.getElementById("logTextBox");
    txtArea.scrollTop = txtArea.scrollHeight;
  } catch (err) {
    console.error(err);
  }
  console_data = null;
  // animations
  hideSpinner();
  loadBar();
  resetAction();
};

// load server action 
function serverAction(cmd) {
  servercmd_data = cmd;
  // change color of send button 
  document.getElementById("sendButton").style.background='#2c0c2c';
  hideSpinner();
};

function resetAction() {
  // return default color of send button 
  document.getElementById("sendButton").style.background='#1e2352';  
  servercmd_data = null;
};

// send server action
async function serverSend(mask) {
  if (servercmd_data == null) {
    document.getElementById("logTextBox").value = "Select an action.";
  } else {
    var cmd_text;
    if (mask == 1) {
       cmd_text = "xxxxxxxx";
    } else {
       cmd_text = servercmd_data;
    }
    showSpinner();
    // send data
    sendCmd('main','server',servercmd_data);
    // delay
    await sleep(400);
    // refresh log
    loadLog();
  }  
  servercmd_data = null;
};

function openLogWindow() {
  // current date
  var date = new Date();
  var hh = (date.getHours() % 12 || 12);
  var mm = date.getMinutes();
  var ss = date.getSeconds();
  var day = date.getDate();
  var mth = 1 + date.getMonth();
  var year = date.getFullYear();
  var curr_time = hh+':'+mm+':'+ss;
  var curr_date = mth+'/'+day+'/'+year;
  // open server log window
  closePopup();
  // help message 
  document.getElementById("logTextBox").value = " Proxmox Linux Server "+curr_time+" "+curr_date+" ";
  // show log form window
  document.getElementById("logForm").style.display = "block";
};

function openCamWindow() {
  closePopup();
  // show camera form window
  document.getElementById("camForm").style.display = "block";
  // Show our element, then call our callback
  $(".iframe-container").show(function(){
      // Find the iframes within our newly-visible element
      $(this).find("iframe").prop("src", function(){
          // Set their src attribute to data-active
          return $(this).data('active');
      });
  });
};

function closePopup() {
  // close all popup windows
  hideSpinner();
  document.getElementById("logForm").style.display = "none";
  document.getElementById("camForm").style.display = "none";
  // Show our element, then call our callback
  $(".iframe-container").show(function(){
      // Find the iframes within our newly-visible element
      $(this).find("iframe").prop("src", function(){
          // Set their src attribute to data-inactive
          return $(this).data('inactive');
      });
  });
};

function showSpinner() {
  // hide button before drawing spinner
  document.getElementById("sendButton").style.display = "none";  
  // show apple spinner
  document.getElementById("formSpinner").style.display = "inline-block";   
};

function hideSpinner() {
  // hide apple spinner
  document.getElementById("formSpinner").style.display = "none";
  // re-enable close button
  document.getElementById("sendButton").style.display = "inline-block";  
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








