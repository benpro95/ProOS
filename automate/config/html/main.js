// globals
var toggledState = 0;
var loadBarState = 0;
var consoleData = null;
var serverCmdData = null;
var promptCount = 0;
var rowState = 0;

//////////////////////////

// runs on any other page load
function loadPage() {
  loadCommon();
};

// runs on automate page load
function loadAutomate() {
  volMode();
  loadCommon();
};

// runs on ambiance page load
function loadAmbiance() {
  relaxMode();
  loadCommon();
};

function loadCommon() {
  resizeEvent();
  // set title
  var elem = document.getElementById("load__bar");
  elem.textContent = "Automate";
  // show buttons and header
  classDisplay('grid','block');
  classDisplay('body__text','inline-block');
};

// resize event
window.onresize = function(event) {
  resizeEvent();
};

function resizeEvent() {
  if (window.innerWidth < 860) {
    classDisplay('parsplit','block');
  } else {
    classDisplay('parsplit','none');
  }
};

// show / hide multiple classes
function classDisplay(_elem, _state) {
  var _itr;
  var _class = document.getElementsByClassName(_elem);
  for (_itr = 0; _itr < _class.length; _itr++) {
      _class[_itr].style.display = _state;
  }
}

// hide all drop down menus
function hideDropdowns() {
  classDisplay('dropdown-content','none');
};

function detectMobile() {
  if (navigator.userAgent.match(/Android/i)
    || navigator.userAgent.match(/webOS/i)
    || navigator.userAgent.match(/iPhone/i)
    || navigator.userAgent.match(/iPad/i)) {
      console.log("Mobile Browser");
  }
};

// toggle dropdown menu's
function showMenu(_menu) {
  var _elem = document.getElementById(_menu);
  if (_elem.style.display == 'block') {
    _elem.style.display = 'none';
  } else {
    hideDropdowns();
    _elem.style.display = 'block';
  }
};

// timer
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
};

// back to home page 
function GoToHomePage() {
  window.location = '/';   
};

// back to home page ****
function GoToAutomate() {
  window.location = 'https://automate.home/';   
};

function GoToCamera() {
  closePopup();
  window.location = location.protocol+"//"+location.hostname+"/cam1";
};

function passwordPrompt(text){
  var pwprompt = document.createElement("div"); //creates the div to be used as a prompt
  pwprompt.id= "pass__prompt"; //gives the prompt an id - not used in my example but good for styling with css-file
  var pwtext = document.createElement("div"); //create the div for the password-text
  pwtext.innerHTML = text; //put inside the text
  pwprompt.appendChild(pwtext); //append the text-div to the password-prompt
  var pwinput = document.createElement("input"); //creates the password-input
  pwinput.id = "password_id"; //give it some id - not really used in this example...
  pwinput.type="password"; // makes the input of type password to not show plain-text
  pwprompt.appendChild(pwinput); //append it to password-prompt
  var pwokbutton = document.createElement("button"); //the ok button
  pwokbutton.innerHTML = "Send";
  var pwcancelb = document.createElement("button"); //the cancel-button
  pwcancelb.innerHTML = "Cancel";
  pwprompt.appendChild(pwcancelb); //append cancel-button first
  pwprompt.appendChild(pwokbutton); //append the ok-button
  document.body.appendChild(pwprompt); //append the password-prompt so it gets visible
  pwinput.focus(); //focus on the password-input-field so user does not need to click 
  /*now comes the magic: create and return a promise*/
  return new Promise(function(resolve, reject) {
      pwprompt.addEventListener('click', function handleButtonClicks(e) { //lets handle the buttons
        if (e.target.tagName !== 'BUTTON') { return; } //nothing to do - user clicked somewhere else
        pwprompt.removeEventListener('click', handleButtonClicks); //removes eventhandler on cancel or ok
        if (e.target === pwokbutton) { //click on ok-button
          resolve(pwinput.value); //return the value of the password
        } else {
          reject(new Error('User cancelled')); //return an error
        }
        document.body.removeChild(pwprompt);  //as we are done clean up by removing the password-prompt

      });
      pwinput.addEventListener('keyup',function handleEnter(e){ //users dont like to click on buttons
          if(e.keyCode == 13){ //if user enters "enter"-key on password-field
              resolve(pwinput.value); //return password-value
              document.body.removeChild(pwprompt); //clean up by removing the password-prompt
          }else if(e.keyCode==27){ //user enters "Escape" on password-field
              document.body.removeChild(pwprompt); //clean up the password-prompt
              reject(new Error("User cancelled")); //return an error
          }
      });
  }); 
}

async function getPassword(){
  var result;
  try{
    hideDropdowns();
    result = await passwordPrompt("Enter password:");
    if (result != null) {  
      if (result != '') {  
        savePOST(result);
        serverAction('attach_bkps');
        serverSend(0);
      }
    } 
    result = "";
  } catch(e){
    result = "";
  }
}

// save file
function savePOST(data) {
  fetch(location.protocol+"//"+location.hostname+"/upload.php", {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: data
  })
  data = "";
};

// switch volume controls on main page
function volMode() {   
  var id = document.getElementById("sub__text");
  if (toggledState == 1) {
     id.textContent = "Subwoofers";
     toggledState = 0;
  } else {  
     id.textContent = "Bedroom";
     toggledState = 1;
  }
};

// switch volume controls on bedroom page
function relaxMode() {   
  var id = document.getElementById("relax__text");
  if (toggledState == 1) {
     id.textContent = "HiFi";
     toggledState = 0;
  } else {  
     id.textContent = "Bedroom";
     toggledState = 1;
  }
};

function relaxSend(_cmd) {
  var _mode;
  // volume mode
  if (_cmd == 'vup' 
   || _cmd == 'vdwn'
   || _cmd == 'vmute') {
    _mode = _cmd;
    if (toggledState == 0) {
      _cmd = 'hifi';
    } else {
      _cmd = 'bedroom';
    } 
  } else {
    // relax mode
    _mode = 'relax';
    if (toggledState == 0) {
      _cmd = _cmd+"-hifi";
    } 
  }
  sendCmd('main',_mode,_cmd);
};


function toggledVol(_mode) {
  if (toggledState == 0) {
    _cmd = 'subs';
  } else {
    _cmd = 'bedroom';
  } 
  sendCmd('main',_mode,_cmd);
};


// send server action
async function serverSend() {
  if (serverCmdData == null) {
    document.getElementById("logTextBox").value = "Select an action.";
  } else {
    showSpinner();
    // send data
    sendCmd('main','server',serverCmdData);
    await sleep(1000);
    loadLog();
    hideSpinner();
  }  
  serverCmdData = null;
};


// transmit command for server
async function sendCmd(act, arg1, arg2) {
  hideDropdowns();
  // construct API string
  const url = location.protocol+"//"+location.hostname+"/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
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
    const url = location.protocol+"//"+location.hostname+"/ram/sysout.txt"+"?ver="+timestamp;
    // parse incoming text file
    const response = await fetch(url);
    consoleData = await response.text(); 
    // display text on page 
    document.getElementById("logTextBox").value = consoleData;
    // scroll to bottom of page
    var txtArea = document.getElementById("logTextBox");
    txtArea.scrollTop = txtArea.scrollHeight;
  } catch (err) {
    console.error(err);
  }
  consoleData = null;
  // animations
  hideSpinner();
  resetAction();
};


// load server action 
function serverAction(cmd) {
  serverCmdData = cmd;
  // change color of send button 
  document.getElementById("sendButton").style.background='#2c0c2c';
  hideSpinner();
};


function resetAction() {
  hideDropdowns();
  // return default color of send button 
  document.getElementById("sendButton").style.background='#1e2352';  
  // clear command data
  serverCmdData = null;
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
  hideDropdowns();
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

function closeSendbox() {
  // close all popup windows
  document.getElementById("sendForm").style.display = "none";
};

function openSendWindow() {
  // open send text window
  closeSendbox();
  document.getElementById("sendForm").style.display = "block";
};


function sendText() {
  const data = document.getElementById("logTextBox").value;
  if (data.trim() === "") {
    document.getElementById("logTextBox").value = "enter a message before sending.";
  } else {
  // Create the HTTP POST request
    const xhr = new XMLHttpRequest();
    const url = location.protocol+"//"+location.hostname+"/upload.php";
    xhr.open("POST", url);
    xhr.setRequestHeader("Content-Type", "text/plain");
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status === 200) {
          // message sent
          document.getElementById("logTextBox").value = "";
        } else {
          document.getElementById("logTextBox").value = "failed to transmit message.";
        }
      }
    }
    xhr.send(data);
  }
  loadBar();
};


function clearText() {
  // celar text window
  document.getElementById("logTextBox").value = "";
};


// disable a button
function disableButton() {
	document.getElementById("sub__text").disabled = true;
};	


// loading bar animation 
async function loadBar() {
  if (loadBarState == 0) {
    loadBarState = 1;
    var elem = document.getElementById("load__bar");
    elem.textContent = " ";  
    var width = 1;
    var id = setInterval(frame, 0.5);
    function frame() {
      if (width >= 100) {
        clearInterval(id);
        loadBarState = 0;
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








