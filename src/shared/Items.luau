--!strict
export type Definition = {name: string, category: string, base: number, wholesale: number, color: {number}, description: string, shape: {{number}}, shapeTag: string, glyph: string, tagCategory: string, rarity: string?}
-- shapeTag is hidden catalog metadata. Grid geometry uses the matching shape cells.
local items = {
 blank1={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="1x1",shape={{0,0}},glyph="?",rarity="common",base=10,wholesale=5,color={105,180,190},description="Unidentified stock."},
 blankL={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="L",shape={{0,0},{0,1},{1,1}},glyph="?",rarity="common",base=30,wholesale=15,color={119,175,183},description="Unidentified stock."},
 blank2={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="2x2",shape={{0,0},{1,0},{0,1},{1,1}},glyph="?",rarity="common",base=40,wholesale=20,color={133,170,176},description="Unidentified stock."},
 blank3={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="1x3",shape={{0,0},{0,1},{0,2}},glyph="?",rarity="common",base=30,wholesale=15,color={147,165,169},description="Unidentified stock."},
 blank4={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="1x4",shape={{0,0},{0,1},{0,2},{0,3}},glyph="?",rarity="common",base=40,wholesale=20,color={161,160,162},description="Unidentified stock."},
 blank9={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="3x3",shape={{0,0},{1,0},{2,0},{0,1},{1,1},{2,1},{0,2},{1,2},{2,2}},glyph="?",rarity="common",base=90,wholesale=45,color={175,155,155},description="Unidentified stock."},
}
return table.freeze({Definitions=table.freeze(items),Order=table.freeze({"blank1","blankL","blank2","blank3","blank4","blank9"})})
