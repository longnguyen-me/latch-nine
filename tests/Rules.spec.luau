--!strict
local config=require("../src/shared/Config")
local items=require("../src/shared/Items")
local tags=require("../src/shared/ItemTags")
local grid=require("../src/shared/Grid")(config,items.Definitions)
local R=require("../src/server/Rules")(config,items.Definitions,grid,tags)
local passed=0
local function test(name: string,fn: ()->())
 local ok,err=pcall(fn)
 if not ok then error("FAIL "..name..": "..tostring(err)) end
 passed+=1; print("PASS "..name)
end
local function stock(id: string,kind: string?): any
 return {id=id,kind=kind or "filter",paid=0,condition=100,authentic=true,restricted=false,inspected=false}
end
local function buyer(item: any): any
 return {id="c1",kind=item.kind,state="Interact",budget=100,offer=40,tolerance=1.1,patience=3,faction="Dock Union"}
end
test("new profile validates",function() assert(R.validate(R.newProfile())) end)
test("buy inspect negotiate sell pay rent full loop",function()
 local p=R.newProfile(); local i=stock("a")
 assert(R.purchase(p,i,24)); assert(p.cash==136 and #p.inventory==1)
 assert(R.inspect(p,"a")); assert(i.inspected and R.value(i)==48)
 local c=buyer(i); assert((R.negotiate(p,c,i,50))); assert(R.sell(p,c,"a",50))
 assert(p.cash==186 and p.revenue==50 and p.tradeProfit==26 and p.reputation==1)
 assert(#p.inventory==0); assert(R.endDay(p)); assert(p.cash==162 and p.day==2 and p.tradeProfit==2)
 assert(R.validate(p))
end)
test("cannot overspend or mutate on failed purchase",function()
 local p=R.newProfile(); p.cash=1
 assert(not R.purchase(p,stock("a"),24)); assert(p.cash==1 and #p.inventory==0)
end)
test("same stock ID cannot duplicate",function()
 local p=R.newProfile(); assert(R.purchase(p,stock("a"),24))
 assert(not R.purchase(p,stock("a"),24)); assert(p.cash==136)
end)
test("sold item cannot be sold again",function()
 local p=R.newProfile(); local i=stock("a"); R.purchase(p,i,24); local c=buyer(i)
 assert(R.sell(p,c,"a",40)); local cash=p.cash
 assert(not R.sell(p,c,"a",40)); assert(p.cash==cash)
end)
test("reject nonfinite fractional negative huge and nonnumeric prices",function()
 for _,price in ipairs({0,-1,1.2,math.huge,-math.huge,0/0,1000001,"50",{}}) do
  local p=R.newProfile(); local i=stock("a"); local c=buyer(i)
  assert(not R.negotiate(p,c,i,price)); assert(c.patience==3)
 end
end)
test("fairness and patience produce deterministic counteroffer",function()
 local p=R.newProfile(); local i=stock("a"); local c=buyer(i)
 local ok,_,left=R.negotiate(p,c,i,99); assert(not ok and not left and c.patience==2 and c.offer==46)
 R.negotiate(p,c,i,99); local _,_,exhausted=R.negotiate(p,c,i,99); assert(exhausted)
end)
test("wrong product and wrong customer phase rejected",function()
 local p=R.newProfile(); local i=stock("a"); R.purchase(p,i,24); local c=buyer(i); c.kind="servo"
 assert(not R.sell(p,c,"a",40)); c.kind="filter"; c.state="Leave"; assert(not R.sell(p,c,"a",40))
 assert(p.cash==136 and #p.inventory==1)
end)
test("restricted goods incur capped Watch fine and trust loss",function()
 local p=R.newProfile(); local i=stock("a","chip"); i.restricted=true; R.purchase(p,i,58)
 local c=buyer(i); c.faction="Transit Watch"; assert(R.sell(p,c,"a",100))
 assert(p.cash==177 and p.reputation==-3 and p.tradeProfit==17 and #p.inventory==0)
end)
test("counterfeit price and trust consequence",function()
 local p=R.newProfile(); local i=stock("a"); i.authentic=false; assert(R.value(i)==28)
 R.purchase(p,i,16); assert(R.sell(p,buyer(i),"a",24)); assert(p.reputation==-1)
end)
test("storage capacity prevents overflow",function()
 local p=R.newProfile(); p.cash=10000
 for i=1,10 do assert(R.purchase(p,stock(tostring(i)),24)) end
 assert(not R.purchase(p,stock("ninth"),24)); assert(#p.inventory==10)
end)
test("insufficient rent does not advance day",function()
 local p=R.newProfile(); p.cash=23; p.visits=5
 assert(not R.endDay(p)); assert(p.day==1 and p.visits==5 and p.cash==23)
end)
test("emergency aid capped once per day",function()
 local p=R.newProfile(); assert(not R.aid(p)); p.cash=0
 assert(R.aid(p)); assert(p.cash==40 and p.reputation==-2)
 assert(not R.aid(p)); assert(R.endDay(p)); assert(R.aid(p)); assert(p.aidDay==2)
end)
test("profile validator rejects corrupt or duplicate inventory",function()
 local p=R.newProfile(); p.cash=0/0; assert(not R.validate(p)); p.cash=160
 table.insert(p.inventory,stock("a")); table.insert(p.inventory,stock("a")); assert(not R.validate(p))
 p.inventory={stock("a")}; p.inventory[1].kind="forged"; assert(not R.validate(p))
end)
test("independent player state",function()
 local a,b=R.newProfile(),R.newProfile(); assert(R.purchase(a,stock("a"),24))
 assert(b.cash==160 and #b.inventory==0 and a.cash==136)
end)
test("receipt history bounded",function()
 local p=R.newProfile(); for i=1,50 do R.log(p,tostring(i)) end
 assert(#p.receipts==12 and p.receipts[1]=="D1 / 50")
end)
test("category buyer accepts its tag instead of exact kind",function()
 local p=R.newProfile();local i=stock("tagged");R.purchase(p,i,24)
 local c=buyer(i);c.requestTag="household";c.kind="servo"
 assert(R.matches(c,i));assert((R.negotiate(p,c,i,40)));assert(R.sell(p,c,i.id,40));assert(#p.inventory==0)
end)
test("category buyer rejects the wrong tag even with matching kind",function()
 local p=R.newProfile();local i=stock("wrong");R.purchase(p,i,24)
 local c=buyer(i);c.requestTag="electronics"
 assert(not R.matches(c,i));assert(not R.negotiate(p,c,i,40));assert(not R.sell(p,c,i.id,40));assert(#p.inventory==1 and p.cash==136)
end)
test("ore catalog has unique stock and hidden rarity weights",function()
 local seen={};assert(#items.Order==15 and not items.Definitions.quartz)
 for _,kind in ipairs(items.Order) do
  assert(not seen[kind]);seen[kind]=true
  local def=items.Definitions[kind]
  local categories: any=tags.Categories;local weights: any=tags.RarityWeights
  assert(categories[def.tagCategory] and weights[def.rarity]>0 and #def.shape>0)
 end
 assert(tags.RarityWeights.common>tags.RarityWeights.uncommon and tags.RarityWeights.uncommon>tags.RarityWeights.rare and tags.RarityWeights.rare>tags.RarityWeights.legendary)
end)
test("quality market and criminality affect ore value independently",function()
 local i=stock("ore","genericOre")
 i.qualityTag="standard";assert(R.value(i)==19)
 i.qualityTag="low";assert(R.value(i)==14)
 i.qualityTag="high";assert(R.value(i)==24)
 i.qualityTag="standard";i.marketCondition="retailer";i.marketPercent=15;assert(R.value(i)==19)
 i.marketCondition="bulk";i.marketPercent=10;assert(R.value(i)==19)
 i.marketCondition=nil;i.criminality="high";assert(R.value(i)==24)
end)
test("new tags persist and malformed bulk percentage is rejected",function()
 local p=R.newProfile();local i=stock("ore","cobalt")
 i.marketCondition="bulk";i.marketPercent=7;i.criminality="low";i.rarity="common";i.qualityTag="high"
 assert(R.purchase(p,i,16) and R.validate(p))
 i.marketPercent=25;assert(not R.validate(p));i.marketPercent=7
 i.rarity="forged";assert(not R.validate(p));i.rarity="common";assert(R.validate(p))
end)
print(string.format("%d domain tests passed",passed))
