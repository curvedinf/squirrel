// Inspired by:
// - ../inferno-code/scripts/shared/campaign/inventory_state/containers/*.nut
// - ../inferno-code/scripts/shared/campaign/inventory_state/progression_and_rewards/*.nut

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

local InventorySchema = {
	DEFAULT_CAPS = {
		ship_salvage_cap = 180,
		ship_component_cap = 90,
		ship_chip_cap = 45,
		ship_blueprint_cap = 24,
		ship_key_cap = 18,
		base_salvage_cap = 1500,
		base_component_cap = 900,
		base_chip_cap = 320,
		base_blueprint_cap = 140,
		base_key_cap = 90
	},

	makeDefaultContainer = function() {
		return {
			salvage_tiers = {},
			components = {},
			chips = {},
			blueprints = {},
			keys = {}
		};
	},

	makeDefaultState = function(seed) {
		return {
			seed = seed,
			ship_cargo = this.makeDefaultContainer(),
			base_storage = this.makeDefaultContainer(),
			progress = {
				key_roll = 0.0,
				blueprint_roll = 0.0
			},
			stats = {
				sorties_completed = 0,
				sorties_failed = 0,
				cargo_secured = 0,
				salvage_secured = 0,
				keys_found = 0,
				blueprints_found = 0
			},
			caps = deepClone(this.DEFAULT_CAPS)
		};
	}
};

local InventoryBench = {
	BUCKET_IDS = ["salvage_tiers", "components", "chips", "blueprints", "keys"],

	reward_tables = [
		{ id = "tier_1", salvage_tier = 1, component_tier = 1, chip_tier = 1, credits_millions = 1, key_chance = 0.02, blueprint_chance = 0.01 },
		{ id = "tier_2", salvage_tier = 2, component_tier = 2, chip_tier = 2, credits_millions = 2, key_chance = 0.04, blueprint_chance = 0.02 },
		{ id = "tier_3", salvage_tier = 3, component_tier = 3, chip_tier = 3, credits_millions = 3, key_chance = 0.06, blueprint_chance = 0.03 },
		{ id = "tier_4", salvage_tier = 4, component_tier = 4, chip_tier = 4, credits_millions = 4, key_chance = 0.08, blueprint_chance = 0.05 },
		{ id = "tier_5", salvage_tier = 5, component_tier = 5, chip_tier = 5, credits_millions = 5, key_chance = 0.11, blueprint_chance = 0.07 },
		{ id = "tier_6", salvage_tier = 6, component_tier = 6, chip_tier = 6, credits_millions = 6, key_chance = 0.14, blueprint_chance = 0.09 }
	],

	_containerForScope = function(state, scope_id) {
		if (scope_id == "base") {
			return state.base_storage;
		}
		return state.ship_cargo;
	},

	_bucketMap = function(container, bucket_id) {
		if (container == null || typeof container != "table" || bucket_id == null) {
			return null;
		}
		local key = bucket_id.tostring();
		if (key.len() == 0) {
			return null;
		}
		if (!(key in container) || container[key] == null || typeof container[key] != "table") {
			container[key] <- {};
		}
		return container[key];
	},

	_capSuffixForBucket = function(bucket_id) {
		local key = bucket_id == null ? "" : bucket_id.tostring();
		if (key == "salvage_tiers") {
			return "salvage";
		}
		if (key == "components") {
			return "component";
		}
		if (key == "chips") {
			return "chip";
		}
		if (key == "blueprints") {
			return "blueprint";
		}
		if (key == "keys") {
			return "key";
		}
		return "";
	},

	_capValueFor = function(state, scope_id, bucket_id) {
		local suffix = this._capSuffixForBucket(bucket_id);
		if (suffix.len() == 0) {
			return -1;
		}
		local scope_key = scope_id == "base" ? "base" : "ship";
		local cap_key = scope_key + "_" + suffix + "_cap";
		if ("caps" in state && typeof state.caps == "table" && cap_key in state.caps) {
			return toInt(state.caps[cap_key], -1);
		}
		if (cap_key in InventorySchema.DEFAULT_CAPS) {
			return InventorySchema.DEFAULT_CAPS[cap_key];
		}
		return -1;
	},

	_normalizeToken = function(bucket_id, raw_token) {
		if (bucket_id == "salvage_tiers") {
			local token_text = raw_token == null ? "" : raw_token.tostring();
			local prefix = "tier_";
			local value = 1;
			if (token_text.len() >= prefix.len() && token_text.slice(0, prefix.len()) == prefix) {
				value = toInt(token_text.slice(prefix.len()), 1);
			} else {
				value = toInt(token_text, 1);
			}
			if (value < 1) {
				value = 1;
			}
			return "tier_" + value;
		}
		local token = raw_token == null ? "" : raw_token.tostring();
		if (token.len() == 0) {
			token = "unknown";
		}
		return token;
	},

	_countMap = function(value) {
		local total = 0;
		if (value == null || typeof value != "table") {
			return total;
		}
		foreach (_key, raw_count in value) {
			local count = toInt(raw_count, 0);
			if (count > 0) {
				total += count;
			}
		}
		return total;
	},

	_countTokenAcrossScopes = function(state, scope_order, bucket_id, token) {
		local total = 0;
		local normalized_token = this._normalizeToken(bucket_id, token);
		foreach (scope_id in scope_order) {
			local container = this._containerForScope(state, scope_id);
			local bucket = this._bucketMap(container, bucket_id);
			if (bucket != null && normalized_token in bucket) {
				total += toInt(bucket[normalized_token], 0);
			}
		}
		return total;
	},

	_removeAcrossScopes = function(state, scope_order, bucket_id, token, amount) {
		local requested = toInt(amount, 0);
		if (requested <= 0) {
			return { ok = false, removed = 0 };
		}
		local normalized_token = this._normalizeToken(bucket_id, token);
		local remaining = requested;
		local removed_total = 0;
		foreach (scope_id in scope_order) {
			if (remaining <= 0) {
				break;
			}
			local removed = this._removeFromContainer(state, scope_id, bucket_id, normalized_token, remaining);
			local delta = ("removed" in removed) ? removed.removed : 0;
			removed_total += delta;
			remaining -= delta;
		}
		return {
			ok = removed_total > 0,
			token = normalized_token,
			requested = requested,
			removed = removed_total
		};
	},

	_containerSummary = function(container) {
		local salvage = this._countMap(("salvage_tiers" in container) ? container.salvage_tiers : {});
		local components = this._countMap(("components" in container) ? container.components : {});
		local chips = this._countMap(("chips" in container) ? container.chips : {});
		local blueprints = this._countMap(("blueprints" in container) ? container.blueprints : {});
		local keys = this._countMap(("keys" in container) ? container.keys : {});
		return {
			salvage = salvage,
			components = components,
			chips = chips,
			blueprints = blueprints,
			keys = keys,
			total = salvage + components + chips + blueprints + keys
		};
	},

	_addToContainer = function(state, scope_id, bucket_id, token, amount) {
		local container = this._containerForScope(state, scope_id);
		local bucket = this._bucketMap(container, bucket_id);
		if (bucket == null) {
			return { ok = false, requested = 0, added = 0, dropped = 0 };
		}
		local requested = toInt(amount, 0);
		if (requested <= 0) {
			return { ok = false, requested = 0, added = 0, dropped = 0 };
		}
		local normalized_token = this._normalizeToken(bucket_id, token);
		local cap = this._capValueFor(state, scope_id, bucket_id);
		local current_total = this._countMap(bucket);
		local available = requested;
		if (cap >= 0) {
			available = cap - current_total;
			if (available < 0) {
				available = 0;
			}
		}
		local added = requested > available ? available : requested;
		if (added > 0) {
			local existing = (normalized_token in bucket) ? toInt(bucket[normalized_token], 0) : 0;
			bucket[normalized_token] <- existing + added;
		}
		return {
			ok = true,
			token = normalized_token,
			requested = requested,
			added = added,
			dropped = requested - added
		};
	},

	_removeFromContainer = function(state, scope_id, bucket_id, token, amount) {
		local container = this._containerForScope(state, scope_id);
		local bucket = this._bucketMap(container, bucket_id);
		if (bucket == null) {
			return { ok = false, requested = 0, removed = 0 };
		}
		local requested = toInt(amount, 0);
		if (requested <= 0) {
			return { ok = false, requested = 0, removed = 0 };
		}
		local normalized_token = this._normalizeToken(bucket_id, token);
		if (!(normalized_token in bucket)) {
			return { ok = true, token = normalized_token, requested = requested, removed = 0 };
		}
		local current = toInt(bucket[normalized_token], 0);
		local removed = requested > current ? current : requested;
		if (removed > 0) {
			local next = current - removed;
			if (next <= 0) {
				delete bucket[normalized_token];
			} else {
				bucket[normalized_token] = next;
			}
		}
		return {
			ok = true,
			token = normalized_token,
			requested = requested,
			removed = removed
		};
	},

	_transfer = function(state, from_scope, to_scope, bucket_id, token, amount) {
		local take_result = this._removeFromContainer(state, from_scope, bucket_id, token, amount);
		local removed = ("removed" in take_result) ? take_result.removed : 0;
		if (removed <= 0) {
			return { ok = true, moved = 0, blocked = 0 };
		}
		local add_result = this._addToContainer(state, to_scope, bucket_id, token, removed);
		local moved = ("added" in add_result) ? add_result.added : 0;
		local blocked = removed - moved;
		if (blocked > 0) {
			local source = this._containerForScope(state, from_scope);
			local source_bucket = this._bucketMap(source, bucket_id);
			local normalized_token = this._normalizeToken(bucket_id, token);
			local existing = (normalized_token in source_bucket) ? toInt(source_bucket[normalized_token], 0) : 0;
			source_bucket[normalized_token] <- existing + blocked;
		}
		return {
			ok = true,
			token = this._normalizeToken(bucket_id, token),
			moved = moved,
			blocked = blocked
		};
	},

	_compareContainerEntries = function(a, b) {
		local as = ("scope_id" in a && a.scope_id != null) ? a.scope_id.tostring() : "ship";
		local bs = ("scope_id" in b && b.scope_id != null) ? b.scope_id.tostring() : "ship";
		local ar = as == "base" ? 1 : 0;
		local br = bs == "base" ? 1 : 0;
		if (ar != br) {
			return ar < br ? -1 : 1;
		}
		local ab = ("bucket_id" in a && a.bucket_id != null) ? a.bucket_id.tostring() : "";
		local bb = ("bucket_id" in b && b.bucket_id != null) ? b.bucket_id.tostring() : "";
		if (ab != bb) {
			return ab < bb ? -1 : 1;
		}
		local at = ("token" in a && a.token != null) ? a.token.tostring() : "";
		local bt = ("token" in b && b.token != null) ? b.token.tostring() : "";
		if (at != bt) {
			return at < bt ? -1 : 1;
		}
		return 0;
	},

	listContainerEntries = function(state, scope_id = "ship", bucket_id = "") {
		local output = [];
		local self = this;
		local scope_text = scope_id == null ? "ship" : scope_id.tostring();
		local scopes = scope_text == "all" ? ["ship", "base"] : (scope_text == "base" ? ["base"] : ["ship"]);
		local bucket_text = bucket_id == null ? "" : bucket_id.tostring();
		foreach (scope_name in scopes) {
			local container = this._containerForScope(state, scope_name);
			local bucket_ids = [];
			if (bucket_text == "") {
				bucket_ids = this.BUCKET_IDS;
			} else {
				bucket_ids.push(bucket_text);
			}
			foreach (bucket_name in bucket_ids) {
				if (!(bucket_name in container) || typeof container[bucket_name] != "table") {
					continue;
				}
				foreach (token, raw_count in container[bucket_name]) {
					local count = toInt(raw_count, 0);
					if (count <= 0) {
						continue;
					}
					output.push({
						scope_id = scope_name,
						bucket_id = bucket_name,
						token = token,
						count = count
					});
				}
			}
		}
		output.sort(function(a, b) {
			return self._compareContainerEntries(a, b);
		});
		return output;
	},

	consumeTokenAcrossScopes = function(state, bucket_id, token, amount = 1, prefer_ship = true) {
		local requested = toInt(amount, 0);
		if (requested <= 0) {
			return { ok = false, removed = 0, available = 0 };
		}
		local order = prefer_ship ? ["ship", "base"] : ["base", "ship"];
		local available = this._countTokenAcrossScopes(state, order, bucket_id, token);
		if (available < requested) {
			return { ok = false, removed = 0, available = available };
		}
		local removed = this._removeAcrossScopes(state, order, bucket_id, token, requested);
		return {
			ok = ("removed" in removed) ? removed.removed >= requested : false,
			removed = ("removed" in removed) ? removed.removed : 0,
			available = available
		};
	},

	secureShipCargoAtBase = function(state) {
		local summary = {
			moved_total = 0,
			blocked_total = 0,
			moved_salvage = 0
		};
		foreach (bucket_id in this.BUCKET_IDS) {
			local ship_bucket = this._bucketMap(state.ship_cargo, bucket_id);
			local tokens = [];
			foreach (token, _count in ship_bucket) {
				tokens.push(token);
			}
			foreach (token in tokens) {
				if (!(token in ship_bucket)) {
					continue;
				}
				local amount = toInt(ship_bucket[token], 0);
				if (amount <= 0) {
					continue;
				}
				local transfer = this._transfer(state, "ship", "base", bucket_id, token, amount);
				summary.moved_total += ("moved" in transfer) ? transfer.moved : 0;
				summary.blocked_total += ("blocked" in transfer) ? transfer.blocked : 0;
				if (bucket_id == "salvage_tiers") {
					summary.moved_salvage += ("moved" in transfer) ? transfer.moved : 0;
				}
			}
		}
		state.stats.cargo_secured = toInt(state.stats.cargo_secured, 0) + summary.moved_total;
		state.stats.salvage_secured = toInt(state.stats.salvage_secured, 0) + summary.moved_salvage;
		return summary;
	},

	recordMissionSuccess = function(state, reward_table, component_bonus = 0, mission_tile_bonus = false) {
		local salvage_tier = toInt(("salvage_tier" in reward_table) ? reward_table.salvage_tier : 1, 1);
		local component_tier = toInt(("component_tier" in reward_table) ? reward_table.component_tier : salvage_tier, salvage_tier);
		local chip_tier = toInt(("chip_tier" in reward_table) ? reward_table.chip_tier : salvage_tier, salvage_tier);
		local credits_millions = toInt(("credits_millions" in reward_table) ? reward_table.credits_millions : 1, 1);
		local salvage_amount = credits_millions * 25;
		if (salvage_amount < 10) {
			salvage_amount = 10;
		}
		if (mission_tile_bonus) {
			salvage_amount += 20 + salvage_tier * 2;
		}
		local component_count = toInt(component_bonus, 0);
		if (component_count < 1) {
			component_count = 1;
		}
		local chip_count = chip_tier >= 3 ? 1 + ((chip_tier - 3) / 3).tointeger() : 0;
		if (mission_tile_bonus && chip_tier >= 2) {
			chip_count += 1;
		}
		local salvage_result = this._addToContainer(state, "ship", "salvage_tiers", salvage_tier, salvage_amount);
		local component_result = this._addToContainer(state, "ship", "components", "component.tier_" + component_tier, component_count);
		local chip_result = this._addToContainer(state, "ship", "chips", "chip.tier_" + chip_tier, chip_count);

		local key_chance = toFloat(("key_chance" in reward_table) ? reward_table.key_chance : 0.0, 0.0);
		local blueprint_chance = toFloat(("blueprint_chance" in reward_table) ? reward_table.blueprint_chance : 0.0, 0.0);
		if (mission_tile_bonus) {
			key_chance += 0.02;
			blueprint_chance += 0.02;
		}
		state.progress.key_roll = toFloat(state.progress.key_roll, 0.0) + key_chance;
		state.progress.blueprint_roll = toFloat(state.progress.blueprint_roll, 0.0) + blueprint_chance;

		local key_grants = state.progress.key_roll.tointeger();
		local blueprint_grants = state.progress.blueprint_roll.tointeger();
		if (key_grants > 0) {
			state.progress.key_roll = state.progress.key_roll - key_grants.tofloat();
		}
		if (blueprint_grants > 0) {
			state.progress.blueprint_roll = state.progress.blueprint_roll - blueprint_grants.tofloat();
		}

		local key_result = this._addToContainer(state, "ship", "keys", "vault.tier_" + salvage_tier, key_grants);
		local blueprint_result = this._addToContainer(state, "ship", "blueprints", "blueprint.tier_" + component_tier, blueprint_grants);
		state.stats.sorties_completed = toInt(state.stats.sorties_completed, 0) + 1;
		state.stats.keys_found = toInt(state.stats.keys_found, 0) + key_result.added;
		state.stats.blueprints_found = toInt(state.stats.blueprints_found, 0) + blueprint_result.added;
		return {
			salvage_added = salvage_result.added,
			components_added = component_result.added,
			chips_added = chip_result.added,
			keys_added = key_result.added,
			blueprints_added = blueprint_result.added
		};
	}
};

function runInventoryFlow(mission_count, query_stride) {
	local checksum = 0;
	local state = InventorySchema.makeDefaultState("benchmark.seed");
	local reward_count = InventoryBench.reward_tables.len();

	for (local i = 0; i < mission_count; i += 1) {
		local reward_table = InventoryBench.reward_tables[i % reward_count];
		local result = InventoryBench.recordMissionSuccess(state, reward_table, (i % 4) + 1, (i % 5) == 0);
		checksum += result.salvage_added;
		checksum += result.components_added * 3;
		checksum += result.chips_added * 5;
		checksum += result.keys_added * 7;
		checksum += result.blueprints_added * 11;

		if ((i % 3) == 0) {
			local secured = InventoryBench.secureShipCargoAtBase(state);
			checksum += secured.moved_total;
			checksum += secured.blocked_total * 2;
		}
		if ((i % 4) == 0) {
			local token = "component.tier_" + (1 + (i % 6));
			local consumed = InventoryBench.consumeTokenAcrossScopes(state, "components", token, 1 + (i % 3), (i % 2) == 0);
			checksum += consumed.removed * 13;
			checksum += consumed.available;
		}
		if ((i % 6) == 0) {
			local moved = InventoryBench._transfer(state, "base", "ship", "chips", "chip.tier_" + (1 + (i % 6)), 1);
			checksum += moved.moved * 17;
			checksum += moved.blocked * 19;
		}
		if ((i % query_stride) == 0) {
			local entries = InventoryBench.listContainerEntries(state, (i % 2) == 0 ? "all" : "ship", "");
			checksum += entries.len();
		}
	}

	local ship_summary = InventoryBench._containerSummary(state.ship_cargo);
	local base_summary = InventoryBench._containerSummary(state.base_storage);
	checksum += ship_summary.total * 23;
	checksum += base_summary.total * 29;
	checksum += toInt(state.stats.sorties_completed, 0);
	checksum += toInt(state.stats.keys_found, 0) * 31;
	checksum += toInt(state.stats.blueprints_found, 0) * 37;
	return checksum;
}

function main() {
	return runInventoryFlow(argInt(0, 2200), argInt(1, 11));
}

return main();
