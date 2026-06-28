// Inspired by:
// - ../inferno-code/scripts/runtime/modes/delving_mode/spatial_and_loot/volume_and_context.nut
// - ../inferno-code/scripts/runtime/modes/delving_mode.nut

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

function toFloat(value, fallback = 0.0) {
	try {
		return value.tofloat();
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

local VolumePresenceBench = {
	empty_array = [],

	makeWorld = function(player_count, lane_count, layer_count) {
		local by_tag = {
			["proc-tile"] = [],
			goal = [],
			["loot-route"] = [],
			["exit-gate"] = []
		};
		for (local lane = 0; lane < lane_count; lane += 1) {
			local lane_x = lane.tofloat() * 6.0;
			for (local layer = 0; layer < layer_count; layer += 1) {
				local base_z = layer.tofloat() * 8.0;
				by_tag["proc-tile"].push({
					min = { x = lane_x, y = -2.0, z = base_z },
					max = { x = lane_x + 4.5, y = 2.0, z = base_z + 5.0 }
				});
				if ((lane % 3) == 0 && (layer % 2) == 0) {
					by_tag["loot-route"].push({
						min = { x = lane_x - 1.0, y = -1.5, z = base_z + 1.0 },
						max = { x = lane_x + 5.0, y = 1.5, z = base_z + 4.0 }
					});
				}
				if ((lane % 4) == 0 && layer == layer_count - 1) {
					by_tag.goal.push({
						min = { x = lane_x, y = -2.5, z = base_z + 1.0 },
						max = { x = lane_x + 4.5, y = 2.5, z = base_z + 6.0 }
					});
				}
			}
			if ((lane % 5) == 0) {
				by_tag["exit-gate"].push({
					min = { x = lane_x + 1.0, y = -3.0, z = (layer_count - 1).tofloat() * 8.0 },
					max = { x = lane_x + 3.5, y = 3.0, z = (layer_count - 1).tofloat() * 8.0 + 6.5 }
				});
			}
		}

		local positions = {};
		local team = [];
		for (local i = 0; i < player_count; i += 1) {
			local name = "player-" + i;
			positions[name] <- {
				x = (i % lane_count).tofloat() * 3.0,
				y = ((i % 3) - 1).tofloat() * 0.75,
				z = (i % layer_count).tofloat() * 6.0
			};
			team.push({ name = name, alive = true });
		}

		return {
			lane_count = lane_count,
			layer_count = layer_count,
			volumes_by_tag = by_tag,
			player_positions = positions,
			state = { team_1 = team }
		};
	},

	playerNamesForTeam = function(state, team_key, allow_fallback = false) {
		local names = [];
		if (state == null || !(team_key in state) || state[team_key] == null) {
			return names;
		}
		foreach (player in state[team_key]) {
			if (!("name" in player) || player.name == null) {
				continue;
			}
			local name = player.name.tostring();
			if (name.len() == 0) {
				continue;
			}
			if (!allow_fallback && "alive" in player && !player.alive) {
				continue;
			}
			names.push(name);
		}
		return names;
	},

	playerPosition = function(world, player_name) {
		if (player_name == null) {
			return null;
		}
		local key = player_name.tostring();
		return (key in world.player_positions) ? world.player_positions[key] : null;
	},

	positionInsideVolume = function(position, volume, margin = 0.0) {
		if (position == null || volume == null || !("min" in volume) || !("max" in volume)) {
			return false;
		}
		local minp = volume.min;
		local maxp = volume.max;
		local pad = toFloat(margin, 0.0);
		local x = ("x" in position) ? toFloat(position.x, 0.0) : 0.0;
		local y = ("y" in position) ? toFloat(position.y, 0.0) : 0.0;
		local z = ("z" in position) ? toFloat(position.z, 0.0) : 0.0;
		return x >= toFloat(("x" in minp) ? minp.x : 0.0, 0.0) - pad
			&& x <= toFloat(("x" in maxp) ? maxp.x : 0.0, 0.0) + pad
			&& y >= toFloat(("y" in minp) ? minp.y : 0.0, 0.0) - pad
			&& y <= toFloat(("y" in maxp) ? maxp.y : 0.0, 0.0) + pad
			&& z >= toFloat(("z" in minp) ? minp.z : 0.0, 0.0) - pad
			&& z <= toFloat(("z" in maxp) ? maxp.z : 0.0, 0.0) + pad;
	},

	volumesWithTag = function(world, tag) {
		if (world == null || !("volumes_by_tag" in world) || world.volumes_by_tag == null) {
			return this.empty_array;
		}
		return (tag in world.volumes_by_tag) ? world.volumes_by_tag[tag] : this.empty_array;
	},

	anyTeamOnePlayerInVolumeTag = function(world, state, tag, margin = 0.0) {
		local volumes = this.volumesWithTag(world, tag);
		if (volumes.len() == 0) {
			return false;
		}
		foreach (player_name in this.playerNamesForTeam(state, "team_1", true)) {
			local player_position = this.playerPosition(world, player_name);
			if (player_position == null) {
				continue;
			}
			foreach (volume in volumes) {
				if (this.positionInsideVolume(player_position, volume, margin)) {
					return true;
				}
			}
		}
		return false;
	},

	generatedProcTileZBounds = function(world) {
		local volumes = this.volumesWithTag(world, "proc-tile");
		if (volumes.len() == 0) {
			return null;
		}
		local min_z = null;
		local max_z = null;
		foreach (volume in volumes) {
			if (!("min" in volume) || !("max" in volume)) {
				continue;
			}
			local vmin = ("z" in volume.min) ? toFloat(volume.min.z, 0.0) : 0.0;
			local vmax = ("z" in volume.max) ? toFloat(volume.max.z, 0.0) : 0.0;
			min_z = min_z == null || vmin < min_z ? vmin : min_z;
			max_z = max_z == null || vmax > max_z ? vmax : max_z;
		}
		if (min_z == null || max_z == null || max_z <= min_z) {
			return null;
		}
		return { min_z = min_z, max_z = max_z };
	},

	anyTeamOnePlayerInGeneratedFinalLayerFallback = function(world, state, margin = 0.0) {
		local bounds = this.generatedProcTileZBounds(world);
		if (bounds == null) {
			return false;
		}
		local threshold = bounds.min_z + (bounds.max_z - bounds.min_z) * 0.66;
		local pad = toFloat(margin, 0.0);
		foreach (player_name in this.playerNamesForTeam(state, "team_1", true)) {
			local player_position = this.playerPosition(world, player_name);
			if (player_position == null || !("z" in player_position)) {
				continue;
			}
			if (toFloat(player_position.z, 0.0) >= threshold - pad) {
				return true;
			}
		}
		return false;
	},

	advancePlayers = function(world, frame) {
		local width = world.lane_count.tofloat() * 6.0;
		local height = world.layer_count.tofloat() * 8.0;
		foreach (name, position in world.player_positions) {
			local idx = toInt(name.slice(7), 0);
			position.x = ((frame * (idx + 1)) % toInt(width * 4.0, 0)).tofloat() / 4.0;
			position.y = (((frame + idx * 3) % 9) - 4).tofloat() / 2.0;
			position.z = ((frame * 2 + idx * 5) % toInt(height + 6.0, 0)).tofloat();
			world.player_positions[name] = position;
		}
	},

	run = function(frame_count, player_count, lane_count, layer_count) {
		local world = this.makeWorld(player_count, lane_count, layer_count);
		local state = world.state;
		local checksum = 0;
		for (local frame = 0; frame < frame_count; frame += 1) {
			this.advancePlayers(world, frame);
			local in_loot = this.anyTeamOnePlayerInVolumeTag(world, state, "loot-route", 0.25);
			local in_goal = this.anyTeamOnePlayerInVolumeTag(world, state, "goal", 0.0);
			local in_exit = this.anyTeamOnePlayerInVolumeTag(world, state, "exit-gate", 0.5);
			local in_final_layer = this.anyTeamOnePlayerInGeneratedFinalLayerFallback(world, state, 0.75);
			local bounds = this.generatedProcTileZBounds(world);
			checksum += in_loot ? 5 : 2;
			checksum += in_goal ? 7 : 3;
			checksum += in_exit ? 11 : 4;
			checksum += in_final_layer ? 13 : 6;
			if (bounds != null) {
				checksum += toInt((bounds.max_z - bounds.min_z) * 10.0, 0);
			}
		}
		checksum += this.volumesWithTag(world, "proc-tile").len();
		checksum += this.volumesWithTag(world, "loot-route").len() * 3;
		checksum += this.volumesWithTag(world, "goal").len() * 5;
		checksum += this.volumesWithTag(world, "exit-gate").len() * 7;
		return checksum;
	}
};

function main() {
	return VolumePresenceBench.run(argInt(0, 600), argInt(1, 6), argInt(2, 12), argInt(3, 6));
}

return main();
