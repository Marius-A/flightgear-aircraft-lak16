

var lat = 54.88660699;
var lon = 23.87886345;
var alt = 0.0;
var dt = nil;
var speed = 25;
var coord = geo.Coord.new();
var hdg = nil;
#var hdg_area = nil;
var winch_factor = 0;
var crs = nil;
var damping = 1;

#var rope_length = [5, 10, 15];
#var length_id = 1;
var id = nil;
var winch_enabled = 1;
var winch_attached = 0;
var throttle_reduced = 0;



var dragger = nil;


### tmp

var _c = geo.Coord.new().set_latlon(lat,lon);
_c.apply_course_distance(90, 230);
print(_c.lat());
print(_c.lon());

### /tmp

#dragger.getNode("valid", 1).setBoolValue(1);

#dragger.setBoolValue("sim/hitches/aerotow/open", 1);

setprop("/aaa/d", 10);


var v = {
    "valid": 1,
    "id": nil,
    "callsign": "dragger",
    "position": {
        "latitude-deg": nil,
        "longitude-deg": nil,
        "altitude-ft": nil,
    },
    "orientation": {
        "pitch-deg": 0,
        "roll-deg": 0,
        "true-heading-deg": 0,
    },
    "sim": {
        "hitches": {
            "aerotow": {
                "open": 1,
                "local-pos-x": 0,
                "local-pos-y": 0,
                "local-pos-z": 0,
            }
        },
    },
};

var timer = maketimer(0, func loop());

var rope_length = func getprop("/sim/hitches/aerotow/tow/length");
var hitch_x = func getprop("/fdm/jsbsim/inertia/cg-x-in") * IN2M;

var attach_rope = func {
    if ( !winch_enabled )
        return gui.popupTip("Winch not available", 1);
    groundHandlingToggle(0);
    timer.stop();
    coord.set(geo.aircraft_position());
    hdg = getprop("/orientation/heading-deg");
    print(hdg);
    crs = getprop("/sim/lak16/training-area/heading-deg");
    print(crs);
    if (crs == nil)
        crs = hdg;

    var dh = 0;
    if (hdg >= crs)
        dh = hdg - crs;
    else dh = crs - hdg;

    if (dh > 90)
        hdg = geo.normdeg(crs + 180);
    else
        hdg = crs;

    coord.apply_course_distance(hdg, rope_length() * 0.7);
    v.id = dragger_id();
    v.orientation["true-heading-deg"] = hdg;
    v.position["latitude-deg"] = coord.lat();
    v.position["longitude-deg"] = coord.lon();
    v.position["altitude-ft"] = geo.elevation(coord.lat(), coord.lon()) * M2FT;

    if ( dragger == nil ) {
        dragger = props.globals.getNode("ai/models").addChild("aircraft");
        setprop("/ai/models/model-added", dragger.getPath());
    }

    dragger.setValues(v);

    towing.findBestAIObject();
    settimer(func dragger.getNode("sim/hitches/aerotow/local-pos-x",1).setValue(0.),0);
    groundHandlingToggle(0);

    setprop("/lak16/winch-attached", winch_attached = 1);
    reset_winch();
    reverse_throttle(0);
    brake_parking(0);
    setprop("controls/engines/engine[0]/throttle", 0.1);
    throttle_reduced = 0;
    timer.start();
}


var enableWinch = func (w = 1)
{
    winch_enabled = (w >= 1);
}


var brake_parking = func (b = 1)
{
    setprop("/controls/gear/brake-parking", b ? b : 0);
}


var reverse_throttle = func (v = 1)
{
    if (v < 1) v = 0;
    setprop("/controls/engines/engine[0]/reverser", v);
}


var throttleAxis = func (inv_t = 0, inv_w = 0)
{
    var v = cmdarg().getValue("setting");
    #winch_attached and return;
    if (winch_attached) {
        if (inv_w) v = -v;
        setprop("/controls/engines/engine[0]/throttle", (1 - v) / 2);
    } else {
        if (inv_t) v = -v;
        reverse_throttle(v < 0);
        setprop("/controls/engines/engine[0]/throttle", math.abs(v));
    }
}


var reset_winch = func ()
{
    setprop("/lak16/throttle-filter", 0);
    setprop("/lak16/winch-factor-raw", 0);
#    setprop("/lak16/winch-factor", 0);
}


var releaseHitch = func ()
{
    towing.releaseHitch("aerotow");
    towing.releaseHitch("winch");
    setprop("/lak16/winch-attached", winch_attached = 0);
    reset_winch();
    timer.stop();
}



var loop = func ()
{
    if (!throttle_reduced) {
        var t = getprop("/controls/engines/engine[0]/throttle");
        if (t <= 0.02) {
            throttle_reduced = 1;
            setprop("/lak16/throttle-filter", 0.5);
        }
    }

    throttle_reduced or return;

    dt = getprop("/sim/time/delta-sec");
    winch_factor = getprop("/lak16/winch-factor");
    damping = getprop("/aaa/damping");

    coord.apply_course_distance(hdg, damping * winch_factor * speed * dt);
    dragger.setValue("position/latitude-deg", coord.lat());
    dragger.setValue("position/longitude-deg", coord.lon());
}


var new_id = func ()
{
    var id_used = {};
    foreach (var m; props.getNode("ai/models", 1).getChildren()) {
        if ((var c = m.getNode("id")) != nil and c.getValue() != "") {
            var v = c.getValue();
            if (v != nil and v != "")
                id_used[v] = 1;
        }
    }

    for (var id = -2; 1; id -= 1)
        if (!id_used[id])
            break;

    return id;
}


var dragger_id = func ()
{
    if (id == nil)
        id = new_id();
    else
        id;
}