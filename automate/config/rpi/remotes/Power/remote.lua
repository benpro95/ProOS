local script = libs.script;


actions.dresser = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa2 toggle");
end

actions.dresseron = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa2 on");
end

actions.dresseroff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa2 off");
end

actions.mainl = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfc1 toggle");
end

actions.mainlon = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfc1 on");
end

actions.mainloff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfc1 off");
end

actions.oldmac = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa3 toggle");
end

actions.oldmacon = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa3 on");
end

actions.oldmacoff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa3 off");
end

actions.crt = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa1 toggle");
end

actions.crton = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa1 on");
end

actions.crtoff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa1 off");
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

actions.lights = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main lights");
end

actions.lightson = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main lightson");
end

actions.lightsoff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main lightsoff");
end

actions.allon = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main allon");
end

actions.alloff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main alloff");
end


