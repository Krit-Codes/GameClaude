-- ModuleScript: EchoScript.Interpreter
-- Tree-walking evaluator: AST -> side effects / a return value.
--
-- Values map onto native Lua values directly:
--   number, string, boolean, nil  -> themselves
--   list literal [1, 2, 3]        -> a plain Lua array table (1-indexed internally,
--                                    but EchoScript indexing is 0-based, see IndexExpr)
--   EchoScript function           -> { __echoFunction = true, params, body, closure }
--   host function                 -> a plain Lua function, called directly
--
-- Control flow (return/break/continue) is implemented by throwing sentinel
-- tables through `error()` and catching them with `pcall` at the nearest
-- function/loop boundary, same trick most tree-walkers use.

local Interpreter = {}

-- sentinels ----------------------------------------------------------------

local BREAK = { __signal = "break" }
local CONTINUE = { __signal = "continue" }

local function isReturnSignal(v)
	return type(v) == "table" and v.__signal == "return"
end

-- environments ---------------------------------------------------------------

local function envNew(parent)
	return { vars = {}, parent = parent }
end

local function envDefine(env, name, value)
	env.vars[name] = { value = value }
end

local function envGet(env, name, line)
	local e = env
	while e do
		local slot = e.vars[name]
		if slot then
			return slot.value
		end
		e = e.parent
	end
	error(string.format("EchoScript runtime error: undefined variable '%s' (line %s)", name, tostring(line)), 0)
end

local function envSet(env, name, value, line)
	local e = env
	while e do
		if e.vars[name] then
			e.vars[name].value = value
			return
		end
		e = e.parent
	end
	error(
		string.format("EchoScript runtime error: assignment to undefined variable '%s' (line %s)", name, tostring(line)),
		0
	)
end

-- helpers --------------------------------------------------------------------

local function isTruthy(v)
	return v ~= nil and v ~= false
end

local stringify

local function isEchoFunction(v)
	return type(v) == "table" and v.__echoFunction == true
end

local function isEchoList(v)
	return type(v) == "table" and not isEchoFunction(v)
end

stringify = function(v)
	if v == nil then
		return "nil"
	elseif type(v) == "string" then
		return v
	elseif type(v) == "boolean" or type(v) == "number" then
		return tostring(v)
	elseif isEchoFunction(v) then
		return "<function>"
	elseif type(v) == "table" then
		local parts = {}
		for _, item in ipairs(v) do
			parts[#parts + 1] = stringify(item)
		end
		return "[" .. table.concat(parts, ", ") .. "]"
	end
	return tostring(v)
end

local function checkNumber(v, line, what)
	if type(v) ~= "number" then
		error(
			string.format("EchoScript runtime error: expected a number for %s (line %s), got %s", what, tostring(line), type(v)),
			0
		)
	end
	return v
end

local function compareValues(left, right, line)
	if type(left) == "number" and type(right) == "number" then
		if left < right then
			return -1
		elseif left > right then
			return 1
		end
		return 0
	elseif type(left) == "string" and type(right) == "string" then
		if left < right then
			return -1
		elseif left > right then
			return 1
		end
		return 0
	end
	error(
		string.format(
			"EchoScript runtime error: cannot compare %s and %s (line %s)",
			type(left),
			type(right),
			tostring(line)
		),
		0
	)
end

-- forward declarations for mutual recursion -----------------------------------

local evalExpr, execStmt, execBlock, callFunction, evalBinary

evalBinary = function(node, env)
	local op = node.op
	local left = evalExpr(node.left, env)
	local right = evalExpr(node.right, env)

	if op == "+" then
		if type(left) == "string" or type(right) == "string" then
			return stringify(left) .. stringify(right)
		end
		checkNumber(left, node.line, "+")
		checkNumber(right, node.line, "+")
		return left + right
	elseif op == "-" then
		checkNumber(left, node.line, "-")
		checkNumber(right, node.line, "-")
		return left - right
	elseif op == "*" then
		checkNumber(left, node.line, "*")
		checkNumber(right, node.line, "*")
		return left * right
	elseif op == "/" then
		checkNumber(left, node.line, "/")
		checkNumber(right, node.line, "/")
		if right == 0 then
			error(string.format("EchoScript runtime error: division by zero (line %s)", tostring(node.line)), 0)
		end
		return left / right
	elseif op == "%" then
		checkNumber(left, node.line, "%")
		checkNumber(right, node.line, "%")
		if right == 0 then
			error(string.format("EchoScript runtime error: modulo by zero (line %s)", tostring(node.line)), 0)
		end
		return left % right
	elseif op == "==" then
		return left == right
	elseif op == "!=" then
		return left ~= right
	elseif op == "<" then
		return compareValues(left, right, node.line) < 0
	elseif op == "<=" then
		return compareValues(left, right, node.line) <= 0
	elseif op == ">" then
		return compareValues(left, right, node.line) > 0
	elseif op == ">=" then
		return compareValues(left, right, node.line) >= 0
	end
	error("EchoScript internal error: unknown binary operator '" .. tostring(op) .. "'", 0)
end

evalExpr = function(node, env)
	local t = node.type

	if t == "Literal" then
		return node.value
	elseif t == "Identifier" then
		return envGet(env, node.name, node.line)
	elseif t == "ListLiteral" then
		local list = {}
		for i, elNode in ipairs(node.elements) do
			list[i] = evalExpr(elNode, env)
		end
		return list
	elseif t == "FunctionExpr" then
		return { __echoFunction = true, params = node.params, body = node.body, closure = env }
	elseif t == "Assign" then
		local value = evalExpr(node.value, env)
		envSet(env, node.name, value, node.line)
		return value
	elseif t == "IndexAssign" then
		local obj = evalExpr(node.object, env)
		local idx = evalExpr(node.index, env)
		local value = evalExpr(node.value, env)
		if not isEchoList(obj) then
			error(string.format("EchoScript runtime error: cannot index into a %s (line %s)", type(obj), tostring(node.line)), 0)
		end
		if type(idx) == "number" then
			idx = idx + 1
		end
		obj[idx] = value
		return value
	elseif t == "IndexExpr" then
		local obj = evalExpr(node.object, env)
		local idx = evalExpr(node.index, env)
		if not isEchoList(obj) then
			error(string.format("EchoScript runtime error: cannot index into a %s (line %s)", type(obj), tostring(node.line)), 0)
		end
		if type(idx) == "number" then
			idx = idx + 1
		end
		return obj[idx]
	elseif t == "Logical" then
		local left = evalExpr(node.left, env)
		if node.op == "or" then
			if isTruthy(left) then
				return left
			end
			return evalExpr(node.right, env)
		else
			if not isTruthy(left) then
				return left
			end
			return evalExpr(node.right, env)
		end
	elseif t == "Unary" then
		if node.op == "-" then
			local v = evalExpr(node.right, env)
			checkNumber(v, node.line, "unary -")
			return -v
		end
		return not isTruthy(evalExpr(node.right, env))
	elseif t == "Binary" then
		return evalBinary(node, env)
	elseif t == "Call" then
		local callee = evalExpr(node.callee, env)
		local args = { n = #node.args }
		for i, a in ipairs(node.args) do
			args[i] = evalExpr(a, env)
		end
		return callFunction(callee, args, node.line)
	end

	error("EchoScript internal error: unknown expression node '" .. tostring(t) .. "'", 0)
end

execStmt = function(node, env)
	local t = node.type

	if t == "LetStmt" then
		local value = nil
		if node.init then
			value = evalExpr(node.init, env)
		end
		envDefine(env, node.name, value)
	elseif t == "FnStmt" then
		envDefine(env, node.name, { __echoFunction = true, params = node.params, body = node.body, closure = env })
	elseif t == "ExprStmt" then
		evalExpr(node.expr, env)
	elseif t == "Block" then
		execBlock(node, envNew(env))
	elseif t == "IfStmt" then
		if isTruthy(evalExpr(node.cond, env)) then
			execBlock(node.thenBranch, envNew(env))
		elseif node.elseBranch then
			if node.elseBranch.type == "IfStmt" then
				execStmt(node.elseBranch, env)
			else
				execBlock(node.elseBranch, envNew(env))
			end
		end
	elseif t == "WhileStmt" then
		while isTruthy(evalExpr(node.cond, env)) do
			local ok, err = pcall(execBlock, node.body, envNew(env))
			if not ok then
				if err == BREAK then
					break
				elseif err ~= CONTINUE then
					error(err, 0)
				end
			end
		end
	elseif t == "ForStmt" then
		local startV = checkNumber(evalExpr(node.start, env), node.line, "for start")
		local stopV = checkNumber(evalExpr(node.stop, env), node.line, "for stop")
		local stepV = node.step and checkNumber(evalExpr(node.step, env), node.line, "for step") or 1
		if stepV == 0 then
			error(string.format("EchoScript runtime error: for-loop step cannot be 0 (line %s)", tostring(node.line)), 0)
		end
		local i = startV
		while (stepV > 0 and i <= stopV) or (stepV < 0 and i >= stopV) do
			local loopEnv = envNew(env)
			envDefine(loopEnv, node.var, i)
			local ok, err = pcall(execBlock, node.body, loopEnv)
			if not ok then
				if err == BREAK then
					break
				elseif err ~= CONTINUE then
					error(err, 0)
				end
			end
			i = i + stepV
		end
	elseif t == "ReturnStmt" then
		local value = nil
		if node.value then
			value = evalExpr(node.value, env)
		end
		error({ __signal = "return", value = value }, 0)
	elseif t == "BreakStmt" then
		error(BREAK, 0)
	elseif t == "ContinueStmt" then
		error(CONTINUE, 0)
	else
		error("EchoScript internal error: unknown statement node '" .. tostring(t) .. "'", 0)
	end
end

execBlock = function(block, env)
	for _, stmt in ipairs(block.body) do
		execStmt(stmt, env)
	end
end

callFunction = function(fn, args, line)
	if type(fn) == "function" then
		return fn(table.unpack(args, 1, args.n or #args))
	end

	if isEchoFunction(fn) then
		local callEnv = envNew(fn.closure)
		for i, paramName in ipairs(fn.params) do
			envDefine(callEnv, paramName, args[i])
		end
		local ok, err = pcall(execBlock, fn.body, callEnv)
		if ok then
			return nil
		end
		if isReturnSignal(err) then
			return err.value
		elseif err == BREAK or err == CONTINUE then
			error("EchoScript runtime error: 'break'/'continue' used outside of a loop", 0)
		end
		error(err, 0)
	end

	error(string.format("EchoScript runtime error: attempt to call a %s value (line %s)", type(fn), tostring(line)), 0)
end

-- public API -------------------------------------------------------------------

local function installBuiltins(globals)
	envDefine(globals, "print", function(...)
		local n = select("#", ...)
		local parts = {}
		for idx = 1, n do
			parts[idx] = stringify((select(idx, ...)))
		end
		print(table.concat(parts, "\t"))
	end)
	envDefine(globals, "len", function(v)
		if type(v) == "string" then
			return #v
		elseif isEchoList(v) then
			return #v
		end
		error("EchoScript runtime error: len() expects a string or a list", 0)
	end)
	envDefine(globals, "str", function(v)
		return stringify(v)
	end)
	envDefine(globals, "num", function(v)
		local n = tonumber(v)
		if n == nil then
			error("EchoScript runtime error: num() could not convert value to a number", 0)
		end
		return n
	end)
	envDefine(globals, "push", function(list, value)
		if not isEchoList(list) then
			error("EchoScript runtime error: push() expects a list", 0)
		end
		list[#list + 1] = value
		return list
	end)
end

-- Runs a parsed Program node. `hostApi` is a plain Lua table of
-- name -> Lua function, exposed to the script as global callables.
-- Returns ok, resultOrError. On success `resultOrError` is the script's
-- top-level `return` value (or nil). On failure it's an error message string.
function Interpreter.run(ast, hostApi)
	local globals = envNew(nil)
	installBuiltins(globals)
	for name, fn in pairs(hostApi or {}) do
		envDefine(globals, name, fn)
	end

	local ok, err = pcall(execBlock, ast, globals)
	if ok then
		return true, nil
	end
	if isReturnSignal(err) then
		return true, err.value
	end
	if err == BREAK or err == CONTINUE then
		return false, "EchoScript runtime error: 'break'/'continue' used outside of a loop"
	end
	return false, err
end

return Interpreter
