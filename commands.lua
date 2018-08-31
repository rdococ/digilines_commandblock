minetest.register_chatcommand("set_node", {
	params = "<x> <y> <z> <name> [param1] [param2]",
	description = "Set the node at the specified position",
	privs = {interact = true, creative = true},
	func = function (name, param)
		local params = {}
		
		for w in param:gmatch("([^%s]+)") do
			table.insert(params, w)
		end
		
		local pos = {x = tonumber(params[1]), y = tonumber(params[2]), z = tonumber(params[3])}
		if not pos.x or not pos.y or not pos.z then
			return false, "invalid position", true
		end
		
		local node = {name = params[4], param1 = tonumber(params[5]), param2 = tonumber(params[6])}
		
		if minetest.is_protected(pos, name) then
			return false, "protected", true
		end
		
		local def = minetest.registered_nodes[node.name]
		if not def then
			return false, "invalid node", true
		end
		
		minetest.set_node(pos, node)
		
		return true, "success", true
	end
})