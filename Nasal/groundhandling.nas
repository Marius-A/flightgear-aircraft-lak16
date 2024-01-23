
var groundHandlingToggle = func(gh = nil) {
    winch_attached and return;

    brake_parking(0);

    if (gh == nil) {
        gh = getprop("/controls/ground-handling");
    } else {
        setprop("/controls/ground-handling", gh);
        return;
    }

    if (gh == nil) {
        gh = 0;
    }

    var gs = getprop("/velocities/groundspeed-kt");
    var wow = getprop("/gear/gear[1]/wow");

    if ( (gs > 20) and !wow ) {
        gh = 1;
    }

    setprop("/controls/ground-handling", !gh);
}