<?php
header("HTTP/1.1 200 OK");
if (isset($_REQUEST['action'], $_REQUEST['arg'], $_REQUEST['var'])) {
    $arg = $_REQUEST['arg'];
    $var = $_REQUEST['var'];
    $action = "wwwcmds";
    $cmd = "/usr/bin/screen -dm /usr/bin/sudo -u server /usr/bin/$action $arg $var";
    system("$cmd");
}
?>
