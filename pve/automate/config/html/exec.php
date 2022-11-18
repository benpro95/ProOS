<?php

header("HTTP/1.1 200 OK");
if (isset($_REQUEST['action'], $_REQUEST['arg'], $_REQUEST['var'])) {
    $arg = $_REQUEST['arg'];
    $var = $_REQUEST['var'];
    $action = $_REQUEST['action'];
    $cmd = "/usr/bin/screen -dm /usr/bin/sudo /opt/system/$action $arg $var";
    system("$cmd");
}
?>
