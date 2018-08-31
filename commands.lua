minetest.register_chatcommand("set_node", {
	params = "<x> <y> <z> <name> [param1] [param2]}",
	description = "Set the node at the specified position\n" ..
		"returns: success, (message), pos, node",
	privs = {interact = true, creative = true},
	func = function (name, param, is_cb)
		local params = {}
		
		for w in param:gmatch("([^%s]+)") do
			table.insert(params, w)
		end
		
		local pos = {x = tonumber(params[1]), y = tonumber(params[2]), z = tonumber(params[3])}
		local node = {name = params[4], param1 = tonumber(params[5]), param2 = tonumber(params[6])}
		
		if not pos.x or not pos.y or not pos.z then
			return false, is_cb and {success = false, message = "invalid position", pos = pos, node = node} or "invalid position", true
		end
		
		if minetest.is_protected(pos, name) then
			return false, is_cb and {success = false, message = "protected", pos = pos, node = node} or "protected", true
		end
		
		local def = minetest.registered_nodes[node.name]
		if not def then
			return false, is_cb and {success = false, message = "invalid node", pos = pos, node = node} or "invalid node", true
		end
		if type(def.not_in_creative_inventory) == "number" and def.not_in_creative_inventory > 0 then
			return false, is_cb and {success = false, message = "must be in creative inventory", pos = pos, node = node} or "must be in creative inventory", true
		end
		
		minetest.place_node(pos, node)
		
		return true, is_cb and {success = true, pos = pos, node = node} or "success", true
	end
})

minetest.register_chatcommand("get_node", {
	params = "<x> <y> <z>",
	description = "Get the node at the specified position\n" ..
		"returns: success, (message), pos, node",
	privs = {interact = true, creative = true},
	func = function (name, param, is_cb)
		local params = {}
		
		for w in param:gmatch("([^%s]+)") do
			table.insert(params, w)
		end
		
		local pos = {x = tonumber(params[1]), y = tonumber(params[2]), z = tonumber(params[3])}
		if not pos.x or not pos.y or not pos.z then
			return false, is_cb and {success = false, message = "invalid position"} or "invalid position", true
		end
		
		if minetest.is_protected(pos, name) then
			return false, is_cb and {success = false, message = "protected"} or "protected", true
		end
		
		local node = minetest.get_node(pos)
		
		return true, is_cb and {success = true, pos = pos, node = node} or (
			minetest.pos_to_string(pos) .. " = (name: " ..
			node.name .. ", param1: " ..
			node.param1 .. ", param2: " ..
			node.param2 .. ")"
		), true
	end
})