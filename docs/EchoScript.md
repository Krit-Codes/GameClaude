# EchoScript

EchoScript is a small scripting language built for this project, so that
game content — cutscene beats, dialogue, simple triggers — can be authored
as data-like text instead of hand-written Lua. It's implemented from
scratch as a lexer, a recursive-descent parser, and a tree-walking
interpreter, entirely in Luau-compatible Lua with no external dependencies,
so it runs directly inside Roblox.

It is not a general-purpose language and doesn't try to be. It's deliberately
small: variables, arithmetic, control flow, functions with closures, lists,
and calls into a **host API** you define — that's it. The interpreter never
touches the filesystem, network, or any Roblox service directly; every
side effect (playing a sound, moving a camera, saying a line) happens
through a function *you* hand it, so what an EchoScript can do is always
exactly what the embedding script allows.

## Where the code lives

```
src/ReplicatedStorage/Modules/EchoScript/
  Lexer.lua        -- source text -> tokens
  Parser.lua        -- tokens -> AST
  Interpreter.lua    -- AST -> execution (environments, control flow, calls)
  EchoScript.lua     -- public entry point, wires the three together
```

Each file is a plain Roblox `ModuleScript`, following the same manual-paste
convention as the rest of this repo (see the main README's Studio setup
section). `EchoScript.lua` is the one you `require`; the other three are
implementation details it pulls in via `require(script.Parent.X)`.

## Embedding it

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EchoScript = require(ReplicatedStorage.Modules.EchoScript.EchoScript)

local hostApi = {
	say = function(text)
		print("[Cutscene]", text)
	end,
	wait = function(seconds)
		task.wait(seconds)
	end,
}

local ok, resultOrErr = EchoScript.run(source, hostApi)
if not ok then
	warn("EchoScript failed: " .. tostring(resultOrErr))
end
```

`EchoScript.run` never raises a Lua error itself — lex, parse, and runtime
failures all come back as `false, "EchoScript ... error: ..."` so callers
can decide how to handle bad content (log it, skip the cutscene, etc.)
instead of crashing a live server.

Lower-level entry points are also available if you just want the pieces:
- `EchoScript.tokenize(source)` — returns the raw token list, raises on
  malformed input.
- `EchoScript.parse(source)` — returns the AST (a `Program` node), raises
  on malformed input.

## Language reference

### Comments

```
// a line comment
-- also a line comment (both styles work)
```

### Values

Numbers, strings, booleans, `nil`, lists, and functions:

```
let n = 42
let s = "hello, \"warden\"\n"
let b = true
let empty = nil
let xs = [1, 2, 3]
```

Lists are **0-indexed**:

```
let xs = [10, 20, 30]
xs[0]        // 10
xs[1] = 99   // xs is now [10, 99, 30]
```

### Variables

```
let x = 10
x = x + 1
```

`let` declares a new variable in the current block scope; plain assignment
(`x = ...`) requires the variable to already exist somewhere in an
enclosing scope (there's no implicit-global assignment).

### Operators

| Category   | Operators |
|------------|-----------|
| Arithmetic | `+ - * / %` |
| Compare    | `== != < <= > >=` |
| Logical    | `and or not` (short-circuiting) |
| Unary      | `-x`, `not x` / `!x` |

`+` also concatenates when either side is a string: `"score: " + 5` →
`"score: 5"`.

### Control flow

```
if health <= 0 {
	say("You fall.")
} else if health < 3 {
	say("Barely holding on...")
} else {
	say("Steady.")
}

let i = 0
while i < 3 {
	say("tick " + i)
	i = i + 1
}

for i = 0, 10, 2 {     // start, stop, step (step defaults to 1)
	if i == 6 { continue }
	if i > 8 { break }
	say(i)
}
```

### Functions

```
fn add(a, b) {
	return a + b
}

let double = fn(x) { return x * 2 }   // anonymous functions work the same way

fn makeCounter() {
	let count = 0
	fn increment() {
		count = count + 1
		return count
	}
	return increment          // closures capture their defining scope
}
```

### Calling into the host

Anything passed in the `hostApi` table to `EchoScript.run` is callable
directly by name from the script, alongside a few always-available
builtins:

| Builtin | Description |
|---|---|
| `print(...)` | debug output, joins args with tabs |
| `len(x)` | length of a string or list |
| `str(x)` | converts any value to its string form |
| `num(x)` | converts a string/number to a number, errors if it can't |
| `push(list, value)` | appends to a list, returns the list |

## Example: a cutscene script

See [`examples/intro_cutscene.echo`](../examples/intro_cutscene.echo) for a
full example that reimplements the waypoint list from
`07_NarrativeCutscenes.server.lua` as an EchoScript, driven entirely
through a `moveCamera`/`say`/`wait` host API.

## Design notes / why it's built this way

- **Tree-walking, not bytecode.** Content scripts here are short (a
  cutscene, a dialogue tree) and run rarely, so interpretation overhead
  is irrelevant; a tree-walker is far less code and much easier to keep
  correct than a bytecode VM.
- **Control flow via `error()`/`pcall`.** `return`, `break`, and
  `continue` are implemented by throwing sentinel tables and catching
  them at the nearest loop/function boundary. This is a standard
  tree-walker trick and keeps the evaluator's control-flow logic out of
  every recursive call's return value.
- **No implicit globals, no sandboxing gaps.** Every capability an
  EchoScript has comes from the `hostApi` table the embedder supplies.
  There is no way for a script to reach Roblox services, `require`
  arbitrary modules, or otherwise escape the interpreter — the worst a
  malformed or malicious script can do is loop forever or throw a runtime
  error, which is why callers may still want their own timeout/step-limit
  guard around long-running scripts.

## Testing

The interpreter has a standalone Lua test suite at
`tests/echoscript/run_tests.lua` (52 assertions covering the lexer, parser,
arithmetic, scoping, control flow, closures, lists, host API calls, and
error surfacing). It runs under any stock Lua 5.1+ interpreter — Roblox
Studio isn't required:

```
lua5.4 tests/echoscript/run_tests.lua
```
