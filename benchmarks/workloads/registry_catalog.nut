// Inspired by:
// - ../inferno-code/scripts/design/item_registry/core_defs.nut
// - ../inferno-code/scripts/design/item_registry/schema_and_helpers.nut

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

function toFloat(value, fallback = 0.0) {
	try {
		return value.tofloat();
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

function buildPercentStatModifiers(stat_type, percent_value) {
	local key = stat_type == null ? "" : stat_type.tostring();
	local amount = toFloat(percent_value, 0.0);
	local normal_multiplier = 1.0 + (amount / 100.0);
	local inverse_multiplier = normal_multiplier <= 0.001 ? 1.0 : 1.0 / normal_multiplier;
	if (key == "damage") {
		return [
			{ stats = ["damage_base", "damage_end"], op = "mul", value = normal_multiplier, min = 0.0 }
		];
	}
	if (key == "fire_rate") {
		return [
			{ stat = "refire_frames", op = "mul", value = inverse_multiplier, min = 1, round = "nearest" }
		];
	}
	if (key == "capacity") {
		return [
			{ stat = "mag_ammo", op = "mul", value = normal_multiplier, min = 1, round = "nearest" }
		];
	}
	if (key == "reload") {
		return [
			{ stats = ["full_reload_frames", "quick_reload_frames"], op = "mul", value = inverse_multiplier, min = 1, round = "nearest" }
		];
	}
	if (key == "accuracy") {
		return [
			{
				stats = ["bloom_base_hipfire", "bloom_base_hipfire_moving", "bloom_base_ads", "bloom_base_ads_moving", "bloom_shot"],
				op = "mul",
				value = inverse_multiplier,
				min = 0.0
			}
		];
	}
	if (key == "recoil") {
		return [
			{ stats = ["recoil_impulse", "recoil_rotation_x_deviation", "recoil_rotation_y_deviation"], op = "mul", value = inverse_multiplier, min = 0.0 }
		];
	}
	return [];
}

function getRarityColor(rarity) {
	if (rarity == "Common") {
		return [0.7, 0.7, 0.7];
	}
	if (rarity == "Uncommon") {
		return [0.2, 0.8, 0.2];
	}
	if (rarity == "Rare") {
		return [0.3, 0.5, 1.0];
	}
	if (rarity == "Epic") {
		return [0.7, 0.2, 0.8];
	}
	if (rarity == "Legendary") {
		return [1.0, 0.7, 0.1];
	}
	return [1.0, 1.0, 1.0];
}

function roundNearest(value) {
	local numeric = toFloat(value, 0.0);
	if (numeric < 0.0) {
		return (numeric - 0.5).tointeger();
	}
	return (numeric + 0.5).tointeger();
}

function applySingleModifier(stats, stat_name, modifier) {
	if (stat_name == null) {
		return;
	}
	local key = stat_name.tostring();
	local current = (key in stats) ? toFloat(stats[key], 0.0) : 0.0;
	local op = ("op" in modifier) ? modifier.op : "set";
	local next = current;
	if (op == "mul") {
		next = current * toFloat(("value" in modifier) ? modifier.value : 1.0, 1.0);
	} else if (op == "add") {
		next = current + toFloat(("value" in modifier) ? modifier.value : 0.0, 0.0);
	} else {
		next = toFloat(("value" in modifier) ? modifier.value : current, current);
	}
	if ("min" in modifier && next < toFloat(modifier.min, next)) {
		next = toFloat(modifier.min, next);
	}
	if ("max" in modifier && next > toFloat(modifier.max, next)) {
		next = toFloat(modifier.max, next);
	}
	if ("round" in modifier && modifier.round == "nearest") {
		stats[key] <- roundNearest(next);
	} else if ((key == "equip_frames" || key == "refire_frames" || key == "mag_ammo"
			|| key == "full_reload_frames" || key == "quick_reload_frames") && next >= 0.0) {
		stats[key] <- roundNearest(next);
	} else {
		stats[key] <- next;
	}
}

function applyModifierSet(base_stats, modifiers) {
	local result = deepClone(base_stats);
	foreach (modifier in modifiers) {
		if (modifier == null || typeof modifier != "table") {
			continue;
		}
		if ("stat" in modifier) {
			applySingleModifier(result, modifier.stat, modifier);
			continue;
		}
		if ("stats" in modifier && typeof modifier.stats == "array") {
			foreach (stat_name in modifier.stats) {
				applySingleModifier(result, stat_name, modifier);
			}
		}
	}
	return result;
}

local RawCatalog = {
	core_pulse_1 = {
		id = "core_pulse_1",
		name = "Pulse Core Mk1",
		item_class = "weapon_core",
		tier = 1,
		rarity = "Common",
		slot_groups = ["barrel", "optic", "ammo", "system"],
		base_stats = {
			damage_base = 16.0,
			damage_end = 16.0,
			weight = 2.6,
			equip_frames = 960,
			refire_frames = 110,
			mag_ammo = 72,
			full_reload_frames = 4900,
			quick_reload_frames = 3600,
			ads_zoom = 1.15,
			ads_movement_multiplier = 0.62,
			recoil_impulse = 0.45,
			recoil_rotation_x_deviation = 0.18,
			recoil_rotation_y_deviation = 0.42,
			bloom_base_hipfire = 0.22,
			bloom_base_hipfire_moving = 0.35,
			bloom_base_ads = 0.05,
			bloom_base_ads_moving = 0.08,
			bloom_shot = 0.025,
			bloom_reduction_rate = 0.0051
		},
		static_modifiers = [{ stat = "weight", op = "add", value = -0.1, min = 0.5 }]
	},
	core_pulse_2 = {
		id = "core_pulse_2",
		name = "Pulse Core Mk2",
		item_class = "weapon_core",
		tier = 2,
		rarity = "Uncommon",
		slot_groups = ["barrel", "optic", "ammo", "system"],
		base_stats = {
			damage_base = 19.0,
			damage_end = 19.0,
			weight = 2.8,
			equip_frames = 920,
			refire_frames = 108,
			mag_ammo = 84,
			full_reload_frames = 4700,
			quick_reload_frames = 3400,
			ads_zoom = 1.18,
			ads_movement_multiplier = 0.6,
			recoil_impulse = 0.5,
			recoil_rotation_x_deviation = 0.2,
			recoil_rotation_y_deviation = 0.48,
			bloom_base_hipfire = 0.2,
			bloom_base_hipfire_moving = 0.33,
			bloom_base_ads = 0.04,
			bloom_base_ads_moving = 0.07,
			bloom_shot = 0.022,
			bloom_reduction_rate = 0.0053
		},
		static_modifiers = [{ stat = "equip_frames", op = "mul", value = 0.97, min = 1, round = "nearest" }]
	},
	core_rail_1 = {
		id = "core_rail_1",
		name = "Rail Core Mk1",
		item_class = "weapon_core",
		tier = 2,
		rarity = "Rare",
		slot_groups = ["barrel", "optic", "battery", "system"],
		base_stats = {
			damage_base = 62.0,
			damage_end = 62.0,
			weight = 1.1,
			equip_frames = 420,
			refire_frames = 340,
			mag_ammo = 6,
			full_reload_frames = 3900,
			quick_reload_frames = 2950,
			ads_zoom = 1.32,
			ads_movement_multiplier = 0.76,
			recoil_impulse = 9.8,
			recoil_rotation_x_deviation = 2.0,
			recoil_rotation_y_deviation = 2.2,
			bloom_base_hipfire = 0.12,
			bloom_base_hipfire_moving = 0.18,
			bloom_base_ads = 0.03,
			bloom_base_ads_moving = 0.045,
			bloom_shot = 1.2,
			bloom_reduction_rate = 0.0046
		},
		static_modifiers = [{ stat = "damage_base", op = "add", value = 3.0, min = 0.0 }]
	},
	core_arc_1 = {
		id = "core_arc_1",
		name = "Arc Core Mk1",
		item_class = "weapon_core",
		tier = 3,
		rarity = "Epic",
		slot_groups = ["emitter", "optic", "capacitor", "system"],
		base_stats = {
			damage_base = 10.0,
			damage_end = 26.0,
			weight = 3.6,
			equip_frames = 850,
			refire_frames = 75,
			mag_ammo = 40,
			full_reload_frames = 3600,
			quick_reload_frames = 2650,
			ads_zoom = 1.08,
			ads_movement_multiplier = 0.57,
			recoil_impulse = 0.2,
			recoil_rotation_x_deviation = 0.08,
			recoil_rotation_y_deviation = 0.2,
			bloom_base_hipfire = 0.4,
			bloom_base_hipfire_moving = 0.55,
			bloom_base_ads = 0.08,
			bloom_base_ads_moving = 0.12,
			bloom_shot = 0.05,
			bloom_reduction_rate = 0.0064
		},
		static_modifiers = [{ stats = ["damage_base", "damage_end"], op = "mul", value = 1.04, min = 0.0 }]
	},
	optic_snap_1 = {
		id = "optic_snap_1",
		name = "Snap Optic",
		item_class = "attachment",
		tier = 1,
		rarity = "Common",
		slot_groups = ["optic"],
		base_stats = {
			ads_zoom = 1.22,
			ads_movement_multiplier = 0.66,
			bloom_base_ads = 0.02,
			bloom_base_ads_moving = 0.04
		},
		static_modifiers = [{ stats = ["ads_zoom"], op = "mul", value = 1.06, min = 0.1 }]
	},
	optic_vector_2 = {
		id = "optic_vector_2",
		name = "Vector Optic",
		item_class = "attachment",
		tier = 2,
		rarity = "Rare",
		slot_groups = ["optic"],
		base_stats = {
			ads_zoom = 1.35,
			ads_movement_multiplier = 0.7,
			bloom_base_ads = 0.015,
			bloom_base_ads_moving = 0.03
		},
		static_modifiers = [{ stats = ["bloom_base_ads", "bloom_base_ads_moving"], op = "mul", value = 0.88, min = 0.0 }]
	},
	module_cooling_2 = {
		id = "module_cooling_2",
		name = "Cooling Module",
		item_class = "module",
		tier = 2,
		rarity = "Uncommon",
		slot_groups = ["system"],
		base_stats = {
			refire_frames = 0,
			recoil_impulse = 0.0,
			weight = 0.4
		},
		static_modifiers = [{ stat = "weight", op = "add", value = 0.15, min = 0.0 }]
	},
	module_balancer_3 = {
		id = "module_balancer_3",
		name = "Balancer Module",
		item_class = "module",
		tier = 3,
		rarity = "Legendary",
		slot_groups = ["system"],
		base_stats = {
			refire_frames = 0,
			recoil_impulse = 0.0,
			weight = 0.55
		},
		static_modifiers = [{ stat = "weight", op = "add", value = 0.25, min = 0.0 }]
	}
};

function normalizeRecord(id, raw_record, round_index) {
	local record = deepClone(raw_record);
	local modifiers = [];
	local dynamic_specs = ["damage", "fire_rate", "capacity", "reload", "accuracy", "recoil"];
	local rarity_bias = {
		Common = 0,
		Uncommon = 2,
		Rare = 4,
		Epic = 6,
		Legendary = 8
	};
	if ("static_modifiers" in record && typeof record.static_modifiers == "array") {
		foreach (modifier in record.static_modifiers) {
			modifiers.push(deepClone(modifier));
		}
	}
	foreach (spec_index, spec_name in dynamic_specs) {
		local bias = (record.rarity in rarity_bias) ? rarity_bias[record.rarity] : 0;
		local percent = ((round_index + spec_index + record.tier + bias) % 7) * 3 - 9;
		local generated = buildPercentStatModifiers(spec_name, percent.tofloat());
		foreach (modifier in generated) {
			modifiers.push(modifier);
		}
	}
	record.final_stats <- applyModifierSet(record.base_stats, modifiers);
	record.color <- getRarityColor(record.rarity);
	record.token <- record.item_class + "." + id;
	record.slot_signature <- "";
	foreach (slot_name in record.slot_groups) {
		record.slot_signature += slot_name + "|";
	}
	return record;
}

function buildCatalog(rounds) {
	local index_by_class = {};
	local index_by_rarity = {};
	local index_by_slot = {};
	local checksum = 0;

	for (local round_index = 0; round_index < rounds; round_index += 1) {
		foreach (id, raw_record in RawCatalog) {
			local record = normalizeRecord(id, raw_record, round_index);
			if (!(record.item_class in index_by_class)) {
				index_by_class[record.item_class] <- [];
			}
			if (!(record.rarity in index_by_rarity)) {
				index_by_rarity[record.rarity] <- [];
			}
			index_by_class[record.item_class].push(record.token);
			index_by_rarity[record.rarity].push(record.token);
			foreach (slot_name in record.slot_groups) {
				if (!(slot_name in index_by_slot)) {
					index_by_slot[slot_name] <- [];
				}
				index_by_slot[slot_name].push(record.token);
			}
			checksum += record.name.len();
			checksum += toInt(record.final_stats.damage_base * 10.0, 0);
			checksum += toInt(record.final_stats.damage_end * 10.0, 0);
			checksum += toInt(record.final_stats.refire_frames, 0);
			checksum += toInt(record.final_stats.mag_ammo, 0);
			checksum += toInt(record.color[0] * 100.0, 0);
			checksum += record.slot_signature.len();
		}
	}

	foreach (_class_name, entries in index_by_class) {
		checksum += entries.len() * 3;
	}
	foreach (_rarity_name, entries in index_by_rarity) {
		checksum += entries.len() * 5;
	}
	foreach (_slot_name, entries in index_by_slot) {
		checksum += entries.len() * 7;
	}
	return checksum;
}

function main() {
	return buildCatalog(argInt(0, 180));
}

return main();
