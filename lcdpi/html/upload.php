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

// write to FIFO
passthru('rm -f /tmp/data.txt');
passthru('touch /tmp/data.txt');
(new DumpHTTPRequestToFile)->execute('/tmp/data.txt');
passthru('cat /tmp/data.txt > /dev/zterm');