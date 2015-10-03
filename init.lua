local load_time_start = os.clock()

--[[
channel is "colour_carrier/"..pos.z .."/"..pos.y .."/"..pos.x
msg is "#RRGGBB"
]]

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

minetest.register_entity("colour_carrier:entity",{
	visual = "cube",
	--visual_size = {x=.33,y=.33},
	collisionbox = {0,0,0,0,0,0},
	physical = false,
	on_activate = function(self, staticdata)
		local pos = self.object:getpos()
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

local function pos_channel_id(pos)
	return "colour_carrier/"..pos.z .."/"..pos.y .."/"..pos.x
end

local function on_digiline_receive(pos, node, channel, msg)
	if #msg ~= 7
	or channel ~= pos_channel_id(pos) then
		return
	end

	local ent = get_entity(pos) or set_entity(pos)

	if not ent then
		return	-- This should not happen
	end

	colour_entity(ent, msg)
end

minetest.register_node("colour_carrier:node", {
	description = "colour carrier",
	tiles = {"blank.png"},
	sunlight_propagates = true,
	paramtype = "light",
	inventory_image = "colour_carrier.png",
	groups = {cracky=3, stone=1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		set_entity(pos)
	end,
	on_destruct = function(pos)
		remove_entity(pos)
	end,
	digiline = {
		receptor = {},
		effector = {
			action = on_digiline_receive
		},
	},
})


local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "[colour_carrier] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
