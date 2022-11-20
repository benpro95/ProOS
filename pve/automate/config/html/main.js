// globals
var vol_mode = 1;
var relax_mode = 1;
var load_bar = 0;
var console_data = null;
var servercmd_data = null;
var promptCount = 0;
var saltValue = null;

const cipher = salt => {
    const textToChars = text => text.split('').map(c => c.charCodeAt(0));
    const byteHex = n => ("0" + Number(n).toString(16)).substr(-2);
    const applySaltToChar = code => textToChars(salt).reduce((a,b) => a ^ b, code);

    return text => text.split('')
      .map(textToChars)
      .map(applySaltToChar)
      .map(byteHex)
      .join('');
}
    
const decipher = salt => {
    const textToChars = text => text.split('').map(c => c.charCodeAt(0));
    const applySaltToChar = code => textToChars(salt).reduce((a,b) => a ^ b, code);
    return encoded => encoded.match(/.{1,2}/g)
      .map(hex => parseInt(hex, 16))
      .map(applySaltToChar)
      .map(charCode => String.fromCharCode(charCode))
      .join('');
}

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

// load server action 
function serverAction(cmd) {
  servercmd_data = cmd;
  document.getElementById("logTextBox").value = "Click send to request action.";
};

// send server action
function serverSend(mask) {
  if (servercmd_data == null) {
    document.getElementById("logTextBox").value = "Select an action.";
  } else {
    var cmd_text;
    if (mask == 1) {
       cmd_text = "xxxxx";
    } else {
       cmd_text = servercmd_data;
    }
    document.getElementById("logTextBox").value = "Please wait one-minute, transmitted the command ("+cmd_text+")";
    showSpinner();
    // request server data
    sendCmd('main','server',servercmd_data);
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

// load entire text file
async function loadLog(url) {
  try {
    const response = await fetch(url);
    console_data = await response.text(); 
    document.getElementById("logTextBox").value = console_data;
  } catch (err) {
    console.error(err);
  }
  console_data = null;
  hideSpinner();
};

// load first line of text file
async function loadSalt(url) {
  saltValue = null;
  try {
    const response = await fetch(url);
    const data = await response.text(); 
    saltValue = data.split('\n').shift(); // first line
  } catch (err) {
    console.error(err);
  }
};

// load salt then show the password prompt
async function passPrompt(url) {
    let res = null;
    try {
        res = await Promise.all([
            loadSalt(url),
            passPromptWindow()
        ]);
        console.log(' Salt read success >>', res);
    } catch (err) {
        console.log('Salt read fail >>', res, err);
    }
  saltValue = null;
}

async function passPromptWindow(){
  var result;
  try{
    result = await passwordPrompt("please enter your password");
    if (result != null ) {
      if (result != "" ) {
        // valid password
        document.getElementById("logTextBox").value = " Please wait one-minute for drives to attach.";
        // To create a cipher using salt key
        const cipher_data = cipher(saltValue);
        // hash password
        var enc_key = cipher_data(result);
        // trasnmit to server
        serverAction("backup_pwd-"+enc_key);
        serverSend(1);
        enc_key = null;
      }
    }    
  } catch(e){
    result = "Password Error!";
    document.getElementById("bottom").innerHTML = result;
  }
  result = null;
};

function passwordPrompt(text){
/*creates a password-prompt instead of a normal prompt*/
/* first the styling - could be made here or in a css-file. looks very silly now but its just a proof of concept so who cares */
var width=280;
var height=150;
var pwprompt = document.createElement("div"); //creates the div to be used as a prompt
pwprompt.id= "password_prompt"; //gives the prompt an id - not used in my example but good for styling with css-file
pwprompt.style.left = ((window.innerWidth / 2) - (width / 2)) + "px"; //let it apear in the middle of the page
pwprompt.style.top = ((window.innerWidth / 2) - (width / 2)) + "px"; //let it apear in the middle of the page
pwprompt.style.width = width + "px";
pwprompt.style.height = height + "px";
var pwtext = document.createElement("div"); //create the div for the password-text
pwtext.innerHTML = text; //put inside the text
pwprompt.appendChild(pwtext); //append the text-div to the password-prompt
var pwinput = document.createElement("input"); //creates the password-input
pwinput.id = "password_id"; //give it some id - not really used in this example...
pwinput.type="password"; // makes the input of type password to not show plain-text
pwprompt.appendChild(pwinput); //append it to password-prompt
var pwokbutton = document.createElement("button"); //the ok button
pwokbutton.innerHTML = "ok";
var pwcancelb = document.createElement("button"); //the cancel-button
pwcancelb.innerHTML = "cancel";
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
      } 
      document.body.removeChild(pwprompt);  //as we are done clean up by removing the password-prompt

    });
    pwinput.addEventListener('keyup',function handleEnter(e){ //users dont like to click on buttons
        if(e.keyCode == 13){ //if user enters "enter"-key on password-field
            resolve(pwinput.value); //return password-value
            document.body.removeChild(pwprompt); //clean up by removing the password-prompt
        }else if(e.keyCode==27){ //user enters "Escape" on password-field
            document.body.removeChild(pwprompt); //clean up the password-prompt
        }
    });
}); 
}





