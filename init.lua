local load_time_start = os.clock()

-- the colour which is set by default
local default_colour = "#213dff"


local function colour_entity(ent, col)
	if ent.colour == col then
		return
	end
	ent.colour = col
	local t = "colour_carrier.png^[colorize:"..col
	ent.object:set_properties({textures = {t,t,t,t,t,t}})
end

minetest.register_entity("colour_carrier:entity", {
	visual = "cube",
	--visual_size = {x=.33,y=.33},
	collisionbox = {0,0,0,0,0,0},
	physical = false,
	on_activate = function(self, staticdata)
		local pos = self.object:get_pos()
		if minetest.get_node(pos).name ~= "colour_carrier:node" then
			self.object:remove()
			return
		end
		local colour = staticdata or ""
		if #colour ~= 7 then
			colour = default_colour
		end
		colour_entity(self, colour)
	end,
	get_staticdata = function(self)
		return self.colour or ""
	end,
})

local function get_entity(pos)
	for _,obj in pairs(minetest.get_objects_inside_radius(pos, .5)) do
		local ent = obj:get_luaentity()
		if ent
		and ent.name == "colour_carrier:entity" then
			return ent
		end
	end
end

local function set_entity(pos)
	return minetest.add_entity(pos, "colour_carrier:entity"):get_luaentity()
end

local function remove_entity(pos)
	local ent = get_entity(pos)
	if ent then
		ent.object:remove()
	end
end

local function check_channel(pos,channel)
	if channel == "colour_carrier/"..pos.z .."/"..pos.y .."/"..pos.x
	or channel == "colour_carrier_all" then
		return true
	end
	if string.sub(channel, 1, 15) ~= "colour_carrier(" then
		return false
	end
	channel = string.sub(channel, 16, -2)
	local p = {{}, {}}
	if string.find(channel, "),(", 1, true) then
		local s = string.split(channel, "),(")
		if #s > 2 then
			return false
		end
		for i = 1, 2 do
			p[i] = string.split(s[i], ",")
		end
	else
		p[1] = string.split(channel, ",")
		p[2] = p[1]
	end
	for i = 1, 2 do
		if p[i] == nil or #p[i] ~= 3 then
			return false
		end
	end
	local xyz = {"x", "y", "z"}
	for i = 1, 3 do
		local n1 = tonumber(p[1][i]) or pos[xyz[i]] + 1
		local n2 = tonumber(p[2][i]) or pos[xyz[i]] - 1
		if not ((n1 <= pos[xyz[i]] or p[1][i] == "*")
		and (n2 >= pos[xyz[i]] or p[2][i] == "*")) then
			return false
		end
	end
	return true
end

local function check_msg(msg)
	if type(msg) ~= "string" then
		return false
	end
	if #msg ~= 7
	and #msg ~= 4 then
		return false
	end
	if string.sub(msg, 1, 1) ~= "#" then
		return false
	end
	msg = string.sub(msg, 2)
	local chars = {
		"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a",
		"b", "c", "d", "e", "f", "A", "B", "C", "D", "E", "F",
	}
	for i = 1, #msg do
		local char = string.sub(msg, i, i)
		local ok = false
		for k = 1, #chars do
			if chars[k] == char then
				ok = true
				break
			end
		end
		if not ok then
			return false
		end
	end
	return true
end

local function on_digiline_receive(pos, node, channel, msg)
	if not check_msg(msg)
	or not check_channel(pos, channel) then
		return
	end

	local ent = get_entity(pos) or set_entity(pos)

	if not ent then
		minetest.log("error", "[colour_carrier] failed to add object.")
		return
	end

	colour_entity(ent, msg)
end

minetest.register_node("colour_carrier:node", {
	description = "colour carrier",
	--~ tiles = {"blank.png"},
	drawtype = "airlike",
	sunlight_propagates = true,
	paramtype = "light",
	inventory_image = "colour_carrier.png",
	wield_image = "colour_carrier.png",
	groups = {cracky = 3, stone = 1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		set_entity(pos)
	end,
	on_destruct = function(pos)
		remove_entity(pos)
	end,
	digiline = {
		receptor = {action = function() end},
		effector = {
			action = on_digiline_receive
		},
	},
})

if minetest.get_modpath("mesecons_lightstone") then
	local lr = "mesecons_lightstone:lightstone_red_off"
	local lg = "mesecons_lightstone:lightstone_green_off"
	local lb = "mesecons_lightstone:lightstone_blue_off"
	local dw = "digilines:wire_std_00000000"
	minetest.register_craft({
		output = "colour_carrier:node 3",
		recipe = {
			{lr, lg, lb},
			{dw, dw, dw},
			{lr, lg, lb}
		}
	})
end

local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "[colour_carrier] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
