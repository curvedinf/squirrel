// Inspired by:
// - ../inferno-code/scripts/runtime/modes/delving_mode/session_and_context/core_context_and_state.nut
// - ../inferno-code/scripts/runtime/modes/delving_mode/session_and_context/sortie_context_and_reports.nut
// - ../inferno-code/scripts/runtime/modes/delving_mode/spatial_and_loot/volume_and_context.nut

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

local SessionContextBench = {
	asset_aliases = {
		["core.asset.map.generated_delving"] = "maps/generated_delving.map",
		["core.asset.map.team_rogue"] = "maps/team_rogue.map"
	},

	resolveAsset = function(path) {
		if (path == null) {
			return "";
		}
		local text = path.tostring();
		return (text in this.asset_aliases) ? this.asset_aliases[text] : text;
	},

	makeContext = function(index) {
		local profile_id = "profile_" + index;
		local map_path = (index % 2) == 0
			? "core.asset.map.generated_delving"
			: "core.asset.map.team_rogue";
		return {
			seed = index,
			active = false,
			campaign_sortie_active = false,
			mode_stats = null,
			game_mode = (index % 3) == 0 ? "campaign" : "delving",
			state_vars = {
				["campaign.gameplay_context"] = (index % 4) == 0 ? "campaign-sortie" : "campaign",
				["sortie.mode_id"] = "delving",
				["sortie.profile_id"] = profile_id,
				["sortie.map_path"] = map_path,
				["sortie.launch_kind"] = (index % 5) == 0 ? "delve" : "mission",
				["sortie.route_mission_id"] = "mission_" + (index % 17),
				["sortie.difficulty"] = ["easy", "normal", "hard", "extreme"][index % 4]
			},
			launch_context = {
				mode_id = "delving",
				profile_id = profile_id,
				map_path = map_path,
				launch_kind = (index % 5) == 0 ? "delve" : "mission",
				route_mission_id = "mission_" + (index % 17)
			},
			anchor_report = {
				source = (index % 2) == 0 ? "procedural_level" : "delving_mode",
				profile_id = profile_id,
				definition_id = "standard_clear_" + (index % 11),
				sortie_def_id = "fallback_" + (index % 7),
				generated_anchor_reports = [
					{ id = "anchor_" + index, lane = index % 3 },
					{ id = "anchor_extra_" + index, lane = (index + 1) % 3 }
				]
			}
		};
	},

	sessionSharedText = function(ctx, key_name, fallback = "") {
		if (key_name != null && key_name.tostring().len() > 7
				&& key_name.tostring().slice(0, 7) == "sortie.") {
			local field_name = key_name.tostring().slice(7);
			local context = ctx.launch_context;
			if (context != null && field_name in context && context[field_name] != null) {
				local context_text = context[field_name].tostring();
				if (context_text.len() > 0) {
					return context_text;
				}
			}
		}
		if (!(key_name in ctx.state_vars) || ctx.state_vars[key_name] == null) {
			return fallback;
		}
		local text = ctx.state_vars[key_name].tostring();
		return text.len() > 0 ? text : fallback;
	},

	campaignSortieLaunchKind = function(ctx) {
		local kind = this.sessionSharedText(ctx, "sortie.launch_kind", "mission").tolower();
		return kind == "mission" ? "mission" : "delve";
	},

	generatedSortieAnchorReportText = function(ctx, key_name, fallback = "") {
		local root = ctx.anchor_report;
		if (root == null || !(key_name in root) || root[key_name] == null) {
			return fallback;
		}
		local text = root[key_name].tostring();
		return text.len() > 0 ? text : fallback;
	},

	generatedSortieAnchorReportDefinitionId = function(ctx, fallback = "standard_clear") {
		local definition_id = this.generatedSortieAnchorReportText(ctx, "definition_id", "");
		if (definition_id.len() == 0) {
			definition_id = this.generatedSortieAnchorReportText(ctx, "sortie_def_id", "");
		}
		return definition_id.len() > 0 ? definition_id : fallback;
	},

	hasCampaignSortieGeneratedAnchorReport = function(ctx) {
		local root = ctx.anchor_report;
		if (root == null) {
			return false;
		}
		local source = ("source" in root && root.source != null) ? root.source.tostring() : "";
		if (source != "procedural_level" && source != "delving_mode") {
			return false;
		}
		local profile_id = ("profile_id" in root && root.profile_id != null)
			? root.profile_id.tostring() : "";
		local definition_id = ("definition_id" in root && root.definition_id != null)
			? root.definition_id.tostring() : "";
		if (definition_id.len() == 0 && "sortie_def_id" in root && root.sortie_def_id != null) {
			definition_id = root.sortie_def_id.tostring();
		}
		if (profile_id.len() == 0 || definition_id.len() == 0) {
			return false;
		}
		if (!("generated_anchor_reports" in root) || root.generated_anchor_reports == null
				|| typeof root.generated_anchor_reports != "array") {
			return false;
		}
		return root.generated_anchor_reports.len() > 0;
	},

	currentGameModeName = function(ctx) {
		local game_mode = ctx.game_mode;
		return game_mode == null ? "" : game_mode.tostring().tolower();
	},

	hasCampaignSortieContextFlag = function(ctx) {
		return this.sessionSharedText(ctx, "campaign.gameplay_context", "").tolower()
			== "campaign-sortie";
	},

	hasCampaignSortieSessionPackage = function(ctx) {
		local mode_name = this.currentGameModeName(ctx);
		local context_active = this.hasCampaignSortieContextFlag(ctx);
		local generated_anchor_active = this.hasCampaignSortieGeneratedAnchorReport(ctx);
		local sortie_mode = this.sessionSharedText(ctx, "sortie.mode_id", "").tolower();
		local profile_id = this.sessionSharedText(ctx, "sortie.profile_id", "");
		local map_ref = this.sessionSharedText(ctx, "sortie.map_path", "");
		local map_path = this.resolveAsset(map_ref).tolower();
		local generated_delving_map = this.resolveAsset("core.asset.map.generated_delving").tolower();
		local delving_hub_map = this.resolveAsset("core.asset.map.team_rogue").tolower();
		local explicit_sortie_package = sortie_mode == "delving" && profile_id.len() > 0
			&& (map_path == generated_delving_map || map_path == delving_hub_map);
		if (mode_name != "campaign" && !context_active) {
			return explicit_sortie_package;
		}
		if (sortie_mode.len() > 0 && sortie_mode != "delving") {
			return generated_anchor_active;
		}
		if (explicit_sortie_package) {
			return true;
		}
		return generated_anchor_active;
	},

	isCampaignSortieGameplayContextActive = function(ctx) {
		return this.hasCampaignSortieContextFlag(ctx)
			|| this.hasCampaignSortieSessionPackage(ctx);
	},

	shouldRunForCurrentContext = function(ctx) {
		local mode_name = this.currentGameModeName(ctx);
		return mode_name == "delving" || mode_name == "campaign"
			|| this.isCampaignSortieGameplayContextActive(ctx);
	},

	refreshActiveForCurrentContext = function(ctx) {
		if (!this.shouldRunForCurrentContext(ctx)) {
			return false;
		}
		if (!ctx.active) {
			ctx.active = true;
			ctx.mode_stats = { respawn_delay_frames = (ctx.seed * 17) % 180 };
		}
		if (this.isCampaignSortieGameplayContextActive(ctx)) {
			ctx.campaign_sortie_active = true;
		}
		return true;
	},

	cycleContext = function(ctx, frame) {
		local cycle = frame + ctx.seed;
		ctx.game_mode = (cycle % 10) == 0 ? "menu"
			: ((cycle % 2) == 0 ? "campaign" : "delving");
		ctx.launch_context.mode_id = (cycle % 9) == 0 ? "assault" : "delving";
		ctx.launch_context.profile_id = (cycle % 6) == 0 ? "" : "profile_" + (cycle % 19);
		ctx.launch_context.map_path = (cycle % 3) == 0
			? "core.asset.map.generated_delving"
			: ((cycle % 3) == 1
				? "core.asset.map.team_rogue"
				: "maps/side_route_" + (cycle % 13));
		ctx.launch_context.launch_kind = (cycle % 4) == 0 ? "delve" : "mission";
		ctx.launch_context.route_mission_id = "mission_" + (cycle % 23);

		ctx.state_vars["campaign.gameplay_context"] <- (cycle % 6) == 0
			? "campaign-sortie"
			: ((cycle % 8) == 0 ? "campaign" : "");
		ctx.state_vars["sortie.mode_id"] <- (cycle % 7) == 0 ? "expedition" : ctx.launch_context.mode_id;
		ctx.state_vars["sortie.profile_id"] <- (cycle % 5) == 0 ? "" : ctx.launch_context.profile_id;
		ctx.state_vars["sortie.map_path"] <- (cycle % 4) == 0
			? ctx.launch_context.map_path
			: "maps/fallback_path_" + (cycle % 17);
		ctx.state_vars["sortie.launch_kind"] <- ctx.launch_context.launch_kind;
		ctx.state_vars["sortie.route_mission_id"] <- ctx.launch_context.route_mission_id;
		ctx.state_vars["sortie.difficulty"] <- ["easy", "normal", "hard", "extreme"][cycle % 4];

		ctx.anchor_report.source = (cycle % 4) == 0 ? "procedural_level" : "delving_mode";
		ctx.anchor_report.profile_id = (cycle % 6) == 0 ? "" : "profile_" + (cycle % 19);
		ctx.anchor_report.definition_id = (cycle % 5) == 0 ? "" : "sortie_def_" + (cycle % 13);
		ctx.anchor_report.sortie_def_id = "fallback_" + (cycle % 9);
		local reports = [];
		local report_count = cycle % 4;
		for (local i = 0; i < report_count; i += 1) {
			reports.push({
				id = "anchor_" + cycle + "_" + i,
				lane = (ctx.seed + i) % 5
			});
		}
		ctx.anchor_report.generated_anchor_reports = reports;

		if ((cycle % 11) == 0) {
			ctx.active = false;
			ctx.campaign_sortie_active = false;
		}
	},

	run = function(frame_count, context_count) {
		local contexts = [];
		for (local i = 0; i < context_count; i += 1) {
			contexts.push(this.makeContext(i));
		}

		local checksum = 0;
		for (local frame = 0; frame < frame_count; frame += 1) {
			foreach (ctx in contexts) {
				this.cycleContext(ctx, frame);
				local refreshed = this.refreshActiveForCurrentContext(ctx);
				local launch_kind = this.campaignSortieLaunchKind(ctx);
				local gameplay_context = this.sessionSharedText(ctx, "campaign.gameplay_context", "");
				local route_mission = this.sessionSharedText(ctx, "sortie.route_mission_id", "");
				local map_path = this.sessionSharedText(ctx, "sortie.map_path", "");
				local has_package = this.hasCampaignSortieSessionPackage(ctx);
				local generated = this.hasCampaignSortieGeneratedAnchorReport(ctx);
				local active = this.isCampaignSortieGameplayContextActive(ctx);
				local definition_id = this.generatedSortieAnchorReportDefinitionId(ctx, "standard_clear");
				checksum += refreshed ? 7 : 3;
				checksum += has_package ? 11 : 5;
				checksum += generated ? 13 : 2;
				checksum += active ? 17 : 0;
				checksum += ctx.campaign_sortie_active ? 19 : 0;
				checksum += launch_kind.len();
				checksum += gameplay_context.len();
				checksum += route_mission.len();
				checksum += map_path.len();
				checksum += definition_id.len();
			}
		}
		return checksum;
	}
};

function main() {
	return SessionContextBench.run(argInt(0, 600), argInt(1, 12));
}

return main();
