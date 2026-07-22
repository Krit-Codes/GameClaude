-- Formats large numbers as "1.23K" / "4.56M" / "7.89B" etc, the way
-- incremental/rebirth games display money once it stops fitting on screen.

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function Format(n)
	n = math.floor(n)

	if n < 1000 then
		return tostring(n)
	end

	local tier = math.floor(math.log(n, 1000))
	tier = math.min(tier, #SUFFIXES - 1)

	local scaled = n / (1000 ^ tier)
	local suffix = SUFFIXES[tier + 1]

	if scaled >= 100 then
		return string.format("%.0f%s", scaled, suffix)
	elseif scaled >= 10 then
		return string.format("%.1f%s", scaled, suffix)
	else
		return string.format("%.2f%s", scaled, suffix)
	end
end

return { Format = Format }
