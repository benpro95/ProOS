<?php
header("Content-Type: application/json");

// read and update a common file (API)

if (isset($_REQUEST['file'], $_REQUEST['action'])) {
    $file = $_REQUEST['file'];
    $action = $_REQUEST['action'];

    // build paths
    $basepath = '/var/www/html/ram/';
    $filepath = $basepath . $file . '.txt';

    // read file action
    if ($action === 'read') {
	    // text data to JSON response
		$fp = @fopen($filepath, 'r'); 
		if ($fp) {
		  $array = explode(PHP_EOL, fread($fp, filesize($filepath)));
		}
		$json_out = json_encode($array);
		if ($json_out === false) {
		  $json_out = json_encode(["jsonError" => json_last_error_msg()]);
		  http_response_code(500);
		}
		echo $json_out;
		return;
	}

	// update file action
	if ($action === 'update') {
		// JSON -> File
		$json_in  = file_get_contents('php://input');
		$table = json_decode($json_in);
        if (!empty($table)) {
			$text = "";
			foreach($table as $key => $value) {
			  $text .= $value."\n";
			}
			$fh = fopen($filepath, "w");
			fwrite($fh, $text);
			fclose($fh);
			http_response_code(200);
			return;
        }
    }

// catch errors
    http_response_code(500);
} else {
  http_response_code(500);
}
?>