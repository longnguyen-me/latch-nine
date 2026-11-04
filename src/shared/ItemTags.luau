--!strict
-- Edit this catalog to customize tag text, colors and price effects.
-- Category tags belong to product definitions; quality tags belong to individual stock units.
local Tags = {
 BuyerCategories={"ore","metal","gem","volcanic","radioactive","exotic"},
 RarityWeights={common=55,uncommon=26,rare=10,legendary=2},
 LegacyMarketConditions={retailer=true,bulk=true},
 BulkSellerChance=0.10,
 BulkDiscountMin=5,BulkDiscountMax=15,
 Criminality={none={name="Legal",multiplier=1},low={name="Low contraband",multiplier=1.05},mid={name="Mid contraband",multiplier=1.12},high={name="High contraband",multiplier=1.25}},
 DefaultQuality = "standard",
 QualityOrder = {"low", "standard", "high"},
 Categories = {
  ore={name="Ore",badge="ORE"}, metal={name="Metal",badge="MET"},gem={name="Gemstone",badge="GEM"},volcanic={name="Volcanic",badge="VOL"},radioactive={name="Radioactive",badge="RAD"},exotic={name="Exotic",badge="EX"},
  household = {name="Household good", badge="HG"},
  gun = {name="Gun", badge="GUN"},
  medicine = {name="Medicine", badge="MED"},
  machinery = {name="Machinery", badge="MC"},
  electronics = {name="Electronics", badge="EL"},
 },
 Qualities = {
  low = {name="Low tier", badge="LQ", multiplier=0.75, color={181,131,106}},
  standard = {name="Mid tier", badge="SQ", multiplier=1.00, color={149,174,170}},
  high = {name="High tier", badge="HQ", multiplier=1.25, color={227,194,117}},
 },
}
return table.freeze(Tags)
