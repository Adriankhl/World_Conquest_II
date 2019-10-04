
----------------------------------------------------------
---- The code that generates the maps, basicially     ----
---- each map is generated in two steps, first        ----
---- the default mapgenerator is used then, one of    ----
---- the codes in ,/postgeneration is run             ----
----------------------------------------------------------

Map = wesnoth.dofile("./distmap.lua")
wesnoth.dofile("./postgeneration_utils/engine.lua")

local postgenerators = {}
for i, v in ipairs(wesnoth.read_file("./postgeneration")) do
	local code = string.match(v, "^(%d%a).*")
	if code then
		postgenerators[string.lower(code)] = v
	end
end

function wct_map_enemy_themed(race, pet, castle, village, chance)
	table.insert(prestart_event, wml.tag.wc2_enemy_themed {
		race = race,
		pet = pet,
		castle = castle,
		village = village,
		chance = chance
	})
end

local function run_postgeneration(map_data, id, scenario_content, nplayers, nhumanplayer)
	local player_list = {}
	for i = 1, nplayers do--nhumanplayer
		player_list[i] = i
	end
	local postgen_starttime = wesnoth.get_time_stamp()
	wesnoth.dofile("./postgeneration_utils/utilities.lua")
	wesnoth.dofile("./postgeneration_utils/events.lua")
	wesnoth.dofile("./postgeneration_utils/snow.lua")
	wesnoth.dofile("./postgeneration_utils/noise.lua")
	local postgenfile = postgenerators[id] or id .. "./lua"
	--local postgenfile = postgenerators["2f"] or id .. "./lua"
	_G.scenario_data = {
		nplayers = nplayers,
		nhumanplayers = nhumanplayer,
		scenario = scenario_content,
	}
	_G.map = wesnoth.create_map(map_data)
	_G.total_tiles = _G.map.width * _G.map.height
	_G.prestart_event = scenario_content.event[1]
	_G.images = {}
	_G.print_time = function(msg)
		std_print(msg, "time:", wesnoth.get_time_stamp() - postgen_starttime)
	end
	--the only reason why we do this here an not in mian.lua is that it needs a map object.
	shuffle_special_locations(map, player_list)
	local fun = wesnoth.dofile(string.format("./postgeneration/%s", postgenfile))
	fun()
	print_time("postegen end")
	wct_fix_impassible_item_spawn(_G.map)
	local map = _G.map.data
	_G.map = nil
	_G.total_tiles = nil
	_G.prestart_event = nil
	_G.scenario_data = nil
	return map
end

function wct_map_generator(default_id, postgen_id, length, villages, castle, iterations, hill_size, players, island)
	return function(scenario, nhumanplayer)
		std_print("wct_map_generator", default_id, postgen_id)
		local generatorfile = "./generator/" .. default_id .. ".lua"
		local generate1 = wesnoth.dofile(generatorfile)
		std_print("run_generation")
		local map_data =generate1(length, villages, castle, iterations, hill_size, players, island)

		--std_print(map_data)
		map_data = run_postgeneration(map_data, postgen_id, scenario, players, nhumanplayer)
		scenario.map_data = map_data
	end
end

function world_conquest_tek_scenario_res()
end
