var saltValue = null;

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

