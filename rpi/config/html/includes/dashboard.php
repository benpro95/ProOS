<?php

/**
*
*
*/
function DisplayDashboard(){

  $status = new StatusMessages();

  exec( 'ifconfig wlan0', $return );
  exec( 'iwconfig wlan0', $return );
  exec( 'ifconfig eth0', $returneth );

  $strEth0 = implode( " ", $returneth );
  $strEth0 = preg_replace( '/\s\s+/', ' ', $strEth0 );

  $strWlan0 = implode( " ", $return );
  $strWlan0 = preg_replace( '/\s\s+/', ' ', $strWlan0 );

  // Parse results from ifconfig/iwconfig
  preg_match( '/ether ([0-9a-f:]+)/i',$strWlan0,$result );
  $strHWAddress = $result[1];
  preg_match( '/inet ([0-9.]+)/i',$strWlan0,$result );
  $strIPAddress = $result[1];
  preg_match( '/netmask ([0-9.]+)/i',$strWlan0,$result );
  $strNetMask = $result[1];
  preg_match( '/RX packets (\d+)/',$strWlan0,$result );
  $strRxPackets = $result[1];
  preg_match( '/TX packets (\d+)/',$strWlan0,$result );
  $strTxPackets = $result[1];
  preg_match( '/UNRX bytes (\d+ \(\d+.\d+ [K|M|G]iB\))/i',$strWlan0,$result );
  $strRxBytes = $result[1];
  preg_match( '/UNTX bytes (\d+ \(\d+.\d+ [K|M|G]iB\))/i',$strWlan0,$result );
  $strTxBytes = $result[1];
  preg_match( '/ESSID:\"([a-zA-Z0-9\s]+)\"/i',$strWlan0,$result );
  $strSSID = str_replace( '"','',$result[1] );
  preg_match( '/Access Point: ([0-9a-f:]+)/i',$strWlan0,$result );
  $strBSSID = $result[1];
  preg_match( '/Bit Rate=([0-9\.]+ Mb\/s)/i',$strWlan0,$result );
  $strBitrate = $result[1];
  preg_match( '/Tx-Power=([0-9]+ dBm)/i',$strWlan0,$result );
  $strTxPower = $result[1];
  preg_match( '/Link Quality=([0-9]+)/i',$strWlan0,$result );
  $strLinkQuality = $result[1];
  preg_match( '/Signal level=(-?[0-9]+ dBm)/i',$strWlan0,$result );
  $strSignalLevel = $result[1];
  preg_match('/Frequency:(\d+.\d+ GHz)/i',$strWlan0,$result);
  $strFrequency = $result[1];

  // Parse results from ifconfig/eth
  preg_match( '/ether ([0-9a-f:]+)/i',$strEth0,$resulteth );
  $strethHWAddress = $resulteth[1];
  preg_match( '/inet ([0-9.]+)/i',$strEth0,$resulteth );
  $strethIPAddress = $resulteth[1];
  preg_match( '/netmask ([0-9.]+)/i',$strEth0,$resulteth );
  $strethNetMask = $resulteth[1];
  preg_match( '/RX packets (\d+)/',$strEth0,$resulteth );
  $strethRxPackets = $resulteth[1];
  preg_match( '/TX packets (\d+)/',$strEth0,$resulteth );
  $strethTxPackets = $resulteth[1];
  preg_match( '/UNRX bytes (\d+ \(\d+.\d+ [K|M|G]iB\))/i',$strEth0,$resulteth );
  $strethRxBytes = $resulteth[1];
  preg_match( '/UNTX bytes (\d+ \(\d+.\d+ [K|M|G]iB\))/i',$strEth0,$resulteth );
  $strethTxBytes = $resulteth[1];

  if(strpos( $strWlan0, "UP" ) !== false && strpos( $strWlan0, "RUNNING" ) !== false ) {
    $status->addMessage('wlan0 Interface is up', 'success');
    $wlan0up = true;
  } else {
    $status->addMessage('wlan0 Interface is down', 'warning');
  }

    if (isset($_POST['system_reboot'])) {
      $result = shell_exec("sudo /sbin/reboot");
    }
    if (isset($_POST['client_mode'])) {
      $result = shell_exec("sudo /opt/rpi/init client");
    }
    if (isset($_POST['apd_mode'])) {
        $result = shell_exec("sudo /opt/rpi/init apd");
    }

  if( isset($_POST['ifdown_wlan0']) ) {
    exec( 'ifconfig wlan0 | grep -i running | wc -l',$test );
    if($test[0] == 1) {
      exec( 'sudo ifdown wlan0',$return );
    } else {
      echo 'wlan0 Interface already down';
    }
  } elseif( isset($_POST['ifup_wlan0']) ) {
    exec( 'ifconfig wlan0 | grep -i running | wc -l',$test );
    if($test[0] == 0) {
      exec( 'sudo ifup wlan0',$return );
    } else {
      echo 'wlan0 Interface already up';
    }
  }
  ?>
  <div class="row">
      <div class="col-lg-12">
          <div class="panel panel-primary">
            <div class="panel-heading"><i class="fa fa-dashboard fa-fw"></i> Network Dashboard   </div>
              <div class="panel-body">
                <p><?php $status->showMessages(); ?></p>
                  <div class="row">

                        <div class="col-md-6">
                        <div class="panel panel-default">
                  <div class="panel-body">

                      <h4>Wireless Interface</h4>
          <div class="info-item">Interface Name</div> wlan0</br>
          <div class="info-item">IP Address</div>     <?php echo $strIPAddress ?></br>
          <div class="info-item">Subnet Mask</div>    <?php echo $strNetMask ?></br>
          <div class="info-item">MAC Address</div>    <?php echo $strHWAddress ?></br></br>

                      <h4>Wireless Statistics</h4>
          <div class="info-item">Downloaded</div>    <?php echo $strRxPackets ?></br>
          <div class="info-item">Uploaded</div>    <?php echo $strTxPackets ?></br>

        </div><!-- /.panel-body -->
        </div><!-- /.panel-default -->
                        </div><!-- /.col-md-6 -->

        <div class="col-md-6">
                    <div class="panel panel-default">
              <div class="panel-body wireless">

                            <h4>Wireless Network</h4>
          <div class="info-item">Connected To</div>   <?php echo $strSSID ?></br>
          <div class="info-item">AP MAC Address</div> <?php echo $strBSSID ?></br>
          <div class="info-item">Bitrate</div>        <?php echo $strBitrate ?></br>
          <div class="info-item">Signal Level</div>   <?php echo $strSignalLevel ?></br>
          <div class="info-item">Transmit Power</div> <?php echo $strTxPower ?></br>
          <div class="info-item">Frequency</div>      <?php echo $strFrequency ?></br></br>
          <div class="info-item">Link Quality</div>
            <div class="progress">
            <div class="progress-bar progress-bar-info progress-bar-striped active"
              role="progressbar"
              aria-valuenow="<?php echo $strLinkQuality ?>" aria-valuemin="0" aria-valuemax="100"
              style="width: <?php echo $strLinkQuality ?>%;"><?php echo $strLinkQuality ?>%
            </div>
          </div>
        </div><!-- /.panel-body -->
        </div><!-- /.panel-default -->
                        </div><!-- /.col-md-6 -->

       <div class="col-md-6">
             <div class="panel panel-default">
         <div class="panel-body eth">

                      <h4>Ethernet Interface</h4>
           <div class="info-item">Interface Name</div> eth0</br>
           <div class="info-item">IP Address</div>     <?php echo $strethIPAddress ?></br>
           <div class="info-item">Subnet Mask</div>    <?php echo $strethNetMask ?></br>
           <div class="info-item">MAC Address</div>    <?php echo $strethHWAddress ?></br></br>

           <h4>Ethernet Statistics</h4>
           <div class="info-item">Downloaded</div>    <?php echo $strethRxPackets ?></br>
           <div class="info-item">Uploaded</div>    <?php echo $strethTxPackets ?></br>

         </div><!-- /.panel-body -->
         </div><!-- /.panel-default -->
                    </div><!-- /.col-md-6 -->

      </div><!-- /.row -->

                  <div class="col-lg-12">
                 <div class="row">
                    <form action="?page=wlan0_info" method="POST">
              <input type="submit" class="btn btn-warning" name="client_mode" value="Home Network" />
              <input type="submit" class="btn btn-warning" name="apd_mode" value="Hotspot Network" />
              </form>
            </div>
              </div>

                </div><!-- /.panel-body -->
                <div class="panel-footer">Information provided by ProOS</div>
            </div><!-- /.panel-default -->
        </div><!-- /.col-lg-12 -->
    </div><!-- /.row -->
  <?php 
}

?>
