// globals
var toggledState = 0;
var loadBarState = 0;
var promptCount = 0;
var rowState = 0;
var consoleData;
var currentTheme;
var serverCmdData;

//////////////////////////

// hide menu's when clicking outside
document.addEventListener('click', function handleClickOutsideBox(event) {
  console.log('user clicked: ', event.target);
  // don't hide when clicking these elements
  if (!event.target.classList.contains('button') &&
      !event.target.classList.contains('button__text') &&
      !event.target.classList.contains('fa-solid') &&
      !event.target.classList.contains('dropbtn') &&  
      !event.target.classList.contains('mainmenu__anchor')) {
    hideDropdowns();
  }
});

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
  classDisplay('body__text','block');
  // read theme from local storage or choose default
  currentTheme = localStorage.getItem("styledata") || "blue-theme";
  setTheme(currentTheme);
};

function setTheme(newTheme) {
  const body = document.getElementsByTagName("html")[0];
  // Remove old theme scope from body's class list
  body.classList.remove(currentTheme);
  // Add new theme scope to body's class list
  body.classList.add(newTheme);
  // Set it as current theme
  currentTheme = newTheme;
  // Store the new theme in local storage
  localStorage.setItem("styledata", newTheme);
}

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
  classDisplay("dropdown-content","none");
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
    // animations
    loadBar(3.0);
    var _elem = document.getElementById("sendButton");
    _elem.classList.remove("button-alert");
    // send command
    sendCmdNoBar('main','server',serverCmdData);
    // load log data
    await sleep(450);
    loadLog();
  }  
  serverCmdData = null;
};


// transmit command for server
function sendCmd(act, arg1, arg2) {
  // animation
  loadBar(0.5);
  sendGET(act,arg1,arg2);
};

function sendCmdNoBar(act, arg1, arg2) {
  sendGET(act,arg1,arg2);
};

function sendGET(act, arg1, arg2) {
  // construct API string
  const url = location.protocol+"//"+location.hostname+"/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
  // display API string on page
  //document.getElementById("bottom").innerHTML = url;
  // send data
  fetch(url, {
      method: 'GET',
    })
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
  serverCmdData = null;
};


// load server action 
function serverAction(cmd) {
  serverCmdData = cmd;
  // change color of send button 
  var _elem = document.getElementById("sendButton");
   _elem.classList.add("button-alert");
};


function openLogWindow() {
  // open server log window
  closePopup();
  // show log form window
  document.getElementById("logForm").style.display = "block";
  // load log data
  loadLog();
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
  loadBar(0.5);
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
async function loadBar(_interval) {
  if (loadBarState == 0) {
    loadBarState = 1;
    var elem = document.getElementById("load__bar");
    elem.textContent = " ";  
    var width = 1;
    var id = setInterval(frame, _interval);
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








