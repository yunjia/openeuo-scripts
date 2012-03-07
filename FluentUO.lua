-------------------------------------------------------------------------------
-- FluentUO
-- @author snicker7
-- @version 0.6.0
-- @client-compat 7.0.1.1
-- @shard-compat OSI / FS
-- @revised 12/01/2010
-- @released 4/26/2010
-- @description Makes searching for objects in the
--	world of Ultima Online easy using a natural
--	fluent interface.
-------------------------------------------------------------------------------

-- module FluentUO
FluentUO = FluentUO or {}

-------------------------------------------------------------------------------
-- Options, can be set globally or for the specific FilteredItemContainer. Use
-- FluentUO.Options(option,value) or FluentUO.Options(tOptions) where tOptions
-- is a table with key value pairs corresponding to the following options:
-- @class table
-- @name Options
-- @field NiceGlobals This will make FluentUO register the "Global" filters
-- 		such as World, Backpack, Ground, and Equipped on the FluentUO table
-- 		instead of globally. Default is false. NOTE: This must be set BEFORE
-- 		you load FluentUO. Please see the usage example:
--			FluentUO = { Options = { NiceGlobals = true } }
--			dofile('fluentuo.lua')
-- @field FindVisible This will make FluentUO run two scan item loops during
-- 		the initial scan in order to populate the Visible property on Item
-- 		objects. If you don't care about filtering by visibility, you can turn
-- 		this off. Default is on.
-- @field FindParents This will make FluentUO populate the Parent and
-- 		RootParent properties on Item objects during the initial scan. If you
-- 		don't need to access these properties or will not be doing recursive
-- 		container searches, you can turn this off and find some optimization.
-- 		However, if you call Parent or RootParent on any Item that is not
-- 		pre-populated, it will be expensive to determine as a new scanitem loop
-- 		must be executed for each item, rather than all items being populated
-- 		simultaneously. Default is on.
-- @field ActionDelay Global only. Cannot be set per instance of
-- 		FilteredItemContainers.This is the object action delay in milliseconds
--		for using or moving items. Default is 900ms.
-- @usage FluentUO = { Options = { NiceGlobals = true } } dofile('fluentuo.lua')
-- @see FluentUO.FilteredItemContainer.Options
-- @see FluentUO.Options
local p_GlobalOptions = {
	NiceGlobals = false,
	FindVisible = true,
	FindParents = true,
	ActionDelay = 1000,
}

-------------------------------------------------------------------------------
-- Used to get or set global options for FluentUO at runtime. If you omit the
-- parameters to the Options() call, the table with the currently set global
-- options will be returned.
-- @usage FluentUO.Options({FindVisible = true,FindParents = true})
-- @usage FluentUO.Options("FindVisible",true)
-- @usage local currentGlobalOptions = FluentUO.Options()
-- @publicname FluentUO.Options
-- @param option Either a table of key-value pairs to set options for, or a
-- 		single string option
-- @param value (only required if option is a string) The value to set the
--		specified option to.
-- @see FluentUO.FilteredItemContainer.Options
-- @see Options
local p_SetOptions = function(option,value)
	if option == nil then
		return p_GlobalOptions
	elseif type(option) == "table" then
		for k,v in pairs(option) do
			p_GlobalOptions[k] = v
		end
	elseif type(option) == "string" then
		p_GlobalOptions[option] = value
	end
end

p_SetOptions(FluentUO.Options)

FluentUO.Options = p_SetOptions

local propertyMetaTable = {
	__index = function(t,k)
		for prop,value in pairs(t) do
			if k:lower() == prop:lower() or k:lower() == prop:gsub("%s",""):lower() then
				return value
			end
		end
	end
}

FluentUO.Action = {}
FluentUO.Action.ActionDelay = 0

-------------------------------------------------------------------------------
-- Used to wait before performing object actions that are dependent on the
-- global action object delay. Can also be called as a non-blocking call and
-- will return false if the timespan of the delay has not passed. The delay is
-- taken from the global FluentUO.Options.ActionDelay value in milliseconds.
-- @param nonblockingcall Optional. if true, this will not stop execution but will return
-- 		true or false if the object action delay has passed. Defaults to false.
-- @return true if the object delay has passed, false if a non-blocking call is
-- 		issued and the delay has not passed
-- @usage FluentUO.Action.WaitForAction() -- This will delay execution until the delay has passed
-- @usage FluentUO.Action.WaitForAction(true) -- This will return false if the object action delay has not passed
-- @publicname FluentUO.Action.WaitForAction
-- @see FluentUO.Options
FluentUO.Action.WaitForAction = function(nonblockingcall)
	if FluentUO.Action.ActionDelay > getticks() and nonblockingcall then return false end
	while FluentUO.Action.ActionDelay > getticks() do
		wait(1)
	end
	FluentUO.Action.ActionDelay = getticks() + p_GlobalOptions.ActionDelay
	return true
end

FluentUO.Action.Item = {}
-------------------------------------------------------------------------------
-- Uses the object action delay waiting methods and invokes macro 17
-- (use last object) on the object ID passed as the 'id' parameter.
-- @param id The ID of the item to use
-- @param nonblockingcall Optional. Should the object action delay be
-- 		non-blocking? Defaults to false.
-- @return true if macro 17 was invoked, false if it is a non-blocking call and
-- 		an action cannot be performed at this time.
-- @publicname FluentUO.Action.Item.Use
FluentUO.Action.Item.Use = function(id,nonblockingcall)
	if FluentUO.Action.WaitForAction(nonblockingcall) then
		UO.LObjectID = id
		UO.Macro(17, 0, "")
		return true
	else
		return false
	end
end
-------------------------------------------------------------------------------
-- Uses the object action delay waiting methods and invokes a drag on the
-- object ID passed as the 'id' parameter.
-- @param id The ID of the item to drag
-- @param amt Optional. The amount of stack to drag. Defaults to 65535
-- @param nonblockingcall Optional. Should the object action delay be
-- 		non-blocking? Defaults to false.
-- @return true if the item was picked up, false if it is a non-blocking call
-- 		and an action cannot be performed at this time.
-- @publicname FluentUO.Action.Item.Drag
FluentUO.Action.Item.Drag = function(id,amt,nonblockingcall)
	if amt == nil then amt = 65535 end
	if FluentUO.Action.WaitForAction(nonblockingcall) then
		UO.Drag(id,amt)
		return true
	else
		return false
	end
end

-------------------------------------------------------------------------------
-- Used to reset the object action delay.
-- @usage FluentUO.Action.ResetDelay()
-- @publicname FluentUO.Action.ResetDelay
-- @see FluentUO.Action.WaitForAction
-- @see FluentUO.Action.Item.Use
-- @see FluentUO.Action.Item.Drag
FluentUO.Action.ResetDelay = function() FluentUO.Action.ActionDelay = 0 end

-------------------------------------------------------------------------------
-- Wraps UO.Property(nID) and parses the properties into a table format for
-- easy reading.
-- @usage local itemProperties = FluentUO.GetProperty(item)
-- @usage local strengthreq = itemProperties.StrengthRequirement
-- @usage local isBlessed = itemProperties.Blessed or false
-- @param item A valid Item table. Should have at least the item.ID value.
-- @return A table with the properties of the item and their values.
-- @see Property
FluentUO.GetProperty = function(item)
	local sName, sInfo = UO.Property(item.ID)
	---------------------------------------------------------------------------
	-- The property table is produced by FluentUO.GetProperty and is always
	-- populated with at least the Name and RawProperty fields. All other
	-- fields will be populated by parsing each property line. Fields can
	-- either be true/nil, single number valued, or
	-- number pair valued. An example of the first is
	-- Item.Property.Exceptional, which will be true if the property exists and
	-- nil if it does not. An example of a single numbered value is
	-- Item.Property.StrengthRequirement. Number pair valued is something like
	-- Item.Property.WeaponDamage, where two values are listed.
	-- The Property table can be accessed with case-insensitive, spaces-omitted
	-- names of the properties expected to be found. In addition to that,
	-- elemental resists and weapon damages will be added to the
	-- Item.Property.Resists and Item.Property.Damage tables respectively.
	-- @class table
	-- @name Property
	-- @field Name The name of the item
	-- @field RawProperty The "raw" property string of the item found using
	-- 		UO.Property.
	-- @field Resists The elemental resistances on an item they exist.
	-- @field Damage The elemental damage types on an item if they exist.
	-- @field misc Each line of the property string will be parsed into
	-- 		table fields as best as possible.
	local proptable = { Name = sName, RawProperty = sInfo }
	for line in string.gmatch(sInfo,"([^\n]+)\n?") do
		local r, _, property, value1, value2 = string.find(line,"([%a%s\-]+)[%s:\+]*([%d%a]*)[%s/\%\-]*(%d*)")
		if r then
			property = string.gsub(property, "^%s*(.-)%s*$", "%1")
			if value1:len() == 0 then
				value1 = true
			else
				local asnumber = tonumber(value1)
				if asnumber ~= nil then
					value1 = asnumber
				end
			end
			if value2:len() > 0 then value1 = { Min = tonumber(value1), Max = tonumber(value2) } end
			proptable[property] = value1
			local q, _, resist = string.find(line,"([%a%s]+)%sResist")
			if q then
				proptable["Resists"] = proptable["Resists"] or {}
				proptable.Resists[resist] = value1
			end
			q, _, dmgtype = string.find(line,"([%a%s]+)%sDamage")
			if q and dmgtype ~= "Weapon" then
				proptable["Damage"] = proptable["Damage"] or {}
				proptable.Damage[dmgtype] = value1
			end
		end
	end
	setmetatable(proptable,propertyMetaTable)
	return proptable
end

local itemMetaTable = {
	__index = function(t,k)
		if k == "Property" then rawset(t,"Property",FluentUO.GetProperty(t))	return t.Property end
		if k == "Name" then rawset(t,"Name",t.Property.Name)	return t.Property.Name end
		if k == "Parent" or k == "RootParent" then
			if t.Kind ~= 0 then return nil end
			local itemsbyid = {}
			for i=0,UO.ScanItems(false)-1 do
				local item = FluentUO.GetItem(i)
				itemsbyid[item.ID] = item
			end
			local rootparent = itemsbyid[t.ContID]
			while rootparent ~= nil and rootparent.Kind == 0 do rootparent = itemsbyid[rootparent.ContID] end
			rawset(t,"RootParent",rootparent)
			rawset(t,"Parent",itemsbyid[t.ContID])
			return t[k]
		end
	end
}

-------------------------------------------------------------------------------
-- Wraps the UO.GetItem function to return a
-- table with object indexers rather than
-- individual values. Also adds several
-- enhancements such as item.Dist() which gives
-- the distance based on the current world
-- position.
-- @param ... Parameters to pass to UO.GetItem
-- @usage local items = FluentUO.GetItem(index)
-- @return A table with item data from UO.GetItem
FluentUO.GetItem = function(...)
	---------------------------------------------------------------------------
	-- The item object table contains all of the standard fields returned by
	-- UO.GetItem as well as some FluentUO specific functionality to enhance
	-- usage. These item objects are returned by FluentUO.GetItem.
	-- @class table
	-- @name Item
	-- @field ID The item ID from UO.GetItem
	-- @field Type The item type from UO.GetItem
	-- @field Kind The item kind from UO.GetItem
	-- @field ContID The ID of the parent container from UO.GetItem
	-- @field X The X coordinate from UO.GetItem
	-- @field Y The Y coordinate from UO.GetItem
	-- @field Z The Z coordinate from UO.GetItem
	-- @field Stack The count of items in the stack from UO.GetItem
	-- @field Rep The reputation of the item/NPC from UO.GetItem
	-- @field Col The hue or findcol of the item from UO.GetItem
	-- @field Property The property table retrieved with FluentUO.GetProperty.
	-- 		This is a table of property values parsed from the property string.
	-- 		The values are cached until Item.InvalidateProperties() is called.
	-- @field Name The name of the object retrieved with FluentUO.GetProperty.
	-- 		The value is cached until Item.InvalidateProperties() is called.
	-- @field Parent The parent item that contains this item.
	-- @field RootParent The root parent item containing this object.
	-- @field Active.Dist The "live" distance from the character to the object
	-- @field Active.Property The "live" property of the item. Warning, this
	-- 		is a expensive call
	-- @field Active.Name The "live" name of the item. Warning, this is an
	-- 		expensive call
	-- @field InvalidateProperties Invalidates the property cache on the item
	-- @field Use Uses the item. See FluentUO.Item.Use.
	-- @field Drag Drags the item. See FluentUO.Item.Drag.
	-- @see FluentUO.GetItem
	-- @see FluentUO.Item.Active.Dist
	-- @see FluentUO.Item.Active.Property
	-- @see FluentUO.Item.Active.Name
	-- @see FluentUO.Item.Use
	-- @see FluentUO.Item.Drag
	-- @see Property
	local t = {}
	t.ID, t.Type, t.Kind, t.ContID, t.X, t.Y, t.Z, t.Stack, t.Rep, t.Col = UO.GetItem(...)
	t.Active = {}
		-----------------------------------------------------------------------
		-- Returns the "live" distance from an object to the character's
		-- position.
		-- @publicname FluentUO.Item.Active.Dist
		-- @return The distance from character to object
		t.Active.Dist = function()
			return math.max(math.abs(UO.CharPosX-t.X),math.abs(UO.CharPosY-t.Y))
		end
		-----------------------------------------------------------------------
		-- Returns the "live" uncached property of an object, always. Expensive
		-- call.
		-- @publicname FluentUO.Item.Active.Property
		-- @return The property table for the object
		-- @see Property
		t.Active.Property = function() return FluentUO.GetProperty(t) end
		-----------------------------------------------------------------------
		-- Returns the "live" uncached name of an object, always. Expensive
		-- call.
		-- @publicname FluentUO.Item.Active.Name
		-- @return The of the object
		t.Active.Name = function() return FluentUO.GetProperty(t).Name end
	---------------------------------------------------------------------------
	-- Invalidates the cached property and name values on the object.
	-- @publicname FluentUO.Item.InvalidateProperties
	t.InvalidateProperties = function() t.Name = nil t.Property = nil end
	t.Dist = t.Active.Dist()
	---------------------------------------------------------------------------
	-- Invokes event macro 17 on the object with proper object action delays.
	-- @see FluentUO.Action.Item.Use
	-- @param nonblockingcall Optional. Should the object action delay be
	-- 		non-blocking? Defaults to false.
	-- @return true if macro 17 was invoked, false if it is a non-blocking call
	-- 		and an action cannot be performed at this time.
	-- @publicname FluentUO.Item.Use
	t.Use = function(nonblockingcall) return FluentUO.Action.Item.Use(t.ID,nonblockingcall) end
	---------------------------------------------------------------------------
	-- Invokes event macro 17 on the object with proper object action delays.
	-- @see FluentUO.Action.Item.Drag
	-- @param amt Optional. The amount of stack to drag. Defaults to 65535
	-- @param nonblockingcall Optional. Should the object action delay be
	-- @return true if the item was picked up, false if it is a non-blocking
	-- 		call and an action cannot be performed at this time.
	-- @publicname FluentUO.Item.Drag
	t.Drag = function(amt,nonblockingcall) return FluentUO.Action.Item.Drag(t.ID,amt,nonblockingcall) end
	setmetatable(t,itemMetaTable)
	return t
end

FluentUO.Utils = {}
	---------------------------------------------------------------------------
	-- Bitwise XOR - thanks to Reuben Thomas and
	-- BitUtils http://lua-users.org/wiki/BitUtils
	-- and Boydon on the EUO forums for doing the
	-- hard work and actually finding this :P
	-- @param a First parameter to perform a bitwise XOR operation on.
	-- @param b Second parameter to perform a bitwise XOR operation on.
	-- @return XOR'd value of a and b.
	FluentUO.Utils.BitwiseXor = function(a,b)
		if Bit ~= nil then
			if Bit.Xor ~= nil then
				return Bit.Xor(a,b)
			end
		end
		local floor = math.floor
		local r = 0
		for i = 0, 31 do
			local x = a / 2 + b / 2
			if x ~= floor (x) then
				r = r + 2^i
			end
			a = floor (a / 2)
			b = floor (b / 2)
		end
		return r
	end

	---------------------------------------------------------------------------
	-- Converts a string value type or ID to the
	-- decimal version of the type or id. Thanks
	-- to Boydon from the EUO forums for coming up
	-- with this. Only minor modifications have
	-- been made.
	-- @param euoid String value of a type or ID to be converted to the decimal
	-- 		format.
	-- @return Converted decimal value of the type or id in euoid.
	FluentUO.Utils.ToOpenEUO = function(euoid)
		assert(type(euoid) == "string","euoid must be a string.")
		euoid = string.upper(euoid)
		local i, j, decid = 1, 0, 0
		for j = 1, #euoid do
			local char = euoid:sub(j,j)
			decid = decid + ( string.byte(char) - string.byte('A') ) * i
			i = i * 26
		end
		decid = FluentUO.Utils.BitwiseXor((decid - 7), 69)
		return decid
	end

	---------------------------------------------------------------------------
	-- Converts a decimal value type or ID to the
	-- EUO string version of the type or id. Thx
	-- to Boydon from the EUO forums for coming up
	-- with this. Only minor modifications have
	-- been made.
	-- @param decid String value of a type or ID to be converted to the decimal
	-- 		format.
	-- @return Converted decimal value of the type or id in euoid.
	FluentUO.Utils.ToEUOX = function(decid)
		assert(type(decid) == "number","decid must be a number.")
		local euoid = ""
		local i = (FluentUO.Utils.BitwiseXor(decid, 69) + 7)
		local j = 0
		while (i > 0) do
			euoid = euoid .. string.char((i % 26) + string.byte('A'))
			i = math.floor(i / 26)
		end
		return euoid
	end

-------------------------------------------------------------------------------
-- A class implementation for returning a chainable, filterable collection of
-- items. This is the main class in FluentUO. Globals like World, Ground,
-- Equipped, and Backpack are all just instances of this class. This provides
-- the scanning and filtering capabilities that are the "core" of FluentUO.
-- @usage local items = FluentUO.FilteredItemContainer().Items
-- @return An instance of the FilteredItemContainer
-- @see World
-- @see Ground
-- @see Backpack
-- @see Equipment
FluentUO.FilteredItemContainer = function()
	local self = {
			m_Items = nil,
			m_ItemsByID = {},
			m_ItemsByType = {},
			filterStack = {},
			options = {},
			nextbool = true
		}

	setmetatable(self.options,{ __index = function(t,k) return p_GlobalOptions[k] end })

	---------------------------------------------------------------------------
	-- Used to set options for this instance of the FilteredItemContainer. Will
	-- always inherit options from the global options if the option is not
	-- explicitly set on this instance. If you call Options() with no params,
	-- it will return a table of the current options set for this instance.
	-- @usage World().Options({FindVisible = true,FindParents = true}).Items
	-- @usage Backpack().Options("FindVisible",true).Items
	-- @usage local currentFilterOptions = myFilter.Options()
	-- @publicname FluentUO.FilteredItemContainer.Options
	-- @param option Either a table of key-value pairs to set options for, or a
	-- 		single string option
	-- @param value (only required if option is a string) The value to set the
	-- 		specified option to.
	-- @see FluentUO.Options
	-- @see Options
	local p_Options = function(option,value)
		if option == nil then
			return self.options
		elseif type(option) == "table" then
			for k,v in pairs(option) do
				print("setting option '"..k.."' to '"..tostring(v).."' on "..tostring(self.options))
				rawset(self.options,k,v)
			end
		elseif type(option) == "string" then
				print("setting option '"..option.."' to '"..tostring(value).."' on "..tostring(self.options))
			rawset(self.options,option,value)
		end
		return self.instance()
	end

	---------------------------------------------------------------------------
	-- Private. Wraps the UO.ScanItems method
	-- with calls to FluentUO.GetItem to populate
	-- the Items table in the FilteredItemContainer.
	-- Populates the table with both visible and
	-- invisible items and sets the Visible flag
	-- on the Item accordingly.
	-- @return a table of item tables from FluentUO.GetItem.
	-- @see FluentUO.GetItem
	-- @publicname FluentUO.FilteredItemContainer.p_Scan
	local p_Scan = function()
			local items, visibleitems, itemsbyid, itemsbytype = {}, {}, {}, {}
			if self.options.FindVisible then
				for i=0,UO.ScanItems(true)-1 do
					local item = FluentUO.GetItem(i)
					visibleitems[item.ID] = item
				end
			end
			for i=0,UO.ScanItems(false)-1 do
				local item = FluentUO.GetItem(i)
				if self.options.FindVisible then item.Visible = visibleitems[item.ID] ~= nil end
				table.insert(items,item)
				itemsbyid[item.ID] = item
				if itemsbytype[item.Type] == nil then itemsbytype[item.Type] = {} end
				itemsbytype[item.Type][item.ID] = item
			end
			if self.options.FindParents then
				for i=1,#items do
					if items[i].Kind == 0 then
						items[i].Parent = itemsbyid[items[i].ContID]
						items[i].RootParent = (function()
								if items[i].Kind ~= 0 then return nil end
								local parent = itemsbyid[items[i].ContID]
								while parent ~= nil and parent.Kind == 0 do parent = itemsbyid[parent.ContID] end
								return parent
							end)()
					end
				end
			end
			return items, itemsbyid, itemsbytype
		end

	---------------------------------------------------------------------------
	-- Filters the Item table according to the provided function or conditional
	-- string which should return true if the item remains in the collection.
	--
	-- @usage World().Where(function(item) return item.Dist() < 4 and item.Type == 210 end).Items --returns items within 4 tiles having a type of 210
	-- @usage World().Where("item.Stack > 50 and item.Stack < 100").Items --returns items with stack greater than 50 but less than 100
	--
	-- @param conditional The conditional string or callback function.
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.Where
	local p_Where = function(conditional)
			if type(conditional) == "string" then
				local funcdef = "local item = ... return "..conditional
				conditional = function(i) return loadstring(funcdef)(i) end
			end
			local items = {}
			for i,v in ipairs(self.m_Items) do
				if conditional(v) == self.nextbool then
					table.insert(items,v)
				end
			end
			self.m_Items = items
			return self.instance()
		end

	---------------------------------------------------------------------------
	-- Private. Parses parameters passed to WithID or WithType to support
	-- "old" style EUO IDs and Types in the format of "ENK" or "ENK_TNK" as
	-- well as decimal Types and IDs. Also supports tables. Even recursive
	-- tables. For people who want to piss me off.
	-- @param argument The argument to parse
	-- @return A table with decimal values of all the parsed IDs.
	-- @publicname FluentUO.FilteredItemContainer.p_ParseTypeOrID
	local p_ParseTypeOrID = function(argument)
			if type(argument) ~= "table" then
				argument = {argument}
			end
			local ids = {}
			for k,id in pairs(argument) do
				if type(id) == "string" then
					local pos, curr = 0, ""
					for st, sp in function() return string.find( id, "_", pos, true ) end do
						curr = string.sub( id, pos, st-1 )
						if string.len(curr) > 0 then
							ids[#ids+1] = FluentUO.Utils.ToOpenEUO(curr);
						end
						pos = sp + 1
					end
					curr = string.sub( id, pos )
					if string.len(curr) > 0 then
						ids[#ids+1] = FluentUO.Utils.ToOpenEUO(curr);
					end
				end
				if type(id) == "number" then
					ids[#ids+1] = id;
				end
				if type(id) == "table" then
					for i,v in ipairs(p_ParseTypeOrID(id)) do
						ids[#ids+1] = v;
					end
				end
			end
			return ids
		end

	---------------------------------------------------------------------------
	-- Filters the Item table by the ID of the item. Supports 'old EUO' style
	-- IDs (not sure why you'd need to use that though).
	-- @usage local item = World().WithID(item.ID).Items[1]
	-- @usage local items = World().WithID(1235,"UDUBAPS",18923).Items
	-- @param ... The ID(s) of the item to filter by.
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.WithID
	local p_WithID = function(...)
			local arg = {n=select('#',...),...}
			return p_Where(
				function(item)
					for j=1,arg.n do
						local ids = p_ParseTypeOrID(arg[j])
						for i=1,#ids do
							if item.ID == ids[i] then
								return true
							end
						end
					end
					return false
				end
			)
		end

	---------------------------------------------------------------------------
	-- Filters the Item table by the FindCol of the item.
	-- @usage local itemsHued2406 = World().WithCol(2406).Items
	-- @usage local itemsHued2406 = World().WithHue(2406).Items --WithHue is just an alias
	-- @usage local items = World().WithHue(2406,2407,2408).Items --Matches any of the specified hues
	-- @param ... The Hues(s) of the item to filter by.
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.WithCol
	local p_WithCol = function(...)
			local arg = {n=select('#',...),...}
			return p_Where(
				function(item)
					for j=1,arg.n do
						if item.Col == arg[j] then
							return true
						end
					end
					return false
				end
			)
		end

	---------------------------------------------------------------------------
	-- Filters the Item table by the Type of the item. Has full support for
	-- 'old EUO' style type identifiers.
	-- @usage local items = World().WithType(1337).Items
	-- @usage local ingots = World().WithType("ENK").Items.
	-- @usage local items = World().WithType(1234,4562,1284).Items
	-- @param ... The Type(s) of the item to filter by.
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.WithType
	local p_WithType = function(...)
			local arg = {n=select('#',...),...}
			return p_Where(
				function(item)
					for j=1,arg.n do
						local types = p_ParseTypeOrID(arg[j])
						for i=1,#types do
							if item.Type == types[i] then
								return true
							end
						end
					end
					return false
				end
			)
		end

	---------------------------------------------------------------------------
	-- Filters the Item table by the container id. Optionally searches all
	-- subcontainers of the specified container as well.
	-- @usage local items = World().InContainer(1225).Items
	-- @usage local items = World().InContainer(1554,12390,819,true).Items --will return items in all subcontainers as well.
	-- @param ... The container IDs to filter by. The final parameter is
	-- 		optional, and should be a boolean value: true if items in
	-- 		subcontainers of this container should be returned.
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.InContainer
	local p_InContainer = function(...)
			local arg = {n=select('#',...),...}
			local recurse = type(arg[#arg]) == "boolean" and arg[#arg] == true
			if recurse then arg[#arg] = nil end
			return p_Where(
				function(item)
					if item.Kind ~= 0 then return false end
					if recurse then
						local parent = item.Parent
						while parent ~= nil and parent.Kind == 0 do
							for j=1,#arg do
								if parent.ID == arg[j] then return true end
							end
							parent = parent.Parent
						end
						return false
					end
					for j=1,#arg do
						if item.ContID == arg[j] then
							return true
						end
					end
					return false
				end
			)
		end

	---------------------------------------------------------------------------
	-- Filters the Item table by the containers type. Full support for 'old
	-- euo' style types as parameters.
	-- @usage local itemsInBags = World().InContainerType("CKF").Items
	-- @usage local items = World.InContainerType(1234,114,192).Items
	-- @param ... The container IDs to filter by.
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.InContainerType
	local p_InContainerType = function(...)
			local arg = {n=select('#',...),...}
			return p_Where(
				function(item)
					local container = self.m_ItemsByID[item.ContID]
					if container == nil then return false end
					for j=1,arg.n do
						local types = p_ParseTypeOrID(arg[j])
						for i=1,#types do
							if container.Type == types[i] then
								return true
							end
						end
					end
					return false
				end
			)
		end

	---------------------------------------------------------------------------
	-- Filters the Item table to include only items in the backpack.
	-- @usage local backpackitems = World().InBackpack().Items
	-- @usage local allbackpackitems = World().InBackpack(true).Items
	-- @usage local allbackpackitems = Backpack().Items -- Just a global alias for the above
	-- @return This instance of the FilteredItemContainer.
	-- @param recurse Optional. True if the all child items of the backpack
	-- 		should be returned.
	-- @publicname FluentUO.FilteredItemContainer.InBackpack
	-- @see Backpack
	local p_InBackpack = function(recurse) return p_InContainer(UO.BackpackID,recurse) end

	---------------------------------------------------------------------------
	-- Filters the Item table to only include items on the characters
	-- paperdoll.
	-- @usage local myEQ = World().Equipped().Items
	-- @usage local myEQ = Equipment().Items -- a global alias for the above
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.Equipped
	-- @see Equipment
	local p_Equipped = function() return p_InContainer(UO.CharID) end

	---------------------------------------------------------------------------
	-- Private. Filters the Item table to only objects
	-- with the specific FindKind value.
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.p_WithKind
	local p_WithKind = function(kind)
			return p_Where(function(item) return item.Kind == kind end)
		end

	---------------------------------------------------------------------------
	-- Filters the Item table to only objects found in containers.
	-- @usage local items = World().InAnyContainer().Items
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.InAnyContainer
	local p_InAnyContainer = function() return p_WithKind(0) end

	---------------------------------------------------------------------------
	-- Filters the Item table to only objects found on the ground.
	-- @usage local grounditems = World().OnGround().Items
	-- @usage local grounditems = Ground().Items -- a global alias for the above
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.OnGround
	-- @see Ground
	local p_OnGround = function() return p_WithKind(1) end

	---------------------------------------------------------------------------
	-- Filters the Item table to only visible objects.
	-- @usage local visible = World().Visible().Items
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.Visible
	local p_Visible = function() return p_Where(function(item) return item.Visible end) end

	---------------------------------------------------------------------------
	-- Filters the Item table to objects only within the specified distance.
	-- @usage local nearby = World().InRange(4).Items
	-- @return This instance of the FilteredItemContainer
	-- @param nRange The distance to limit returned items by.
	-- @publicname FluentUO.FilteredItemContainer.InRange
	local p_InRange = function(nRange) return p_Where(function(item) return item.Dist <= nRange end) end

	---------------------------------------------------------------------------
	-- Toggles the boolean flag to adjust results returned by the next filter.
	-- @usage local notvisible = World().Not().Visible()
	-- @usage local faraway = World().OnGround().Not().InRange(4)
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.Not
	local p_Not = function() self.nextbool = not self.nextbool return self.instance() end

	---------------------------------------------------------------------------
	-- Private. Intercepts all function calls on a certain
	-- table and adds a closure around the function for
	-- having fun later on. The closure is then added to
	-- the filterStack table.
	-- @param t The table whose function calls to intercept.
	-- @return The table being proxied.
	-- @publicname FluentUO.FilteredItemContainer.p_proxy
	local p_proxy = function(t)
			for k,v in pairs(t) do
				if type(v) == "function" and k ~= "Update" and k ~= "Options" then
					t[k] = function(...)
						if(self.m_Items == nil) then
							self.m_Items, self.m_ItemsByID, self.m_ItemsByType = p_Scan()
						end
						table.insert(self.filterStack,{ Name = k, Args = { ... }, NArgs = select("#",...), Func = v})
						local retval = v(...)
						if(k ~= "Not" and k ~= "WithProperty" and k ~= "Options") then self.nextbool = true end
						return retval
					end
				end
			end
			return t
		end

	---------------------------------------------------------------------------
	-- Filters the Item table to objects matching the specified property
	-- criteria. Properties without a numerical value will either be nil or
	-- true, properties with one numerical value will either be a number or
	-- nil, properties with one string value will either be a string or nil,
	-- and properties with more than one numerical value will either be a table
	-- of those values or nil.
	-- @usage local manaleech = World().WithProperty("Hit Mana Leech").GreaterThan(4).Items
	-- @usage local manaleech = World().WithProperty(function(props) return props.HitManaLeech ~= nil and props.HitManaLeech > 4 end).Items
	-- @return This instance of the FilteredItemContainer or a collection of
	-- 		criteria quantifiers.
	-- @param sProperty The property to check or a function accepting the
	-- 		item's property collection returning a boolean on whether or not to
	-- 		keep the item in the table.
	-- @publicname FluentUO.FilteredItemContainer.WithProperty
	local p_WithProperty = function(sProperty)
			if type(sProperty) == "function" then
				local retval = p_Where(function(item) return sProperty(item.Property) end)
				self.nextbool = true
				return retval
			end
			return p_proxy({
				---------------------------------------------------------------
				-- Filters the item table to include only objects having the
				-- specified property.
				-- @usage local nightsight = World().WithProperty("Night Sight").Exists().Items
				-- @return This instance of the FilteredItemContainer
				-- @publicname FluentUO.FilteredItemContainer.WithProperty(sProperty).Exists
				Exists = function() return p_Where(function(item) return item.Property[sProperty] ~= nil end) end,
				---------------------------------------------------------------
				-- Filters the item table to include only objects having the
				-- specified property equal to the specified value.
				-- @usage local nightsight = World().WithProperty("Night Sight").EqualTo(true).Items
				-- @return This instance of the FilteredItemContainer
				-- @param value The value to compare with
				-- @publicname FluentUO.FilteredItemContainer.WithProperty(sProperty).EqualTo
				EqualTo = function(value) return p_Where(function(item) return item.Property[sProperty] == value end) end,
				---------------------------------------------------------------
				-- Filters the item table to include only objects having the
				-- specified property greater than the specified value
				-- @usage local mageitems = World().WithProperty("Magery").GreaterThan(10).Items
				-- @return This instance of the FilteredItemContainer
				-- @param value The value to compare with
				-- @publicname FluentUO.FilteredItemContainer.WithProperty(sProperty).GreaterThan
				GreaterThan = function(value) return p_Where(function(item) return item.Property[sProperty] ~= nil and item.Property[sProperty] > value end) end,
				---------------------------------------------------------------
				-- Filters the item table to include only objects having the
				-- specified property less than the specified value
				-- @usage local mageweps = World().WithProperty("Mage Weapon").LessThan(-27).Items
				-- @return This instance of the FilteredItemContainer
				-- @param value The value to compare with
				-- @publicname FluentUO.FilteredItemContainer.WithProperty(sProperty).LessThan
				LessThan = function(value) return p_Where(function(item) return item.Property[sProperty] ~= nil and item.Property[sProperty] < value end) end,
				---------------------------------------------------------------
				-- Filters the item table to include only objects having the
				-- specified property greater than or equal to the specified
				-- value
				-- @usage local stufftosteal = Ground().WithProperty("Artifact Rarity").GreaterThanOrEqualTo(9).Items
				-- @return This instance of the FilteredItemContainer
				-- @param value The value to compare with
				-- @publicname FluentUO.FilteredItemContainer.WithProperty(sProperty).GreaterThanOrEqualTo
				GreaterThanOrEqualTo = function(value) return p_Where(function(item) return item.Property[sProperty] ~= nil and item.Property[sProperty] >= value end) end,
				---------------------------------------------------------------
				-- Filters the item table to include only objects having the
				-- specified property less than or equal to the specified
				-- value
				-- @usage local stuffIcanCarry = Ground().WithProperty("Weight").LessThanOrEqualTo(maxweight - curweight).Items
				-- @return This instance of the FilteredItemContainer
				-- @param value The value to compare with
				-- @publicname FluentUO.FilteredItemContainer.WithProperty(sProperty).LessThanOrEqualTo
				LessThanOrEqualTo = function(value) return p_Where(function(item) return item.Property[sProperty] ~= nil and item.Property[sProperty] <= value end) end,
				---------------------------------------------------------------
				-- Filters the item table to include only objects having the
				-- specified property between the specified values
				-- @usage local stealingpractice = World().InContainer(stealfrom).WithProperty("Weight").Between({9,12}).Items
				-- @return This instance of the FilteredItemContainer
				-- @param t a table with the minimum and maximum values that
				-- 		the property should fall between
				-- @publicname FluentUO.FilteredItemContainer.WithProperty(sProperty).Between
				Between = function(t) return p_Where(function(item) return item.Property[sProperty] ~= nil and item.Property[sProperty] >= t[1] and item.Property[sProperty] <= t[2] end) end,
				---------------------------------------------------------------
				-- Filters the item table to include only objects having the
				-- specified property matching the specified pattern
				-- @usage local leechweps = World().WithProperty("RawProperty").Like("Hit %a+ Leech").Items
				-- @return This instance of the FilteredItemContainer
				-- @param pattern a Lua style pattern string to match.
				-- @publicname FluentUO.FilteredItemContainer.WithProperty(sProperty).Like
				Like = function(pattern) return p_Where(function(item) return type(item.Property[sProperty]) == "string" and string.find(item.Property[sProperty],pattern) ~= nil end) end
			})
		end

	---------------------------------------------------------------------------
	-- Filters the Item table to objects with names matching the specified
	-- pattern.
	-- @usage local tailors = World().WithName({"Tailor","Weaver"}).Items
	-- @return This instance of the FilteredItemContainer
	-- @param pattern The pattern(s) to check. Accepts multiple patterns or
	-- 		tables of patterns.
	-- @param ... Additional patterns to match. Multiple patterns will be OR'd.
	-- @publicname FluentUO.FilteredItemContainer.WithName
	local p_WithName = function(pattern,...)
			local arg = {n=select('#',...),...}
			arg[#arg+1] = pattern
			return p_Where(function(item)
				for i=1,#arg do
					if type(arg[i]) == "table" then
						for j=1,#arg[i] do
							if string.find(item.Name,arg[i][j]) ~= nil then return true end
						end
					else
						if string.find(item.Name,arg[i]) ~= nil then return true end
					end
				end
				return false
			end)
		end

	---------------------------------------------------------------------------
	-- Calls all of the closures for the
	-- currently active filters on a freshly scanned
	-- set of items.
	-- @usage local backpackreagentfilter = Backpack().WithType(reagenttypes)
	-- @usage local items = backpackreagentfilter.Update().Items
	-- @usage local items = backpackreagentfilter.Live().Items -- alias for Update()
	-- @return This instance of FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.Update
	local p_Update = function()
			self.m_Items, self.m_ItemsByID, self.m_ItemsByType = p_Scan()
			for k,v in pairs(self.filterStack) do
				v.Func(unpack(v.Args,1,v.NArgs))
				if(v.Name ~= "Not" and v.Name ~= "WithProperty" and k ~= "Options") then self.nextbool = true end
			end
			return self.instance()
		end


	local instanceMetaTable = {
		__index = function(t,k)
			if k == "Items" then
				self.m_Items, self.m_ItemsByID, self.m_ItemsByType = p_Scan()
				rawset(t,"Items",self.m_Items)
				return self.m_Items
			end
			if k == "First" then
				if t["Items"] ~= nil and #t["Items"] > 0 then
					return t["Items"][1]
				end
			end
		end
	}

	---------------------------------------------------------------------------
	-- Private. Returns the public instance of this FilteredItemContainer.
	-- @return This instance of the FilteredItemContainer.
	-- @publicname FluentUO.FilteredItemContainer.instance
	self.instance = function()
			-------------------------------------------------------------------
			-- The FilteredItemContainer table. Returns additional filters as
			-- as well as collections of items.
			-- @class table
			-- @name FilteredItemContainer
			-- @field Items The collection of item objects currently matching
			--			the filter.
			-- @field First The first item object in the Items collection
			--			matching the filter.
			local inst = {
				Items = self.m_Items,
				First = nil,
				Options = p_Options,
				Update = p_Update,
				Live = p_Update,
				WithID = p_WithID,
				WithType = p_WithType,
				WithCol = p_WithCol,
				WithHue = p_WithCol,
				WithProperty = p_WithProperty,
				WithName = p_WithName,
				InAnyContainer = p_InAnyContainer,
				InContainer = p_InContainer,
				InContainerType = p_InContainerType,
				InBackpack = p_InBackpack,
				InRange = p_InRange,
				Equipped = p_Equipped,
				OnGround = p_OnGround,
				Where = p_Where,
				Visible = p_Visible,
				Not = p_Not
			}
			p_proxy(inst)
			setmetatable(inst,instanceMetaTable)
			return inst
		end

	return self.instance()
end

---------------------------------------------------------------------------
-- An interface returning access to all currently found items.
-- @return An instance of FluentUO.FilteredItemContainer
-- @see FluentUO.FilteredItemContainer
local World = function() return FluentUO.FilteredItemContainer() end

---------------------------------------------------------------------------
-- An interface returning access to all items on the ground.
-- @return An instance of FluentUO.FilteredItemContainer pre-filtered to
-- 			only items found on the ground.
-- @see FluentUO.FilteredItemContainer
local Ground = function() return FluentUO.FilteredItemContainer().OnGround() end

---------------------------------------------------------------------------
-- An interface returning access to items in the characters backpack.
-- @return An instance of FluentUO.FilteredItemContainer pre-filtered to
-- 			only items found in the users backpack. Includes all
-- 			subcontainers as well.
-- @see FluentUO.FilteredItemContainer
local Backpack = function() return FluentUO.FilteredItemContainer().InBackpack(true) end

---------------------------------------------------------------------------
-- An interface returning access to items found on the character's
-- paperdoll.
-- @return An instance of FluentUO.FilteredItemContainer pre-filtered to
-- 			only items equipped on the character.
-- @see FluentUO.FilteredItemContainer
local Equipment = function() return FluentUO.FilteredItemContainer().Equipped() end

local destinationTable = nil
if p_GlobalOptions.NiceGlobals ~= true then
	destinationTable = _G
else
	destinationTable = FluentUO
end
destinationTable.World = World
destinationTable.Ground = Ground
destinationTable.Backpack = Backpack
destinationTable.Equipment = Equipment
