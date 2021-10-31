local script = libs.script;


actions.sine300 = function ()
    script.default("/opt/rpi/main 300sine");
end

actions.sine600 = function ()
    script.default("/opt/rpi/main 600sine");
end

actions.sine1k = function ()
    script.default("/opt/rpi/main 1ksine");
end

actions.square300 = function ()
    script.default("/opt/rpi/main 300square");
end

actions.square600 = function ()
    script.default("/opt/rpi/main 600square");
end

actions.square1k = function ()
    script.default("/opt/rpi/main 1ksquare");
end

actions.stop = function ()
    script.default("/opt/rpi/main stop");
end
