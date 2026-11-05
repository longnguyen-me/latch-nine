--!strict
-- Pure, synchronous domain rules. Inject definitions for CLI tests and Studio.
return function(config: any, definitions: any, grid: any, tags: any)
	local Rules = {DefaultQuality=tags.DefaultQuality}
	local function integer(n: any, low: number, high: number): boolean
		return type(n) == "number" and n == n and n % 1 == 0 and n >= low and n <= high
	end
	Rules.integer = integer
	function Rules.newProfile(): any
		return {version = 5, legacyRows = 0, gridRevision = 0, cash = config.StartingCash, day = 1, walletTier = 0, inventory = {{id="starter-wallet",kind="wallet0",paid=0,condition=100,authentic=true,restricted=false,inspected=false,qualityTag=tags.DefaultQuality,gridX=0,gridY=0,rotation=0}}, reputation = 0,
			upgrade = 0, revenue = 0, costs = 0, tradeProfit = 0, visits = 0, aidDay = 0, receipts = {}}
	end
	local function validateFields(p: any, version: number): boolean
		if type(p) ~= "table" or p.version ~= version then return false end
		for _, key in ipairs({"cash", "day", "upgrade", "revenue", "costs", "visits", "aidDay"}) do
			if not integer(p[key], 0, 1000000000) then return false end
		end
		if p.day < 1 or p.upgrade > config.MaxUpgrade
			or not integer(p.reputation, -20, 20) or not integer(p.tradeProfit, -1000000000, 1000000000)
			or type(p.inventory) ~= "table" or #p.inventory > config.MaxInventory
			or type(p.receipts) ~= "table" or #p.receipts > 12 then return false end
		local seen: {[string]: boolean} = {}
		for _, receipt in ipairs(p.receipts) do
			if type(receipt) ~= "string" or #receipt > 300 then return false end
		end
		for key, item in pairs(p.inventory) do
			if not integer(key, 1, #p.inventory) or type(item) ~= "table" or type(item.id) ~= "string"
				or #item.id > 80 or seen[item.id] or not definitions[(item :: any).kind]
				or not integer((item :: any).condition, 30, 100) or not integer((item :: any).paid, 0, 1000000)
				or type((item :: any).authentic) ~= "boolean" or type((item :: any).restricted) ~= "boolean"
				or type((item :: any).inspected) ~= "boolean" then return false end
			seen[item.id] = true
		end
		return true
	end
	local function validGrid(p: any, version: number): boolean
		return validateFields(p, version) and integer(p.legacyRows, 0, config.MaxLegacyRows)
			and integer(p.gridRevision, 0, 1000000000) and (if version<5 then grid.validate(p,8,6+p.upgrade*2+p.legacyRows) else grid.validate(p))
	end
	function Rules.validate(p: any): boolean
		if not validGrid(p, 5) then return false end
		for _, item in ipairs(p.inventory) do
			if type((item :: any).qualityTag) ~= "string" or not tags.Qualities[(item :: any).qualityTag] then return false end
			if item.marketCondition~=nil and not tags.LegacyMarketConditions[item.marketCondition] then return false end
			if item.marketCondition=="bulk" and not integer(item.marketPercent,5,15) then return false end
			if item.criminality~=nil and not tags.Criminality[item.criminality] then return false end
			if item.rarity~=nil and not tags.RarityWeights[item.rarity] then return false end
		end
		return true
	end
	function Rules.setItemTag(p: any, id: any, quality: any): (boolean, string)
		if type(id) ~= "string" or #id > 80 or type(quality) ~= "string" or not tags.Qualities[quality] then return false, "Invalid item tag." end
		local item = Rules.find(p, id)
		if not item then return false, "Item not owned." end
		if item.qualityTag ~= quality then item.qualityTag = quality; p.gridRevision += 1 end
		return true, tags.Qualities[quality].name
	end
	local function clone(value: any): any
		if type(value) ~= "table" then return value end
		local out: any = {}; for key, child in pairs(value) do out[key] = clone(child) end; return out
	end
	function Rules.migrate(saved: any): any
		if type(saved) ~= "table" then return nil end
		if saved.version == 5 then return if Rules.validate(saved) then saved else nil end
		if saved.version ~= 1 and saved.version ~= 2 and saved.version ~= 3 and saved.version ~= 4 then return nil end
		if saved.version == 1 then
			if not validateFields(saved, 1) or #saved.inventory > 24 then return nil end
		elseif not validGrid(saved, saved.version) then return nil end
		if saved.version == 4 then
			for _, item in ipairs(saved.inventory) do if not tags.Qualities[(item :: any).qualityTag] then return nil end end
		end
		local p = clone(saved); local previous = p.inventory
		p.version = 5; p.inventory = {}; p.labels = nil; p.labelRevision = nil; p.legacyRows = 0; p.gridRevision = (p.gridRevision or 0) + 1
		for _, item in ipairs(previous) do
			local x, y, rotation = grid.firstFit(p, item.kind)
			while x == nil and p.legacyRows < config.MaxLegacyRows do p.legacyRows += 1; x, y, rotation = grid.firstFit(p, item.kind) end
			if x == nil then return nil end
			item.gridX = x; item.gridY = y; item.rotation = rotation; item.qualityTag = item.qualityTag or tags.DefaultQuality
			table.insert(p.inventory, item)
		end
		return if Rules.validate(p) then p else nil
	end
	function Rules.capacity(p: any): number local cols, rows = grid.size(p); return cols * rows end
	function Rules.move(p: any, id: any, x: any, y: any, rotation: any, revision: any): (boolean, string)
		if type(id) ~= "string" or #id > 80 then return false, "Invalid stock ID." end
		local item = Rules.find(p, id)
		if not item then return false, "That item is no longer in your storage." end
		if not integer(revision, 0, 1000000000) or revision ~= p.gridRevision then return false, "Storage changed." end
		local ok, reason = grid.check(p, item.kind, x, y, rotation, id)
		if not ok then return false, reason end
		if item.gridX ~= x or item.gridY ~= y or item.rotation ~= rotation then
			item.gridX = x; item.gridY = y; item.rotation = rotation; item.qualityTag = item.qualityTag or tags.DefaultQuality; p.gridRevision += 1
		end
		return true, "Stored. " .. definitions[item.kind].name .. " at column " .. (x+1) .. ", row " .. (y+1) .. "."
	end
	function Rules.bill(p: any): number return config.Rent + p.upgrade * 5 + config.OperatingCost end
	function Rules.value(item: any): number
		local value = definitions[item.kind].base * item.condition / 100
		if not item.authentic then value *= 0.58 end
		if item.restricted then value *= 1.15 end
		value *= tags.Qualities[item.qualityTag or tags.DefaultQuality].multiplier
		value *= tags.Criminality[item.criminality or "none"].multiplier
		return math.max(1, math.floor(value + 0.5))
	end
	function Rules.find(p: any, id: string): (any, number?)
		for index, item in ipairs(p.inventory) do if item.id == id then return item, index end end
		return nil, nil
	end
	function Rules.log(p: any, message: string)
		table.insert(p.receipts, 1, "D" .. p.day .. " / " .. message)
		if #p.receipts > 12 then table.remove(p.receipts) end
	end
	function Rules.purchase(p: any, item: any, price: number): (boolean, string)
		local x, y, rotation = grid.firstFit(p, item.kind)
		if x == nil then return false, "Insufficient storage space." end
		if p.cash < price then return false, "Not enough Eddies." end
		if Rules.find(p, item.id) then return false, "That item is already in storage." end
		p.cash -= price; p.costs += price; item.paid = price
		item.gridX = x; item.gridY = y; item.rotation = rotation; item.qualityTag = item.qualityTag or tags.DefaultQuality; p.gridRevision += 1
		table.insert(p.inventory, item)
		Rules.log(p, "Bought " .. definitions[item.kind].name .. " for " .. price)
		return true, "Purchased."
	end
	function Rules.inspect(p: any, id: string): (boolean, string)
		local item = Rules.find(p, id)
		if not item then return false, "Item no longer in storage." end
		item.inspected = true
		return true, "Inspected."
	end
	function Rules.category(item: any): string return definitions[item.kind].tagCategory end
	function Rules.categoryBudget(category: string): number
		local value=120
		for _,def in pairs(definitions) do if def.tagCategory==category then value=math.max(value,def.base*2) end end
		return value
	end
	function Rules.matches(customer: any, item: any): boolean
		local def=definitions[item.kind]
		if not def then return false end
		return if customer.requestTag then def.tagCategory==customer.requestTag else item.kind==customer.kind
	end
	function Rules.negotiate(p: any, customer: any, item: any, ask: any): (boolean, string, boolean)
		if not integer(ask, 1, 1000000) then return false, "Invalid sale price.", false end
		if customer.state ~= "Interact" or not Rules.matches(customer,item) then return false, "This customer wants a different item.", false end
		local value = Rules.value(item)
		local cap = math.min(customer.budget, math.floor(value * customer.tolerance + math.max(0, p.reputation) * 1.5))
		if ask <= cap then return true, "Deal accepted.", false end
		customer.patience -= 1
		customer.offer = math.min(cap, math.max(customer.offer, math.floor((customer.offer + cap) / 2)))
		if customer.patience <= 0 then return false, "Too expensive. I'm leaving.", true end
		return false, "Too high. My counteroffer is " .. customer.offer .. " Eddies.", false
	end
	function Rules.sell(p: any, customer: any, id: string, price: number): (boolean, string)
		local item, index = Rules.find(p, id)
		if not item or not index or customer.state ~= "Interact" or not Rules.matches(customer,item) then
			return false, "This sale is no longer available."
		end
		if not integer(price, 1, customer.budget) then return false, "Invalid sale price." end
		-- Fine and trust consequence are deterministic and disclosed by inspection.
		local fine = 0
		if item.restricted and customer.faction == "Transit Watch" then fine = math.min(p.cash + price, 25) end
		table.remove(p.inventory, index); p.gridRevision += 1
		p.cash += price - fine; p.revenue += price; p.costs += fine
		p.tradeProfit += price - item.paid - fine
		local honest = item.authentic and not item.restricted and item.condition >= 60
		p.reputation = math.clamp(p.reputation + (if honest then 1 else -1) - (if fine > 0 then 2 else 0), -20, 20)
		Rules.log(p, "Sold " .. definitions[item.kind].name .. " for " .. price .. (if fine > 0 then "; Watch fine " .. fine else ""))
		return true, "Sold for " .. price .. " Eddies." .. (if fine > 0 then " Restricted tech: 25-credit Watch fine." else "")
	end
	function Rules.endDay(p: any): (boolean, string)
		local bill = Rules.bill(p)
		if p.cash < bill then return false, "Need " .. bill .. " Eddies required for expenses." end
		p.cash -= bill; p.costs += bill; p.tradeProfit -= bill
		Rules.log(p, "Rent + operations paid: " .. bill)
		p.day += 1; p.visits = 0
		return true, "Expenses paid. A new trading day begins."
	end
	function Rules.aid(p: any): (boolean, string)
		if p.cash > Rules.bill(p) + 24 or p.aidDay == p.day then return false, "Emergency credit is available once per day when funds are low." end
		p.cash += 40; p.aidDay = p.day; p.reputation = math.max(-20, p.reputation - 2)
		Rules.log(p, "Emergency credit +40; trust -2")
		return true, "The dock union advances 40 Eddies. Trust falls by 2."
	end
	return Rules
end
