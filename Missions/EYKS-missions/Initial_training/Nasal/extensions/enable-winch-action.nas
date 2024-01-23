var enable_winch_action = {
	type: "enable-winch-action",

	new: func(n) {
		var m = {
			parents     : [enable_winch_action],
			name        : n.getValue("name"),
            _activated  : n.getValue("activated") or 0,
		};

        if ( m._activated )
            m.start();
        else m.stop();

		return m;
	},

	start: func {
        lak16.enableWinch();
	},

	stop: func lak16.enableWinch(0),

	del: func lak16.enableWinch(),
};

mission.extension_add("MissionObject", enable_winch_action);