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
		// open the file in read mode
		$file = new SplFileObject($filepath, 'r');
		// get the total lines
		$file->seek(PHP_INT_MAX);
		$last_line = $file->key();
		// Rewind to first line to get header
		$file->rewind();
		// selecting the line limit
		$line_limit = 2000;
		if ($last_line > $line_limit) {
		  // selecting the last lines using the limit
		  $file = new LimitIterator($file, ($last_line - $line_limit), $last_line);
		}
		// new array
        $array = array();
        // write each line to array
		foreach ($file as $line) {
		    $array[] = rtrim($line, "\n\r\t\v\x00");
		}
		if (!empty($array)) {
			// convert array to JSON object
		    $json_out = json_encode($array);
		    // valid object has data
			if ($json_out === false) {
			  $json_out = json_encode(["jsonError" => json_last_error_msg()]);
			  http_response_code(500);
			}
			echo $json_out;
			return;
	    }
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
?>dev