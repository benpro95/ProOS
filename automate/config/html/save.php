$headers = array();
foreach($_SERVER as $key => $value) {
    if (substr($key, 0, 5) <> 'HTTP_') {
        continue;
    }
    $headers[$key] = ($value);
}

file_put_contents("/tmp/post.json", json_encode($headers));