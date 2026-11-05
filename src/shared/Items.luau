--!strict
export type Definition = {name: string, category: string, base: number, wholesale: number, color: {number}, description: string, shape: {{number}}, shapeTag: string, glyph: string, tagCategory: string, rarity: string?}
-- shapeTag is hidden catalog metadata. Grid geometry uses the matching shape cells.
local items = {
 wallet0={name="Starter wallet",category="WALLET",tagCategory="wallet",shapeTag="1x1",shape={{0,0}},glyph="W",rarity="common",walletTier=0,base=1,wholesale=0,color={94,143,150},description="2 by 3 pocket wallet."},
 wallet1={name="Street wallet",category="WALLET",tagCategory="wallet",shapeTag="1x1",shape={{0,0}},glyph="W",rarity="uncommon",walletTier=1,base=300,wholesale=150,color={120,142,175},description="Upgradeable wallet."},
 wallet2={name="Courier wallet",category="WALLET",tagCategory="wallet",shapeTag="1x1",shape={{0,0}},glyph="W",rarity="rare",walletTier=2,base=700,wholesale=350,color={150,142,175},description="Upgradeable wallet."},
 wallet3={name="Vault wallet",category="WALLET",tagCategory="wallet",shapeTag="1x1",shape={{0,0}},glyph="W",rarity="legendary",walletTier=3,base=1400,wholesale=700,color={185,142,175},description="Upgradeable wallet."},
 cash1={name="1 Eddie note",category="CURRENCY",tagCategory="currency",shapeTag="1x1",shape={{0,0}},glyph="1",rarity="common",denomination=1,base=1,wholesale=1,color={170,183,128},description="One loose note. Does not stack in stock."},
 cash5={name="5 Eddie note",category="CURRENCY",tagCategory="currency",shapeTag="1x1",shape={{0,0}},glyph="5",rarity="common",denomination=5,base=5,wholesale=5,color={170,183,128},description="One loose note. Does not stack in stock."},
 cash10={name="10 Eddie note",category="CURRENCY",tagCategory="currency",shapeTag="1x1",shape={{0,0}},glyph="10",rarity="common",denomination=10,base=10,wholesale=10,color={170,183,128},description="One loose note. Does not stack in stock."},
 cash25={name="25 Eddie note",category="CURRENCY",tagCategory="currency",shapeTag="1x1",shape={{0,0}},glyph="25",rarity="common",denomination=25,base=25,wholesale=25,color={170,183,128},description="One loose note. Does not stack in stock."},
 cash50={name="50 Eddie note",category="CURRENCY",tagCategory="currency",shapeTag="1x1",shape={{0,0}},glyph="50",rarity="common",denomination=50,base=50,wholesale=50,color={170,183,128},description="One loose note. Does not stack in stock."},
 cash100={name="100 Eddie note",category="CURRENCY",tagCategory="currency",shapeTag="1x1",shape={{0,0}},glyph="100",rarity="common",denomination=100,base=100,wholesale=100,color={170,183,128},description="One loose note. Does not stack in stock."},
 cash250={name="250 Eddie note",category="CURRENCY",tagCategory="currency",shapeTag="1x1",shape={{0,0}},glyph="250",rarity="common",denomination=250,base=250,wholesale=250,color={170,183,128},description="One loose note. Does not stack in stock."},
 cash500={name="500 Eddie note",category="CURRENCY",tagCategory="currency",shapeTag="1x1",shape={{0,0}},glyph="500",rarity="common",denomination=500,base=500,wholesale=500,color={170,183,128},description="One loose note. Does not stack in stock."},
 cash1000={name="1000 Eddie note",category="CURRENCY",tagCategory="currency",shapeTag="1x1",shape={{0,0}},glyph="1000",rarity="common",denomination=1000,base=1000,wholesale=1000,color={170,183,128},description="One loose note. Does not stack in stock."},

 blank1={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="1x1",shape={{0,0}},glyph="?",rarity="common",base=10,wholesale=5,color={105,180,190},description="Unidentified stock."},
 blankL={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="L",shape={{0,0},{0,1},{1,1}},glyph="?",rarity="common",base=30,wholesale=15,color={119,175,183},description="Unidentified stock."},
 blank2={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="2x2",shape={{0,0},{1,0},{0,1},{1,1}},glyph="?",rarity="common",base=40,wholesale=20,color={133,170,176},description="Unidentified stock."},
 blank3={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="1x3",shape={{0,0},{0,1},{0,2}},glyph="?",rarity="common",base=30,wholesale=15,color={147,165,169},description="Unidentified stock."},
 blank4={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="1x4",shape={{0,0},{0,1},{0,2},{0,3}},glyph="?",rarity="common",base=40,wholesale=20,color={161,160,162},description="Unidentified stock."},
 blank9={name="Blank item",category="UNIDENTIFIED",tagCategory="unknown",shapeTag="3x3",shape={{0,0},{1,0},{2,0},{0,1},{1,1},{2,1},{0,2},{1,2},{2,2}},glyph="?",rarity="common",base=90,wholesale=45,color={175,155,155},description="Unidentified stock."},
}
return table.freeze({Definitions=table.freeze(items),Order=table.freeze({"blank1","blankL","blank2","blank3","blank4","blank9","wallet1","wallet2","wallet3"})})
