// Automate Website - JavaScript Frontend
// by Ben Provenzano III

//////////////////
let device = null;
let selectedVM = "";
let dynMenuActive = 0;
let dynChkboxChanged = 0;
let colorPromptActive = 0;
let defaultSite = "Automate";
let serverCmdData = null;
let bookmarkState = 0;
let loadBarState = 0;
let promptCount = 0;
let socket = null;
let fileData = [];
let arcState = 0;
let ctlState = 0;
let ctlMode;
////////////

// runs after DOM finishes loading
window.addEventListener("DOMContentLoaded", (event) => {
  // hide menu's when clicking outside
  document.addEventListener('click', function handleClickOutsideBox(event) {
    // don't hide menus when clicking these elements
    if (!(event.target.classList.contains('button') || // button click
          event.target.classList.contains('button__text') || // button text click
          event.target.classList.contains('mainmenu__anchor') || // main menu click
          event.target.classList.contains('bookmarked__item') || // bookmark menu click
          event.target.classList.contains('editfav__window') || // bookmark edit window
          event.target.classList.contains('fa-regular') || // icon click
          event.target.classList.contains('fa-solid') || // icon click
          event.target.classList.contains('dropbtn') || // dropdown menu
          event.target.classList.contains('chkbox'))) { // checkbox click
      hideDropdowns();
    }
  }); 
});

function hideDropdowns() {
  // hide all dropdown menus
  classDisplay("dd-content","none");
  // hide all bookmark menu elements
  hideBookmarks();
  // remove any current dynamic menus
  removeDynMenus();
}

// runs on page load
function loadPage() {
  // read device type
  device = deviceType(); 
  if (device === defaultSite) {
    // load control menu
    let _mode = localStorage.getItem("ctls-mode")
    if (_mode === null || _mode === undefined || _mode === "") {
      ctlMode = 'lr'; // living room 
    } else {
      ctlMode = localStorage.getItem("ctls-mode");
    }  
    ctlsMenu(ctlMode);
    // server home
    classDisplay('server-grid','block');
    // update devices status
    sendCmd('main','status','')
  } else { // pi's
    if (device === 'Pi') {
      classDisplay('pi-grid','block');
    }  
    if (device === 'LEDpi') {
      classDisplay('ledpi-grid','block');
    }
    if (device === 'LCDpi') {
      classDisplay('lcdpi-grid','block');
    }
  }
  // mobile device setup
  detectMobile();
  // set title
  let currentTheme;
  let elem = document.getElementById("load__bar");
  elem.textContent = defaultSite;
  // set theme
  let _theme = localStorage.getItem("main-color")
  if (_theme === null || _theme === undefined || _theme === "") {
    currentTheme = "#1f2051"; // dark blue
  } else {
    currentTheme = localStorage.getItem("main-color");
  }  
  setTheme(currentTheme);
}

function setTheme(newTheme) {
  let body = document.getElementsByTagName("html")[0];
  body.style.setProperty('--main-color', newTheme);
  localStorage.setItem("main-color", newTheme);
}

function showLEDsPage() {
  hidePages();
  classDisplay('led-grid','block');
}

function hidePages() {
  classDisplay('pi-grid','none'); 
  classDisplay('lcdpi-grid','none');
  classDisplay('server-grid','none');
  classDisplay('ledpi-grid','none');
  classDisplay('led-grid','none');
}

// show / hide multiple classes
function classDisplay(_elem, _state) {
  let _itr;
  let _class = document.getElementsByClassName(_elem);
  for (_itr = 0; _itr < _class.length; _itr++) {
    _class[_itr].style.display = _state;
  }
}

function detectMobile() {
  if (navigator.userAgent.match(/Android/i) ||
      navigator.userAgent.match(/webOS/i)   ||
      navigator.userAgent.match(/iPhone/i)  || 
      navigator.userAgent.match(/iPad/i)) {
        console.log("Mobile Browser");
  } else {
    // PC browser
    starsAnimation(true);
  }
}

function starsAnimation(_state) {
  let _itr;
  var elem;
  for (_itr = 1; _itr <= 12; _itr++) {
    elem = document.getElementById("star-" + _itr);
    if (_state === true) {
      elem.classList.add("animate-stars");
    } else {
      elem.classList.remove("animate-stars");
    }
  }
}

// timer
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// back to home page 
function GoToHomePage() {
  if (device === defaultSite) {
    hidePages();
    loadPage();
  } else {
    window.location = 'https://'+defaultSite+'.home';   
  }
}

function GoToExtPage(_path) {
  window.location = "https://"+_path;   
}

function GotoSubURL(_path) {
  closePopup();
  window.location = location.protocol+"//"+location.hostname+"/"+_path;
}

function show_vmsPrompt(text){
  selectedVM = "";
  clearPendingCmd();
  let vms_prompt = document.createElement("div"); //creates the div to be used as a prompt
  vms_prompt.id= "vms__prompt"; //gives the prompt an id - not used in my example but good for styling with css-file
  let vms_text = document.createElement("div"); //create the div for the password-text
  vms_text.innerHTML = text; //put inside the text
  vms_text.id="vms__text"; 
  vms_prompt.appendChild(vms_text); //append the text-div
  // the cancel-button
  let vms_cancelb = document.createElement("button"); 
  vms_cancelb.innerHTML = "Close";
  vms_cancelb.className ="button button_vmctrls_close"; 
  vms_cancelb.type="button"; 
  vms_prompt.appendChild(vms_cancelb); //append cancel-button
  // the dev-button 
  let vms_devbtn = document.createElement("button"); 
  vms_devbtn.innerHTML = "Development";
  vms_devbtn.className ="button button_vmctrls"; 
  vms_devbtn.type="button"; 
  vms_prompt.appendChild(vms_devbtn); 
  // the unifi-button 
  let vms_unifibtn = document.createElement("button"); 
  vms_unifibtn.innerHTML = "UniFi Controller";
  vms_unifibtn.className ="button button_vmctrls"; 
  vms_unifibtn.type="button"; 
  vms_prompt.appendChild(vms_unifibtn); 
  // the cifs-button 
  let vms_cifsbtn = document.createElement("button"); 
  vms_cifsbtn.innerHTML = "Legacy CIFS";
  vms_cifsbtn.className ="button button_vmctrls"; 
  vms_cifsbtn.type="button"; 
  vms_prompt.appendChild(vms_cifsbtn); 
  // the xana-button 
  let vms_xanabtn = document.createElement("button"); 
  vms_xanabtn.innerHTML = "Xana";
  vms_xanabtn.className ="button button_vmctrls"; 
  vms_xanabtn.type="button"; 
  vms_prompt.appendChild(vms_xanabtn);
  // erase button (hidden)
  let vms_restorebtn = document.createElement("button"); 
  vms_restorebtn.innerHTML = "Erase";
  vms_restorebtn.className ="button button_vmactions";
  vms_restorebtn.id = "vms__restorebtn";
  vms_restorebtn.type="button";
  vms_restorebtn.style.display = "none";
  // start button (hidden)
  let vms_startbtn = document.createElement("button"); 
  vms_startbtn.innerHTML = "Start";
  vms_startbtn.className ="button button_vmactions";
  vms_startbtn.id = "vms__startbtn";
  vms_startbtn.type="button";
  vms_startbtn.style.display = "none";
  // stop button (hidden)
  let vms_stopbtn = document.createElement("button"); 
  vms_stopbtn.innerHTML = "Stop";
  vms_stopbtn.className ="button button_vmactions";
  vms_stopbtn.id = "vms__stopbtn";
  vms_stopbtn.type="button";
  vms_stopbtn.style.display = "none";
  // open button (hidden)
  let vms_openbtn = document.createElement("button"); 
  vms_openbtn.innerHTML = "Open";
  vms_openbtn.className ="button button_vmactions";
  vms_openbtn.id = "vms__openbtn";
  vms_openbtn.type="button";
  vms_openbtn.style.display = "none";
  // button order
  vms_prompt.appendChild(vms_stopbtn); 
  vms_prompt.appendChild(vms_startbtn);
  vms_prompt.appendChild(vms_restorebtn);
  vms_prompt.appendChild(vms_openbtn);
  // append the prompt so it gets visible
  document.body.appendChild(vms_prompt); 
  new Promise(function(resolve, reject) { 
	  vms_prompt.addEventListener('click', function handleButtonClicks(e) { //lets handle the buttons
	    if (e.target.tagName !== 'BUTTON') { return; } //nothing to do - user clicked somewhere else      
	      if (e.target === vms_cancelb) { //click on cancel-button
	        vms_prompt.removeEventListener('click', handleButtonClicks); //removes eventhandler on cancel or ok
	        document.body.removeChild(vms_prompt);  //as we are done clean up by removing the password-prompt
	        clearPendingCmd(); // clear any pending command
	      }
	      // selection buttons
	      if (e.target === vms_devbtn) { 
	        vmPromptSelect('dev');
	      }
	      if (e.target === vms_unifibtn) { 
	        vmPromptSelect('unifi');
	      }  
	      if (e.target === vms_cifsbtn) {
	        vmPromptSelect('legacy');
	      }  
	      if (e.target === vms_xanabtn) {
          if (arcState > 0) {
            if (arcState === 1) {
              serverAction('files-priv_region');
              serverSend();
              document.body.removeChild(vms_prompt); 
              clearPendingCmd();
            }
            if (arcState === 2) {
              serverAction('files-arc2_region');
              serverSend();
              document.body.removeChild(vms_prompt); 
              clearPendingCmd();
            }             
          } else {  
            vmPromptSelect('xana');
          }
	      }
	      // action buttons
	      if (e.target === vms_startbtn) { 
	        if (selectedVM !==  ""){
	          serverAction('start' + selectedVM);
	          serverSend();
	        }
	      }         
	      if (e.target === vms_stopbtn) { 
	        if (selectedVM !==  ""){
	          serverAction('stop' + selectedVM);
	          serverSend();
	        }           
	      }                 
	      if (e.target === vms_openbtn) { 
	        if (selectedVM === 'unifi'){
	          GoToExtPage('unifi.home:8443');
	        }           
	      } 
	      if (e.target === vms_restorebtn) { 
	        if (selectedVM !==  ""){
	          serverAction('restore' + selectedVM);
	          let _text = "Click send to confirm erase of " + selectedVM;
	          document.getElementById('vms__text').innerHTML = _text;
	        }           
	      }                        
	  });
  });   
}

function piWiFiPrompt(){
  let pinetprompt = document.createElement("div"); 
  pinetprompt.id= "pinet__prompt"; 
  // SSID text
  let pinettext1 = document.createElement("div"); 
  pinettext1.innerHTML = "Network (SSID):"; 
  pinetprompt.appendChild(pinettext1); 
  // SSID box 
  let pinetssidbox = document.createElement("input"); 
  pinetssidbox.id = "pinet__ssidbox"; 
  pinetprompt.appendChild(pinetssidbox); 
  // password text
  let pinettext2 = document.createElement("div"); 
  pinettext2.innerHTML = "Password:"; 
  pinetprompt.appendChild(pinettext2);   
  // password box
  let pinetpassbox = document.createElement("input"); 
  pinetpassbox.id = "pinet__passbox"; 
  pinetpassbox.type="password";
  pinetprompt.appendChild(pinetpassbox); 
  // save button
  let pinetokbutton = document.createElement("button"); 
  pinetokbutton.innerHTML = "Save";
  pinetokbutton.className ="button"; 
  pinetokbutton.type="button"; 
  // cancel button
  let pinetcancelb = document.createElement("button"); 
  pinetcancelb.innerHTML = "Cancel";
  pinetcancelb.className ="button"; 
  pinetcancelb.type="button"; 
  // create window
  pinetprompt.appendChild(pinetcancelb); 
  pinetprompt.appendChild(pinetokbutton); 
  document.body.appendChild(pinetprompt); 
  // focus on SSID text box
  pinetssidbox.focus();
  // control logic
  return new Promise(function(resolve, reject) {
  	function cancelWiFi(){
  		pinetssidbox.value = "";
  		pinetpassbox.value = "";
        document.body.removeChild(pinetprompt);
    }
  	function sendWiFiData(){
	    if (pinetssidbox.value === "") {
	      pinettext1.innerHTML = "enter SSID!";
	    } else {
	      if (pinetpassbox.value === "") {
	        pinettext1.innerHTML = "enter password!";
	      } else {
	      	// concat and convert to base64
	        let _wifidata = btoa(pinetssidbox.value + "|$|" + pinetpassbox.value);
	        resolve(_wifidata);
	        cancelWiFi();
	      }
	    }
    }
    // button clicks
    pinetprompt.addEventListener('click', function handleButtonClicks(e) { 
      if (e.target.tagName !== 'BUTTON') { return; }
        if (e.target === pinetokbutton) {
          sendWiFiData();
        }
        if (e.target === pinetcancelb) {
          cancelWiFi();
        }        
    });
    // key focused on SSID box
    pinetssidbox.addEventListener('keyup',function handleSSID(e){ 
        if(e.keyCode == 13){ //if user enters "enter"-key on password-field
          pinetpassbox.focus(); // focus on password field
        }else if(e.keyCode==27){ //user enters "Escape" on password-field
          cancelWiFi();
        }
    });
    // key focused on password box
    pinetpassbox.addEventListener('keyup',function handlePass(e){ 
        if(e.keyCode == 13){ //if user enters "enter"-key on password-field
          sendWiFiData();
        }else if(e.keyCode==27){ //user enters "Escape" on password-field
          cancelWiFi();
        }
    });
  }); 
}

function show_aboutPrompt(){
  let aboutprompt = document.createElement("div"); 
  aboutprompt.id= "about__prompt";
  // title
  let abouttext = document.createElement("div");
  abouttext.innerHTML = device + " Controller";
  aboutprompt.appendChild(abouttext); 
  // logo
  let img = document.createElement("img");
  img.src = "img/automate.png";
  img.id = "about__img";
  aboutprompt.appendChild(img);
  // version details
  let currentDate = new Date();
  let currentYear = currentDate.getFullYear();
  let aboutdets2 = document.createElement("div"); 
  aboutdets2.innerHTML = "Version: 3.7 (" + currentYear + ")";
  aboutdets2.className = "about__text";
  aboutprompt.appendChild(aboutdets2);
  // author details
  let aboutdets1 = document.createElement("div"); 
  aboutdets1.innerHTML = "by Ben Provenzano III";
  aboutdets1.className = "about__text";
  aboutprompt.appendChild(aboutdets1); 
  // cancel button
  let aboutcancelb = document.createElement("button");
  aboutcancelb.innerHTML = "Close";
  aboutcancelb.className ="button"; 
  aboutcancelb.id = "about__btn";
  aboutcancelb.type="button"; 
  aboutprompt.appendChild(aboutcancelb); //append cancel-button
  document.body.appendChild(aboutprompt); //append the password-prompt so it gets visible
  new Promise(function(resolve, reject) {
      aboutprompt.addEventListener('click', function handleButtonClicks(e) { //lets handle the buttons
        if (e.target.tagName !== 'BUTTON') { return; } //nothing to do - user clicked somewhere else
          aboutprompt.removeEventListener('click', handleButtonClicks); //removes eventhandler on cancel or ok
          document.body.removeChild(aboutprompt);  //as we are done clean up by removing the password-prompt
      });
  });   
}

async function aboutPrompt(){
  await show_aboutPrompt();
}

async function showPiWiFiPrompt(){
  let result;
  try {
    hideDropdowns();
    result = await piWiFiPrompt();
    if (result !== null) {  
      if (result !== '') {  
        sendCmd('main-www','confwpa',result);
        document.getElementById("logTextBox").value = "Wi-Fi configuration updated, select client mode to apply changes.";
      }
    } 
    result = "";
  } catch(e){
    result = "";
  }
}

function vmPromptSelect(_vm){
  let _text = "Select action for " + _vm + " VM:";
  // set top text
  document.getElementById('vms__text').innerHTML = _text;
  // hide existing buttons
  document.getElementById("vms__restorebtn").style.display = "none";
  document.getElementById("vms__openbtn").style.display = "none";
  // show actions buttons after selection
  document.getElementById("vms__startbtn").style.display = "inline-block";
  document.getElementById("vms__stopbtn").style.display = "inline-block";
  if ( _vm === "xana" ) { 
    document.getElementById("vms__restorebtn").style.display = "inline-block";
  }
  if ( _vm === "unifi" ) { 
    document.getElementById("vms__openbtn").style.display = "inline-block";
  }    
  selectedVM = _vm;
}

async function vmsPrompt(){
  await show_vmsPrompt("Select Virtual Machine:");
}

function show_wifiPwdPrompt(){
  let wifiprompt = document.createElement("div");
  wifiprompt.id = "wifi__prompt";
  let wifitext = document.createElement("div");
  wifitext.innerHTML = "Scan for WiFi Access:"; 
  wifiprompt.appendChild(wifitext);
  let img = document.createElement("img");
  img.src = "img/wifi.png";
  img.id = "wifi__img";
  wifiprompt.appendChild(img);
  let wifipwd = document.createElement("div");
  wifipwd.id = "wifi__pwdtxt";
  wifipwd.innerHTML = atob(SSIDpwd());
  wifiprompt.appendChild(wifipwd);
  let wificancelb = document.createElement("button");
  wificancelb.innerHTML = "Close";
  wificancelb.className = "button"; 
  wificancelb.type = "button"; 
  wificancelb.id = "wifipmt__btn";
  wifiprompt.appendChild(wificancelb);
  document.body.appendChild(wifiprompt);
  new Promise(function(resolve, reject) {
      wifiprompt.addEventListener('click', function handleButtonClicks(e) {
        if (e.target.tagName !== 'BUTTON') { return; }
	        wifiprompt.removeEventListener('click', handleButtonClicks);
	        document.body.removeChild(wifiprompt);
      });
  });   
}

async function wifiPrompt(){
  await show_wifiPwdPrompt();
}

function passwordPrompt(){
  let pwprompt = document.createElement("div"); //creates the div to be used as a prompt
  pwprompt.id= "pass__prompt"; //gives the prompt an id - not used in my example but good for styling with css-file
  let pwtextdiv = document.createElement("div"); //create the div for the password-text
  pwtextdiv.innerHTML = "Enter password:"; //put inside the text
  pwprompt.appendChild(pwtextdiv); //append the text-div to the password-prompt
  let pwinput = document.createElement("input"); //creates the password-input
  pwinput.id = "pass__textbox"; //give it some id - not really used in this example...
  pwinput.type="password"; // makes the input of type password to not show plain-text
  pwprompt.appendChild(pwinput); //append it to password-prompt
  let pwokbutton = document.createElement("button"); //the ok button
  pwokbutton.innerHTML = "Send";
  pwokbutton.className ="button"; 
  pwokbutton.type="button"; 
  let pwcancelb = document.createElement("button"); //the cancel-button
  pwcancelb.innerHTML = "Cancel";
  pwcancelb.className = "button"; 
  pwcancelb.type = "button"; 
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
  let result;
  try{
    hideDropdowns();
    result = await passwordPrompt();
    if (result !== null) {  
      if (result !== '') {  
        savePOST('pwd',[result]);
      }
    } 
    result = "";
  } catch(e){
    result = "";
  }
}

function relaxSend(_cmd) {
  sendCmd('main','relax',_cmd);
}

// send server action
async function serverSend() {
  if (serverCmdData === null) {
    document.getElementById("logTextBox").value = "select an option.";
  } else {
    // send command
    if (device === defaultSite) {
      sendCmd('main','server',serverCmdData);
    } else {
      sendCmd('main-www','server',serverCmdData);
    }
    // display command sent
    document.getElementById("logTextBox").value += "\n"+ serverCmdData + " command sent.";
    // scroll to bottom of page
    let txtArea = document.getElementById("logTextBox");
    txtArea.scrollTop = txtArea.scrollHeight;
    // animations
    loadBar(2.5);
    sendBtnAlert("off");
  }  
  serverCmdData = null;
}

function sendBtnAlert(state) {
  let _elmid;
  if (device === 'LCDpi') {
    _elmid = "sendButtonLCDpi";
  } else {
    _elmid = "sendButton";
  }
  let _elem = document.getElementById(_elmid);
  if (state === 'off') {
    _elem.classList.remove("button-alert");
  }
  if (state === 'on') {  
    _elem.classList.add("button-alert");
  }
}

// clear a pending server command 
function clearPendingCmd() {
  sendBtnAlert("off");
  serverCmdData = null;
  arcState = 0;
}

// transmit command
function sendCmd(act, arg1, arg2) {
  // construct API string
  const url = location.protocol+"//"+location.hostname+"/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
  // send data
  fetch(url, {
    method: 'GET',
  })
}

// volume controls
function sendVol(_cmd) {
  // volume mode
  if (ctlState === 0 ){
    sendCmd('main',_cmd+'f',''); // living room system 
  }
  if (ctlState === 1 ){
    sendCmd('main','v'+_cmd,'bedroom'); // bedroom system
  }
  if (ctlState === 2 ){
    sendCmd('main','v'+_cmd,'subs'); // living room subwoofers
  }
}

// controls menu actions
function ctlsMenu(_mode) {
  classDisplay('submode','none');
  if ((_mode === 'lr') || (_mode === 'subs')) { // living room
    classDisplay('bedroom-grid','none');
    classDisplay('hifi-grid','block');
    if (_mode === 'lr') { // normal mode
      ctlState = 0; 
    }
    if (_mode === 'subs') { // subwoofer mode
      classDisplay('submode','inline-block');
      ctlState = 2; 
    }
  } 
  if (_mode === 'br') { // bedroom
    classDisplay('hifi-grid','none');
    classDisplay('bedroom-grid','block');
    ctlState = 1;
  }
  // save state 
  localStorage.setItem("ctls-mode", _mode);
}

// controls menu dropdown
function showCtlsMenu() {
  if (ctlState === 0 ) { // living room 
    showMenu('ctls-menu-lr');
  }
  if (ctlState === 1 ) { // bedroom
    showMenu('ctls-menu-br');
  }
  if (ctlState === 2 ) { // subwoofers
    showMenu('ctls-menu-sub');
  }
}

// toggle dropdown menu's
function showMenu(_menu) {
  let _elem = document.getElementById(_menu);
  if (_elem.style.display === 'block') {
    _elem.style.display = 'none';
  } else {
    hideDropdowns();
    _elem.style.display = 'block';
  }
}

//// Bookmarks Menu ////

function hideBookmarks() {
  // close edit / add window
  closeFavEditPrompt();
  // hide bookmark edit/add buttons
  classDisplay("bookmark-buttons","none");
  // reset color of menu
  const elem = document.getElementById("bookmarks");
  if (elem) {
    elem.classList.remove("bookmark-editmode");
  }
  // reset bookmarks state flag 
  bookmarkState = 0;
}

function showBookmarks() {
  // hide menu if clicked while open
  if (bookmarkState != 0) {
    hideDropdowns();
    return;
  }
  // draw menu
  showDynMenu('bookmarks');
  // show add / edit buttons
  classDisplay("bookmark-buttons","block");
  // link open mode
  bookmarkState = 1;
}

function editBookmark() {
  // hide menu if clicked while open
  if (bookmarkState == 2) {
    hideDropdowns();
    return;
  }
  enableEditAddMode();
}

function addBookmark() {
  enableEditAddMode();
  // create new unique menu ID
  const _newid = fileData.length;
  // add temporary entry to menu array
  fileData.push("placeholder");
  // create placeholder menu item
  const _name = "New Bookmark";
  const navElement = document.getElementById('bookmarks');
  const _elm = document.createElement('a');
  _elm.id = "menu-" + _newid;
  _elm.innerText = _name;
  _elm.classList.add('bookmarked__item');
  // store URL
  Object.defineProperty(_elm, "url", {
    enumerable: false,
    writable: true,
    value: "about:blank"
  });
  // define click action
  _elm.addEventListener("click", function(event) {
    clickBookmark(_newid);
  });
  // highlight selected item
  _elm.classList.add("dd-selected");
  navElement.insertBefore(_elm,navElement.firstChild);
  // add new window
  showFavEditPrompt('add',null,null,_elm);
}

function enableEditAddMode () {
  const elem = document.getElementById("bookmarks");
  if (elem) { // change color of menu
    elem.classList.add("bookmark-editmode");
  } 
  bookmarkState = 2;
  closeFavEditPrompt();
}

function clickBookmark(id) {
  const elmid = "menu-" + id.toString();
  const elem = document.getElementById(elmid);
  const url = Object.values(elem.url).join("");
  const name = elem.innerText;
  if (elem) { 
    if (bookmarkState == 1) {
      if (!(url == null || url == "" || url == "about:blank")) {
        // open URL in new tab
        window.open(url, "_blank");
      }
    }
    if (bookmarkState == 2) {
      // edit bookmark item
      closeFavEditPrompt();
      elem.classList.add("dd-selected"); // highlight selected item
      showFavEditPrompt('edit',url,name,elem);
    }
  }
}

function closeFavEditPrompt() {
  const favPrompt = document.getElementById("editFav__prompt");
  if (favPrompt) {
    favPrompt.remove();
  }
  // un-highlight selected item
  for (var idx = 0; idx < fileData.length; idx++) {
    if (idx !== 0) { // skip menu ID
      const _menuid = "menu-" + idx.toString();
      const elem = document.getElementById(_menuid);
      if (elem) {
        if(elem.classList.contains('dd-selected')) {
          elem.classList.remove("dd-selected");
        }
      }
    }
  }
}

function showFavEditPrompt(type,url,name,elem){
  let bannerText;
  let defaultTextBoxURL;
  let defaultTextBoxName;
  if (type === 'edit') { // edit mode 
    bannerText = "Edit Bookmark";
  }
  if (type === 'add') { // add new mode
    bannerText = "Add Bookmark";
    defaultTextBoxURL = "Enter URL";
    defaultTextBoxName = "Enter Name";
  }
  // create empty window
  let editFavPrompt = document.createElement("div"); 
  editFavPrompt.id = "editFav__prompt";
  editFavPrompt.className = "editfav__window"; 
  // window banner text
  let editFavText = document.createElement("div"); 
  editFavText.className = "editfav__window editFav__text";
  editFavText.innerHTML = bannerText; 
  // Link name edit box
  let editFavName = document.createElement("input"); 
  editFavName.type = "text";
  editFavName.value = name;
  editFavName.placeholder = defaultTextBoxName;
  editFavName.className = "editfav__window editFav__textbox";
  // URL edit box
  let editFavURL = document.createElement("input"); 
  editFavURL.type = "text";
  editFavURL.value = url;
  editFavURL.placeholder = defaultTextBoxURL;
  editFavURL.className = "editfav__window editFav__textbox";
  // cancel button
  let editFavCancelBtn = document.createElement("button");
  editFavCancelBtn.innerHTML = '<i class="fa-solid fa-ban"></i>';
  editFavCancelBtn.className = "button editfav__window editFav__cancelbtn"; 
  editFavCancelBtn.type = "button"; 
  // save button
  let editFavSaveBtn = document.createElement("button");
  editFavSaveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i>';
  editFavSaveBtn.className = "button editfav__window editFav__button"; 
  editFavSaveBtn.type = "button"; 
  // delete button
  let editFavDeleteBtn = document.createElement("button");
  editFavDeleteBtn.innerHTML = '<i class="fa-solid fa-trash-can"></i>'  
  editFavDeleteBtn.className = "button editfav__window editFav__button";
  editFavDeleteBtn.type = "button";
  // up button
  let editFavUpBtn = document.createElement("button");
  editFavUpBtn.innerHTML = '<i class="fa-solid fa-arrow-up"></i>';
  editFavUpBtn.className = "button editfav__window editFav__button"; 
  editFavUpBtn.type = "button"; 
  // down button
  let editFavDownBtn = document.createElement("button");
  editFavDownBtn.innerHTML = '<i class="fa-solid fa-arrow-down"></i>';
  editFavDownBtn.className = "button editfav__window editFav__button"; 
  editFavDownBtn.type = "button"; 
  // append elements to window
  editFavPrompt.appendChild(editFavText);
  editFavPrompt.appendChild(editFavName); 
  editFavPrompt.appendChild(editFavURL); 
  editFavPrompt.appendChild(editFavUpBtn); 
  editFavPrompt.appendChild(editFavSaveBtn); 
  editFavPrompt.appendChild(editFavDownBtn);
  editFavPrompt.appendChild(editFavDeleteBtn); 
  editFavPrompt.appendChild(editFavCancelBtn);  
  // display window on page
  document.body.appendChild(editFavPrompt); 
  // handle button actions
  new Promise(function(resolve, reject) {
      editFavPrompt.addEventListener('click', function handleButtonClicks(e) { 
        if (e.target.tagName !== 'BUTTON') { return; }
          // cancel button action
          if (e.target === editFavCancelBtn) {
            editFavPrompt.removeEventListener('click', handleButtonClicks);
            hideDropdowns();
          }
          // common save / delete actions
          if (e.target === editFavDeleteBtn || e.target === editFavSaveBtn) {
            // do not allow empty name or URL
            if (e.target === editFavSaveBtn) {
              if (editFavURL.value == null || editFavURL.value == "" || 
                editFavName.value == null || editFavName.value == "") {
                  editFavText.innerHTML = "Enter URL & Name";
                  return;
              }    
            }
            // remove buttons
            editFavPrompt.removeChild(editFavUpBtn); 
            editFavPrompt.removeChild(editFavDownBtn); 
            editFavPrompt.removeChild(editFavDeleteBtn); 
            editFavPrompt.removeChild(editFavSaveBtn); 
            editFavCancelBtn.innerHTML = "Close"; 
            // set text read-only
            editFavName.readOnly = true;
            editFavURL.readOnly = true;
            // delete action
            if (e.target === editFavDeleteBtn) {
              editFavName.style.textDecoration = 'line-through';
              editFavURL.style.textDecoration = 'line-through';
              // remove element from menu
              elem.remove();
              editFavText.innerHTML = "Bookmark Deleted"; 
            }
            // save action
            if (e.target === editFavSaveBtn) {
              // update changed values
              if (elem) { // replace pipes
                elem['url'] = editFavURL.value.replaceAll("|", "-");
                elem.innerText = editFavName.value.replaceAll("|", "-");
                editFavText.innerHTML = "Changes Saved"; 
              }
            }
            // save to file
            saveBookmarks();
          }        
          // move up button action
          if (e.target === editFavUpBtn) {
            shiftMenuUp(elem);
          }
          // move down button action
          if (e.target === editFavDownBtn) {
            shiftMenuDown(elem);
          }    
      });
  });   
}

function shiftMenuUp(elem) {
  if (elem) {
    if(elem.previousElementSibling)
      elem.parentNode.insertBefore(elem, elem.previousElementSibling);
  }
}

function shiftMenuDown(elem) {
  if (elem) {
    if(elem.nextElementSibling)
      elem.parentNode.insertBefore(elem.nextElementSibling, elem);
  }
}

function saveBookmarks() {
  let _file = "";
  // loop through edited bookmarks
  [...document.getElementsByClassName('bookmarked__item')].forEach(elem => {
    if (elem) {
      const url = Object.values(elem.url).join("");
      const name = elem.innerText;
      // build output file
      _file += url + "|2|" + name + "\n";
    }
  })
  // transmit file
  savePOST('bookmarks',[_file]);
  // animations
  loadBar(1.0);
}

//// Dynamic Menus ////

function showDynMenu(_menu) {
  let _elem = document.getElementById(_menu);
  if (_elem.style.display === 'block') {
    _elem.style.display = 'none';
  } else {
    hideDropdowns();
    // read menu data from file
    readMenuData(_menu);
    _elem.style.display = 'block';
  }
}

// build menu
function readMenuData(menu) {
  // build URL / append data
  const url = location.protocol+"//"+location.hostname+"/exec.php?var=&arg="+menu+"&action=read";
  // read file action
  fetch(url, {
      method: 'GET'
    })
    .then(res => {
      return res.json()
    })
    .then((response) => {
      // clear global data
      while (fileData.length) { fileData.pop(); }
      // load JSON to global data
      fileData[0] = menu;
      for(var i in response) {
        let _line = response[i].toString();
        // ignore empty lines
        if (_line) {
          if (_line !== "") {
            fileData.push(_line);
          }
        }
      }
      // action after loading
      fileLoadAction(menu);
    })
}

function fileLoadAction(_menu) {
  // LED options menu
  let _id = null;
  // loop through menu items
  for (var idx = 0; idx < fileData.length; idx++) {
    let line = fileData[idx].toString();
    if (idx == 0) { // store first line (ID)
      _id = line;
    } else { // verify data matches
      if (_id == _menu) {
        const item = line.split("|");
        const _col0 = item[0];
        const _col1 = item[1];
        const _col2 = item[2].trim();
        // 0=Host, 1=Type, 2=Name, Menu Name, Item Index
        drawMenu(_col0,_col1,_col2,_menu,idx);
      }
    }
  }  
}

// draws each menu item
function drawMenu(col0,col1,col2,menu,id) {
  const navElement = document.getElementById(menu);
  // draw menu item
  navElement.appendChild(createListItem(col0,col1,col2,id));
  dynMenuActive = 1;
}

function createListItem(_col0,_col1,_col2,_id) {
  const _elm = document.createElement('a');
  // add elements to menu
  _elm.id = "menu-" + _id.toString();
  _elm.innerText = _col2;
  // checkbox menu
  if (_col1 == '0' || _col1 == '1') {
    const _cbox = document.createElement('input');
    _cbox.type = "checkbox";
    _cbox.className = "chkbox";
    _cbox.id = "chkbox-" + _col2;
    // read checkbox state from file
    if (_col1 == '0') {
      _cbox.checked = false;
    }
    if (_col1 == '1') {
      _cbox.checked = true;
    }
    _elm.appendChild(_cbox);
    // URL on click
    _elm.href = _col0;
    // a checkbox was clicked
    _elm.addEventListener('click', function(event) {
      if (event.target.classList.contains('chkbox')) {
        dynChkboxChanged = 1;
      }
    });
  }
  // bookmarks menu  
  if (_col1 == '2') {
    _elm.classList.add('bookmarked__item');
    // store URL
    Object.defineProperty(_elm, "url", {
      enumerable: false,
      writable: true,
      value: _col0
    });
    // define click action
    _elm.addEventListener("click", function(event) {
      clickBookmark(_id);
    });
  }
  // indicator / status menu  
  if (_col1 == '3' || _col1 == '4' || _col1 == '5') {
    const _dot = document.createElement('span');
    _dot.classList.add('ind_dot');
    if (_col1 == '4'){
      _dot.classList.add('ind_dot_green');
    }
    if (_col1 == '5'){
      _dot.classList.add('ind_dot_red');
    }
    _dot.id = "ind-" + _col2;
    _elm.appendChild(_dot);
  }
  // theme menu  
  if (_col1 == '8') {
    const _color = _col0;
    _elm.classList.add('theme-colorbox');
    _elm.style.setProperty('background-color', _color);
    _elm.addEventListener("click", function(event) {
      setTheme(_color);
    });
  }
  return _elm;
}

function removeDynMenus() {
  // only if menu is on-screen 
  if (dynMenuActive == 1) {
    // checkbox changed action (I)
    if (dynChkboxChanged == 1) {
      boxChanged();
    }
    // remove dynamic menu elements (II)
    for (var idx = 0; idx < fileData.length; idx++) {
      if (idx !== 0) { // skip menu ID
        const _menuid = "menu-" + idx.toString();
        const menuRemove = document.getElementById(_menuid);
        if (menuRemove != null) {
          menuRemove.remove();
        }
      }
    }
    if (dynChkboxChanged == 1) {
      // write checkbox changes to file (III)
      const id = fileData[0];
      updateMenuData(id);
      dynChkboxChanged = 0;
    }  
    dynMenuActive = 0;
  }
}

function boxChanged() {
  // loop through checkbox's state
  let id = null;
  for (var i = 0; i < fileData.length; i++) {
    let line = fileData[i].toString();
    if (i == 0) { // store menu ID
      id = line;
    } else {  
      // split up into array (host,state,name)
      const linearr = line.split("|");
      if (linearr) {
        // only write box state on 0/1 state items
        if (linearr[1] == '0' || linearr[1] == '1') {
          // read elements checkbox then write state
          const box = "chkbox-" + linearr[2].toString();
          var boxelm = document.getElementById(box);
          if (boxelm.checked === true) {
            linearr[1] = '1';
          } else {
            linearr[1] = '0';
          }
        }
        // build new data
        let _outstr = linearr.join('|')
        // replace existing data
        fileData[i] = _outstr;
      }
    }
  }
}

// API call POST (update menu file)
function updateMenuData(file) {
  let id = "";
  // store ID object
  id = fileData[0];
  // remove first ID object
  fileData.shift();
  // verify correct menu is in array
  if (id === file) {
    savePOST(file,fileData);
  }
  // clear global data
  while (fileData.length) { fileData.pop(); }      
}

//// End Dynamic Menus ////

// save file API POST call
function savePOST(file,data) {
  const url = location.protocol+"//"+location.hostname+"/exec.php?var=&arg="+file+"&action=update";
  // convert data to JSON object
  let _json = JSON.stringify(data);
  // Send data as HTTP POST request
  const xhr = new XMLHttpRequest();
  xhr.open("POST", url);
  xhr.setRequestHeader("Content-Type", "text/plain");
  xhr.onreadystatechange = function() {
    if (xhr.readyState === XMLHttpRequest.DONE) {
      if (xhr.status == 200) {
        // action on successful transmit
        if (file === 'message') {
          sendCmd('main','message','');
        }
        if (file === 'pwd') {
          serverAction('attach_bkps');
          serverSend(0);
        }
      }
      if (xhr.status !== 200) {
        console.log("failed to send POST: savePOST("+file+")");
      }
    }
  }
  xhr.send(_json);
}

// load entire text file
async function loadLog(file) {
  try {
    // build URL / append data
    let _textData = " ";
    const url = location.protocol+"//"+location.hostname+"/exec.php?var=&arg="+file+"&action=read";
    // read file action
    fetch(url, {
      method: 'GET'
    })
    .then(res => {
      return res.json()
    })
    .then((response) => {
      // load JSON to text buffer
      for(var i in response) {
        let _line = response[i].toString();
        // ignore empty lines
        if (_line) {
          if (_line !== "") {
             _textData += _line; 
             _textData += '\n'; 
          }
        }
      }
      // display text on page
      const elmid = "logTextBox";
      document.getElementById(elmid).value = _textData;
      // scroll to bottom of page
      let txtArea = document.getElementById(elmid);
      txtArea.scrollTop = txtArea.scrollHeight;
    })
  } catch (err) {
    console.log(err);
  }
  serverCmdData = null;
}

// load server action 
function serverAction(cmd) {
  if (cmd === 'files-ext_region') {
    arcState = 1;
  }
  if (cmd === 'files-snap_region') {
    arcState = 2;
  }
  serverCmdData = cmd;
  // change color of send button
  sendBtnAlert("on");
}

function openLogWindow() {
  // open server log window
  closePopup();
  // show log form window
  document.getElementById("logTextBox").value = "select an option.";
  document.getElementById("logForm").style.display = "block";
}

function openCamWindow() {
  closePopup();
  // show camera form window
  document.getElementById("camForm").style.display = "block";
  document.getElementById("cam-iframe").src = "/cam1";
}

function closePopup() {
  // close all popup windows
  document.getElementById("logForm").style.display = "none";
  document.getElementById("camForm").style.display = "none";
  document.getElementById("cam-iframe").src = "about:blank";
  clearPendingCmd();
}

function closeSendbox() {
  // close all popup windows
  document.getElementById("sendForm").style.display = "none";
  clearPendingCmd();
}

function openSendWindow() {
  // open send text window
  closeSendbox();
  document.getElementById("sendForm").style.display = "block";
}

function sendText() {
  const data = document.getElementById("lcdTextBox").value;
  const sendtext = "enter a message before sending.";
  if (data.trim() === "" || data === sendtext) {
    document.getElementById("lcdTextBox").value = sendtext;
  } else {
    if (device === defaultSite) {
      sendCmd('main','lcdpimsg',data);
    } else {
      // Create the HTTP POST request
      savePOST('message',[data]);  
    }
    loadBar(0.25);
    clearText();   
  }
}

function clearText() {
  // clear text window
  document.getElementById("lcdTextBox").value = "";
  clearPendingCmd();
}

// loading bar animation 
async function loadBar(_interval) {
  if (loadBarState === 0) {
    loadBarState = 1;
    let elem = document.getElementById("load__bar");
    elem.textContent = " ";  
    let width = 1;
    let id = setInterval(frame, _interval);
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
        elem.textContent = defaultSite;  
      }
    }
  }
}

function hexToRgb(hex) {
  // Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
  let shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
  hex = hex.replace(shorthandRegex, function(m, r, g, b) {
      return r + r + g + g + b + b;
  });
  let result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? {
      r: parseInt(result[1], 16),
      g: parseInt(result[2], 16),
      b: parseInt(result[3], 16)
  } : null;
}

function updateSettings(_hexin) {
  let _proto = 'wss://';
  let color;
  if (location.protocol === 'http:'){
    _proto = 'ws://';
  }
  _host = _proto + location.hostname + ":7890";
  // Connect to a Fadecandy server
  socket = new WebSocket(_host);
  socket.onopen = function(event) {
    color = hexToRgb(_hexin);
    let rounds = 32;
    for (let i = 0; i < rounds; i++) {
        writeFrame(
        color.r,
        color.g,
        color.b);
    }           
  }
}

// Set all pixels to a given color
function writeFrame(red, green, blue) {
  let leds = 512;
  let packet = new Uint8ClampedArray(4 + leds * 3);
  if (socket.readyState != 1 /* OPEN */) {
      // The server connection isn't open. Nothing to do.
      return;
  }
  if (socket.bufferedAmount > packet.length) {
      // The network is lagging, and we still haven't sent the previous frame.
      // Don't flood the network, it will just make us laggy.
      // If fcserver is running on the same computer, it should always be able
      // to keep up with the frames we send, so we shouldn't reach this point.
      return;
  }
  // Dest position in our packet. Start right after the header.
  let dest = 4;
  // Sample the center pixel of each LED
  for (let i = 0; i < leds; i++) {
      packet[dest++] = red;
      packet[dest++] = green;
      packet[dest++] = blue;
  }
  socket.send(packet.buffer);
}

async function colorPrompt(){
  if (device === defaultSite) {
    sendCmd('leds','randcolor','');
  } else {
    hideDropdowns();
    if (colorPromptActive === 0) {
      await show_colorPrompt("Pick a color:");
    } 
  }
}

function show_colorPrompt(text){
  colorPromptActive = 1; 
  let colorprompt = document.createElement("div"); //creates the div to be used as a prompt
  colorprompt.id= "color__prompt"; //gives the prompt an id - not used in my example but good for styling with css-file
  let colortext = document.createElement("div"); //create the div for the password-text
  colortext.innerHTML = text; //put inside the text
  colortext.id = "color__text";
  colorprompt.appendChild(colortext); //append the text-div to the prompt
  // the cancel-button
  let colorcancelb = document.createElement("button"); 
  colorcancelb.innerHTML = "Close";
  colorcancelb.className ="button"; 
  colorcancelb.type="button"; 
  colorprompt.appendChild(colorcancelb); //append cancel-button
  // the set color-button
  let colorsetb = document.createElement("button"); 
  colorsetb.innerHTML = "Apply";
  colorsetb.className ="button"; 
  colorsetb.type="button"; 
  colorprompt.appendChild(colorsetb); //append set-button
  // color selector box
  let colorinput = document.createElement("input");
  colorinput.id = "color__box";
  colorinput.name = "color";
  colorinput.type = "color";
  colorinput.value = "#000000";
  colorprompt.appendChild(colorinput);
  // append the password-prompt so it is visible
  document.body.appendChild(colorprompt); 
  let _colorval;
  new Promise(function(resolve, reject) {
      colorinput.addEventListener('input', function () {
        _colorval = colorinput.value; // save color values
      });
      colorprompt.addEventListener('click', function handleButtonClicks(e) { //lets handle the buttons
        if (e.target.tagName !== 'BUTTON') { return; } //nothing to do - user clicked somewhere else
        if (e.target === colorsetb) { 
          // set button action
          updateSettings(_colorval);
        } else { // close button
          colorprompt.removeEventListener('click', handleButtonClicks);
          document.body.removeChild(colorprompt);  //as we are done clean up by removing the-prompt
          colorPromptActive = 0;
        }  
      });
  });   
}



