--!strict
export type Definition = {name: string, category: string, base: number, wholesale: number, color: {number}, description: string, shape: {{number}}, glyph: string, tagCategory: string, rarity: string?}
local items: {[string]: Definition} = {
	filter = {tagCategory="household", shape = {{0,0},{1,0},{2,0},{0,1},{1,1},{2,1},{0,2},{1,2},{2,2}}, glyph = "WF", name = "Water filter", category = "LIFE SUPPORT", base = 48, wholesale = 24, color = {84, 198, 196}, description = "A district-grade filter. Check the seal and serial stamp."},
	servo = {tagCategory="machinery", shape = {{0,0},{0,1},{1,1},{2,1}}, glyph = "SV", name = "Cargo servo", category = "MACHINERY", base = 74, wholesale = 39, color = {227, 166, 82}, description = "A compact actuator recovered from the freight decks."},
	chip = {tagCategory="electronics", shape = {{0,0},{1,0}}, glyph = "RC", name = "Relay chip", category = "ELECTRONICS", base = 106, wholesale = 58, color = {181, 128, 213}, description = "A station-network module. Some carry restricted firmware."},
 genericOre={tagCategory="ore",rarity="common",shape={{0,0},{1,0}},glyph="OR",name="Mixed ore",category="ORE",base=19,wholesale=10,color={118,150,159},description="Unsorted planetary mineral."},
 cobalt={tagCategory="metal",rarity="common",shape={{0,0},{1,0}},glyph="CO",name="Cobalt",category="METAL",base=28,wholesale=15,color={84,132,181},description="Blue alloying metal."},
 titanium={tagCategory="metal",rarity="uncommon",shape={{0,0},{1,0},{0,1}},glyph="TI",name="Titanium",category="METAL",base=48,wholesale=26,color={174,184,195},description="Lightweight hull metal."},
 lapis={tagCategory="gem",rarity="common",shape={{0,0}},glyph="LA",name="Lapis",category="GEM",base=30,wholesale=17,color={57,92,189},description="Deep blue crystal."},
 volcanicRock={tagCategory="volcanic",rarity="common",shape={{0,0},{1,0},{0,1},{1,1}},glyph="VR",name="Volcanic rock",category="VOLCANIC",base=22,wholesale=12,color={114,87,86},description="Heat-scarred volcanic stone."},
 amethyst={tagCategory="gem",rarity="uncommon",shape={{0,0},{1,0}},glyph="AM",name="Amethyst",category="GEM",base=52,wholesale=29,color={157,93,189},description="Purple crystal."},
 topaz={tagCategory="gem",rarity="uncommon",shape={{0,0}},glyph="TO",name="Topaz",category="GEM",base=64,wholesale=36,color={228,174,78},description="Golden crystal."},
 diamond={tagCategory="gem",rarity="legendary",shape={{0,0}},glyph="DI",name="Diamond",category="GEM",base=420,wholesale=240,color={197,234,244},description="Exceptionally rare gemstone."},
 sapphire={tagCategory="gem",rarity="rare",shape={{0,0}},glyph="SA",name="Sapphire",category="GEM",base=142,wholesale=82,color={64,106,209},description="Blue gem."},
 obsidian={tagCategory="volcanic",rarity="uncommon",shape={{0,0},{1,0}},glyph="OB",name="Obsidian",category="VOLCANIC",base=60,wholesale=34,color={53,45,68},description="Black volcanic glass."},
 emerald={tagCategory="gem",rarity="rare",shape={{0,0}},glyph="EM",name="Emerald",category="GEM",base=168,wholesale=94,color={77,194,126},description="Green gem."},
 ruby={tagCategory="gem",rarity="rare",shape={{0,0}},glyph="RU",name="Ruby",category="GEM",base=180,wholesale=102,color={216,70,90},description="Red gem."},
 cuprite={tagCategory="metal",rarity="uncommon",shape={{0,0},{1,0}},glyph="CU",name="Cuprite",category="METAL",base=55,wholesale=30,color={174,81,65},description="Copper-rich oxide."},
 uranium={tagCategory="radioactive",rarity="rare",shape={{0,0},{1,0},{1,1}},glyph="U",name="Uranium",category="RADIOACTIVE",base=210,wholesale=120,color={133,214,81},description="Regulated radioactive ore."},
 mythril={tagCategory="exotic",rarity="legendary",shape={{0,0},{1,0},{0,1}},glyph="MY",name="Mythril",category="EXOTIC",base=480,wholesale=275,color={114,224,207},description="Legendary offworld metal."},
}
return table.freeze({Definitions = table.freeze(items), Order = table.freeze({"genericOre","cobalt","titanium","lapis","volcanicRock","amethyst","topaz","diamond","sapphire","obsidian","emerald","ruby","cuprite","uranium","mythril"})})
