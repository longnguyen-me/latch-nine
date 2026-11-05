--!strict
local HttpService = game:GetService("HttpService")
local Tags=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").ItemTags)
local Customers = {}
local archetypes = {
	{name = "Mara Venn", personality = "Patient", faction = "Dock Union", tolerance = 1.1, patience = 4, color = {86, 181, 177}},
	{name = "Pell Rusk", personality = "Frugal", faction = "Lower Decks", tolerance = 0.96, patience = 3, color = {207, 156, 87}},
	{name = "Inspector Sable", personality = "Exacting", faction = "Transit Watch", tolerance = 1.04, patience = 2, color = {126, 145, 184}},
	{name = "Ivo Coil", personality = "Impulsive", faction = "Free Relay", tolerance = 1.22, patience = 2, color = {176, 113, 174}},
}
function Customers.create(p: any, rules: any, rng: Random): any
	local archetype = archetypes[rng:NextInteger(1, #archetypes)]
	local buyer=p.visits%2==1
	local requested=if buyer then Tags.BuyerCategories[rng:NextInteger(1,#Tags.BuyerCategories)] else nil
	local item=nil
	if requested then
	 for _,unit in ipairs(p.inventory) do if rules.category(unit)==requested then item=unit;break end end
	end
	local value=if item then rules.value(item) else 0
	local line=if requested then "I'm looking for "..Tags.Categories[requested].name:lower()..". Do you have anything?" else "I've got some unmarked goods. Looking to sell."

	return {id = HttpService:GenerateGUID(false), name = archetype.name, personality = archetype.personality,
		faction = archetype.faction, tolerance = archetype.tolerance, color = archetype.color,
		mode = if buyer then "Buyer" else "Seller", goods = {}, basket = {}, basketRevision = 0, quote = nil,
		dialogue=line,requestTag=requested, kind = if item then item.kind else nil, itemId = if item then item.id else nil,
		budget = if buyer then rules.categoryBudget(requested) else 0,
		offer = math.max(1, math.floor(value * 0.86)), patience = archetype.patience, state = "WalkToCounter"}
end
return Customers
