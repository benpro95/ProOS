<?php

/**
 * ProOS Settings Portal
 * 
 * 
 * @author     Ben Provenzano III <benprovenzano@gmail.com>
 * @license    GNU General Public License, version 3 (GPL-3.0)
 * @version    2.0
 */

//define('RASPI_CONFIG', '/etc/proos');
//define('RASPI_ADMIN_DETAILS', RASPI_CONFIG.'/proos.auth');

// Constants for configuration file paths.
// These are typical for default RPi installs. Modify if needed.
define('RASPI_DNSMASQ_CONFIG', '/tmp/dnsmasq.tmp');
define('RASPI_DNSMASQ_LEASES', '/tmp/dnsmasq.leases.tmp');
define('RASPI_HOSTAPD_CONFIG', '/etc/hostapd/hostapd.conf');
define('RASPI_WPA_SUPPLICANT_CONFIG', '/etc/wpa_supplicant/wpa_supplicant.conf');
define('RASPI_HOSTAPD_CTRL_INTERFACE', '/var/run/hostapd');
define('RASPI_WPA_CTRL_INTERFACE', '/var/run/wpa_supplicant');
define('RASPI_OPENVPN_CLIENT_CONFIG', '/tmp/openvpn.tmp');
define('RASPI_OPENVPN_SERVER_CONFIG', '/tmp/openvpn-svr.tmp');
define('RASPI_TORPROXY_CONFIG', '/tmp/torproxy.tmp');

// Optional services, set to true to enable.
define('RASPI_OPENVPN_ENABLED', false );
define('RASPI_TORPROXY_ENABLED', false );

//include_once( RASPI_CONFIG.'/proos.php' );
include_once( 'includes/functions.php' );
include_once( 'includes/dashboard.php' );
//include_once( 'includes/authenticate.php' );
include_once( 'includes/admin.php' );
include_once( 'includes/hostapd.php' );
include_once( 'includes/system.php' );
include_once( 'includes/configure_client.php' );

$output = $return = 0;
$page = $_GET['page'];

session_start();
if (empty($_SESSION['csrf_token'])) {
    if (function_exists('mcrypt_create_iv')) {
        $_SESSION['csrf_token'] = bin2hex(mcrypt_create_iv(32, MCRYPT_DEV_URANDOM));
    } else {
        $_SESSION['csrf_token'] = bin2hex(openssl_random_pseudo_bytes(32));
    }
}
$csrf_token = $_SESSION['csrf_token'];
?>

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="">
    <meta name="author" content="">

    <title>RaspberryPi Settings</title>

    <!-- Bootstrap Core CSS -->
    <link href="bower_components/bootstrap/dist/css/bootstrap.min.css" rel="stylesheet">

    <!-- MetisMenu CSS -->
    <link href="bower_components/metisMenu/dist/metisMenu.min.css" rel="stylesheet">

    <!-- Timeline CSS -->
    <link href="dist/css/timeline.css" rel="stylesheet">

    <!-- Custom CSS -->
    <link href="dist/css/sb-admin-2.css" rel="stylesheet">

    <!-- Morris Charts CSS -->
    <link href="bower_components/morrisjs/morris.css" rel="stylesheet">

    <!-- Custom Fonts -->
    <link href="bower_components/font-awesome/css/font-awesome.min.css" rel="stylesheet" type="text/css">

    <!-- Custom CSS -->
    <link href="dist/css/custom.css" rel="stylesheet">
    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
        <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
        <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>
  <body>

    <div id="wrapper">
      <!-- Navigation -->
      <nav class="navbar navbar-default navbar-static-top" role="navigation" style="margin-bottom: 0">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="/">RaspberryPi Home</a>
        </div>
        <!-- /.navbar-header -->

        <!-- Navigation -->
        <div class="navbar-default sidebar" role="navigation">
          <div class="sidebar-nav navbar-collapse">
            <ul class="nav" id="side-menu">
              <li>
                <a href="index.php?page=wlan0_info"><i class="fa fa-dashboard fa-fw"></i> Network Dashboard</a>
              </li>
              <li>
                <a href="index.php?page=wpa_conf"><i class="fa fa-signal fa-fw"></i> Configure WiFi</a>
              </li>
              <li>
                <a href="index.php?page=hostapd_conf"><i class="fa fa-dot-circle-o fa-fw"></i> Hotspot Info</a>
              </li>
              <?php if ( RASPI_OPENVPN_ENABLED ) : ?>
              <li>
                <a href="index.php?page=openvpn_conf"><i class="fa fa-lock fa-fw"></i> Configure OpenVPN</a>
              </li>
              <?php endif; ?>
              <?php if ( RASPI_TORPROXY_ENABLED ) : ?>
              <li>
                 <a href="index.php?page=torproxy_conf"><i class="fa fa-eye-slash fa-fw"></i> Configure TOR proxy</a>
              </li>
              <?php endif; ?>
              <li>
                 <a href="index.php?page=system_info"><i class="fa fa-cube fa-fw"></i> System</a>
              </li>
            </ul>
          </div><!-- /.navbar-collapse -->
        </div><!-- /.navbar-default -->
      </nav>

      <div id="page-wrapper">

        <!-- Page Heading -->
        <div class="row">
          <div class="col-lg-12">
            <h1 class="page-header">
              <img class="logo" src="img/proos-logo.png" width="45" height="45">RaspberryPi
            </h1>
          </div>
        </div><!-- /.row -->

        <?php 
        // handle page actions
        switch( $page ) {
          case "wlan0_info":
            DisplayDashboard();
            break;
          case "wpa_conf":
            DisplayWPAConfig();
            break;
          case "hostapd_conf":
            DisplayHostAPDConfig();
            break;
          case "dhcpd_conf":
            DisplayDHCPConfig();
            break;
          case "openvpn_conf":
            DisplayOpenVPNConfig();
            break;
          case "torproxy_conf":
            DisplayTorProxyConfig();
            break;
          case "auth_conf":
            DisplayAuthConfig($config['admin_user'], $config['admin_pass']);
            break;
          case "save_hostapd_conf":
            SaveTORAndVPNConfig();
            break;
          case "system_info":
            DisplaySystem();
            break;
          default:
            DisplayDashboard();
        }
        ?>
      </div><!-- /#page-wrapper --> 
    </div><!-- /#wrapper -->

    <!-- proos JavaScript -->
    <script src="dist/js/functions.js"></script>

    <!-- jQuery -->
    <script src="bower_components/jquery/dist/jquery.min.js"></script>

    <!-- Bootstrap Core JavaScript -->
    <script src="bower_components/bootstrap/dist/js/bootstrap.min.js"></script>

    <!-- Metis Menu Plugin JavaScript -->
    <script src="bower_components/metisMenu/dist/metisMenu.min.js"></script>

    <!-- Morris Charts JavaScript -->
    <!--script src="bower_components/raphael/raphael-min.js"></script-->
    <!--script src="bower_components/morrisjs/morris.min.js"></script-->
    <!--script src="js/morris-data.js"></script-->

    <!-- Custom Theme JavaScript -->
    <script src="dist/js/sb-admin-2.js"></script>
  </body>
</html>
