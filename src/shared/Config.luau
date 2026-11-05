--!strict
return table.freeze({
	StartingCash = 160,
	GridColumns = 15,
	GridBaseRows = 7,
	GridRowsPerUpgrade = 0,
	MaxInventory = 320,
	MaxLegacyRows = 36,
	Rent = 18,
	OperatingCost = 6,
	VisitsPerDay = 5,
	-- Add one visitor every two days, capped at twelve.
	DailyVisitors = function(day: number): number return math.min(12,3+math.floor((day-1)/2)) end,
	ArrivalSeconds = 2.5,
	WalkSeconds = 1.5,
	ServiceSeconds = 180,
	TradeColumns = 12,
	TradeRows = 5,
	SaveInterval = 60,
	LockSeconds = 240,
	-- Studio is deliberately memory-only unless you change this to true.
	PersistenceInStudio = false,
	DataStoreName = "LatchNine_Cyberpunk_v1",
	ReputationDiscountAt = 3,
	MaxUpgrade = 2, -- Older save validation only.
	RequestBurst = 10,
	RequestRate = 5,
})
