local script = libs.script;

actions.vdwn = function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit dwnc");
end

actions.vup= function ()
script.default("/usr/bin/screen -dm /bin/bash /opt/rpi/xmit upc");
end

actions.stop = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main stoprelax');
end

actions.amazon = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax amazon.wav');
end

actions.campfire = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax campfire.mp3');
end

actions.forest = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax forest.wav');
end

actions.harbour = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax harbour.wav');
end

actions.wind = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax wind.mp3');
end

actions.jungle = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax jungle.mp3');
end

actions.meadow = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax meadow.wav');
end

actions.stream = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax stream.mp3');
end

actions.ocean = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax ocean.wav');
end

actions.river = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax river.wav');
end

actions.rain = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax rain.mp3');
end

actions.rainii = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax rain-2.mp3');
end

actions.storm = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax storm.mp3');
end

actions.thunder = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax thunder.wav');
end

actions.waterfall = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax waterfall.mp3');
end

actions.traffic = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax traffic.wav');
end

actions.beach = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax beach.mp3');
end

actions.warp = function ()
script.default('/usr/bin/screen -dm /bin/bash /opt/rpi/main relax warp.mp3');
end
