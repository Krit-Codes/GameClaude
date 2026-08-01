-- ModuleScript: EchoScript.Parser
-- Recursive-descent parser: token list -> AST.
-- Every node is a plain table with a `type` field and a `line` for error reporting.

local Parser = {}
Parser.__index = Parser

local function new(tokens)
	return setmetatable({ tokens = tokens, pos = 1 }, Parser)
end

function Parser:peek(offset)
	local idx = self.pos + (offset or 0)
	if idx < 1 then
		idx = 1
	end
	local tok = self.tokens[idx]
	if tok then
		return tok
	end
	return self.tokens[#self.tokens]
end

function Parser:check(tokenType)
	return self:peek().type == tokenType
end

function Parser:advance()
	local tok = self.tokens[self.pos]
	if self.pos < #self.tokens then
		self.pos = self.pos + 1
	end
	return tok
end

function Parser:match(...)
	for _, t in ipairs({ ... }) do
		if self:check(t) then
			return self:advance()
		end
	end
	return nil
end

function Parser:expect(tokenType)
	if self:check(tokenType) then
		return self:advance()
	end
	local tok = self:peek()
	error(
		string.format(
			"EchoScript parse error: expected '%s' but got '%s' at line %d",
			tokenType,
			tostring(tok.value ~= nil and tok.value or tok.type),
			tok.line
		),
		0
	)
end

function Parser:skipSemi()
	while self:check(";") do
		self:advance()
	end
end

-- statements --------------------------------------------------------------

function Parser:parseProgram()
	local body = {}
	while not self:check("EOF") do
		body[#body + 1] = self:parseStatement()
	end
	return { type = "Program", body = body }
end

function Parser:parseStatement()
	if self:check("LET") then
		return self:parseLet()
	elseif self:check("FN") then
		return self:parseFn()
	elseif self:check("IF") then
		return self:parseIf()
	elseif self:check("WHILE") then
		return self:parseWhile()
	elseif self:check("FOR") then
		return self:parseFor()
	elseif self:check("RETURN") then
		return self:parseReturn()
	elseif self:check("BREAK") then
		local tok = self:advance()
		self:skipSemi()
		return { type = "BreakStmt", line = tok.line }
	elseif self:check("CONTINUE") then
		local tok = self:advance()
		self:skipSemi()
		return { type = "ContinueStmt", line = tok.line }
	elseif self:check("{") then
		return self:parseBlock()
	end
	return self:parseExprStmt()
end

function Parser:parseLet()
	local line = self:peek().line
	self:advance() -- 'let'
	local name = self:expect("IDENT").value
	local init = nil
	if self:match("=") then
		init = self:parseExpr()
	end
	self:skipSemi()
	return { type = "LetStmt", name = name, init = init, line = line }
end

function Parser:parseParamList()
	self:expect("(")
	local params = {}
	if not self:check(")") then
		params[#params + 1] = self:expect("IDENT").value
		while self:match(",") do
			params[#params + 1] = self:expect("IDENT").value
		end
	end
	self:expect(")")
	return params
end

function Parser:parseFn()
	local line = self:peek().line
	self:advance() -- 'fn'
	local name = self:expect("IDENT").value
	local params = self:parseParamList()
	local body = self:parseBlock()
	return { type = "FnStmt", name = name, params = params, body = body, line = line }
end

function Parser:parseIf()
	local line = self:peek().line
	self:advance() -- 'if'
	local cond = self:parseExpr()
	local thenBranch = self:parseBlock()
	local elseBranch = nil
	if self:match("ELSE") then
		if self:check("IF") then
			elseBranch = self:parseIf()
		else
			elseBranch = self:parseBlock()
		end
	end
	return { type = "IfStmt", cond = cond, thenBranch = thenBranch, elseBranch = elseBranch, line = line }
end

function Parser:parseWhile()
	local line = self:peek().line
	self:advance() -- 'while'
	local cond = self:parseExpr()
	local body = self:parseBlock()
	return { type = "WhileStmt", cond = cond, body = body, line = line }
end

function Parser:parseFor()
	local line = self:peek().line
	self:advance() -- 'for'
	local var = self:expect("IDENT").value
	self:expect("=")
	local startExpr = self:parseExpr()
	self:expect(",")
	local stopExpr = self:parseExpr()
	local stepExpr = nil
	if self:match(",") then
		stepExpr = self:parseExpr()
	end
	local body = self:parseBlock()
	return { type = "ForStmt", var = var, start = startExpr, stop = stopExpr, step = stepExpr, body = body, line = line }
end

function Parser:parseReturn()
	local line = self:peek().line
	self:advance() -- 'return'
	local value = nil
	if not self:check(";") and not self:check("}") and not self:check("EOF") then
		value = self:parseExpr()
	end
	self:skipSemi()
	return { type = "ReturnStmt", value = value, line = line }
end

function Parser:parseBlock()
	self:expect("{")
	local body = {}
	while not self:check("}") do
		body[#body + 1] = self:parseStatement()
	end
	self:expect("}")
	return { type = "Block", body = body }
end

function Parser:parseExprStmt()
	local line = self:peek().line
	local expr = self:parseExpr()
	self:skipSemi()
	return { type = "ExprStmt", expr = expr, line = line }
end

-- expressions (precedence climbing) ---------------------------------------

function Parser:parseExpr()
	return self:parseAssignment()
end

function Parser:parseAssignment()
	local expr = self:parseOr()
	if self:check("=") then
		local line = self:peek().line
		self:advance()
		local value = self:parseAssignment()
		if expr.type == "Identifier" then
			return { type = "Assign", name = expr.name, value = value, line = line }
		elseif expr.type == "IndexExpr" then
			return { type = "IndexAssign", object = expr.object, index = expr.index, value = value, line = line }
		end
		error(string.format("EchoScript parse error: invalid assignment target at line %d", line), 0)
	end
	return expr
end

function Parser:parseOr()
	local expr = self:parseAnd()
	while self:check("OR") do
		local op = self:advance()
		expr = { type = "Logical", op = "or", left = expr, right = self:parseAnd(), line = op.line }
	end
	return expr
end

function Parser:parseAnd()
	local expr = self:parseEquality()
	while self:check("AND") do
		local op = self:advance()
		expr = { type = "Logical", op = "and", left = expr, right = self:parseEquality(), line = op.line }
	end
	return expr
end

function Parser:parseEquality()
	local expr = self:parseComparison()
	while self:check("==") or self:check("!=") do
		local op = self:advance()
		expr = { type = "Binary", op = op.type, left = expr, right = self:parseComparison(), line = op.line }
	end
	return expr
end

function Parser:parseComparison()
	local expr = self:parseTerm()
	while self:check("<") or self:check("<=") or self:check(">") or self:check(">=") do
		local op = self:advance()
		expr = { type = "Binary", op = op.type, left = expr, right = self:parseTerm(), line = op.line }
	end
	return expr
end

function Parser:parseTerm()
	local expr = self:parseFactor()
	while self:check("+") or self:check("-") do
		local op = self:advance()
		expr = { type = "Binary", op = op.type, left = expr, right = self:parseFactor(), line = op.line }
	end
	return expr
end

function Parser:parseFactor()
	local expr = self:parseUnary()
	while self:check("*") or self:check("/") or self:check("%") do
		local op = self:advance()
		expr = { type = "Binary", op = op.type, left = expr, right = self:parseUnary(), line = op.line }
	end
	return expr
end

function Parser:parseUnary()
	if self:check("-") or self:check("NOT") or self:check("!") then
		local op = self:advance()
		local opName = (op.type == "-") and "-" or "not"
		return { type = "Unary", op = opName, right = self:parseUnary(), line = op.line }
	end
	return self:parseCall()
end

function Parser:parseCall()
	local expr = self:parsePrimary()
	while true do
		if self:check("(") then
			self:advance()
			local args = {}
			if not self:check(")") then
				args[#args + 1] = self:parseExpr()
				while self:match(",") do
					args[#args + 1] = self:parseExpr()
				end
			end
			local closeTok = self:expect(")")
			expr = { type = "Call", callee = expr, args = args, line = closeTok.line }
		elseif self:check("[") then
			local line = self:peek().line
			self:advance()
			local index = self:parseExpr()
			self:expect("]")
			expr = { type = "IndexExpr", object = expr, index = index, line = line }
		elseif self:check(".") then
			local line = self:peek().line
			self:advance()
			local name = self:expect("IDENT").value
			expr = { type = "IndexExpr", object = expr, index = { type = "Literal", value = name }, line = line }
		else
			break
		end
	end
	return expr
end

function Parser:parsePrimary()
	local tok = self:peek()

	if self:check("NUMBER") or self:check("STRING") then
		self:advance()
		return { type = "Literal", value = tok.value, line = tok.line }
	elseif self:check("TRUE") then
		self:advance()
		return { type = "Literal", value = true, line = tok.line }
	elseif self:check("FALSE") then
		self:advance()
		return { type = "Literal", value = false, line = tok.line }
	elseif self:check("NIL") then
		self:advance()
		return { type = "Literal", value = nil, line = tok.line }
	elseif self:check("IDENT") then
		self:advance()
		return { type = "Identifier", name = tok.value, line = tok.line }
	elseif self:check("(") then
		self:advance()
		local expr = self:parseExpr()
		self:expect(")")
		return expr
	elseif self:check("[") then
		self:advance()
		local elements = {}
		if not self:check("]") then
			elements[#elements + 1] = self:parseExpr()
			while self:match(",") do
				elements[#elements + 1] = self:parseExpr()
			end
		end
		self:expect("]")
		return { type = "ListLiteral", elements = elements, line = tok.line }
	elseif self:check("FN") then
		self:advance()
		local params = self:parseParamList()
		local body = self:parseBlock()
		return { type = "FunctionExpr", params = params, body = body, line = tok.line }
	end

	error(string.format("EchoScript parse error: unexpected token '%s' at line %d", tok.type, tok.line), 0)
end

function Parser.parse(tokens)
	local p = new(tokens)
	return p:parseProgram()
end

return Parser
