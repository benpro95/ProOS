// Automate Website - JavaScript Frontend
// by Ben Provenzano III

// global variables //
let ctlMode;
let ctlCommand;
let selectedVM = "";
let dynMenuActive = 0;
let resizeState = false;
const BKM_INACTIVE = 0;
const BKM_OPEN_MODE = 1;
const BKM_EDIT_MODE = 2;
let bookmarkState = 0;
let serverCmdData;
let socket = null;
let fileData = [];
var timeStamp;
let sysModel;

// global constants
let resizeTimeout = 800; // in ms
let serverSite = "Automate";
let siteVersion = "10.4";

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
  if (bookmarkState === BKM_EDIT_MODE) {
    if (event.target.className !== "editFav__win") {
       // disable all clicks outside of window
      event.stopPropagation();
    }
    return;
  }
  // don't hide menus when clicking these elements
  if (!(event.target.classList.contains('button') || // button click
        event.target.classList.contains('button__text') || // button text click
        event.target.classList.contains('bookmarked__item') || // bookmark menu click
        event.target.classList.contains('fas') || // solid icon clicks
        event.target.classList.contains('fad') || // duotone icon clicks
        event.target.classList.contains('fab') || // brand icon clicks
        event.target.classList.contains('am-spinner') || // spinner clicks
        event.target.classList.contains('dropbtn') || // dropdown button click
        event.target.classList.contains('chkbox'))) { // checkbox click
    hideDropdowns(true); // hide all dropdown menus
  }
}

// hide all dropdowns //
function hideDropdowns(eraseDynMenus) {
  classDisplay("dd-content","none");
  // hide bookmark menus
  hideBookmarks();
  // remove dynamic menus
  if (eraseDynMenus === true) {
    removeDynMenus();
  }
}

// show / hide multiple classes
function classDisplay(_elem, _state) {
  let _itr;
  let _class = document.getElementsByClassName(_elem);
  for (_itr = 0; _itr < _class.length; _itr++) {
    _class[_itr].style.display = _state;
  }
}

function checkElemIsVisibleByID(id){
  let _elmvis = false;
  let _elem = document.getElementById(id);
  if (_elem) {
    var _style = window.getComputedStyle(_elem)
    if (_style.display !== 'none') {
      _elmvis = true;
    }
  }
  return _elmvis;
}

// open URL in new tab
function GoToExtPage(_path) {
  let url = "https://"+_path;   
  window.open(url, "_blank");
}

function mapNumber(num, inMin, inMax, outMin, outMax) {
  return (num - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
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

function hidePages() {
  classDisplay('pi-grid','none'); 
  classDisplay('ledpi-grid','none'); 
  classDisplay('server-grid','none');
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
  // set theme
  let currentTheme;
  let _theme = localStorage.getItem("main-color")
  if (_theme === null || _theme === undefined || _theme === "") {
    currentTheme = "#1f2051"; // dark blue
  } else {
    currentTheme = localStorage.getItem("main-color");
  }  
  setTheme(currentTheme);
  enableAnimatedStars();
}

function enableAnimatedStars() {
  const avalRAM = navigator.deviceMemory;
  const iOS = /^(iPhone|iPad|iPod)/.test(navigator.platform);
  if (iOS === false) {
    if (avalRAM >= 2) { // GT 2GB of RAM 
      setTimeout(function() {
        // start stars animation 
        starsAnimation(true);
        // pause stars animation on window resize
        window.addEventListener("resize", function() {
          resizeEvent(); // on window resize
        });
      }, resizeTimeout);
    } else {
      console.log('stars disabled < 2GB RAM');
    }
  } else {
    console.log('stars disabled on iOS');
  }
}

function setTheme(newTheme) {
  let body = document.getElementsByTagName("html")[0];
  body.style.setProperty('--main-color', newTheme);
  localStorage.setItem("main-color", newTheme);
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
  console.log('stars state: ' + _state);
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
async function sendCmd(act, arg1, arg2) {
  // construct API URL
  const url = location.protocol+"//"+location.hostname+"/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
  // send request 
  const response = await fetch(url, {
    method: 'GET'
  });
  try {
    const obj = await response.json();
    var out = null;
    var empty = isObjEmpty(obj);
    if (empty === false) {
      out = obj.toString();
    } 
    return out; // return data
  } catch (err) {
    console.log('sendCmd: ' + err);
  }
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
  hideDropdowns(true);
  clearPendingCmd();
  classDisplay("svropt__prompt","none");
  classDisplay("svropt__main","none");
  classDisplay("svropt__regions","none");
  classDisplay("svropt__backup","none");
}

/// END- text popup window ///

async function aboutPrompt(){
  const _winid = 'about__prompt';
  // only allow one-instance of the window
  if (document.getElementById(_winid)) {
    return;
  }
  let aboutprompt = document.createElement("div"); 
  aboutprompt.id= _winid;
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
  aboutdets2.innerHTML = "v" + siteVersion + " (" + currentYear + ")";
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

/// Temperature & Humidity ///

async function showTempHumidity(){
  const _winid = 'temp__prompt';
  // only allow one-instance of the window
  if (document.getElementById(_winid)) {
    return;
  }
  // create window
  let tempprompt = document.createElement("div"); 
  tempprompt.id= _winid;
  // top window text
  let temptext = document.createElement("div");
  temptext.innerHTML = 'Temperature/Humidity';
  temptext.id = 'temp_top_text';
  tempprompt.appendChild(temptext);
  // thermometer container
  let tempcon = document.createElement("div");
  tempcon.id = 'temp_therm_grid';
  // temperature thermometer 
  let tmeter = document.createElement("div"); 
  tmeter.className = "thermometer";
  let tdisplay = document.createElement("div"); 
  tdisplay.className = "temperature";
  tdisplay.id = "thermo__1";
  tdisplay.dataset.value = "--°";
  tmeter.appendChild(tdisplay); 
  tempcon.appendChild(tmeter); 
  // humidity thermometer 
  let hmeter = document.createElement("div"); 
  hmeter.className = "thermometer";
  let hdisplay = document.createElement("div"); 
  hdisplay.className = "temperature";
  hdisplay.id = "thermo__2";
  hdisplay.dataset.value = "--%";
  hmeter.appendChild(hdisplay);
  tempcon.appendChild(hmeter); 
  // add thermo container to window
  tempprompt.appendChild(tempcon);
  // buttons container
  let btnscon = document.createElement("div");
  // cancel button
  let tempcancelb = document.createElement("button");
  tempcancelb.classList.add("button");
  tempcancelb.classList.add("temp__btn");
  tempcancelb.classList.add("fas");
  tempcancelb.classList.add("fa-times");
  tempcancelb.type = "button";
  btnscon.appendChild(tempcancelb);
  // refresh button
  let temprefreshb = document.createElement("button");
  temprefreshb.classList.add("button");
  temprefreshb.classList.add("temp__btn");
  temprefreshb.classList.add("fad");
  temprefreshb.classList.add("fa-sync");
  temprefreshb.type = "button";
  btnscon.appendChild(temprefreshb);
  // add buttons container to window
  tempprompt.appendChild(btnscon);
  // add window to DOM
  document.body.appendChild(tempprompt);
  // call API for data
  getTemperatureData();
  // button actions
  new Promise(function() {
    tempprompt.addEventListener('click', function handleButtonClicks(e) {
      if (e.target.tagName !== 'BUTTON') { return; } 
        // close button
        if (e.target === tempcancelb) {
          tempprompt.removeEventListener('click', handleButtonClicks); 
          document.body.removeChild(tempprompt);  
        }
        // refresh button
        if (e.target === temprefreshb) {
          getTemperatureData();
        }
    });
  });
}

function getTemperatureData() {
  sendCmd('main','brxmit','roomth').then((data) => {
    const resp = data.replace(/(\r\n|\n|\r)/gm, "");
    const resp_arr = resp.split("~");
    let temp_elm = document.getElementById("thermo__1");
    let humd_elm = document.getElementById("thermo__2");
    if (resp_arr.length == 2) {
      // valid response
      pushTempDataToThermos(resp_arr,temp_elm,humd_elm);
    } else {
      // retry request
      setTimeout(function(){
        retryGetTempData(temp_elm,humd_elm);
      }, 500); // in ms
    }
  });
}

function retryGetTempData(temp_elm,humd_elm) {
  console.log("re-trying DHT data refresh...");
  sendCmd('main','brxmit','roomth').then((data) => {
    const resp = data.replace(/(\r\n|\n|\r)/gm, "");
    // extract numerics
    const resp_arr = resp.split("~");
    // validate response
    if (resp_arr.length == 2) {
      pushTempDataToThermos(resp_arr,temp_elm,humd_elm);
    } else {
      pushTempErrorThermos(temp_elm,humd_elm);
    }
  });
}

function pushTempDataToThermos(resp_arr,temp_elm,humd_elm) {
  // thermometer limits
  const minTemp = 25;
  const maxTemp = 100;
  const minHumidity = 5;
  const maxHumitidy = 100;
  // verify elements exist
  if (!(temp_elm && humd_elm)) {
    return;
  }
  // validate response
  if (resp_arr.length == 2) {
    let tvalue = resp_arr[0];
    let hvalue = resp_arr[1];
    // set temperature
    temp_elm.dataset.value = tvalue + "°F";
    if (tvalue >= maxTemp) { tvalue = maxTemp; }
    if (tvalue <= minTemp) { tvalue = minTemp; }
    temp_elm.style.height = (tvalue - minTemp) / (maxTemp - minTemp) * 100 + "%";
    // set humidity
    humd_elm.dataset.value = hvalue + "%";
    if (hvalue >= maxHumitidy) { hvalue = maxHumitidy; }
    if (hvalue <= minHumidity) { hvalue = minHumidity; }
    humd_elm.style.height = (hvalue - minHumidity) / (maxHumitidy - minHumidity) * 100 + "%";
  } else {
    pushTempErrorThermos(temp_elm,humd_elm);
  }
}

function pushTempErrorThermos(temp_elm,humd_elm) {
  // verify elements exist
  if (!(temp_elm && humd_elm)) {
    return;
  }
  temp_elm.style.height = "0%";
  temp_elm.dataset.value = "--";
  humd_elm.style.height = "0%";
  humd_elm.dataset.value = "--";
}

/// END - Temperature & Humidity ///

async function showPiWiFiPrompt() {
  const winid = "pinet__prompt";
  // only allow one-instance of the window
  if (document.getElementById(winid)) {
    return;
  }
  let result;
  try {
    hideDropdowns(true);
    result = await piWiFiPrompt(winid);
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

async function piWiFiPrompt(_winid){
  let pinetprompt = document.createElement("div"); 
  pinetprompt.id = _winid; 
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

async function wifiPrompt(){
  const _winid = "wifi__prompt";
  // only allow one-instance of the window
  if (document.getElementById(_winid)) {
    return;
  }
  let wifiprompt = document.createElement("div");
  wifiprompt.id = _winid;
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

async function getPassword(_type){
  let result;
  try{
    hideDropdowns(true);
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

function passwordPrompt(){
  const _winid = "pass__prompt_win";
  // only allow one-instance of the window
  if (document.getElementById(_winid)) {
    return;
  }
  let pwprompt = document.createElement("div"); //creates the div to be used as a prompt
  pwprompt.id = _winid; //gives the prompt an id
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

async function colorPrompt(){
  const winid = "color__prompt";
  // only allow one-instance of the window
  if (document.getElementById(winid)) {
    return;
  }
  hideDropdowns(true);
  let colorprompt = document.createElement("div"); //creates the div to be used as a prompt
  colorprompt.id= winid; //gives the prompt an id
  let colortext = document.createElement("div"); //create the div for the password-text
  colortext.innerHTML = "Pick a color:"; //put inside the text
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
          updateColor(_colorval);
        } else { // close button
          colorprompt.removeEventListener('click', handleButtonClicks);
          document.body.removeChild(colorprompt);  //as we are done clean up by removing the-prompt
        }  
      });
  });   
}

function updateColor(_hexin) {
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

/// END DYNAMIC WINDOWS ///

function relaxSend(_cmd) {
  sendCmd('main','relax',_cmd);
}

// volume controls
function sendVol(_cmd) {
  // volume mode
  if (ctlCommand == 'lr' ){
    sendCmd('main','lrxmit',_cmd); // living room system 
  }
  if (ctlCommand == 'subs' ){
    sendCmd('main','lrxmit','sub'+_cmd); // living room subwoofers
  }  
  if (ctlCommand == 'br' ){
    setAmpVolume(_cmd); // bedroom system
  }
}

async function setAmpVolume(_state) {
  sendCmd('main','brpi','vol'+_state).then((data) => { // GET request
    const maxAmpData = 192;
    let ampVol = Number(data.replace(/(\r\n|\n|\r)/gm, "")); // remove newlines, convert to number
    if (!(isNaN(ampVol))) {
      // re-map volume data to 0-100%, show volume pop-up
      showVolumePopup(Math.round(mapNumber(ampVol,0,maxAmpData,0,100))); 
    }
  });
}

function showVolumePopup(vol) {
  let elem = document.getElementById('vol-popup');
  let vol_text = document.getElementById('vol-text');
  let vol_bar = document.getElementById('vol-bar1');
  // set volume pop-up text
  if (vol == 0) {
    vol_text.innerHTML = "Mute";
  } else {
    vol_text.innerHTML = vol + "%";
  }
  // set volume progress bar
  vol_bar.style.width = vol + "%";
  // make window visible
  if (elem.style.display !== 'block') {
    elem.style.display = "block";
    setTimeout(function(){
      // hide after 3 seconds
      elem.style.display = "none";
    }, 3000);
  }
}

function roomOnOff(action){
   if (ctlCommand == 'lr'){
    // living room
    sendCmd('main','lr' + action,'');
    return;
  }
  if (ctlCommand == 'br'){
    // bedroom
    sendCmd('main','br' + action,'');
    return;
  }
}

function subModeToggle() {
  // toggle subwoofer mode
  if (ctlCommand == 'subs' ){
    ctlsMenu('lr');
    return;
  }
  if (ctlCommand != 'subs'){
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
  ctlCommand = _mode; 
  // living room controls
  if ((_mode === 'lr') || (_mode === 'subs')) {
    // disable bedroom grid
    classDisplay('bedroom-grid','none');
    // enable hifi grid
    classDisplay('hifi-grid','block');
    if (_mode === 'lr') {
      // hide subwoofer controls 
      subMode('hide');
    } else {
      // subwoofer controls
      subMode('show');
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
  }
  // save state 
  localStorage.setItem("ctls-mode", _mode);
}

// toggle dropdown menu's
function showMenu(_menu,_scrolltobtm) {
  let _elem = document.getElementById(_menu);
  if (_elem.style.display === 'block') {
    _elem.style.display = 'none';
  } else {
    hideDropdowns(true);
    _elem.style.display = 'block';
    if (_scrolltobtm === true) {
      scrollToBottom();
    }
  }
}

function scrollToBottom() {
  window.scrollTo(0,document.body.scrollHeight);
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
  bookmarkState = BKM_INACTIVE;
}

function showBookmarks() {
  // hide menu if clicked while open
  if (bookmarkState !== BKM_INACTIVE) {
    hideDropdowns(true);
    return;
  }
  // draw menu
  showDynMenu('bookmarks');
  // show add / edit buttons
  classDisplay("bookmark-buttons","block");
  // link open mode
  bookmarkState = BKM_OPEN_MODE;
}

function editBookmark() {
  // hide menu if clicked while open
  if (bookmarkState === BKM_EDIT_MODE) {
    hideDropdowns(true);
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
  const navElement = document.getElementById('bookmarks');
  const _elm = document.createElement('a');
  _elm.id = "menu-" + _newid;
  _elm.innerText = "New Bookmark";
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
  bookmarkState = BKM_EDIT_MODE;
  closeBookmarkPrompt();
}

function clickBookmark(id) {
  const elmid = "menu-" + id.toString();
  const elem = document.getElementById(elmid);
  const url = Object.values(elem.url).join("");
  const name = elem.innerText;
  if (elem) { 
    if (bookmarkState === BKM_OPEN_MODE) {
      if (!(url == null || url == "" || url == "about:blank")) {
        // open URL in new tab
        window.open(url, "_blank");
      }
    }
    if (bookmarkState === BKM_EDIT_MODE) {
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
  editFavCancelBtn.classList.add("fas");
  editFavCancelBtn.classList.add("fa-times");
  editFavCancelBtn.type = "button";
  // lookup favorites
  let editFavLookupBtn = document.createElement("button");
  editFavLookupBtn.classList.add("editFav__button");
  editFavLookupBtn.classList.add("button");
  editFavLookupBtn.classList.add("fad");
  editFavLookupBtn.classList.add("fa-search");
  editFavLookupBtn.type = "button";
  // save button
  let editFavSaveBtn = document.createElement("button");
  editFavSaveBtn.classList.add("editFav__button");
  editFavSaveBtn.classList.add("button");
  editFavSaveBtn.classList.add("fad");
  editFavSaveBtn.classList.add("fa-save");
  editFavSaveBtn.type = "button";
  // delete button
  let editFavDeleteBtn = document.createElement("button");
  editFavDeleteBtn.classList.add("editFav__button");
  editFavDeleteBtn.classList.add("button");
  editFavDeleteBtn.classList.add("fad");
  editFavDeleteBtn.classList.add("fa-trash-alt");
  editFavDeleteBtn.type = "button";
  // up button
  let editFavUpBtn = document.createElement("button");
  editFavUpBtn.classList.add("editFav__button");
  editFavUpBtn.classList.add("button");
  editFavUpBtn.classList.add("fad");
  editFavUpBtn.classList.add("fa-arrow-up");
  editFavUpBtn.type = "button"; 
  // down button
  let editFavDownBtn = document.createElement("button");
  editFavDownBtn.classList.add("editFav__button");
  editFavDownBtn.classList.add("button");
  editFavDownBtn.classList.add("fad");
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
        hideDropdowns(true);
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

function base64URLSafeEncode(buffer) 
{
  return btoa(buffer)
    .replace(/\+/g, '-')  // Convert '+' to '-'
    .replace(/\//g, '_')  // Convert '/' to '_'
    .replace(/\=/g, '@'); // Convert '=' to '@'
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
    let encoded_url = base64URLSafeEncode(url);
    // search for URLs title
    sendCmd('main','sitelookup',encoded_url).then((data) => {
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
        nameBoxElem.value = data.replace(/(\r\n|\n|\r)/gm, '');
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
      _file += url + "|bkmrk|" + name + "\n";
    }
  })
  // transmit file
  savePOST('bookmarks',[_file]);
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

// concat and add delimiters to dynamic menu data
function buildRemoteAPIMenu(_menubtn,_host,_cmd,_indtype,_title) {
  return _menubtn + '~' + _host + '~' + _cmd
                  + '|' + _indtype 
                  + '|' + _title + '\n';
}

function showAmpInput() {
  const target = 'brpi';
  let _elem = document.getElementById("brinpmenu");
  if (_elem.style.display === 'block') {
    _elem.style.display = 'none';
  } else {
    hideDropdowns(false);
    // start spinner animation
    let btnText = document.getElementById('ampinp-text');
    let btnSpinner = document.getElementById('ampinp-spinner');
    btnText.style.visibility = 'hidden';
    btnSpinner.classList.add('btn-spinner');
    _elem.style.display = 'block';
    sendCmd('main',target,'inputstate').then((data) => { // GET request
      const resp = data.replace(/(\r\n|\n|\r)/gm, ""); // remove newlines
      // draw menu items
      let _menubtn; // menu type
      let _cmd;     // remote host command 
      let _indtype; // indicator type
      let _title;   // menu button title
      let _menudata = "";
      // apple TV input 
      _menubtn = "cmd";
      _title = "Optical I"  
      _cmd = "opt-a";
      _indtype = 'blkind';
      if (resp == '2'){
        _indtype = 'grnind';
      }
      _menudata += buildRemoteAPIMenu(_menubtn,target,_cmd,_indtype,_title);
      // aux optical input
      _menubtn = "cmd";
      _title = "Optical II"  
      _cmd = "opt-b";
      _indtype = 'blkind';
      if (resp == '1'){
        _indtype = 'grnind';
      } 
      _menudata += buildRemoteAPIMenu(_menubtn,target,_cmd,_indtype,_title);
      // coaxial input
      _menubtn = "cmd";
      _title = "Coaxial"  
      _cmd = "coaxial";  
      _indtype = 'blkind';
      if (resp == '3'){ 
        _indtype = 'grnind';
      }
      _menudata += buildRemoteAPIMenu(_menubtn,target,_cmd,_indtype,_title);
      // aux analog input
      _menubtn = "cmd";
      _title = "Analog"  
      _cmd = "aux";
      _indtype = 'blkind';
      if (resp == '4'){
        _indtype = 'grnind';
      }
      _menudata += buildRemoteAPIMenu(_menubtn,target,_cmd,_indtype,_title);
      // stop spinner animation
      btnText.style.visibility = 'visible';
      btnSpinner.classList.remove('btn-spinner');
      // draw menu items
      drawMenu(_menudata.split("\n"),"brinpmenu",true);
    });
  }
}

function showPowerMenu(target,menu,tobtm) {
  let _elem = document.getElementById(menu + '-menu');
  if (_elem.style.display === 'block') {
    _elem.style.display = 'none';
  } else {
    hideDropdowns(false);
    // start spinner animation
    let btnText = document.getElementById(menu + '-text');
    let btnSpinner = document.getElementById(menu + '-spinner');
    btnText.style.visibility = 'hidden';
    btnSpinner.classList.add('btn-spinner');
    // show menu
    _elem.style.display = 'block';
    sendCmd('main',target,menu).then((data) => { // GET request
      const resp = data.replace(/(\r\n|\n|\r)/gm, ''); // remove newlines
      // draw menu items
      let _menubtn; // menu type
      let _cmd;     // remote host command 
      let _indtype; // indicator type
      let _title;   // menu button title
      let _menudata = "";
      // status display (I)
      switch(resp) {
        case '0':
          _indtype = 'blkind';
          _title = "Offline";
          break;
        case '1':
          _indtype = 'grnind';
          _title = "Online";
          break;
        case 'pc_awake':
          _indtype = 'grnind';
          _title = "Online";
          break;        
        default:
          _indtype = 'redind';
          _title = "Error";
      }
      _menudata += buildRemoteAPIMenu(_menubtn,target,_cmd,_indtype,_title);
      // power on/off buttons (II)
      if (resp == '1') { // online
        _menudata += buildRemoteAPIMenu('offcmd',target,menu + 'off','noind','Off');
      }
      if (resp == '0') { // offline
        _menudata += buildRemoteAPIMenu('oncmd',target,menu + 'on','noind','On');
      }
      /// custom menus ///
      if (resp == 'pc_awake') {
        _menudata += buildRemoteAPIMenu('sleepmode',target,menu + 'off','noind','Sleep');
      }
      // stop spinner animation
      btnText.style.visibility = 'visible';
      btnSpinner.classList.remove('btn-spinner');
      // draw menu items
      drawMenu(_menudata.split("\n"),menu + '-menu',tobtm);
    });
  }
}

function showStatusMenu() {
  const _menu = 'statsmenu';
  let statIcon = document.getElementById('navstats-icon');
  let statSpinner = document.getElementById('navstats-spinner');
  let _elem = document.getElementById(_menu);
  if (_elem.style.display === 'block') {
    _elem.style.display = 'none';
    // stop spinner animation
    statIcon.style.visibility = 'visible';
    statSpinner.classList.remove('right-nav-spinner');
  } else {
    hideDropdowns(false);
    // start spinner animation
    statIcon.style.visibility = 'hidden';
    statSpinner.classList.add('right-nav-spinner');
    // show menu
    _elem.style.display = 'block';
    sendCmd('main','status','').then((data) => { // GET request
      // draw menu items
      drawMenu(data.split("\n"),_menu,false);
      // stop spinner animation
      statIcon.style.visibility = 'visible';
      statSpinner.classList.remove('right-nav-spinner');
    });
  }   
}

//// Dynamic Menus ////

function showDynMenu(menu,tobtm) {
  let _elem = document.getElementById(menu);
  if (_elem.style.display === 'block') {
    _elem.style.display = 'none';
  } else {
    hideDropdowns(false);
     _elem.style.display = 'block';
    // build URL / append data
    const url = location.protocol+"//"+location.hostname+"/exec.php?var=&arg="+menu+"&action=read";
    menuDataGET(url).then((data) => { // wait for response
      drawMenu(data,menu,tobtm);
    });  
    async function menuDataGET(url) {
      const response = await fetch(url, {
        method: "GET"
      });
      try {
        const obj = await response.json();
        return obj;
      } catch (err) {
        console.log("readMenuData: " + err);
      }
    }
  }
}

// draws each menu item
function drawMenu(data,menu,tobtm) {
  // remove any current dynamic menus
  removeDynMenus();
  if (!(data === null || data === "")) {
    // erase global data
    while (fileData.length) { 
      fileData.pop(); 
    } 
    for (var idx in data) {
      let line = data[idx].toString();
      if (line != "") {
        fileData.push(line); // write to array
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
    // store menu name at end of array
    fileData.push(menu);
    // scroll to bottom of page
    if (tobtm === true) {
      scrollToBottom();
    }
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
  if (_col1 == 'chkon' || _col1 == 'chkoff') {
    const _cbox = document.createElement('input');
    _cbox.type = "checkbox";
    _cbox.className = "chkbox";
    _cbox.id = "chkbox-" + _col2;
    // read checkbox state from file
    if (_col1 == 'chkoff') {
      _cbox.checked = false;
    }
    if (_col1 == 'chkon') {
      _cbox.checked = true;
    }
    _elm.appendChild(_cbox);
    // URL on click
    _elm.href = _col0;
    // a checkbox was clicked
    _elm.addEventListener('click', function(event) {
      if (event.target.classList.contains('chkbox')) {
        boxChanged();
      }
    });
  }
  // API call menu
  if (_col1 == 'ledmenu') {
    _elm.addEventListener("click", function(event) {
      sendCmd('leds',_col0,'');
    });
  }
  if (_col1 == 'relaxmenu') {
    _elm.addEventListener("click", function(event) {
      relaxSend(_col0);
    });
  } 
  // link only menu
  if (_col1 == 'link') {
    _elm.href = _col0;
  }
  // status menus
  if (_col1.includes('ind')) { // indicators
    // power toggle type
    const _icon = document.createElement('span');
    const field = _col0.split("~");
    const menutype = field[0]; // menu button type
    const target   = field[1]; // target server 
    const cmd      = field[2]; // target command
    let hoverOff = true;
    if (menutype == 'oncmd') { // power-on remote API call on click
      hoverOff = false;
      _icon.classList.add('fa');
      _icon.classList.add('fa-toggle-on');
      _icon.classList.add('leftjfy'); // left-justify icon
      _elm.appendChild(_icon);
      _elm.addEventListener("click", function(event) {
        sendCmd('main',target,cmd);
      });
    }
    if (menutype == 'offcmd') { // power-off remote API call on click
      hoverOff = false;
      _icon.classList.add('fa');
      _icon.classList.add('fa-toggle-off');
      _icon.classList.add('leftjfy'); // left-justify icon
      _elm.appendChild(_icon);
      _elm.addEventListener("click", function(event) {
        sendCmd('main',target,cmd);
      });
    }
    if (menutype == 'sleepmode') { // sleep PC type menu
      hoverOff = false;
      _icon.classList.add('fa');
      _icon.classList.add('fa-moon');
      _icon.classList.add('leftjfy'); // left-justify icon
      _elm.appendChild(_icon);
      _elm.addEventListener("click", function(event) {
        sendCmd('main',target,cmd);
      });
    }
    if (menutype == 'cmd') { // generic remote API call on click
      hoverOff = false;
      _elm.addEventListener("click", function(event) {
        sendCmd('main',target,cmd);
      });
    }
    const _dot = document.createElement('span');
    if (_col1 == 'blkind'){
      _dot.classList.add('ind_dot');
    }
    if (_col1 == 'grnind'){
      _dot.classList.add('ind_dot');
      _dot.classList.add('ind_dot_green');
    }
    if (_col1 == 'redind'){
      _dot.classList.add('ind_dot');
      _dot.classList.add('ind_dot_red');
    }
    if (_col1 == 'ylwind'){
      _dot.classList.add('ind_dot');
      _dot.classList.add('ind_dot_yellow');
    }
    // disable hover/click on non-clickable menus
    if (hoverOff === true){
      _elm.classList.add('no_select');
    }
    _dot.id = "ind-" + _col2;
    _elm.appendChild(_dot);
  }
  // theme menu  
  if (_col1 == 'thm') {
    const _color = _col0;
    _elm.classList.add('theme-colorbox');
    _elm.style.setProperty('background-color', _color);
    _elm.addEventListener("click", function(event) {
      setTheme(_color);
    });
  }
  // bookmarks menu  
  if (_col1 == 'bkmrk') {
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

function boxChanged() {
  // loop through checkbox's state
  for (var i = 0; i < (fileData.length - 1); i++) {
    let line = fileData[i].toString();
    // split up into array (host,state,name)
    const linearr = line.split("|");
    // only write box state on 0/1 state items
    if (linearr[1] == 'chkon' || linearr[1] == 'chkoff') {
      // read elements checkbox then write state
      const box = "chkbox-" + linearr[2].toString();
      var boxelm = document.getElementById(box);
      if (boxelm.checked === true) {
        linearr[1] = 'chkon';
      } else {
        linearr[1] = 'chkoff';
      }
      // build new data
      let _outstr = linearr.join('|');
      console.log(_outstr);
      // replace existing data
      fileData[i] = _outstr;
    }
  }
  // write checkbox changes to file (III)
  let menuid = fileData[fileData.length - 1]; // extract menu ID
  // remove last element of array
  fileData.pop();
  // update file
  savePOST(menuid,fileData);
  // add menu ID back to array
  fileData.push(menuid);
}

function removeDynMenus() {
  // only if menu is on-screen 
  if (dynMenuActive == 1) {
    // remove dynamic menu elements (II)
    for (var idx = 0; idx <= fileData.length; idx++) {
      const _menuid = "menu-" + idx.toString();
      const menuRemove = document.getElementById(_menuid);
      if (menuRemove != null) {
        menuRemove.remove();
      }
    }
    dynMenuActive = 0;
  }
}

//// End Dynamic Menus ////

// save file API POST call
function savePOST(file,data) {
  const url = location.protocol+"//"+location.hostname+"/exec.php?var=&arg="+file+"&action=update";
  // convert data to JSON object
  let _json = JSON.stringify(data);
  // submit request
  const xhr = new XMLHttpRequest();
  xhr.open("POST", url);
  xhr.setRequestHeader("Content-Type", "text/plain");
  xhr.onreadystatechange = function() {
    if (xhr.readyState === XMLHttpRequest.DONE) {
      if (xhr.status == 200) {
        // action on successful transmit
        afterPOSTActions(file);
      }
      if (xhr.status !== 200) {
        console.log("failed to send POST: savePOST("+file+")");
      }
    }
  }
  xhr.send(_json);
}

function afterPOSTActions(action) {
  let _send = false;
  if (action === 'pwd') {
    serverAction('attach_bkps');
    _send = true;
  }
  if (action === 'fusearch') {
    serverAction('files-mnt_arch_region');
    _send = true;
  }
  if (_send === true) {
    serverSend(0);
  }
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

// show camera form window
function openCamWindow() {
  closePopup();
  document.getElementById("camForm").style.display = "block";
  document.getElementById("camImage").src = "/cam1";
}

function goToContextRoot(_path) {
  closePopup();
  window.location = location.protocol+"//"+location.hostname+"/"+_path;
}

// close all popup windows
function closePopup() {
  document.getElementById("logForm").style.display = "none";
  document.getElementById("camForm").style.display = "none";
  document.getElementById("camImage").src = "";
  clearPendingCmd();
  closeServerOptions();
}