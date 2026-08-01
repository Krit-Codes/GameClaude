-- Test suite for EchoScript. Run with:  lua5.4 tests/echoscript/run_tests.lua
-- (any Lua 5.1+ interpreter works; the language modules themselves are
-- Luau/Roblox compatible, only this harness is stock-Lua-only.)

-- Lua 5.1 has no table.unpack (it's the global `unpack`); Luau (the actual
-- target runtime) has table.unpack natively, so this shim exists purely to
-- let this test suite also run under a stock 5.1 interpreter for extra
-- compatibility confidence. It is never shipped to the game.
table.unpack = table.unpack or unpack

local scriptPath = arg and arg[0] or "tests/echoscript/run_tests.lua"
local testsDir = scriptPath:match("(.*/)") or "./"
local repoRoot = testsDir .. "../../"
local srcDir = repoRoot .. "src/ReplicatedStorage/Modules/EchoScript"

package.path = testsDir .. "?.lua;" .. package.path
local shim = require("shim")

local tree = shim.newModuleTree(srcDir)
local EchoScript = tree.load(tree.handles.EchoScript)

local passed, failed = 0, 0
local failures = {}

local function fail(name, msg)
	failed = failed + 1
	failures[#failures + 1] = string.format("FAIL: %s\n      %s", name, msg)
end

local function ok(name, cond, msg)
	if cond then
		passed = passed + 1
	else
		fail(name, msg or "assertion failed")
	end
end

local function eq(name, actual, expected)
	if actual == expected then
		passed = passed + 1
	else
		fail(name, string.format("expected %s, got %s", tostring(expected), tostring(actual)))
	end
end

-- Runs source with an optional host API, asserts it succeeds, returns the
-- captured stdout lines (via a `print`-shadowing collector passed as `out`)
-- and the top-level return value.
local function run(source, hostApi)
	return EchoScript.run(source, hostApi)
end

local function runCapturingPrints(source, hostApi)
	local lines = {}
	hostApi = hostApi or {}
	if not hostApi.__no_capture then
		-- EchoScript's builtin `print` calls the real Lua `print`; capture by
		-- temporarily redirecting the global.
	end
	local realPrint = _G.print
	_G.print = function(...)
		local n = select("#", ...)
		local parts = {}
		for i = 1, n do
			parts[i] = tostring((select(i, ...)))
		end
		lines[#lines + 1] = table.concat(parts, "\t")
	end
	local success, result = EchoScript.run(source, hostApi)
	_G.print = realPrint
	return success, result, lines
end

-- 1. lexer -------------------------------------------------------------

do
	local Lexer = tree.load(tree.handles.Lexer)
	local tokens = Lexer.tokenize('let x = 5 + "hi" // comment\n')
	local types = {}
	for _, t in ipairs(tokens) do
		types[#types + 1] = t.type
	end
	eq("lexer: token count", #tokens, 7) -- LET IDENT = NUMBER + STRING EOF
	eq("lexer: types", table.concat(types, " "), "LET IDENT = NUMBER + STRING EOF")

	local okBad = pcall(Lexer.tokenize, '"unterminated')
	ok("lexer: unterminated string errors", not okBad)

	local okBad2 = pcall(Lexer.tokenize, "let x = @")
	ok("lexer: unknown char errors", not okBad2)
end

-- 2. parser --------------------------------------------------------------

do
	local Parser = tree.load(tree.handles.Parser)
	local Lexer = tree.load(tree.handles.Lexer)
	local ast = Parser.parse(Lexer.tokenize("let x = 1 + 2 * 3"))
	eq("parser: program has 1 stmt", #ast.body, 1)
	local stmt = ast.body[1]
	eq("parser: LetStmt", stmt.type, "LetStmt")
	eq("parser: precedence (Binary +)", stmt.init.type, "Binary")
	eq("parser: precedence (+ op)", stmt.init.op, "+")
	eq("parser: precedence (right side is * )", stmt.init.right.type, "Binary")
	eq("parser: precedence (* op)", stmt.init.right.op, "*")

	local okBad = pcall(Parser.parse, Lexer.tokenize("let = 5"))
	ok("parser: missing ident errors", not okBad)
end

-- 3. arithmetic & comparisons --------------------------------------------

do
	local success, result = run("return 1 + 2 * 3")
	ok("arith: 1 + 2 * 3 succeeds", success, result)
	eq("arith: 1 + 2 * 3 == 7", result, 7)

	local s2, r2 = run("return (1 + 2) * 3")
	ok("arith: parens succeed", s2)
	eq("arith: (1+2)*3 == 9", r2, 9)

	local s3, r3 = run("return 10 % 3")
	eq("arith: 10 %% 3 == 1", r3, 1)

	local s4, r4 = run('return "a" + "b" + 1')
	eq("arith: string concat via +", r4, "ab1")

	local s5, r5 = run("return 3 < 5 and 5 <= 5 and not (2 > 9)")
	eq("logic: combined comparisons", r5, true)

	local sDiv, rDiv = run("return 1 / 0")
	ok("arith: division by zero is a runtime error", not sDiv, rDiv)
end

-- 4. variables & scoping ---------------------------------------------------

do
	local success, result = run([[
		let x = 10
		{
			let x = 20
			x = x + 1
		}
		return x
	]])
	ok("scope: shadowing succeeds", success, result)
	eq("scope: outer x unaffected by inner shadow", result, 10)

	local s2, r2 = run("x = 5")
	ok("scope: assigning undefined var errors", not s2, r2)
end

-- 5. control flow ----------------------------------------------------------

do
	local success, result = run([[
		let sum = 0
		let i = 0
		while i < 5 {
			sum = sum + i
			i = i + 1
		}
		return sum
	]])
	ok("while: sums 0..4", success, result)
	eq("while: sum == 10", result, 10)

	local s2, r2 = run([[
		let sum = 0
		for i = 1, 10 {
			if i % 2 == 0 {
				continue
			}
			if i > 7 {
				break
			}
			sum = sum + i
		}
		return sum
	]])
	ok("for: continue/break succeed", s2, r2)
	eq("for: odd numbers 1,3,5,7 == 16", r2, 16)

	local s3, r3 = run([[
		for i = 10, 1, -3 {
			return i
		}
	]])
	eq("for: negative step, first i == 10", r3, 10)
end

-- 6. functions & closures ---------------------------------------------------

do
	local success, result = run([[
		fn add(a, b) {
			return a + b
		}
		return add(3, 4)
	]])
	ok("fn: named function call succeeds", success, result)
	eq("fn: add(3,4) == 7", result, 7)

	local s2, r2 = run([[
		fn makeCounter() {
			let count = 0
			fn increment() {
				count = count + 1
				return count
			}
			return increment
		}
		let counter = makeCounter()
		counter()
		counter()
		return counter()
	]])
	ok("fn: closures succeed", s2, r2)
	eq("fn: closure keeps private state across calls", r2, 3)

	local s3, r3 = run([[
		let apply = fn(f, x) { return f(x) }
		return apply(fn(n) { return n * n }, 6)
	]])
	ok("fn: anonymous functions + higher order succeed", s3, r3)
	eq("fn: apply(square, 6) == 36", r3, 36)

	local s4, r4 = run([[
		fn fact(n) {
			if n <= 1 {
				return 1
			}
			return n * fact(n - 1)
		}
		return fact(6)
	]])
	ok("fn: recursion succeeds", s4, r4)
	eq("fn: fact(6) == 720", r4, 720)
end

-- 7. lists -------------------------------------------------------------------

do
	local success, result = run([[
		let xs = [10, 20, 30]
		xs[1] = 99
		push(xs, 40)
		return xs[0] + xs[1] + xs[3] + len(xs)
	]])
	ok("list: literals/index/push succeed", success, result)
	eq("list: 10 + 99 + 40 + 4 == 153", result, 153)
end

-- 8. host API bridging --------------------------------------------------------

do
	local calls = {}
	local hostApi = {
		say = function(text)
			calls[#calls + 1] = text
		end,
	}
	local success, result = EchoScript.run([[
		say("hello " + "warden")
		say("second line")
	]], hostApi)
	ok("host: calling host functions succeeds", success, result)
	eq("host: first call captured", calls[1], "hello warden")
	eq("host: second call captured", calls[2], "second line")

	local s2, r2 = EchoScript.run("undefinedHostFn()", {})
	ok("host: calling unknown identifier is a runtime error", not s2, r2)
end

-- 9. builtins (print/str/num) -------------------------------------------------

do
	local success, result, lines = runCapturingPrints([[
		print("x =", 5, true, nil)
		print(str(42) + "!")
	]])
	ok("builtin: print succeeds", success, result)
	eq("builtin: print line count", #lines, 2)
	eq("builtin: print formats args", lines[1], "x =\t5\ttrue\tnil")
	eq("builtin: str() + concat", lines[2], "42!")

	local s2, r2 = run('return num("3") + num("4")')
	ok("builtin: num() succeeds", s2)
	eq("builtin: num(\"3\") + num(\"4\") == 7", r2, 7)
end

-- 10. error surface ------------------------------------------------------------

do
	local s1, e1 = run("let x = ")
	ok("errors: parse error surfaces as failure", not s1)
	ok("errors: parse error message mentions EchoScript", type(e1) == "string" and e1:find("EchoScript"))

	local s2, e2 = run("return undefinedVar")
	ok("errors: undefined var is a runtime failure", not s2)
	ok("errors: message mentions the var name", e2:find("undefinedVar") ~= nil)

	local s3, e3 = run("return 1 + true")
	ok("errors: type mismatch on + is a runtime failure", not s3)
end

-- 11. the shipped example script actually runs -------------------------------

do
	local examplePath = repoRoot .. "examples/intro_cutscene.echo"
	local f = io.open(examplePath, "r")
	ok("example: intro_cutscene.echo exists and opens", f ~= nil, examplePath)
	if f then
		local source = f:read("*a")
		f:close()

		local cameraMoves, lines = 0, {}
		local hostApi = {
			moveCamera = function(dx, dy, dz, seconds)
				cameraMoves = cameraMoves + 1
			end,
			say = function(text)
				lines[#lines + 1] = text
			end,
			wait = function(seconds) end,
		}
		local success, result = EchoScript.run(source, hostApi)
		ok("example: intro_cutscene.echo runs without error", success, result)
		eq("example: camera moved for all 3 beats", cameraMoves, 3)
		eq("example: said the intro line + 3 beats + branch line", #lines, 5)
		eq("example: branch picks the no-shards line", lines[5], "Find the Color Shards. The world remembers what you restore.")
	end
end

-- summary ------------------------------------------------------------------

print(string.format("\n%d passed, %d failed", passed, failed))
if #failures > 0 then
	print("")
	for _, f in ipairs(failures) do
		print(f)
	end
	os.exit(1)
end
