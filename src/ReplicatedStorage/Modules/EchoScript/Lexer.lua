-- ModuleScript: EchoScript.Lexer
-- Turns EchoScript source text into a flat list of tokens.
-- Pure string/table ops only, so this runs unmodified under Luau or stock Lua 5.1+.

local Lexer = {}

local KEYWORDS = {
	["let"] = true, ["fn"] = true, ["if"] = true, ["else"] = true,
	["while"] = true, ["for"] = true, ["return"] = true, ["break"] = true,
	["continue"] = true, ["true"] = true, ["false"] = true, ["nil"] = true,
	["and"] = true, ["or"] = true, ["not"] = true,
}

local SIMPLE_CHARS = {
	["("] = true, [")"] = true, ["{"] = true, ["}"] = true, ["["] = true, ["]"] = true,
	[","] = true, [";"] = true, ["="] = true, ["+"] = true, ["-"] = true, ["*"] = true,
	["/"] = true, ["%"] = true, ["<"] = true, [">"] = true, ["!"] = true, ["."] = true,
}

local function isDigit(c)
	return c ~= nil and c >= "0" and c <= "9"
end

local function isAlpha(c)
	return c ~= nil and ((c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_")
end

local function isAlphaNum(c)
	return isAlpha(c) or isDigit(c)
end

-- Returns a list of { type, value, line } tokens, ending with an EOF token.
-- Raises a Lua error (string) on malformed input.
function Lexer.tokenize(source)
	local tokens = {}
	local i = 1
	local line = 1
	local n = #source

	local function peek(offset)
		local idx = i + (offset or 0)
		if idx > n then
			return nil
		end
		return source:sub(idx, idx)
	end

	local function advance()
		local c = peek()
		i = i + 1
		if c == "\n" then
			line = line + 1
		end
		return c
	end

	local function addToken(tokenType, value, tokenLine)
		tokens[#tokens + 1] = { type = tokenType, value = value, line = tokenLine or line }
	end

	while i <= n do
		local c = peek()

		if c == " " or c == "\t" or c == "\r" or c == "\n" then
			advance()
		elseif c == "/" and peek(1) == "/" then
			while peek() and peek() ~= "\n" do
				advance()
			end
		elseif c == "-" and peek(1) == "-" then
			while peek() and peek() ~= "\n" do
				advance()
			end
		elseif isDigit(c) then
			local startLine = line
			local start = i
			while isDigit(peek()) do
				advance()
			end
			if peek() == "." and isDigit(peek(1)) then
				advance()
				while isDigit(peek()) do
					advance()
				end
			end
			addToken("NUMBER", tonumber(source:sub(start, i - 1)), startLine)
		elseif c == "\"" or c == "'" then
			local quote = c
			local startLine = line
			advance()
			local buf = {}
			while peek() and peek() ~= quote do
				local ch = advance()
				if ch == "\\" then
					local esc = advance()
					if esc == "n" then
						buf[#buf + 1] = "\n"
					elseif esc == "t" then
						buf[#buf + 1] = "\t"
					elseif esc == "\"" or esc == "'" or esc == "\\" then
						buf[#buf + 1] = esc
					else
						buf[#buf + 1] = esc or ""
					end
				else
					buf[#buf + 1] = ch
				end
			end
			if peek() ~= quote then
				error(string.format("EchoScript lex error: unterminated string starting at line %d", startLine), 0)
			end
			advance()
			addToken("STRING", table.concat(buf), startLine)
		elseif isAlpha(c) then
			local startLine = line
			local start = i
			while isAlphaNum(peek()) do
				advance()
			end
			local text = source:sub(start, i - 1)
			if KEYWORDS[text] then
				addToken(text:upper(), text, startLine)
			else
				addToken("IDENT", text, startLine)
			end
		else
			local startLine = line
			local two = c .. (peek(1) or "")
			if two == "==" or two == "!=" or two == "<=" or two == ">=" then
				advance()
				advance()
				addToken(two, two, startLine)
			elseif SIMPLE_CHARS[c] then
				advance()
				addToken(c, c, startLine)
			else
				error(string.format("EchoScript lex error: unexpected character '%s' at line %d", c, startLine), 0)
			end
		end
	end

	addToken("EOF", nil, line)
	return tokens
end

return Lexer
