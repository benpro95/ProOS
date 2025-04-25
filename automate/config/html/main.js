// Automate Website - JavaScript Frontend
// by Ben Provenzano III

// global variables //
let ctlMode;
let ctlCommand = 0;
let selectedVM = "";
let dynMenuActive = 0;
let dynChkboxChanged = 0;
let colorPromptActive = 0;
let resizeState = false;
let bookmarkState = 0;
let loadBarState = 0;
let serverCmdData;
let socket = null;
let fileData = [];
let cmdOutput = [];
var timeStamp;
let sysModel;

// global constants
let resizeTimeout = 800; // in ms
let serverSite = "Automate";
let siteVersion = "5.8";

//////////////////////

// runs after DOM finishes loading
window.addEventListener("DOMContentLoaded", () => {
  // on-click actions
  window.addEventListener('click', handleClicks, false);
  // load content
  loadPage();
});

// runs on-each mouse click
function handleClicks(event) {
  // disable click events when in bookmark edit mode
  if (bookmarkState === 2) {
    if (event.target.className !== "editFav__win") {
      event.stopPropagation(); // disable clicks
    }
    return;
  }
  // don't hide menus when clicking these elements
  if (!(event.target.classList.contains('button') || // button click
        event.target.classList.contains('button__text') || // button text click
        event.target.classList.contains('mainmenu__anchor') || // main menu click
        event.target.classList.contains('bookmarked__item') || // bookmark menu click
        event.target.classList.contains('fa-regular') || // font -
        event.target.classList.contains('fa-brands') ||  // awesome -
        event.target.classList.contains('fa-solid') ||   // icon clicks
        event.target.classList.contains('am-spinner') || // spinner clicks
        event.target.classList.contains('dropbtn') || // dropdown button click
        event.target.classList.contains('chkbox'))) { // checkbox click
    hideDropdowns(); // hide all dropdown menus
  }
}

// runs on page load
function loadPage() {
  // read device type
  sysModel = deviceType(); 
  if (sysModel === serverSite) {
    // load control menu
    let _mode = localStorage.getItem("ctls-mode")
    if (_mode === null || _mode === undefined || _mode === "") {
      ctlMode = 'lr'; // living room 
    } else {
      ctlMode = _mode;
    }  
    ctlsMenu(ctlMode);
    // server home page
    classDisplay('server-grid','block');
  } else { // pi's
    if (sysModel === 'Pi') {
      classDisplay('pi-grid','block');
    }  
    if (sysModel === 'LEDpi') {
      classDisplay('ledpi-grid','block');
    }
  }
  // set title
  let currentTheme;
  let elem = document.getElementById("load__bar");
  elem.textContent = serverSite;
  // set theme
  let _theme = localStorage.getItem("main-color")
  if (_theme === null || _theme === undefined || _theme === "") {
    currentTheme = "#1f2051"; // dark blue
  } else {
    currentTheme = localStorage.getItem("main-color");
  }  
  setTheme(currentTheme);
  // not on Safari
  if (!(navigator.vendor.match(/apple/i))) {
    setTimeout(function() {
      // enable stars animation 
      starsAnimation(true);
      // pause stars animation on window resize
      window.addEventListener("resize", function() {
        resizeEvent(); // on window resize
      });
    }, resizeTimeout);
  }
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
  classDisplay('server-grid','none');
  classDisplay('ledpi-grid','none');
  classDisplay('led-grid','none');
}

function hideDropdowns() {
  // hide all dropdown menus
  classDisplay("dd-content","none");
  // hide bookmark menus
  hideBookmarks();
  // remove any current dynamic menus
  removeDynMenus();
}

// show / hide multiple classes
function classDisplay(_elem, _state) {
  let _itr;
  let _class = document.getElementsByClassName(_elem);
  for (_itr = 0; _itr < _class.length; _itr++) {
    _class[_itr].style.display = _state;
  }
}

// back to home page 
function GoToHomePage() {
  if (sysModel === serverSite) {
    hidePages();
    loadPage();
  } else {
    window.location = 'https://'+serverSite+'.home';   
  }
}

function GoToExtPage(_path) {
  window.location = "https://"+_path;   
}

function GotoSubURL(_path) {
  closePopup();
  window.location = location.protocol+"//"+location.hostname+"/"+_path;
}

/// stars animation ///

function resizeEvent() {
  timeStamp = new Date();
  if (resizeState === false) {
    // resize event started
    resizeState = true;
    setTimeout(resizeDone, resizeTimeout);
    // disable stars animation 
    starsAnimation(false);
  }
}

function resizeDone() {
  // detect when resize event completes
  if (+new Date() - +timeStamp < resizeTimeout) {
    setTimeout(resizeDone, resizeTimeout);
  } else {
    // resize event completed
    resizeState = false;
    // re-enable stars animation
    starsAnimation(true);
  }               
}

function starsAnimation(_state) {
  // animated stars background
  let _itr;
  for (_itr = 1; _itr <= 12; _itr++) {
    let _elm = "star-" + _itr;
    let _class = "star-a-" + _itr;
    if (_state === true) {
      elemToClass('show',_elm,_class);
    } else {
      elemToClass('hide',_elm,_class);
    }
  }
}

// returns (true) if object is empty
function isObjEmpty(obj) {
  var isEmpty = true;
  for (keys in obj) {
     isEmpty = false;
     break;
  }
  return isEmpty;
}

// transmit a command
function sendCmd(act, arg1, arg2) {
  // construct API URL
  const url = location.protocol+"//"+location.hostname+"/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
  // send request 
  return fetch(url, {
    method: 'GET'
  }) 
  // process JSON response
  .then(response => {
  return response.json().then((obj) => {
      var out = null;
      var empty = isObjEmpty(obj);
      if (empty === false) {
        out = obj.toString();
      } // return string
      return out;
    }).catch((err) => {
      console.log('sendCmd: ' + err);
    })
  });
}

/// text popup window ///

// send server action
async function serverSend() {
  if (serverCmdData === null) {
    // load log data
    document.getElementById("logTextBox").value = "select an option.";
  } else {
    // send command
    if (sysModel === serverSite) {
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
  }
  sendBtnAlert("off");
  serverCmdData = null;
  closeServerOptions();
}

function sendBtnAlert(state) {
  let _class = "button_alert";
  let _elem = "sendButton";
  if (state === 'off') {
    elemToClass('hide',_elem,_class);
  }
  if (state === 'on') {
    elemToClass('show',_elem,_class);
  }
}

// clear pending server command 
function clearPendingCmd() {
  sendBtnAlert("off");
  serverCmdData = null;
}

function openServerOptions(){
  closeServerOptions();
  classDisplay("svropt__prompt","block");
  classDisplay("svropt__main","block");
}

function openRegionsOptions(){
  closeServerOptions();
  classDisplay("svropt__prompt","block");
  classDisplay("svropt__regions","block");
}

function openBackupOptions(){
  closeServerOptions();
  classDisplay("svropt__prompt","block");
  classDisplay("svropt__backup","block");
}

function closeServerOptions(){
  hideDropdowns();
  clearPendingCmd();
  classDisplay("svropt__prompt","none");
  classDisplay("svropt__main","none");
  classDisplay("svropt__regions","none");
  classDisplay("svropt__backup","none");
}

/// END- text popup window ///

function piWiFiPrompt(){
  let pinetprompt = document.createElement("div"); 
  pinetprompt.className= "prompt__win"; 
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
  pinetokbutton.className ="button pinet__btn"; 
  pinetokbutton.type="button"; 
  // cancel button
  let pinetcancelb = document.createElement("button"); 
  pinetcancelb.innerHTML = "Cancel";
  pinetcancelb.className ="button pinet__btn"; 
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
  abouttext.innerHTML = sysModel + " Controller";
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
  aboutdets2.innerHTML = "Version: " + siteVersion + " (" + currentYear + ")";
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

function mountFUSEvolume() {
  let _elmvis = false;
  let _elem = document.getElementById('about__prompt');
  if (_elem) {
    var _style = window.getComputedStyle(_elem)
    if (_style.display !== 'none') {
      _elmvis = true;
    }
  }
  if (_elmvis === true) {
    serverAction('files-mnt_vol_region');
  } else {
    serverAction('files-mnt_arch_region');
  }
  serverSend(0);
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

function show_wifiPwdPrompt(){
  let wifiprompt = document.createElement("div");
  wifiprompt.id = "wifi__prompt";
  let wifitext = document.createElement("div");
  wifitext.innerHTML = "Scan for WiFi Access"; 
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
  pwprompt.className = "prompt__win"; //gives the prompt an id - not used in my example but good for styling with css-file
  let pwtextdiv = document.createElement("div"); //create the div for the password-text
  pwtextdiv.innerHTML = "Enter password:"; //put inside the text
  pwprompt.appendChild(pwtextdiv); //append the text-div to the password-prompt
  let pwinput = document.createElement("input"); //creates the password-input
  pwinput.id = "pass__textbox"; //give it some id - not really used in this example...
  pwinput.type="password"; // makes the input of type password to not show plain-text
  pwprompt.appendChild(pwinput); //append it to password-prompt
  // buttons 
  let pwbtndiv = document.createElement("div");
  pwbtndiv.id = "pass__prmbtnctr";
  let pwokbutton = document.createElement("button"); //the ok button
  pwokbutton.innerHTML = "Send";
  pwokbutton.className ="button pass__prompt_btn"; 
  pwokbutton.type="button"; 
  let pwcancelb = document.createElement("button"); //the cancel-button
  pwcancelb.innerHTML = "Cancel";
  pwcancelb.className = "button pass__prompt_btn"; 
  pwcancelb.type = "button"; 
  pwbtndiv.appendChild(pwcancelb); //append cancel-button first
  pwbtndiv.appendChild(pwokbutton); //append the ok-button
  pwprompt.appendChild(pwbtndiv); // append button center div to prompt div
  //append the password-prompt so it gets visible
  document.body.appendChild(pwprompt); 
  pwinput.focus(); //focus on the password-input-field so user does not need to click
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

async function getPassword(_type){
  let result;
  try{
    hideDropdowns();
    result = await passwordPrompt();
    if (result !== null) {  
      if (result !== '') {
        savePOST(_type,[result]);
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

// volume controls
function sendVol(_cmd) {
  // volume mode
  if (ctlCommand === 0 ){
    sendCmd('main',_cmd,''); // living room system 
  }
  if (ctlCommand === 1 ){
    sendCmd('main','br','vol'+_cmd); // bedroom system
  }
  if (ctlCommand === 2 ){
    sendCmd('main','sub'+_cmd,''); // living room subwoofers
  }
}

function subModeToggle() {
  // toggle subwoofer mode
  if (ctlCommand === 2 ){
    ctlsMenu('lr');
    return;
  }
  if (ctlCommand === 0 || ctlCommand === 1 ){
    ctlsMenu('subs');
    return;
  } 
}

// add / remove a class from a element
function elemToClass(_action,_elmid,_class) {
  let _elm = document.getElementById(_elmid);
  if (_action === 'show') {
    if (!(_elm.classList.contains(_class))) {
      _elm.classList.add(_class);
    }
  }
  if (_action === 'hide') {
    if (_elm.classList.contains(_class)) {
      _elm.classList.remove(_class);
    } 
  }
}

function subMode(_action) {
  // hide subwoofer mode indicator
  elemToClass(_action,'voldwnbtn','submode_btn');
  elemToClass(_action,'volmutebtn','submode_btn');
  elemToClass(_action,'volupbtn','submode_btn');
  elemToClass(_action,'subwooferbtn','submode_btn');
}

// controls menu actions
function ctlsMenu(_mode) {
  // living room controls
  if ((_mode === 'lr') || (_mode === 'subs')) {
    // disable bedroom grid
    classDisplay('bedroom-grid','none');
    // enable hifi grid
    classDisplay('hifi-grid','block');
    if (_mode === 'lr') {
      // hide subwoofer controls 
      subMode('hide');
      // hifi controls
      ctlCommand = 0;
    } else {
      // subwoofer controls
      subMode('show');
      ctlCommand = 2; 
    }
  } 
  // bedroom controls
  if (_mode === 'br') { 
    // disable hifi grid
    classDisplay('hifi-grid','none');
    // hide subwoofer controls 
    subMode('hide');
    // enable bedroom grid
    classDisplay('bedroom-grid','block');
    ctlCommand = 1;
  }
  // save state 
  localStorage.setItem("ctls-mode", _mode);
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
  closeBookmarkPrompt();
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
  let _newid;
  const _datalen = fileData.length;
  if (_datalen <= 1) {
    if (_datalen == 1) {
      _newid = 1;
    } else {
      _newid = 0;
    }
  } else {
    _newid = _datalen - 1;
  }
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
  drawBookmarkPrompt(true,null,null,_elm);
}

function enableEditAddMode() {
  const elem = document.getElementById("bookmarks");
  if (elem) { // change color of menu
    elem.classList.add("bookmark-editmode");
  } 
  bookmarkState = 2;
  closeBookmarkPrompt();
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
      closeBookmarkPrompt();
      elem.classList.add("dd-selected"); // highlight selected item
      drawBookmarkPrompt(false,url,name,elem);
    }
  }
}

async function drawBookmarkPrompt(add,url,name,elem){
  // create empty window
  let editFavPrompt = document.createElement("div"); 
  editFavPrompt.className = "editFav__win";
  editFavPrompt.id = "editFav__prompt";
  // Link name edit box
  let editFavName = document.createElement("input"); 
  editFavName.type = "text";
  editFavName.value = name;
  editFavName.autocorrect = "off";
  editFavName.autocapitalize = "none"; 
  editFavName.id = "editFav__namebox";
  editFavName.classList.add("editFav__textbox");
  // URL edit box
  let editFavURL = document.createElement("input"); 
  editFavURL.type = "text";
  editFavURL.value = url;
  editFavURL.autocorrect = "off";
  editFavURL.autocapitalize = "none";
  editFavURL.id = "editFav__urlbox";
  editFavURL.classList.add("editFav__textbox");
  let bannerText;
  if (add === true) { // add new mode
    bannerText = "Add Bookmark";
    editFavName.placeholder = "Enter Name";
    editFavURL.placeholder = "Enter URL";
  } else { // edit mode 
    bannerText = "Edit Bookmark";
  }
  // window banner text
  let editFavText = document.createElement("div");
  editFavText.classList.add("editFav__text");
  editFavText.innerHTML = bannerText; 
  // cancel button
  let editFavCancelBtn = document.createElement("button");
  editFavCancelBtn.classList.add("editFav__button");
  editFavCancelBtn.classList.add("button");
  editFavCancelBtn.classList.add("fa-solid");
  editFavCancelBtn.classList.add("fa-ban");
  editFavCancelBtn.type = "button";
  // lookup favorites
  let editFavLookupBtn = document.createElement("button");
  editFavLookupBtn.classList.add("editFav__button");
  editFavLookupBtn.classList.add("button");
  editFavLookupBtn.classList.add("fa-solid");
  editFavLookupBtn.classList.add("fa-search");
  editFavLookupBtn.type = "button";
  // save button
  let editFavSaveBtn = document.createElement("button");
  editFavSaveBtn.classList.add("editFav__button");
  editFavSaveBtn.classList.add("button");
  editFavSaveBtn.classList.add("fa-solid");
  editFavSaveBtn.classList.add("fa-floppy-disk");
  editFavSaveBtn.type = "button";
  // delete button
  let editFavDeleteBtn = document.createElement("button");
  editFavDeleteBtn.classList.add("editFav__button");
  editFavDeleteBtn.classList.add("button");
  editFavDeleteBtn.classList.add("fa-solid");
  editFavDeleteBtn.classList.add("fa-trash-can");
  editFavDeleteBtn.type = "button";
  // up button
  let editFavUpBtn = document.createElement("button");
  editFavUpBtn.classList.add("editFav__button");
  editFavUpBtn.classList.add("button");
  editFavUpBtn.classList.add("fa-solid");
  editFavUpBtn.classList.add("fa-arrow-up");
  editFavUpBtn.type = "button"; 
  // down button
  let editFavDownBtn = document.createElement("button");
  editFavDownBtn.classList.add("editFav__button");
  editFavDownBtn.classList.add("button");
  editFavDownBtn.classList.add("fa-solid");
  editFavDownBtn.classList.add("fa-arrow-down");
  editFavDownBtn.type = "button";
  // append elements to window
  editFavPrompt.appendChild(editFavText);      // window title text
  editFavPrompt.appendChild(editFavName);      // name text box
  editFavPrompt.appendChild(editFavURL);       // URL text box
  editFavPrompt.appendChild(editFavUpBtn);     // button row #1
  editFavPrompt.appendChild(editFavLookupBtn); // button row #1 
  editFavPrompt.appendChild(editFavDownBtn);   // button row #2
  editFavPrompt.appendChild(editFavSaveBtn);   // button row #2
  editFavPrompt.appendChild(editFavCancelBtn); // button row #3
  editFavPrompt.appendChild(editFavDeleteBtn); // button row #3
  // display window on page
  document.body.appendChild(editFavPrompt);
  // handle button actions
  new Promise(function(resolve, reject) {
    editFavPrompt.addEventListener('click', function handleButtonClicks(e) { 
    if (e.target.tagName !== 'BUTTON') { return; }
      // move up button action
      if (e.target === editFavUpBtn) {
        shiftMenuUp(elem);
      }
      // move down button action
      if (e.target === editFavDownBtn) {
        shiftMenuDown(elem);
      }         
      // cancel button action
      if (e.target === editFavCancelBtn) {
        editFavPrompt.removeEventListener('click', handleButtonClicks);
        hideDropdowns();
      }
      // lookup URL action
      if (e.target === editFavLookupBtn) {
        lookupURL();
      }
      // save button action
      if (e.target === editFavSaveBtn) {
        // do not allow empty URL or name
        var stopsave = false;
        if (editFavName.value == null || editFavName.value == "") {
          editFavName.placeholder = "Name cannot be empty";
          stopsave = true;
        }
        if (editFavURL.value == null || editFavURL.value == "") {
          editFavURL.placeholder = "URL cannot be empty";
          stopsave = true;
        }
        if (stopsave === true){
          return;
        }
        // update changed values
        if (elem) { 
          // save name to menu object
          let _boxname = editFavName.value.replaceAll("|", "-");
          // name length limiter
          let maxNameLength = 42;
          if (_boxname.length >= maxNameLength) {
            elem.innerText = _boxname.substring(0,maxNameLength) + "...";
          } else {
            elem.innerText = _boxname;
          }
          // save URL to menu object
          let _boxurl = addHTTPtoURL(editFavURL.value.replaceAll("|", "-"));
          elem['url'] = _boxurl;
          editFavURL.value = _boxurl;
          editFavText.innerHTML = "Changes Saved"; 
        }
        // save to file
        saveBookmarks();
        // close dropdown
        editFavPrompt.removeEventListener('click', handleButtonClicks);
        closeBookmarkPrompt();
      }
      // delete button action
      if (e.target === editFavDeleteBtn) {
        elem.remove();
        // save to file
        saveBookmarks();
        // close dropdown
        editFavPrompt.removeEventListener('click', handleButtonClicks);
        closeBookmarkPrompt();
      }    
    });
  });   
}

// add HTTPs prefix if not defined
function addHTTPtoURL(linkin) {
  let linkout;
  if (linkin === "" || linkin === null) {
    linkout = "";
  } else {  
    if (linkin.toLowerCase().startsWith('http://', 0) || 
        linkin.toLowerCase().startsWith('https://', 0)) {
      linkout = linkin;
    } else {
      linkout = "https://" + linkin;
    }
  }
  return linkout;
}

async function lookupURL() {
  const urlBoxElem = document.getElementById("editFav__urlbox");
  const nameBoxElem = document.getElementById("editFav__namebox");
  if (urlBoxElem && nameBoxElem) {
    nameBoxElem.value = "Processing...";
    // read URL box
    let urlin = urlBoxElem.value;
    if (urlin === null || urlin === "") {
      // read from clipboard if URL empty
      urlin = await navigator.clipboard.readText();
    }
    // add HTTPs to URL
    let url = addHTTPtoURL(urlin);
    urlBoxElem.value = url;
    // search for URLs title
    sendCmd('main','sitelookup',url).then((data) => {
      if (data === null || data === "") {
        // URL lookup failed actions
        nameBoxElem.value = "Not Found";
        setTimeout(function() {
          if (urlBoxElem && nameBoxElem) {
            nameBoxElem.value = null;
            urlBoxElem.value = null;
          }
        }, 2000);
      } else { 
        // remove invalid characters, write to name box
        nameBoxElem.value = data.replace(/(\r\n|\n|\r)/gm, "");
      }
    });
  }
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
      _file += url + "|9|" + name + "\n";
    }
  })
  // transmit file
  savePOST('bookmarks',[_file]);
  // animations
  loadBar(1.0);
}

// close add / edit window
function closeBookmarkPrompt() {
  // re-enable click outside of window
  document.querySelectorAll("*:not(#editFav__prompt)").forEach(e => {
    e.style.pointerEvents = "";
  }); 
  // un-highlight selected item
  for (var idx = 0; idx <= fileData.length; idx++) {
    const _menuid = "menu-" + idx.toString();
    const elem = document.getElementById(_menuid);
    if (elem) {
      if(elem.classList.contains('dd-selected')) {
        elem.classList.remove("dd-selected");
      }
    }
  }
  const favPrompt = document.getElementById("editFav__prompt");
  if (favPrompt) {
    favPrompt.remove();
  }  
}

function buildRemoteAPIMenu(_menubtn,_host,_cmd,_indtype,_title) {
  return _menubtn + '~' + _host + '~' + _cmd
                  + '|' + _indtype 
                  + '|' + _title + '\n';
}

function showAmpStatus() {
  const _host = "br"; // Bedroom Pi
  const _menu = _host + "pwrmenu";
  let _elem = document.getElementById(_menu);
  if (_elem.style.display === 'block') {
    _elem.style.display = 'none';
  } else {
    hideDropdowns(); // hide all dropdown menus
    _elem.style.display = 'block';
    sendCmd('main',_host + '-resp','ampstate').then((data) => { // GET request
      const resp = data.replace(/(\r\n|\n|\r)/gm, ""); // remove newlines
      // draw menu items
      let _menubtn; // menu type
      let _cmd;     // remote host command 
      let _indtype; // indicator type
      let _title;   // menu button title
      let _error = true; // error flag
      let _menudata = "";
      // status display (I)
      if (resp == '0') {
        _indtype = '3';   
        _title = "Offline";
        _error = false;
      }
      if (resp == '1') {
        _indtype = '4';  
        _title = "Online";
        _error = false;
      }
      if (_error == true) {
        _indtype = '5';    
        _title = "Unknown";
      }
      _menudata += buildRemoteAPIMenu(_menubtn,_host,_cmd,_indtype,_title);
      // power on/off buttons (II)
      if (resp == '0' || _error == true) {
        _menubtn = "oncmd";
        _cmd = "poweron";
        _indtype = '6'; 
        _title = "Turn-On"  
        _menudata += buildRemoteAPIMenu(_menubtn,_host,_cmd,_indtype,_title);
      }
      if (resp == '1' || _error == true) {
        _menubtn = "offcmd"; 
        _cmd = "poweroff";  
        _indtype = '6';     
        _title = "Turn-Off"  
        _menudata += buildRemoteAPIMenu(_menubtn,_host,_cmd,_indtype,_title);
      }
      drawMenu(_menudata.split("\n"),_menu); // draw menu 
    });
  }
}


//// Dynamic Menus ////

function showStatusMenu() {
  const _menu = 'statsmenu';
  let _elem = document.getElementById(_menu);
  if (_elem.style.display === 'block') {
    _elem.style.display = 'none';
  } else {
    // spinner animation
    let btnText = document.getElementById('stat-text');
    let btnSpinner = document.getElementById('stat-spinner');
    btnText.style.display = 'none';
    btnSpinner.style.display = 'inline-block';
    hideDropdowns(); // hide all dropdown menus
    _elem.style.display = 'block';
    sendCmd('main','status','').then((data) => { // GET request
      // draw menu items
      let _rowarr = data.split('\n');
      drawMenu(_rowarr,_menu);
      btnText.style.display = 'inline-block';
      btnSpinner.style.display = 'none';
    });
  }   
}

function showDynMenu(_menu) {
  let _elem = document.getElementById(_menu);
  if (_elem.style.display === 'block') {
    _elem.style.display = 'none';
  } else {
    hideDropdowns();
     _elem.style.display = 'block';   
    // read menu data from file
    readMenuData(_menu);
  }
}

function readMenuData(menu) {
  // build URL / append data
  const url = location.protocol+"//"+location.hostname+"/exec.php?var=&arg="+menu+"&action=read";
  menuDataGET(url).then((data) => { // wait for response
    drawMenu(data,menu);
  });  
  function menuDataGET(url) {
    return fetch(url, {
        method: "GET"
      }).then(response => response.json().then(obj => obj).catch(err => {
        console.log("readMenuData: " + err)
      }
    ));
  }
}

// draws each menu item
function drawMenu(data,menu) {
  if (!(data === null || data === "")) {
    // erase global data
    while (fileData.length) { fileData.pop(); } 
    for (var idx in data) {
      let line = data[idx].toString();
      if (line != "") {
        fileData.push(line); // write to register
        const navElement = document.getElementById(menu);
        const linearr = line.split("|");
        // 0=Host, 1=Type, 2=Name
        const col0 = linearr[0];
        const col1 = linearr[1];
        const col2 = linearr[2].trim();
        // draw menu item
        navElement.appendChild(createListItem(col0,col1,col2,idx));
        dynMenuActive = 1;
      }
    }
    // store menu name at end of register
    fileData.push(menu);
  } else {
    console.log("drawMenu: no data");
  }
}

function createListItem(_col0,_col1,_col2,_id) {
  const _elm = document.createElement('a');
  // assign menu ID
  _elm.id = "menu-" + _id.toString();
  // set menu text
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
  // link only menu
  if (_col1 == '2') {
    _elm.href = _col0;
  }
  // indicator / status menu  
  if (_col1 == '3' || // black indicator
      _col1 == '4' || // green indicator
      _col1 == '5' || // red indicator
      _col1 == '6') { // no indicator
    // power toggle type
    const _icon = document.createElement('span');
    const field = _col0.split("~");
    const menutype = field[0]; // menu button type
    const target   = field[1]; // target server 
    const cmd      = field[2]; // target command
    if (menutype == 'oncmd') {
      _icon.classList.add('fa-solid');
      _icon.classList.add('fa-toggle-on');
      _icon.classList.add('icon-right');
      _elm.appendChild(_icon);
      _elm.addEventListener("click", function(event) {
        sendCmd('main',target,cmd);
      });
    }
    if (menutype == 'offcmd') {
      _icon.classList.add('fa-solid');
      _icon.classList.add('fa-toggle-off');
      _icon.classList.add('icon-right');
      _elm.appendChild(_icon);
      _elm.addEventListener("click", function(event) {
        sendCmd('main',target,cmd);
      });
    }
    const _dot = document.createElement('span');
    if (_col1 == '3'){
      _dot.classList.add('ind_dot');
    }
    if (_col1 == '4'){
      _dot.classList.add('ind_dot');
      _dot.classList.add('ind_dot_green');
    }
    if (_col1 == '5'){
      _dot.classList.add('ind_dot');
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
  // bookmarks menu  
  if (_col1 == '9') {
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
    for (var idx = 0; idx <= fileData.length; idx++) {
      const _menuid = "menu-" + idx.toString();
      const menuRemove = document.getElementById(_menuid);
      if (menuRemove != null) {
        menuRemove.remove();
      }
    }
    if (dynChkboxChanged == 1) {
      // write checkbox changes to file (III)
      let menuid = fileData[fileData.length - 1];
      // remove menu item element
      fileData.pop();
      // save to API
      savePOST(menuid,fileData);
      // clear global data
      while (fileData.length) { fileData.pop(); }  
      dynChkboxChanged = 0;
    }  
    dynMenuActive = 0;
  }
}

function boxChanged() {
  // loop through checkbox's state
  for (var i = 0; i < (fileData.length - 1); i++) {
    let line = fileData[i].toString();
    // split up into array (host,state,name)
    const linearr = line.split("|");
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
      // build new data
      let _outstr = linearr.join('|');
      console.log(_outstr);
      // replace existing data
      fileData[i] = _outstr;
    }
  }
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
        if (file === 'fusearch') {
          mountFUSEvolume();
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
  serverCmdData = cmd;
  // change color of send button
  sendBtnAlert("on");
}

function openLogWindow() {
  // open server log window
  closePopup();
  // show log form window
  document.getElementById("logForm").style.display = "block";
  // load log data
  loadLog('sysout');
}

function openCamWindow() {
  closePopup();
  // show camera form window
  document.getElementById("camForm").style.display = "block";
  document.getElementById("camImage").src = "/cam1";
}

function closePopup() {
  // close all popup windows
  document.getElementById("logForm").style.display = "none";
  document.getElementById("camForm").style.display = "none";
  document.getElementById("camImage").src = "";
  clearPendingCmd();
  closeServerOptions();
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
        elem.textContent = serverSite;  
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
  if (sysModel === serverSite) {
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
