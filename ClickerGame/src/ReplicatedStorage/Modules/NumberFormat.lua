-- ModuleScript. Formats large numbers for display: abbreviates past 1000
-- with K/M/B/T/Qd/Qt/Sx/Sp/Oc/No/Dc/Udc/Ddc/Tdc, shows at most 2 decimal
-- places, and omits the decimal part entirely when it's exactly ".00".

local NumberFormat = {}

local SUFFIXES = {
	{ 1e42, "Tdc" },
	{ 1e39, "Ddc" },
	{ 1e36, "Udc" },
	{ 1e33, "Dc" },
	{ 1e30, "No" },
	{ 1e27, "Oc" },
	{ 1e24, "Sp" },
	{ 1e21, "Sx" },
	{ 1e18, "Qt" },
	{ 1e15, "Qd" },
	{ 1e12, "T" },
	{ 1e9, "B" },
	{ 1e6, "M" },
	{ 1e3, "K" },
}

local function trimTrailingZeros(text)
	if text:find("%.") then
		text = text:gsub("0+$", "")
		text = text:gsub("%.$", "")
	end
	return text
end

-- Always rounds to at most 2 decimals (so callers can't accidentally show
-- more, regardless of floating-point drift in the underlying value).
function NumberFormat.Format(value)
	local sign = ""
	if value < 0 then
		sign = "-"
		value = -value
	end

	for _, entry in ipairs(SUFFIXES) do
		local threshold, suffix = entry[1], entry[2]
		if value >= threshold then
			local scaled = value / threshold
			return sign .. trimTrailingZeros(string.format("%.2f", scaled)) .. suffix
		end
	end

	return sign .. trimTrailingZeros(string.format("%.2f", value))
end

return NumberFormat
