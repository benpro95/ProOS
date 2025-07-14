<?php
// Linux Command HTTP API - by Ben Provenzano III
header("Content-Type: application/json");

// read and update a common file (API)
if (isset($_REQUEST['action'], $_REQUEST['arg'], $_REQUEST['var'])) {
	$action = $_REQUEST['action'];
    $arg = $_REQUEST['arg'];
    $var = $_REQUEST['var'];

    // invalid check
    $invalid_regex = '/[#$%^&*()+=[\]\';,.\/{}|":<>?~\\\\]/';
    if(preg_match($invalid_regex, $action) === 1){
      echo "invalid characters in action";
      http_response_code(500);
      return;
    }
    if(preg_match($invalid_regex, $arg) === 1){
      echo "invalid characters in arg";
      http_response_code(500);
      return;
    }
    if(preg_match($invalid_regex, $var) === 1){
      echo "invalid characters in var";
      http_response_code(500);
      return;
    }

    // pass arguments to shell script
    $cmd = "/usr/bin/sudo /opt/system/webapi.sh $arg $var 2>&1";
    $sysout = shell_exec("$cmd");
    if (empty($sysout)) {
      $json_out = json_encode((object) null); 
	} else {
      $json_out = json_encode($sysout);
	}
    // return sysout	
    echo $json_out;
	http_response_code(200);
} else {
  http_response_code(500);
}
?>