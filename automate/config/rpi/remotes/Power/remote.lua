local script = libs.script;

actions.oldmac = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa3 toggle");
end

actions.oldmacon = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa3 on");
end

actions.oldmacoff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa3 off");
end

actions.desktop = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfb2 toggle");
end

actions.desktopon = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfb2 on");
end

actions.desktopoff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfb2 off");
end

actions.pc = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfb3");
end

actions.pcon = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main pcon");
end

actions.pcoff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main pcoff");
end

actions.ron = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main roomon");
end

actions.roff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main roomoff");
end

actions.lightson = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main lightson");
end

actions.lightsoff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main lightsoff");
end

