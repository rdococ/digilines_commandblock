digilines_commandblock = {}

function digilines_commandblock.setting(settingname, default, min)
	local setting = "digilines_commandblock." .. settingname

	if type(default) == "boolean" then
		local ret = minetest.settings:get_bool(setting)
		if ret == nil then
			ret = default
		end
		return ret
	elseif type(default) == "string" then
		return minetest.settings:get(setting) or default
	elseif type(default) == "number" then
		local ret = tonumber(minetest.settings:get(setting)) or default
		if not ret then
			minetest.log("warning", "[digilines_commandblock]: setting '"..setting.."' must be a number. Set to default value ("..tostring(default)..").")
			ret = default
		elseif ret ~= ret then -- NaN
			minetest.log("warning", "[digilines_commandblock]: setting '"..setting.."' is NaN. Set to default value ("..tostring(default)..").")
			ret = default
		end
		if min and ret < min then
			minetest.log("warning", "[digilines_commandblock]: setting '"..setting.."' is under minimum value "..tostring(min)..". Set to minimum value ("..tostring(min)..").")
			ret = min
		end
		return ret
	end
end