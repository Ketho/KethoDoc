
KethoDoc = {}
local eb = KethoEditBox

local branches = {
	[80100] = "live",
	[80200] = "ptr",
	[11302] = "classic",
}

KethoDoc.branch = branches[select(4, GetBuildInfo())]

function KethoDoc:DumpAPI(isLuaCheck)
	local frameXML = self.FrameXML[self.branch]
	self:InsertTable(self.FrameXmlBlacklist, frameXML)
	self:InsertTable(self.LuaAPI, frameXML)
	local API = self:GetApiSystemFuncs(isLuaCheck)
	
	-- filter all functions against FrameXML functions and Lua API
	for funcName in pairs(self:GetGlobalFuncs()) do
		if not frameXML[funcName] then
			tinsert(API, funcName)
		end
	end
	
	sort(API)
	eb:Show()
	for _, apiName in pairs(API) do
		eb:InsertLine(apiName)
	end
end

function KethoDoc:LuaTableCVars()
	local cvarTbl, commandTbl = {}, {}
	local cvarFs = '\t\t["%s"] = {"%s", %d, %s, %s, "%s"},'
	local commandFs = '\t\t["%s"] = {%d, "%s"},'
	
	for _, v in pairs(C_Console.GetAllCommands()) do
		if v.commandType == 0 then -- cvar
			local _, defaultValue, server, character = GetCVarInfo(v.command)
			local helpString = v.help and v.help:gsub('"', '\\"') or ""
			tinsert(cvarTbl, cvarFs:format(v.command, defaultValue or "", v.category, tostring(server), tostring(character), helpString))
		elseif v.commandType == 1 then -- command
			tinsert(commandTbl, commandFs:format(v.command, v.category, v.help or ""))
		end
	end
	sort(cvarTbl, self.SortCaseInsensitive)
	sort(commandTbl, self.SortCaseInsensitive)
	
	eb:Show()
	eb:InsertLine("CVar = {")
	eb:InsertLine("\tvariable = {")
	eb:InsertLine("\t\t-- variable = default, category, server, character, help")
	for _, cvar in pairs(cvarTbl) do
		eb:InsertLine(cvar)
	end
	eb:InsertLine("\t},")
	
	eb:InsertLine("\tcommand = {")
	eb:InsertLine("\t\t-- command = category, help")
	for _, command in pairs(commandTbl) do
		eb:InsertLine(command)
	end
	eb:InsertLine("\t},\n}")
end

function KethoDoc:LuaTableEnums()
	-- Enum table
	eb:Show()
	eb:InsertLine("Enum = {")
	local enums = {}
	for name in pairs(Enum) do
		tinsert(enums, name)
	end
	sort(enums)
	
	for _, name in pairs(enums) do
		local TableEnum = {}
		eb:InsertLine("\t"..name.." = {")
		
		for enumType, enumValue in pairs(Enum[name]) do
			tinsert(TableEnum, {enumType, enumValue})
		end
		
		sort(TableEnum, function(a, b)
			return a[2] < b[2]
		end)
		
		for _, enum in pairs(TableEnum) do
			eb:InsertLine(format("\t\t%s = %d,", enum[1], enum[2]))
		end
		
		eb:InsertLine("\t},")
	end
	eb:InsertLine("}\n")
	
	-- NUM_LE_* variables
	local NumLuaEnum, LuaEnum = {}, {}
	for enumType, enumValue in pairs(_G) do
		if enumType:find("^NUM_LE_") then
			tinsert(NumLuaEnum, {enumType, enumValue})
		end
	end
	
	sort(NumLuaEnum, function(a, b)
		return a[1] < b[1]
	end)
	
	for _, enum in pairs(NumLuaEnum) do
		eb:InsertLine(format("%s = %d", enum[1], enum[2]))
	end
	eb:InsertLine("")
	
	-- LE_* variables
	for enumType, enumValue in pairs(_G) do
		if enumType:find("^LE_") and not enumType:find("GAME_ERR") then
			tinsert(LuaEnum, {enumType, enumValue})
		end
	end
	
	-- cba to filter by enum value and group, too difficult
	sort(LuaEnum, function(a, b)
		return a[1] < b[1]
	end)
	
	for _, enum in pairs(LuaEnum) do
		eb:InsertLine(format("%s = %d", enum[1], enum[2]))
	end
end

function KethoDoc:LuaTableEvents()
	APIDocumentation_LoadUI()
	eb:Show()
	eb:InsertLine("Event = {")
	
	sort(APIDocumentation.systems, function(a, b)
		return (a.Namespace or a.Name) < (b.Namespace or b.Name)
	end)
	
	for _, system in pairs(APIDocumentation.systems) do
		if #system.Events > 0 then -- skip systems with no events
			eb:InsertLine("\t"..(system.Namespace or system.Name).." = {")
			
			for _, event in pairs(system.Events) do
				eb:InsertLine(format('\t\t"%s",', event.LiteralName))
			end
			
			eb:InsertLine("\t},")
		end
	end
	
	eb:InsertLine("}")
end

function KethoDoc:LuaTableWidgets()
	eb:Show()
	eb:InsertLine("Widget = {")
	for _, objectName in pairs(self.WidgetOrder) do
		eb:InsertLine("\t"..objectName.." = {")
		local object = self.WidgetClasses[objectName]
		
		local inheritsTable = {}
		for _, v in pairs(object.inherits) do
			tinsert(inheritsTable, format('"%s"', v)) -- stringify
		end
		eb:InsertLine(format("\t\tinherits = {%s},", table.concat(inheritsTable, ", ")))
		
		eb:InsertLine("\t\tmethods = {")
		local methods = self:SortTable(object.methods())
		for _, methodName in pairs(methods) do
			eb:InsertLine("\t\t\t"..methodName.." = true,")
		end
		
		eb:InsertLine("\t\t},")
		eb:InsertLine("\t},")
	end
	
	eb:InsertLine("}")
end
