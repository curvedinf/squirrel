// Inspired by:
// - ../inferno-code/scripts/runtime/modes/delving_mode.nut
// - ../inferno-code/scripts/runtime/modes/delving_mode/gameplay_and_outcome/scenario_flow.nut
// - ../inferno-code/scripts/runtime/modes/delving_mode/session_and_context/core_context_and_state.nut

function argInt(index, fallback) {
	if (vargv.len() <= index) {
		return fallback;
	}
	try {
		return vargv[index].tointeger();
	} catch (err) {
		return fallback;
	}
}

function toInt(value, fallback = 0) {
	try {
		return value.tointeger();
	} catch (err) {
		return fallback;
	}
}

local ScenarioTickBench = {
	makeMode = function(route_count) {
		local route_states = [];
		local local_states = [];
		local diff_cycle = ["easy", "normal", "hard", "extreme"];
		for (local i = 0; i < route_count; i += 1) {
			route_states.push({
				active_route_mission = "mission_" + i,
				active_zone_difficulty = diff_cycle[i % diff_cycle.len()]
			});
			local_states.push({
				active_route_mission = "local_mission_" + i,
				active_zone_difficulty = diff_cycle[(i + 1) % diff_cycle.len()]
			});
		}
		return {
			active = false,
			mode_stats = null,
			objective_initialized = false,
			difficulty = "easy",
			campaign_sortie_active = false,
			sortie_runtime_initialized = false,
			sortie_mission_runtime_enabled = true,
			sortie_native_scenario_started = true,
			sortie_last_tick_frame = -1,
			sortie_players_spawned = false,
			selected_route_mission_id = "",
			can_author = true,
			game_mode = "delving",
			session_vars = {
				["campaign.gameplay_context"] = "",
				["sortie.mode_id"] = "delving",
				["sortie.profile_id"] = "profile_0",
				["sortie.map_path"] = "core.asset.map.generated_delving",
				["sortie.route_mission_id"] = "mission_0",
				["sortie.difficulty"] = "easy"
			},
			launch_context = {
				mode_id = "delving",
				profile_id = "profile_0",
				map_path = "core.asset.map.generated_delving",
				route_mission_id = "mission_0"
			},
			route_states = route_states,
			local_states = local_states,
			last_state_write = 0
		};
	},

	makeState = function(enemy_count) {
		local team_1 = [];
		local team_2 = [];
		for (local i = 0; i < 4; i += 1) {
			team_1.push({
				name = "player-" + i,
				alive = true,
				ready = (i % 2) == 0
			});
		}
		for (local i = 0; i < enemy_count; i += 1) {
			team_2.push({
				name = "enemy-" + i,
				alive = true,
				respawn_enabled = (i % 3) != 0,
				respawn_start = 0,
				last_attacker_name = "",
				last_attacked_frame = 0
			});
		}
		return {
			team_1 = team_1,
			team_2 = team_2,
			respawn_delay = 18,
			scenario_started = false,
			scenario_ended = false,
			scenario_between_rounds = false
		};
	},

	sessionSharedText = function(mode, key_name, fallback = "") {
		if (key_name != null && key_name.tostring().len() > 7
				&& key_name.tostring().slice(0, 7) == "sortie.") {
			local field_name = key_name.tostring().slice(7);
			local context = mode.launch_context;
			if (context != null && field_name in context && context[field_name] != null) {
				local context_text = context[field_name].tostring();
				if (context_text.len() > 0) {
					return context_text;
				}
			}
		}
		if (!(key_name in mode.session_vars) || mode.session_vars[key_name] == null) {
			return fallback;
		}
		local text = mode.session_vars[key_name].tostring();
		return text.len() > 0 ? text : fallback;
	},

	currentGameModeName = function(mode) {
		local game_mode = mode.game_mode;
		return game_mode == null ? "" : game_mode.tostring().tolower();
	},

	hasCampaignSortieContextFlag = function(mode) {
		return this.sessionSharedText(mode, "campaign.gameplay_context", "").tolower()
			== "campaign-sortie";
	},

	hasCampaignSortieSessionPackage = function(mode) {
		local sortie_mode = this.sessionSharedText(mode, "sortie.mode_id", "").tolower();
		local profile_id = this.sessionSharedText(mode, "sortie.profile_id", "");
		local map_path = this.sessionSharedText(mode, "sortie.map_path", "").tolower();
		return sortie_mode == "delving" && profile_id.len() > 0
			&& (map_path == "core.asset.map.generated_delving"
				|| map_path == "core.asset.map.team_rogue");
	},

	isCampaignSortieGameplayContextActive = function(mode) {
		return this.hasCampaignSortieContextFlag(mode)
			|| this.hasCampaignSortieSessionPackage(mode);
	},

	shouldRunForCurrentContext = function(mode) {
		local mode_name = this.currentGameModeName(mode);
		return mode_name == "delving" || mode_name == "campaign"
			|| this.isCampaignSortieGameplayContextActive(mode);
	},

	refreshActiveForCurrentContext = function(mode) {
		if (!this.shouldRunForCurrentContext(mode)) {
			return false;
		}
		if (!mode.active) {
			mode.active = true;
			mode.mode_stats = { respawn_delay_frames = 18 };
		}
		if (this.isCampaignSortieGameplayContextActive(mode)) {
			mode.campaign_sortie_active = true;
		}
		return true;
	},

	isCampaignSortieActive = function(mode, route_state, gameplay_context) {
		local context = gameplay_context == null ? "" : gameplay_context.tostring().tolower();
		if (context == "campaign-sortie") {
			return true;
		}
		if (route_state != null && "force_sortie" in route_state && route_state.force_sortie) {
			return true;
		}
		return this.hasCampaignSortieSessionPackage(mode);
	},

	teamArray = function(state, key) {
		if (state == null || !(key in state) || state[key] == null) {
			return [];
		}
		return state[key];
	},

	respawnDelayFrames = function(mode, state) {
		if (state != null && "respawn_delay" in state) {
			return toInt(state.respawn_delay, 0);
		}
		if (mode.mode_stats != null && "respawn_delay_frames" in mode.mode_stats) {
			return toInt(mode.mode_stats.respawn_delay_frames, 0);
		}
		return 0;
	},

	sortieRosterUnitsReady = function(state) {
		local team = this.teamArray(state, "team_1");
		if (team.len() == 0) {
			return false;
		}
		local ready = 0;
		foreach (player in team) {
			if (("alive" in player) ? player.alive : false
					&& ("ready" in player) ? player.ready : false) {
				ready += 1;
			}
		}
		return ready == team.len();
	},

	setScenarioState = function(mode, state) {
		mode.last_state_write = this.countAlive(this.teamArray(state, "team_2"));
		return true;
	},

	countAlive = function(team) {
		local alive = 0;
		foreach (player in team) {
			if (("alive" in player) ? player.alive : false) {
				alive += 1;
			}
		}
		return alive;
	},

	cycleMode = function(mode, state, frame) {
		mode.game_mode = (frame % 19) == 0 ? "campaign"
			: ((frame % 13) == 0 ? "menu" : "delving");
		mode.session_vars["campaign.gameplay_context"] <- (frame % 7) == 0
			? "campaign-sortie"
			: ((frame % 5) == 0 ? "campaign" : "");
		mode.session_vars["sortie.mode_id"] <- (frame % 9) == 0 ? "assault" : "delving";
		mode.session_vars["sortie.profile_id"] <- (frame % 6) == 0 ? "" : "profile_" + (frame % 23);
		mode.session_vars["sortie.map_path"] <- (frame % 4) == 0
			? "core.asset.map.generated_delving"
			: ((frame % 4) == 1 ? "core.asset.map.team_rogue" : "maps/side_route_" + (frame % 11));
		mode.session_vars["sortie.route_mission_id"] <- (frame % 8) == 0 ? "" : "mission_" + (frame % mode.route_states.len());
		mode.session_vars["sortie.difficulty"] <- ["easy", "normal", "hard", "extreme"][frame % 4];

		mode.launch_context.mode_id = (frame % 10) == 0 ? "expedition" : "delving";
		mode.launch_context.profile_id = (frame % 5) == 0 ? "" : "profile_" + ((frame + 3) % 23);
		mode.launch_context.map_path = (frame % 3) == 0
			? "core.asset.map.generated_delving"
			: ((frame % 3) == 1 ? "core.asset.map.team_rogue" : "maps/field_" + (frame % 9));
		mode.launch_context.route_mission_id = "mission_" + ((frame + 1) % mode.route_states.len());

		local route_state = mode.route_states[frame % mode.route_states.len()];
		route_state.active_zone_difficulty = ["easy", "normal", "hard", "extreme"][(frame + 1) % 4];
		route_state.active_route_mission = "mission_" + ((frame + 2) % mode.route_states.len());
		route_state.force_sortie <- (frame % 12) == 0;

		local local_state = mode.local_states[frame % mode.local_states.len()];
		local_state.active_zone_difficulty = ["normal", "hard", "extreme", "easy"][(frame + 2) % 4];
		local_state.active_route_mission = "local_mission_" + ((frame + 3) % mode.local_states.len());
		local_state.force_sortie <- (frame % 14) == 0;

		if ((frame % 41) == 0) {
			mode.objective_initialized = false;
			mode.campaign_sortie_active = false;
			mode.sortie_runtime_initialized = false;
			mode.sortie_players_spawned = false;
			state.scenario_started = false;
			state.scenario_ended = false;
		}
		mode.can_author = (frame % 17) != 0;

		if ((frame % 9) == 0) {
			local team = state.team_2;
			local idx = frame % team.len();
			local player = team[idx];
			player.alive = false;
			player.respawn_enabled = (frame % 4) != 0;
			player.respawn_start = frame - (idx % 5) - 1;
			player.last_attacker_name = "player-" + (frame % 4);
			player.last_attacked_frame = frame;
			team[idx] = player;
		}
	},

	tickScenario = function(mode, state, frame) {
		if (!this.refreshActiveForCurrentContext(mode)) {
			return 0;
		}
		if (frame == mode.sortie_last_tick_frame) {
			return 0;
		}
		mode.sortie_last_tick_frame = frame;

		if (!("scenario_started" in state)) {
			state.scenario_started <- false;
		}
		if (!("scenario_ended" in state)) {
			state.scenario_ended <- false;
		}
		if (!("scenario_between_rounds" in state)) {
			state.scenario_between_rounds <- false;
		}

		if (mode.campaign_sortie_active && !mode.sortie_runtime_initialized) {
			mode.sortie_runtime_initialized = true;
			return 3;
		}

		if (!state.scenario_started) {
			if (!mode.can_author) {
				return 5;
			}
			state.scenario_started <- true;
			state.scenario_ended <- false;
			state.scenario_between_rounds <- false;
			if (this.isCampaignSortieGameplayContextActive(mode)
					&& (frame % 5) == 0
					&& this.sortieRosterUnitsReady(state)) {
				mode.sortie_players_spawned = true;
			}
		}

		local live_gameplay_context = this.sessionSharedText(mode, "campaign.gameplay_context", "");
		local live_route_state = mode.route_states[frame % mode.route_states.len()];
		local local_route_state = mode.local_states[frame % mode.local_states.len()];
		if (!mode.campaign_sortie_active
				&& this.isCampaignSortieActive(mode, live_route_state, live_gameplay_context)) {
			mode.campaign_sortie_active = true;
			mode.objective_initialized = true;
			mode.sortie_runtime_initialized = true;
			return 7;
		}

		if (!mode.objective_initialized) {
			local diff = "easy";
			local session_route_mission = this.sessionSharedText(mode, "sortie.route_mission_id", "");
			local session_difficulty = this.sessionSharedText(mode, "sortie.difficulty", "");
			local route_state = mode.campaign_sortie_active ? live_route_state : local_route_state;
			local diff_from_route_state = false;
			if (route_state != null && "active_zone_difficulty" in route_state) {
				diff = route_state.active_zone_difficulty;
				diff_from_route_state = true;
			}
			if (!diff_from_route_state && session_difficulty != "") {
				diff = session_difficulty;
			}
			mode.difficulty = diff;
			mode.campaign_sortie_active = this.isCampaignSortieActive(mode, route_state, live_gameplay_context);
			mode.objective_initialized = true;
			if (mode.campaign_sortie_active) {
				mode.sortie_runtime_initialized = true;
				return 11;
			}

			local mission = "none";
			if (route_state != null && "active_route_mission" in route_state) {
				mission = route_state.active_route_mission;
			}
			if (session_route_mission != "") {
				mission = session_route_mission;
			}
			if (mission == null || mission == "" || mission == "none") {
				mode.selected_route_mission_id = "";
				return 13;
			}
			mode.selected_route_mission_id = mission;
			return mission.len();
		}

		if (!state.scenario_started || state.scenario_ended) {
			return 0;
		}

		if (!mode.sortie_players_spawned && (frame % 6) == 0 && this.sortieRosterUnitsReady(state)) {
			mode.sortie_players_spawned = true;
		}
		if (mode.sortie_mission_runtime_enabled && (frame % 8) == 0) {
			return 17;
		}

		local respawn_delay = this.respawnDelayFrames(mode, state);
		local changed = false;
		local respawned = 0;
		local team = this.teamArray(state, "team_2");
		for (local i = 0; i < team.len(); i += 1) {
			local player = team[i];
			if (("alive" in player) ? player.alive : false) {
				continue;
			}
			if (!(("respawn_enabled" in player) ? player.respawn_enabled : false)) {
				continue;
			}
			local respawn_start = toInt(("respawn_start" in player) ? player.respawn_start : 0, 0);
			if (frame < respawn_start + respawn_delay) {
				continue;
			}
			local player_name = ("name" in player) ? player.name.tostring() : "";
			if (player_name.len() == 0) {
				continue;
			}
			player.alive <- true;
			player.last_attacker_name <- "";
			player.last_attacked_frame <- 0;
			team[i] = player;
			changed = true;
			respawned += 1;
		}
		state["team_2"] <- team;
		if (changed) {
			this.setScenarioState(mode, state);
		}
		return respawned;
	},

	run = function(frame_count, enemy_count, route_count) {
		local mode = this.makeMode(route_count);
		local state = this.makeState(enemy_count);
		local checksum = 0;
		for (local frame = 0; frame < frame_count; frame += 1) {
			this.cycleMode(mode, state, frame);
			local tick_result = this.tickScenario(mode, state, frame);
			local alive_team_2 = this.countAlive(this.teamArray(state, "team_2"));
			checksum += tick_result * 13;
			checksum += alive_team_2 * 3;
			checksum += mode.selected_route_mission_id.len();
			checksum += mode.difficulty.len();
			checksum += mode.campaign_sortie_active ? 17 : 5;
			checksum += mode.sortie_players_spawned ? 19 : 7;
			checksum += state.scenario_started ? 23 : 11;
			checksum += state.scenario_ended ? 29 : 13;
			checksum += mode.last_state_write;
		}
		checksum += this.countAlive(this.teamArray(state, "team_1")) * 31;
		checksum += this.countAlive(this.teamArray(state, "team_2")) * 37;
		checksum += mode.selected_route_mission_id.len() * 41;
		return checksum;
	}
};

function main() {
	return ScenarioTickBench.run(argInt(0, 10200), argInt(1, 24), argInt(2, 14));
}

return main();
