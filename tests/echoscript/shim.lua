-- Minimal shim that fakes just enough of Roblox's `script`/`require(Instance)`
-- convention so the EchoScript ModuleScripts can be loaded and exercised with
-- a stock `lua` interpreter, outside of Roblox Studio.
--
-- Real Roblox: require(script.Parent.Lexer) resolves a sibling ModuleScript
-- instance and returns whatever it `return`s (cached per instance).
-- Here: each "instance" is just a handle table { __path = "...lua" } with a
-- `Parent` pointer; our global `require` loads and caches by handle identity.

local M = {}

local function makeHandle(path)
	return { __path = path }
end

function M.newModuleTree(srcDir)
	local Lexer = makeHandle(srcDir .. "/Lexer.lua")
	local Parser = makeHandle(srcDir .. "/Parser.lua")
	local Interpreter = makeHandle(srcDir .. "/Interpreter.lua")
	local EchoScriptHandle = makeHandle(srcDir .. "/EchoScript.lua")

	local folder = {
		Lexer = Lexer,
		Parser = Parser,
		Interpreter = Interpreter,
		EchoScript = EchoScriptHandle,
	}
	for _, handle in pairs(folder) do
		handle.Parent = folder
	end

	local cache = {}

	local function load(handle)
		if cache[handle] ~= nil then
			return cache[handle]
		end
		local prevScript = _G.script
		_G.script = handle
		local chunk = assert(loadfile(handle.__path))
		local result = chunk()
		_G.script = prevScript
		cache[handle] = result
		return result
	end

	local prevRequire = _G.require
	_G.require = function(handle)
		if type(handle) == "table" and handle.__path then
			return load(handle)
		end
		if prevRequire then
			return prevRequire(handle)
		end
		error("test shim: require() expects a module handle table")
	end

	return {
		handles = folder,
		load = load,
	}
end

return M
