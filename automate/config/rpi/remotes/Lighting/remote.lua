local script = libs.script;

actions.dresser = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa1 toggle");
end

actions.dresseron = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa1 on");
end

actions.dresseroff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa1 off");
end

actions.ceiling = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa2 toggle");
end

actions.ceilingon = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa2 on");
end

actions.ceilingoff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfa2 off");
end

actions.desk = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfb1 toggle");
end

actions.deskon = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfb1 on");
end

actions.deskoff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit rfb1 off");
end

actions.mainl = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit fet0 toggle");
end

actions.mainlon = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit fet0 on");
end

actions.mainloff = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit fet0 off");
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

