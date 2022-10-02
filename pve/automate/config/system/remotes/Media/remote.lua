local script = libs.script;

actions.aux = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main aux");
end

actions.phono = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main phono");
end

actions.dac = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main dac");
end

actions.pwrhifi = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main pwrhifi");
end

actions.hifion = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main hifion");
end

actions.hifioff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main hifioff");
end

actions.vdwnc = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main dwnc");
end

actions.vupc = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main upc");
end

actions.vdwn = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main dwnf");
end

actions.vup= function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main upf");
end

actions.mute = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main mute");
end

actions.hpf= function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main togglehpf");
end

actions.submute = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main subpwr");
end

actions.subup = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main subup");
end

actions.subdwn = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main subdwn");
end

actions.subs = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main subs");
end

actions.usb = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main usb");
end

actions.coax = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main coax");
end

actions.opt = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main opt");
end

actions.autodac = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/system/main autodac");
end




