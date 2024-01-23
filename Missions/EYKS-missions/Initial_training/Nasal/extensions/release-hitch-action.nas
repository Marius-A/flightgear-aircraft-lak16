var release_hitch_action = {
	type: "release-hitch-action",

	new: func(n) {
		var m = {
			parents     : [release_hitch_action],
			name        : n.getValue("name"),
		};

		return m;
	},

	start: func {
        lak16.releaseHitch();
	},

	stop: func,

	del: func,
};

mission.extension_add("MissionObject", release_hitch_action);