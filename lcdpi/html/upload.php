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
(new DumpHTTPRequestToFile)->execute('/dev/zterm');
