var tid;
var ractive;
var model;
var tiptid;
var first;
var log;

function update() {
    ractive.set(model)
}

function reload_page(c) {
    if (!c) {}
    var b = "?t=" + new Date().getTime() % 1000;
    var a = document.location.hash;
    document.location = b + a
}

function navigate(d) {
    d = d.substr(d.indexOf("#"));
    var a = d.split("/");
    ractive.set("view.page.*", false);
    if (a.length >= 2) {
        ractive.set("view.page." + a[1], true)
    } else {
        ractive.set("view.page.welcome", true)
    }
    if (a.length >= 3) {
        var c = a[2];
        var b = UR.store.getRemoteById(c);
        if (b) {
            selectRemote(b);
            showRemote(b)
        } else {
            ractive.set("view.page.welcome", true);
            ractive.set("remotes.*.active", false);
            tip("Missing remote " + c)
        }
    }
}

function showRemote(d) {
    var c = function(f) {
        var e = UR.render.flattenLayout(f);
        model.current_layout = f;
        model.current_remote = d;
        model.current_actions = e;
        update();
        UR.render.prettyRows(e);
        update()
    };
    var a = function() {};
    var b = model.current_remote;
    if (b) {
        UR.client.instance.stopRemote(b)
    }
    UR.client.instance.startRemote(d, c, a)
}

function onRemoteEvent(a) {
    if (a.Error === "Not authorized") {
        ractive.set("view.connected", false);
        UR.client.instance.restart()
    }
    if (a.length > 0) {
        _.forEach(a, function(b) {
            UR.events.publish(b, model.current_remote)
        })
    }
}

function selectRemote(a) {
    _.forEach(model.remotes, function(b) {
        b.active = false
    });
    a.active = true;
    update()
}

function tip(a) {
    if (!ractive) {
        return
    }
    ractive.set("view.tip", a);
    $(".tips").hide();
    clearTimeout(tiptid);
    $(".tips").slideDown(100, function() {
        tiptid = setTimeout(function() {
            $(".tips").slideUp(100)
        }, 2000)
    })
}

function onEvent(b, a) {
    tip("Event from " + b.id + ": " + a);
    return true
}
var model = {};
$(document).ready(function() {
    first = true;
    log = "";
    model = {
        year: new Date().getFullYear(),
        view: {
            disconnected: true,
            loading_remotes: true,
            tip: "",
            page: {
                welcome: false,
                login: false,
                remote: false,
                unauthorized: false,
                connecting: true
            }
        },
        remotes: UR.store.getRemoteList(),
        current_remote: undefined,
        current_layout: undefined,
        current_actions: undefined,
        current_sync_queue: {},
        element_child_style: function(b) {
            return "width: " + (100 / b.length) + "%"
        },
        init_onhold: function(b) {
            setTimeout(function() {
                UR.render.bindHold(b, function() {
                    UR.client.instance.sendAction(model.current_remote, b.OnHold)
                })
            }, 500)
        },
        try_image: function(b) {
            if (b.Image) {
                return "data:image/jpeg;base64," + b.Image
            } else {
                return "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD//gATQ3JlYXRlZCB3aXRoIEdJTVD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wgARCAAKAAoDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAj/xAAUAQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAGqQAf/xAAUEAEAAAAAAAAAAAAAAAAAAAAg/9oACAEBAAEFAh//xAAUEQEAAAAAAAAAAAAAAAAAAAAg/9oACAEDAQE/AR//xAAUEQEAAAAAAAAAAAAAAAAAAAAg/9oACAECAQE/AR//xAAUEAEAAAAAAAAAAAAAAAAAAAAg/9oACAEBAAY/Ah//xAAUEAEAAAAAAAAAAAAAAAAAAAAg/9oACAEBAAE/IR//2gAMAwEAAgADAAAAEJJP/8QAFBEBAAAAAAAAAAAAAAAAAAAAIP/aAAgBAwEBPxAf/8QAFBEBAAAAAAAAAAAAAAAAAAAAIP/aAAgBAgEBPxAf/8QAFBABAAAAAAAAAAAAAAAAAAAAIP/aAAgBAQABPxAf/9k="
            }
        }
    };
    ractive = new Ractive({
        el: "container",
        template: "#tmain",
        data: model
    });
    $(window).unload(function() {
        UR.client.instance.stop(model.current_remote)
    });
    $(window).on("hashchange", function() {
        navigate(window.location.hash);
        ga("send", "pageview", {
            page: location.pathname + location.search + location.hash
        })
    });

    function a(e, d) {
        e = _.cloneDeep(e);
        var b = {
            Values: [{
                Key: "0",
                Value: d
            }]
        };
        var c = e.Extras;
        e.Extras = _.merge(b, c, function(g, f) {
            return _.isArray(g) ? g.concat(f) : undefined
        });
        return e
    }
    ractive.on({
        simple_event: function(b, c) {
            UR.client.instance.sendAction(model.current_remote, c)
        },
        toggle_down: function(b, c) {
            var d = UR.render.isChecked(b.context);
            UR.render.setChecked(b.context, !d);
            UR.client.instance.sendAction(model.current_remote, c)
        },
        toggle_changed: function(b, e, c) {
            if (e !== undefined) {
                var f = $(b.node).attr("data-down") === "yes";
                var d = a(e, f);
                UR.client.instance.sendAction(model.current_remote, d)
            }
            UR.client.instance.sendAction(model.current_remote, c)
        },
        slider_up: function(b) {
            var e = b.context;
            var f = e.ID;
            var d = Math.round(parseFloat(b.node.value));
            if (model.current_sync_queue[f] === "<baconbacon>") {
                model.current_sync_queue[f] = undefined
            }
            if (e.OnUp) {
                var c = a(e.OnUp, d);
                UR.client.instance.sendAction(model.current_remote, c)
            }
            if (e.OnChange) {
                var c = a(e.OnChange, d);
                UR.client.instance.sendAction(model.current_remote, c)
            }
            if (e.OnDone) {
                var c = a(e.OnDone, d);
                UR.client.instance.sendAction(model.current_remote, c)
            }
            model.current_sync_queue[f] = d;
            setTimeout(function() {
                model.current_sync_queue[f] = undefined
            }, 2000)
        },
        slider_down: function(b) {
            var e = b.context;
            var f = e.ID;
            var d = Math.round(parseFloat(b.node.value));
            model.current_sync_queue[f] = "<baconbacon>";
            if (e.OnDone) {
                var c = a(e.OnDone, d);
                UR.client.instance.sendAction(model.current_remote, c)
            }
        },
        login: function(b, c, d) {
            ractive.set("view.page.*", false);
            ractive.set("view.page.remote", true);
            UR.client.instance.onAuthentication(c, d)
        },
        input_keydown: function(b) {
            if (b.original.keyCode === 13) {
                $("#" + $(b.node).attr("data-target")).click()
            }
        }
    });
    UR.client.instance = UR.client.init(function() {
        ractive.set("view.disconnected", false);
        ractive.set("view.loading_remotes", false);
        ractive.set("view.page.*", false);
        ractive.set("view.page.welcome", true);
        UR.client.instance.listenToEvents(onRemoteEvent);
        if (window.location.hash) {
            navigate(window.location.hash)
        }
    }, function() {
        ractive.set("view.disconnected", true);
        ractive.set("view.loading_remotes", true);
        ractive.set("view.page.*", false);
        ractive.set("view.page.connecting", true)
    }, function(b) {
        ractive.set("view.page.*", false);
        ractive.set("view.disconnected", true);
        ractive.set("view.loading_remotes", true);
        if (b) {
            ractive.set("view.page.login_user", true)
        } else {
            ractive.set("view.page.login_anonymous", true)
        }
    }, function() {
        ractive.set("view.disconnected", true);
        ractive.set("view.loading_remotes", true);
        ractive.set("view.page.*", false);
        ractive.set("view.page.unauthorized", true)
    })
});