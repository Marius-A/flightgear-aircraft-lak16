var marker_counter = 0;
var box_counter = 0;


var create_poi = func(name, target, lat, lon) {
    mission.mission_node.addChild("object").setValues({
        "name": name,
        "type": "point-of-interest",
        "activated": 0,
        "target-name": target,
        "attached-world-position": {
            "latitude-deg": lat,
            "longitude-deg": lon,
            "altitude-m": 1,
            "altitude-is-AGL": 1,
        },
    });
}

var create_box = func(name, w, h, l, lat, lon, hdg) {
    var box = {
        "name": name,
        "type": "rectangle-area",
        "width": w,
        "height": h,
        "length": l,
        "orientation": {
            "heading-deg": hdg,
            "pitch-deg": 0,
            "roll-deg": 0,
        },
        "attached-world-position": {
            "latitude-deg": lat,
            "longitude-deg": lon,
            "altitude-m": 0,
            "altitude-is-AGL": 1,
        },
    };
    mission.mission_node.addChild("object").setValues(box);
}

var put_model = func(mdl, lat, lon, hdg) {
    var mdl = {
        "name": "Marker " ~ marker_counter,
        "type": "model",
        "activated": 1,
        "path": mdl,
        "orientation": {
            "heading-deg": hdg,
            "pitch-deg": 0,
            "roll-deg": 0,
        },
        "world-position": {
            "latitude-deg": lat,
            "longitude-deg": lon,
            "altitude-m": 0,
            "altitude-is-AGL": 1,
        },
    };
    mission.mission_node.addChild("object").setValues(mdl);
    marker_counter += 1;
}

var generate_markers = func(n) {
    var path = n.getValue("marker/model");
    var hdg = n.getValue("heading-deg");
    var hdg_mdl = n.getValue("marker/heading-offset-deg") + hdg;
    var width = n.getValue("width-m");
    var length = n.getValue("length-m");
    var spacing = length / n.getValue("markers-per-length");
    var cc = geo.Coord.new().set_latlon(
        n.getValue("latitude-deg"),
        n.getValue("longitude-deg")
    );
    var cl = geo.Coord.new(cc);
    var cr = geo.Coord.new(cc);

    cl.apply_course_distance(hdg + 180, length / 2);
    cr.apply_course_distance(hdg + 180, length / 2);
    cl.apply_course_distance(hdg + 90, width / 2);
    cr.apply_course_distance(hdg - 90, width / 2);

    for (var i = 0; i <= length; i += spacing){
        put_model(path, cl.lat(), cl.lon(), hdg_mdl);
        put_model(path, cr.lat(), cr.lon(), hdg_mdl);


        cl.apply_course_distance(hdg, spacing);
        cr.apply_course_distance(hdg, spacing);
    }

}


var generate_areas = func(n) { #FIX: duplication
    var c = geo.Coord.new().set_latlon(
        n.getValue("latitude-deg"),
        n.getValue("longitude-deg")
    );
#    var c1 = geo.Coord.new(c);
    var width = n.getValue("width-m");
    var length = n.getValue("length-m");
    var hdg = n.getValue("heading-deg");

    var hlp = func(i) create_box("AREA-START-" ~ i,
                                 width / 2, 20, width / 2,
                                 c.lat(), c.lon(), hdg);

    var hlp2 = func(i) create_box("AREA-FINISH-" ~ i,
                                 width * 5, 100, width * 2,
                                 c.lat(), c.lon(), hdg);

    var hlp1 = func(i) create_poi("POI-START-" ~ i,
                                  "Start " ~ i,
                                  c.lat(), c.lon());

    c.apply_course_distance(hdg + 180, length / 2);
#    c1.apply_course_distance(hdg + 180, length / 2 + width / 2 + 2);
    hlp(0); hlp1(0); hlp2(0);
    c.apply_course_distance(hdg, length);
#    c1.apply_course_distance(hdg, length + 2 * width + 4);
    hlp(1); hlp1(1); hlp2(1);
}


var trainingArea = {
    node: nil,
    init: func {
        print("Training area init");
        foreach(var obj; mission.mission_node.getChildren("object"))
            if (obj.getValue("type") == "training-area") {
                print(obj.getValue("name"));
                me.node = obj;
                break; # NOTE: only one training area
            }
        me.node != nil or return;
        #generate_hoop_data(me.node);
        generate_markers(me.node);
        generate_areas(me.node);
    },
};

mission.extension_add("ObjectGenerator", trainingArea);
