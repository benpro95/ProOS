local script = libs.script;

actions.aux = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit aux");
end

actions.phono = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit phono");
end

actions.dac = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit dac");
end

actions.audio = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main pwrhifi");
end

actions.hifion = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main hifion");
end

actions.hifioff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main hifioff");
end

actions.vdwnc = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit dwnc");
end

actions.vupc = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit upc");
end

actions.vdwn = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit dwnf");
end

actions.vup= function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit upf");
end

actions.mute = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit mute");
end

actions.submute = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main submute");
end

actions.subup = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main subup");
end

actions.subdwn = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main subdwn");
end

actions.subs = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main subs");
end

actions.usb = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main usb");
end

actions.coax = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main coax");
end

actions.opt = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main opt");
end

actions.autodac = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/main autodac");
end




