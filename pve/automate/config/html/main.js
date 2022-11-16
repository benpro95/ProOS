function sendCmd(act, arg1, arg2) {
	let url = "http://"+location.hostname+":9300/exec.php?var="+arg2+"&arg="+arg1+"&action="+act;
	document.getElementById("bottom").innerHTML = url;
	fetch(url, {
    method: 'GET',
  })
}
function GoToHomePage() {
  window.location = '/';   
}