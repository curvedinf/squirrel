// Inspired by:
// - ../inferno-code/scripts/shared/campaign/hex_grid.nut
// - ../inferno-code/scripts/shared/campaign/world_map_builder/*.nut

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

function deepClone(value) {
	local value_type = typeof value;
	if (value_type == "table") {
		local result = {};
		foreach (k, v in value) {
			result[k] <- deepClone(v);
		}
		return result;
	}
	if (value_type == "array") {
		local result = [];
		foreach (entry in value) {
			result.push(deepClone(entry));
		}
		return result;
	}
	return value;
}

function countEntries(value) {
	local count = 0;
	foreach (_k, _v in value) {
		count += 1;
	}
	return count;
}

local HexGrid = {
	DIRECTIONS = [
		{ q = 1, r = 0, s = -1 },
		{ q = 1, r = -1, s = 0 },
		{ q = 0, r = -1, s = 1 },
		{ q = -1, r = 0, s = 1 },
		{ q = -1, r = 1, s = 0 },
		{ q = 0, r = 1, s = -1 }
	],

	absValue = function(value) {
		return value < 0 ? -value : value;
	},

	max3 = function(a, b, c) {
		local out = a;
		if (b > out) {
			out = b;
		}
		if (c > out) {
			out = c;
		}
		return out;
	},

	cube = function(q, r, s = null) {
		local qq = q == null ? 0 : q.tointeger();
		local rr = r == null ? 0 : r.tointeger();
		local ss = s == null ? (-qq - rr) : s.tointeger();
		return { q = qq, r = rr, s = ss };
	},

	axial = function(q, r) {
		return this.cube(q, r, -q - r);
	},

	copyHex = function(hex) {
		if (hex == null || typeof hex != "table") {
			return this.cube(0, 0, 0);
		}
		return this.cube(("q" in hex) ? hex.q : 0, ("r" in hex) ? hex.r : 0, ("s" in hex) ? hex.s : null);
	},

	key = function(hex) {
		local normalized = this.copyHex(hex);
		return normalized.q + ":" + normalized.r + ":" + normalized.s;
	},

	add = function(lhs, rhs) {
		local a = this.copyHex(lhs);
		local b = this.copyHex(rhs);
		return this.cube(a.q + b.q, a.r + b.r, a.s + b.s);
	},

	subtract = function(lhs, rhs) {
		local a = this.copyHex(lhs);
		local b = this.copyHex(rhs);
		return this.cube(a.q - b.q, a.r - b.r, a.s - b.s);
	},

	distance = function(lhs, rhs) {
		local delta = this.subtract(lhs, rhs);
		return this.max3(this.absValue(delta.q), this.absValue(delta.r), this.absValue(delta.s));
	},

	isWithinRadius = function(hex, radius) {
		local limit = radius == null ? 0 : radius.tointeger();
		return this.distance(this.cube(0, 0, 0), hex) <= limit;
	}
};

local Registry = {
	node_types = {
		["base"] = { name = "Base", category = "safe_hub", safe = true, default_services = ["repair", "storage", "trade"] },
		station = { name = "Station", category = "checkpoint", safe = true, default_services = ["trade", "travel"] },
		mission = { name = "Mission", category = "combat_instance", safe = false, default_services = [] },
		special = { name = "Special", category = "special_instance", safe = false, default_services = [] },
		vault = { name = "Vault", category = "keyed_reward", safe = false, default_services = ["unlock"] },
		research = { name = "Research", category = "crafting", safe = true, default_services = ["craft", "analyze"] }
	},
	mission_specs = {
		mission_0 = { id = "mission_0", route_id = "route.a", map_id = "map.a", mode_id = "delving", focus = "salvage" },
		mission_1 = { id = "mission_1", route_id = "route.b", map_id = "map.b", mode_id = "assault", focus = "combat" },
		mission_2 = { id = "mission_2", route_id = "route.c", map_id = "map.c", mode_id = "escort", focus = "defense" },
		mission_3 = { id = "mission_3", route_id = "route.d", map_id = "map.d", mode_id = "recovery", focus = "loot" }
	},
	special_specs = {
		special_0 = { id = "special_0", route_id = "special.route.a", map_id = "special.map.a", mode_id = "delving" },
		special_1 = { id = "special_1", route_id = "special.route.b", map_id = "special.map.b", mode_id = "expedition" }
	}
};

local NodeCoords = [
	{ q = 0, r = 0 },
	{ q = 1, r = 0 },
	{ q = 1, r = -1 },
	{ q = 0, r = -1 },
	{ q = -1, r = 0 },
	{ q = -1, r = 1 },
	{ q = 0, r = 1 },
	{ q = 2, r = 0 },
	{ q = 2, r = -1 },
	{ q = 1, r = 1 },
	{ q = 0, r = 2 },
	{ q = -1, r = 2 },
	{ q = -2, r = 1 },
	{ q = -2, r = 0 },
	{ q = -1, r = -1 },
	{ q = 0, r = -2 },
	{ q = 1, r = -2 },
	{ q = 2, r = -2 }
];

local WorldBuilder = {
	cloneValue = function(value) {
		return deepClone(value);
	},

	zoneNodeId = function(zone_id, type_id, template_id) {
		local zone_key = zone_id == null ? "zone" : zone_id.tostring();
		local type_key = type_id == null ? "node" : type_id.tostring();
		local template_key = template_id == null ? "entry" : template_id.tostring();
		if (type_key == "base" && template_key == "base") {
			return "base." + zone_key;
		}
		return type_key + "." + zone_key + "." + template_key;
	},

	tileId = function(zone_id, local_hex) {
		local zone_key = zone_id == null ? "zone" : zone_id.tostring();
		local hex = HexGrid.copyHex(local_hex);
		return "tile." + zone_key + "." + hex.q + "." + hex.r;
	},

	parseTileId = function(tile_id) {
		if (tile_id == null) {
			return null;
		}
		local text = tile_id.tostring();
		if (text.len() < 8 || text.slice(0, 5) != "tile.") {
			return null;
		}
		local remaining = text.slice(5);
		local dot_a = remaining.find(".");
		if (dot_a == null || dot_a <= 0 || dot_a >= remaining.len() - 1) {
			return null;
		}
		local zone_id = remaining.slice(0, dot_a);
		local coord = remaining.slice(dot_a + 1);
		local dot_b = coord.find(".");
		if (dot_b == null || dot_b <= 0 || dot_b >= coord.len() - 1) {
			return null;
		}
		local q = toInt(coord.slice(0, dot_b), 0);
		local r = toInt(coord.slice(dot_b + 1), 0);
		return {
			id = text,
			zone_id = zone_id,
			q = q,
			r = r,
			local_hex = HexGrid.axial(q, r)
		};
	},

	collectTypeLookup = function(zone_def) {
		local lookup = {};
		foreach (template in zone_def.node_templates) {
			local template_id = ("id" in template) ? template.id.tostring() : "node";
			local type_id = ("type_id" in template) ? template.type_id.tostring() : "mission";
			lookup[template_id] <- type_id;
		}
		return lookup;
	},

	resolveLinks = function(zone_id, links, type_lookup) {
		local result = [];
		if (links == null || typeof links != "array") {
			return result;
		}
		foreach (template_id in links) {
			local key = template_id == null ? "" : template_id.tostring();
			if (key.len() == 0 || !(key in type_lookup)) {
				continue;
			}
			result.push(this.zoneNodeId(zone_id, type_lookup[key], key));
		}
		return result;
	},

	buildNode = function(world_map_def, zone_def, zone_center_hex, template, type_lookup) {
		local template_id = ("id" in template) ? template.id.tostring() : "node";
		local type_id = ("type_id" in template) ? template.type_id.tostring() : "mission";
		if (!(type_id in Registry.node_types)) {
			return null;
		}
		local node_type = Registry.node_types[type_id];
		local local_hex = HexGrid.axial(("q" in template) ? template.q : 0, ("r" in template) ? template.r : 0);
		if (!HexGrid.isWithinRadius(local_hex, world_map_def.zone_radius)) {
			return null;
		}

		local mission_def = null;
		local special_def = null;
		if ("mission_id" in template && template.mission_id in Registry.mission_specs) {
			mission_def = Registry.mission_specs[template.mission_id];
		}
		if ("special_id" in template && template.special_id in Registry.special_specs) {
			special_def = Registry.special_specs[template.special_id];
		}

		local route_id = mission_def != null ? mission_def.route_id : (special_def != null ? special_def.route_id : ("route." + zone_def.id + "." + template_id));
		local map_id = mission_def != null ? mission_def.map_id : (special_def != null ? special_def.map_id : ("generic.map." + type_id));
		local mode_id = mission_def != null ? mission_def.mode_id : (special_def != null ? special_def.mode_id : "delving");
		local links = this.resolveLinks(zone_def.id, ("links" in template) ? template.links : null, type_lookup);
		return {
			id = this.zoneNodeId(zone_def.id, type_id, template_id),
			template_id = template_id,
			type_id = type_id,
			type_name = node_type.name,
			node_category = node_type.category,
			name = ("name" in template) ? template.name.tostring() : node_type.name + " " + zone_def.name,
			zone_id = zone_def.id,
			local_hex = local_hex,
			world_hex = HexGrid.add(zone_center_hex, local_hex),
			links = links,
			services = this.cloneValue(node_type.default_services),
			prototype_launch = {
				enabled = type_id == "mission" || type_id == "special" || type_id == "vault",
				route_id = route_id,
				map_id = map_id,
				mode_id = mode_id,
				difficulty = zone_def.level >= 5 ? "hard" : (zone_def.level >= 3 ? "medium" : "easy")
			}
		};
	},

	buildZone = function(world_map_def, zone_def) {
		local zone_center_hex = HexGrid.axial(zone_def.q * world_map_def.zone_stride, zone_def.r * world_map_def.zone_stride);
		local type_lookup = this.collectTypeLookup(zone_def);
		local nodes = [];
		local node_index = {};
		local tile_overrides = {};
		local base_tile_ids = [];

		foreach (template in zone_def.node_templates) {
			local node = this.buildNode(world_map_def, zone_def, zone_center_hex, template, type_lookup);
			if (node == null) {
				continue;
			}
			nodes.push(node);
			node_index[node.id] <- node;
			local tile_id = this.tileId(zone_def.id, node.local_hex);
			base_tile_ids.push(tile_id);
			tile_overrides[tile_id] <- {
				id = tile_id,
				zone_id = zone_def.id,
				local_hex = HexGrid.copyHex(node.local_hex),
				world_hex = HexGrid.copyHex(node.world_hex),
				kind = node.type_id,
				transition_target_zone = null
			};
		}

		return {
			id = zone_def.id,
			name = zone_def.name,
			level = zone_def.level,
			center_hex = zone_center_hex,
			nodes = nodes,
			node_index = node_index,
			tile_overrides = tile_overrides,
			base_tile_ids = base_tile_ids
		};
	},

	ensureTransitionTile = function(zone, other_zone, world_map) {
		local transition_hex = HexGrid.axial((other_zone.level % 3) - 1, (zone.level % 3) - 1);
		if (!HexGrid.isWithinRadius(transition_hex, world_map.zone_radius)) {
			transition_hex = HexGrid.axial(0, 0);
		}
		local tile_id = this.tileId(zone.id, transition_hex);
		if (!(tile_id in zone.tile_overrides)) {
			zone.tile_overrides[tile_id] <- {
				id = tile_id,
				zone_id = zone.id,
				local_hex = HexGrid.copyHex(transition_hex),
				world_hex = HexGrid.add(zone.center_hex, transition_hex),
				kind = "transition",
				transition_target_zone = other_zone.id
			};
		} else {
			zone.tile_overrides[tile_id].transition_target_zone = other_zone.id;
		}
		world_map.tile_override_index[tile_id] <- zone.tile_overrides[tile_id];
	},

	build = function(world_map_def) {
		local zones = [];
		local zone_index = {};
		foreach (zone_def in world_map_def.zones) {
			local built_zone = this.buildZone(world_map_def, zone_def);
			zones.push(built_zone);
			zone_index[built_zone.id] <- built_zone;
		}

		local world_map = {
			id = world_map_def.id,
			name = world_map_def.name,
			zone_radius = world_map_def.zone_radius,
			zone_stride = world_map_def.zone_stride,
			zones = zones,
			zone_index = zone_index,
			node_index = {},
			world_hex_index = {},
			tile_override_index = {},
			connections = this.cloneValue(world_map_def.connections),
			blocked_adjacency = this.cloneValue(world_map_def.blocked_adjacency)
		};

		foreach (zone in zones) {
			foreach (node in zone.nodes) {
				world_map.node_index[node.id] <- node;
				world_map.world_hex_index[HexGrid.key(node.world_hex)] <- node.id;
			}
			foreach (tile_id, tile in zone.tile_overrides) {
				world_map.tile_override_index[tile_id] <- tile;
			}
		}

		foreach (connection in world_map.connections) {
			if (connection == null || typeof connection != "table") {
				continue;
			}
			local a = ("a" in connection) ? connection.a.tostring() : "";
			local b = ("b" in connection) ? connection.b.tostring() : "";
			if (!(a in zone_index) || !(b in zone_index)) {
				continue;
			}
			this.ensureTransitionTile(zone_index[a], zone_index[b], world_map);
			this.ensureTransitionTile(zone_index[b], zone_index[a], world_map);
		}

		return world_map;
	}
};

function generateNodeTemplates(nodes_per_zone) {
	local templates = [];
	local type_cycle = ["base", "mission", "station", "mission", "special", "vault", "research"];
	for (local i = 0; i < nodes_per_zone; i += 1) {
		local coord = NodeCoords[i % NodeCoords.len()];
		local template_id = "node_" + i;
		local links = [];
		if (i > 0) {
			links.push("node_" + (i - 1));
		}
		if (i > 2 && (i % 3) == 0) {
			links.push("node_" + (i - 3));
		}
		templates.push({
			id = template_id,
			type_id = type_cycle[i % type_cycle.len()],
			q = coord.q,
			r = coord.r,
			name = "Node " + i,
			links = links,
			mission_id = "mission_" + (i % 4),
			special_id = "special_" + (i % 2)
		});
	}
	return templates;
}

function makeWorldMapDefinition(zone_count, nodes_per_zone) {
	local zones = [];
	local connections = [];
	local blocked_adjacency = [];
	for (local i = 0; i < zone_count; i += 1) {
		local zone_id = "zone_" + i;
		zones.push({
			id = zone_id,
			name = "Zone " + i,
			q = i % 6,
			r = (i / 6).tointeger() + ((i % 2) == 0 ? 0 : 1),
			level = 1 + (i % 6),
			node_templates = generateNodeTemplates(nodes_per_zone)
		});
		if (i > 0) {
			connections.push({ a = "zone_" + (i - 1), b = zone_id, kind = "route" });
		}
		if (i > 2 && (i % 4) == 0) {
			connections.push({ a = "zone_" + (i - 2), b = zone_id, kind = "route" });
			blocked_adjacency.push({ a = "zone_" + (i - 3), b = zone_id, blocker = "gate_" + i });
		}
	}
	return {
		id = "generic_world_" + zone_count + "_" + nodes_per_zone,
		name = "Generic World",
		zone_radius = 4,
		zone_stride = 14,
		zones = zones,
		connections = connections,
		blocked_adjacency = blocked_adjacency
	};
}

function runBuilds(build_count, zone_count, nodes_per_zone) {
	local checksum = 0;
	local world_map_def = makeWorldMapDefinition(zone_count, nodes_per_zone);
	for (local i = 0; i < build_count; i += 1) {
		local world_map = WorldBuilder.build(world_map_def);
		checksum += world_map.zones.len() * 11;
		checksum += countEntries(world_map.node_index) * 7;
		checksum += countEntries(world_map.tile_override_index) * 5;
		checksum += world_map.connections.len() * 3;
		foreach (zone in world_map.zones) {
			checksum += zone.base_tile_ids.len();
			foreach (node in zone.nodes) {
				checksum += node.id.len();
				checksum += node.links.len();
				checksum += node.prototype_launch.map_id.len();
				local parsed = WorldBuilder.parseTileId(WorldBuilder.tileId(zone.id, node.local_hex));
				if (parsed != null) {
					checksum += parsed.zone_id.len();
					checksum += parsed.q * parsed.q;
					checksum += parsed.r * parsed.r;
				}
			}
		}
	}
	return checksum;
}

function main() {
	local build_count = argInt(0, 30);
	local zone_count = argInt(1, 18);
	local nodes_per_zone = argInt(2, 12);
	return runBuilds(build_count, zone_count, nodes_per_zone);
}

return main();
