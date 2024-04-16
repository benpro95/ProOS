// Home Automation Website
// by Ben Provenzano III

// globals
let defaultSite = "Automate";
let device = null;
let selectedVM = "";
let colorPromptActive = 0;
let toggledPageMode = 0;
let loadBarState = 0;
let promptCount = 0;
let arcState = 0;
let currentTheme = null;
let serverCmdData = null;
let socket = null;
let fileData = [];
let dynMenuActive = 0;
let dynChkboxChanged = 0;

//////////////////////////

// hide menu's when clicking outside
document.addEventListener('click', function handleClickOutsideBox(event) {
  // don't hide when clicking these elements
  if (! event.target.classList.contains('button') &&
      ! event.target.classList.contains('button__text') &&
      ! event.target.classList.contains('fa-regular') &&
      ! event.target.classList.contains('fa-solid') &&
      ! event.target.classList.contains('dropbtn') &&  
      ! event.target.classList.contains('chkbox') &&  
      ! event.target.classList.contains('mainmenu__anchor')) {
    hideDropdowns();
  }
});

// a checkbox was clicked
document.addEventListener('click', function handleClickCheckbox(event) {
  if (event.target.classList.contains('chkbox')) {
    dynChkboxChanged = 1;
  }
});

// resize event
window.onresize = function(event) {
  resizeEvent();
};

// hide all drop down menus
function hideDropdowns() {
  classDisplay("dropdown-content","none");
  // remove any current dynamic menus
  removeDynMenus();
}

// runs on page load
function loadPage() {
  // read device type
  device = deviceType(); 
  // resize button grid
  resizeEvent();
  if (device === defaultSite) {
    // volume mode switch
    volMode();
    // server home
    classDisplay('server-grid','block');
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
  // set title
  let elem = document.getElementById("load__bar");
  elem.textContent = defaultSite; 
  // read theme from local storage or choose default
  currentTheme = localStorage.getItem("styledata") || "darkblue-theme";
  setTheme(currentTheme);
}

function showLEDsPage() {
  hidePages();
  classDisplay('led-grid','block');
}

function showSoundsPage() {
  toggledPageMode = 0;
  hidePages();
  relaxMode();
  classDisplay('sounds-grid','block');
}

function hidePages() {
  classDisplay('server-grid','none');  
  classDisplay('sounds-grid','none');
  classDisplay('pi-grid','none'); 
  classDisplay('lcdpi-grid','none');
  classDisplay('ledpi-grid','none');
  classDisplay('led-grid','none');
}

function setTheme(newTheme) {
  let body = document.getElementsByTagName("html")[0];
  // Remove old theme scope from body's class list
  body.classList.remove(currentTheme);
  // Add new theme scope to body's class list
  body.classList.add(newTheme);
  // Set it as current theme
  currentTheme = newTheme;
  // Store the new theme in local storage
  localStorage.setItem("styledata", newTheme);
}

function resizeEvent() {
  if (device != 'LCDpi') {
    // auto re-size on all other devices
    if (window.innerWidth < 860) {
      classDisplay('parsplit','block');
    } else {
      classDisplay('parsplit','none');
    }
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

function detectMobile() {
  if (navigator.userAgent.match(/Android/i) ||
      navigator.userAgent.match(/webOS/i)   ||
      navigator.userAgent.match(/iPhone/i)  || 
      navigator.userAgent.match(/iPad/i)) {
        console.log("Mobile Browser");
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
    toggledPageMode = 0;
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
  //the cancel-button
  let vms_cancelb = document.createElement("button"); 
  vms_cancelb.innerHTML = "Close";
  vms_cancelb.className ="button button_vmctrls_close"; 
  vms_cancelb.type="button"; 
  vms_prompt.appendChild(vms_cancelb); //append cancel-button
  //the dev-button 
  let vms_devbtn = document.createElement("button"); 
  vms_devbtn.innerHTML = "Development";
  vms_devbtn.className ="button button_vmctrls"; 
  vms_devbtn.type="button"; 
  vms_prompt.appendChild(vms_devbtn); 
  //the unifi-button 
  let vms_unifibtn = document.createElement("button"); 
  vms_unifibtn.innerHTML = "UniFi Controller";
  vms_unifibtn.className ="button button_vmctrls"; 
  vms_unifibtn.type="button"; 
  vms_prompt.appendChild(vms_unifibtn); 
  //the cifs-button 
  let vms_cifsbtn = document.createElement("button"); 
  vms_cifsbtn.innerHTML = "Legacy CIFS";
  vms_cifsbtn.className ="button button_vmctrls"; 
  vms_cifsbtn.type="button"; 
  vms_prompt.appendChild(vms_cifsbtn); 
  //the xana-button 
  let vms_xanabtn = document.createElement("button"); 
  vms_xanabtn.innerHTML = "Xana";
  vms_xanabtn.className ="button button_vmctrls"; 
  vms_xanabtn.type="button"; 
  vms_prompt.appendChild(vms_xanabtn); 
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
  // restore button (hidden)
  let vms_restorebtn = document.createElement("button"); 
  vms_restorebtn.innerHTML = "Erase";
  vms_restorebtn.className ="button button_vmactions";
  vms_restorebtn.id = "vms__restorebtn";
  vms_restorebtn.type="button";
  vms_restorebtn.style.display = "none";
  // open button (hidden)
  let vms_openbtn = document.createElement("button"); 
  vms_openbtn.innerHTML = "Open";
  vms_openbtn.className ="button button_vmactions";
  vms_openbtn.id = "vms__openbtn";
  vms_openbtn.type="button";
  vms_openbtn.style.display = "none";
  // button order
  vms_prompt.appendChild(vms_restorebtn);
  vms_prompt.appendChild(vms_openbtn);
  vms_prompt.appendChild(vms_stopbtn); 
  vms_prompt.appendChild(vms_startbtn);
  //append the prompt so it gets visible
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
              serverAction('files-arc_region');
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
	          let _text = "Click send to confirm restore of " + selectedVM;
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

function show_wifiPrompt(text){
  let wifiprompt = document.createElement("div"); //creates the div to be used as a prompt
  wifiprompt.id= "wifi__prompt"; //gives the prompt an id - not used in my example but good for styling with css-file
  let wifitext = document.createElement("div"); //create the div for the password-text
  wifitext.innerHTML = text; //put inside the text
  wifiprompt.appendChild(wifitext); //append the text-div to the password-prompt   wifi__img
  let img = document.createElement("img");
  img.src = "img/wifi.png";
  img.id = "wifi__img";
  wifiprompt.appendChild(img);
  let wificancelb = document.createElement("button"); //the cancel-button
  wificancelb.innerHTML = "Close";
  wificancelb.className ="button"; 
  wificancelb.type="button"; 
  wifiprompt.appendChild(wificancelb); //append cancel-button
  document.body.appendChild(wifiprompt); //append the password-prompt so it gets visible
  new Promise(function(resolve, reject) {
      wifiprompt.addEventListener('click', function handleButtonClicks(e) { //lets handle the buttons
        if (e.target.tagName !== 'BUTTON') { return; } //nothing to do - user clicked somewhere else
	        wifiprompt.removeEventListener('click', handleButtonClicks); //removes eventhandler on cancel or ok
	        document.body.removeChild(wifiprompt);  //as we are done clean up by removing the password-prompt
      });
  });   
}

async function wifiPrompt(){
  await show_wifiPrompt("Scan for WiFi Access:");
}

function passwordPrompt(text){
  let pwprompt = document.createElement("div"); //creates the div to be used as a prompt
  pwprompt.id= "pass__prompt"; //gives the prompt an id - not used in my example but good for styling with css-file
  let pwtext = document.createElement("div"); //create the div for the password-text
  pwtext.innerHTML = text; //put inside the text
  pwprompt.appendChild(pwtext); //append the text-div to the password-prompt
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
  pwcancelb.className ="button"; 
  pwcancelb.type="button"; 
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
    result = await passwordPrompt("Enter password:");
    if (result !== null) {  
      if (result !== '') {  
        savePOST('pwd',result);
      }
    } 
    result = "";
  } catch(e){
    result = "";
  }
}

// save file API POST call
function savePOST(file,data) {
  const url = location.protocol+"//"+location.hostname+"/update.php?file="+file+"&action=update"; 
  // convert data to JSON object
  let _json = JSON.stringify([data]);
  // Send Base64 data as HTTP POST request
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

// switch volume controls on main page
function volMode() {   
  let id = document.getElementById("sub__text");
  if (toggledPageMode === 1) {
     id.textContent = "Subwoofers";
     toggledPageMode = 0;
  } else {  
     id.textContent = "Bedroom";
     toggledPageMode = 1;
  }
}

// switch volume controls on bedroom page
function relaxMode() {   
  let id = document.getElementById("relax__text");
  if (toggledPageMode === 1) {
     id.textContent = "HiFi";
     toggledPageMode = 0;
  } else {  
     id.textContent = "Bedroom";
     toggledPageMode = 1;
  }
}

function relaxSend(_cmd) {
  let _mode;
  // volume mode
  if (_cmd === 'vup' 
   || _cmd === 'vdwn'
   || _cmd === 'vmute') {
    _mode = _cmd;
    if (toggledPageMode === 0) {
      _cmd = 'hifi';
    } else {
      _cmd = 'bedroom';
    } 
  } else {
    // relax mode
    _mode = 'relax';
    if (toggledPageMode === 0) {
      _cmd = _cmd+"-hifi";
    } 
  }
  sendCmd('main',_mode,_cmd);
}

function toggledVol(_mode) {
  if (toggledPageMode === 0) {
    _cmd = 'subs';
  } else {
    _cmd = 'bedroom';
  } 
  sendCmd('main',_mode,_cmd);
}

// send server action
async function serverSend() {
  if (serverCmdData === null) {
    document.getElementById("logTextBox").value = "select an option.";
  } else {
    // animations
    loadBar(3.0);
    sendBtnAlert("off");
    // send command
    if (device === defaultSite) {
      sendCmdNoBar('main','server',serverCmdData);
    } else {
      sendCmdNoBar('main-www','server',serverCmdData);
    }
    // display command sent
    document.getElementById("logTextBox").value += "\ncommand sent, click load to refresh log.";
    // scroll to bottom of page
    let txtArea = document.getElementById("logTextBox");
    txtArea.scrollTop = txtArea.scrollHeight;    
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

// transmit command for server
function sendCmd(act, arg1, arg2) {
  // animation
  loadBar(0.3);
  sendGET(act,arg1,arg2);
}

function sendCmdNoBar(act, arg1, arg2) {
  sendGET(act,arg1,arg2);
}

// API GET call
function sendGET(act, arg1, arg2) {
  // construct API string
  const url = location.protocol+"//"+location.hostname+"/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
  // send data
  fetch(url, {
      method: 'GET',
    })
}

//// Dynamic Menus ////

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

function showDynMenu(_menu) {
  let _elem = document.getElementById(_menu);
  if (_elem.style.display === 'block') {
    _elem.style.display = 'none';
  } else {
    hideDropdowns();
    // dynamic LED selection menu
    readMenuData(_menu);
    _elem.style.display = 'block';
  }
}

// build menu
function readMenuData(menu) {
  // build URL / append data
  const url = location.protocol+"//"+location.hostname+"/update.php?file="+menu+"&action=read";
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
  for (var i = 0; i < fileData.length; i++) {
    let line = fileData[i].toString();
    if (i == 0) { // store first line (ID)
      _id = line;
    } else { // verify data matches
      if (_id == _menu) {
        const item = line.split("|");
        const _host = item[0];
        const _state = item[1];
        const _name = item[2].trim();
        // 0=Host,1=State,2=Name,Menu ID
        drawMenu(_host,_state,_name,_menu);
      }
    }
  }  
}

function drawMenu(url,state,name,menu) {
  const navElement = document.getElementById(menu);
  const createListItem = (navItem,url,state) => {
    const _menuid = navItem
      .trim()
      .split(" ")
      .join("");
    const li = document.createElement('a');
    const _elmname = "menu-" + _menuid;
    li.id = _elmname;
    li.innerText = navItem;
    // draw menus
    if (state == '0' || state == '1') {
      // URL on click
      li.href = url;
      // add checkbox
      var checkbox = document.createElement('input');
      checkbox.type = "checkbox";
      checkbox.className = "chkbox";
      checkbox.id = "chkbox-" + navItem;
      li.appendChild(checkbox);
    }
    if (state == '2') {
      // URL on click, no checkbox
      li.href = url;
    }
    if (state == '3' || state == '4' || state == '5') {
      // add indicator dot
      var dot = document.createElement('span');
      dot.className = "ind_dot";
      if (state == '4'){
        dot.className += " ind_dot_green";
      }
      if (state == '5'){
        dot.className += " ind_dot_red";
      }
      dot.id = "ind-" + navItem;
      li.appendChild(dot);
    }
    return li;
  };
  navElement.appendChild(createListItem(name,url,state));
  // read checkbox state from file
  if (state == '0') {
    document.getElementById("chkbox-" + name).checked = false;
  }
  if (state == '1') {
    document.getElementById("chkbox-" + name).checked = true;
  }
  dynMenuActive = 1;
}

function removeDynMenus() {
  // only if menu is on-screen 
  if (dynMenuActive == 1) {
    // checkbox changed action (I)
    if (dynChkboxChanged == 1) {
      boxChanged();
    }
    // remove dynamic menu elements (II)
    for (var i = 0; i < fileData.length; i++) {
      let line = fileData[i].toString();
      if (i !== 0) { // skip menu ID
        const item = line.split("|");
        if (item) {
          const _menuid = item[2].toString()
            .trim()
            .split(" ")
            .join("");
          const navItem = "menu-" + _menuid;
          //console.log(navItem);
          var menuRemove = document.getElementById(navItem);
          if (menuRemove != null) {
            menuRemove.remove();
          }
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
function updateMenuData(menu) {
  let encoded = "";
  let id = "";
  // store ID object
  id = fileData[0];
  // remove first ID object
  fileData.shift();
  // convert array to JSON object
  let _json = JSON.stringify(fileData);
  // clear global data
  while (fileData.length) { fileData.pop(); }    
  // build URL / append data
  const url = location.protocol+"//"+location.hostname+"/update.php?file="+menu+"&action=update"; 
  // verify correct menu is in array
  if (id === menu) {
    // Send Base64 data as HTTP POST request
    const xhr = new XMLHttpRequest();
    xhr.open("POST", url);
    xhr.setRequestHeader("Content-Type", "text/plain");
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status != 200) {
          console.log("failed to send POST: updateMenuData()");
        }
      }
    }
    xhr.send(_json);
  }  
}

//// End Dynamic Menus ////

// load entire text file
async function loadLog(file) {
  try {
    // build URL / append data
    let _textData = " ";
    const url = location.protocol+"//"+location.hostname+"/update.php?file=sysout&action=read";
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
  // Create the HTTP POST request
    savePOST('message',data);
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
