-- Ordered list of purchasable upgrades. Read by both server (authoritative
-- economy math) and client (building/labeling the shop UI), so nothing about
-- the shop's contents has to be duplicated or kept in sync by hand.
--
-- Type = "Click"  -> Effect is added to the player's flat per-click value.
-- Type = "Income" -> Effect is added (per level) to money earned per second.

return {
	{
		Id = "click",
		Name = "Stronger Clicks",
		Description = "+$%s per click",
		BaseCost = 25,
		CostGrowth = 1.07,
		Effect = 1,
		Type = "Click",
	},
	{
		Id = "jar",
		Name = "Coin Jar",
		Description = "+$%s per second",
		BaseCost = 15,
		CostGrowth = 1.07,
		Effect = 0.5,
		Type = "Income",
	},
	{
		Id = "lemonade",
		Name = "Lemonade Stand",
		Description = "+$%s per second",
		BaseCost = 100,
		CostGrowth = 1.07,
		Effect = 3,
		Type = "Income",
	},
	{
		Id = "paperroute",
		Name = "Paper Route",
		Description = "+$%s per second",
		BaseCost = 500,
		CostGrowth = 1.07,
		Effect = 12,
		Type = "Income",
	},
	{
		Id = "foodtruck",
		Name = "Food Truck",
		Description = "+$%s per second",
		BaseCost = 3000,
		CostGrowth = 1.07,
		Effect = 60,
		Type = "Income",
	},
	{
		Id = "vending",
		Name = "Vending Machines",
		Description = "+$%s per second",
		BaseCost = 15000,
		CostGrowth = 1.07,
		Effect = 300,
		Type = "Income",
	},
	{
		Id = "factory",
		Name = "Small Factory",
		Description = "+$%s per second",
		BaseCost = 75000,
		CostGrowth = 1.07,
		Effect = 1400,
		Type = "Income",
	},
	{
		Id = "stocks",
		Name = "Stock Portfolio",
		Description = "+$%s per second",
		BaseCost = 400000,
		CostGrowth = 1.07,
		Effect = 7000,
		Type = "Income",
	},
	{
		Id = "printer",
		Name = "Money Printer",
		Description = "+$%s per second",
		BaseCost = 2000000,
		CostGrowth = 1.07,
		Effect = 35000,
		Type = "Income",
	},
}
