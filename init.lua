local function initialize_data(meta)
	local commands = minetest.formspec_escape(meta:get_string("commands"))
	meta:set_string("formspec",
		"invsize[9,7;]" ..
		"textarea[0.5,0.5;8.5,4;commands;Commands;"..commands.."]" ..
		"label[1,4;${key} is replaced with the corresponding value]" ..
		"label[0.9,4.875;channel]" .. 
		"field[2.5,5;4,1;channel;;${channel}]" ..
		"button_exit[3.3,5.7;2,1;submit;Submit]")
	local owner = meta:get_string("owner")
	if owner == "" then
		owner = "not owned"
	else
		owner = "owned by " .. owner
	end
	meta:set_string("infotext", "Digilines Command Block\n" ..
		"(" .. owner .. ")\n" ..
		"Commands: "..commands)
end

local function construct(pos)
	local meta = minetest.get_meta(pos)

	meta:set_string("commands", "tell @nearest Commandblock unconfigured")

	meta:set_string("owner", "")
	
	meta:set_string("channel", "")

	initialize_data(meta)
end

local function after_place(pos, placer)
	if placer then
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		initialize_data(meta)
	end
end

local function receive_fields(pos, formname, fields, sender)
	if not fields.submit then
		return
	end
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if owner ~= "" and sender:get_player_name() ~= owner then
		return
	end
	meta:set_string("commands", fields.commands)
	meta:set_string("channel", fields.channel)

	initialize_data(meta)
end

local function resolve_commands(commands, pos, channel, message)
	local meta = minetest.get_meta(pos)
	local players = minetest.get_connected_players()

	-- No players online: remove all commands containing
	-- @nearest, @farthest and @random
	if #players == 0 then
		commands = commands:gsub("[^\r\n]+", function (line)
			if line:find("@nearest") then return "" end
			if line:find("@farthest") then return "" end
			if line:find("@random") then return "" end
			return line
		end)
		return commands
	end

	local nearest, farthest = nil, nil
	local min_distance, max_distance = math.huge, -1
	for index, player in pairs(players) do
		local distance = vector.distance(pos, player:getpos())
		if distance < min_distance then
			min_distance = distance
			nearest = player:get_player_name()
		end
		if distance > max_distance then
			max_distance = distance
			farthest = player:get_player_name()
		end
	end
	local random = players[math.random(#players)]:get_player_name()
	commands = commands:gsub("@nearest", nearest)
	commands = commands:gsub("@farthest", farthest)
	commands = commands:gsub("@random", random)
	
	-- If the message isn't a table, wrap it in a table
	-- Then, substitute "${" .. key .. "}" for message[key]
	if type(message) ~= "table" then
		message = {msg = message}
	end
	commands = commands:gsub("%${([^}]-)}", function (key)
		return tostring(message[key])
	end)
	
	return commands
end

local function commandblock_action_on(pos, node, channel, message)
	if node.name ~= "digilines_commandblock:commandblock_off" then
		return
	end
	
	local meta = minetest.get_meta(pos)
	if meta:get_string("channel") ~= channel then return end
	
	minetest.get_node_timer(pos):start(1)
	minetest.swap_node(pos, {name = "digilines_commandblock:commandblock_on"})
	
	local owner = meta:get_string("owner")
	if owner == "" then
		return
	end

	local commands = resolve_commands(meta:get_string("commands"), pos, channel, message)
	if not commands then return end
	for _, command in pairs(commands:split("\n")) do
		local pos = command:find(" ")
		local cmd, param = command, ""
		if pos then
			cmd = command:sub(1, pos - 1)
			param = command:sub(pos + 1)
		end
		local cmddef = minetest.chatcommands[cmd]
		if not cmddef then
			minetest.chat_send_player(owner, "The command "..cmd.." does not exist")
			return
		end
		local has_privs, missing_privs = minetest.check_player_privs(owner, cmddef.privs)
		if not has_privs then
			minetest.chat_send_player(owner, "You don't have permission "
					.."to run "..cmd
					.." (missing privileges: "
					..table.concat(missing_privs, ", ")..")")
			return
		end
		cmddef.func(owner, param)
	end
end

local function commandblock_action_off(pos, node)
	if node.name == "digilines_commandblock:commandblock_on" then
		minetest.swap_node(pos, {name = "digilines_commandblock:commandblock_off"})
	end
end

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	return owner == "" or owner == player:get_player_name()
end

minetest.register_node("digilines_commandblock:commandblock_off", {
	description = "Digilines Command Block",
	tiles = {"digilines_commandblock_off.png"},
	inventory_image = minetest.inventorycube("digilines_commandblock_off.png"),
	is_ground_content = false,
	groups = {cracky=2, mesecon_effector_off=1},
	on_construct = construct,
	after_place_node = after_place,
	on_receive_fields = receive_fields,
	can_dig = can_dig,
	sounds = default.node_sound_stone_defaults(),
	--[[mesecons = {effector = {
		action_on = commandblock_action_on
	}},]]
	digiline = 
	{
		receptor = {},
		effector = {
			action = commandblock_action_on
		},
	},
	on_blast = mesecon and mesecon.on_blastnode,
})

minetest.register_node("digilines_commandblock:commandblock_on", {
	tiles = {"digilines_commandblock_on.png"},
	is_ground_content = false,
	groups = {cracky=2, mesecon_effector_on=1, not_in_creative_inventory=1},
	light_source = 10,
	drop = "digilines_commandblock:commandblock_off",
	on_construct = construct,
	after_place_node = after_place,
	on_receive_fields = receive_fields,
	can_dig = can_dig,
	sounds = default.node_sound_stone_defaults(),
	--[[mesecons = {effector = {
		action_off = commandblock_action_off
	}},]]
	digiline = 
	{
		receptor = {},
		effector = {
			action = commandblock_action_on
		},
	},
	on_blast = mesecon and mesecon.on_blastnode,
	
	on_timer = function (pos, elapsed)
		minetest.swap_node(pos, {name = "digilines_commandblock:commandblock_off"})
	end,
})