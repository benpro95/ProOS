<?php
// Save JSON POST request body data to file

class DumpHTTPRequestToFile {
	public function execute($targetFile) {
		file_put_contents(
			$targetFile,
		    file_get_contents('php://input') . "\n"
		);
	}
}

// write to file
passthru('rm -f /tmp/message.txt');
passthru('touch /tmp/message.txt');
(new DumpHTTPRequestToFile)->execute('/tmp/message.txt');
// send to Z-terminal
passthru('/opt/rpi/main message');


