-- ModuleScript: EchoScript
-- Public entry point: source text -> tokens/AST/execution.
--
-- Usage from any other script:
--   local EchoScript = require(ReplicatedStorage.Modules.EchoScript.EchoScript)
--   local ok, resultOrErr = EchoScript.run(source, {
--       say = function(line) ... end,
--       wait = function(seconds) task.wait(seconds) end,
--   })
--
-- See docs/EchoScript.md for the language reference.

local Lexer = require(script.Parent.Lexer)
local Parser = require(script.Parent.Parser)
local Interpreter = require(script.Parent.Interpreter)

local EchoScript = {}

-- Returns the raw token list for `source`. Raises a Lua error on bad input.
function EchoScript.tokenize(source)
	return Lexer.tokenize(source)
end

-- Returns the parsed AST (a Program node) for `source`. Raises a Lua error
-- on bad input (lex or parse failure).
function EchoScript.parse(source)
	return Parser.parse(Lexer.tokenize(source))
end

-- Lexes, parses, and executes `source` against the given host API table.
-- Never raises: always returns (ok: boolean, resultOrErrorMessage).
function EchoScript.run(source, hostApi)
	local okLex, tokensOrErr = pcall(Lexer.tokenize, source)
	if not okLex then
		return false, tokensOrErr
	end

	local okParse, astOrErr = pcall(Parser.parse, tokensOrErr)
	if not okParse then
		return false, astOrErr
	end

	return Interpreter.run(astOrErr, hostApi)
end

return EchoScript
