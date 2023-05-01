// globals
var vol_mode = 1;
var relax_mode = 1;
var load_bar = 0;
var console_data = null;
var servercmd_data = null;
var promptCount = 0;

// on-page-load
window.onload = function() {
  const mainpg = "https://"+location.hostname+"/"
  // load volume mode support on main page only
  if (window.location.href == mainpg) {
    volMode();
  }else{
    vol_mode = 0;  
  }
  // load relax mode support on bedroom page only
  const roompg = "https://"+location.hostname+"/room.html"
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
  window.location = "https://"+location.hostname+"/cam1";
};

// password prompt
function getPasswordB()
{
    var pwd = prompt('Enter password:', '');
    if(pwd != null)
    {
        if(pwd != '')
        {
            savePOST(pwd);
            serverAction('attach_bkps');
            pwd = "";
            return true;
        }
    }
    return false;
}


function passwordPrompt(text){
/*creates a password-prompt instead of a normal prompt*/
/* first the styling - could be made here or in a css-file.*/
var width=200;
var height=120;
var pwprompt = document.createElement("div"); //creates the div to be used as a prompt
pwprompt.id= "password_prompt"; //gives the prompt an id - not used in my example but good for styling with css-file
pwprompt.style.position = "fixed"; //make it fixed as we do not want to move it around
pwprompt.style.left = ((window.innerWidth / 2) - (width / 2)) + "px"; //let it apear in the middle of the page
pwprompt.style.top = ((window.innerWidth / 2) - (width / 2)) + "px"; //let it apear in the middle of the page
pwprompt.style.border = "1px solid black"; //give it a border
pwprompt.style.padding = "16px"; //give it some space
pwprompt.style.background = "white"; //give it some background so its not transparent
pwprompt.style.zIndex = 99999; //put it above everything else - just in case

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
    result = await passwordPrompt("Enter password:");
    savePOST(result);
    serverAction('attach_bkps');
    serverSend(0);
  } catch(e){
    alert("Canceled");
  }
}

// save file
function savePOST(data) {
  fetch("https://"+location.hostname+"/upload.php", {
      method: 'POST',
      headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
      },
      body: data
  })
  data = "";
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
  let url = "https://"+location.hostname+"/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
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
    const url = "https://"+location.hostname+"/ram/sysout.txt"+"?ver="+timestamp;
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








