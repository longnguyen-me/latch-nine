--!strict
local C=require("../src/shared/Config")
local D=require("../src/shared/Items").Definitions
local factory=require("../src/shared/Grid")
local G=factory(C,D);local R=require("../src/server/Rules")(C,D,G,require("../src/shared/ItemTags"))
local config: any=table.clone(C);config.GridBaseRows=C.TradeRows;config.GridColumns=C.TradeColumns;config.GridRowsPerUpgrade=0
local tray=factory(config,D);local T=require("../src/server/TradeService")(C,D,R,G,tray)
local count=0
local function test(name: string,fn: ()->()) local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));count+=1;print("PASS trade: "..name) end
local function item(id: string,kind: string): any return {id=id,kind=kind,paid=0,condition=100,authentic=true,restricted=false,inspected=false,rotation=0,gridX=0,gridY=0} end
local function visitor(): any
 return {id="v1",name="Test trader",state="Interact",basket={},basketRevision=0,quote=nil,goods={
  {item=item("f","filter"),price=24},{item=item("s","servo"),price=39},{item=item("c","chip"),price=58}}}
end
local function all(c: any)
 assert(T.stage(c,"f",0,0,0,c.basketRevision));assert(T.stage(c,"s",3,0,0,c.basketRevision));assert(T.stage(c,"c",6,0,0,c.basketRevision))
end
test("staging is not a purchase or ownership transfer",function()
 local p=R.newProfile();local c=visitor();assert(T.stage(c,"f",0,0,0,0));assert(p.cash==160 and #p.inventory==0 and #c.basket==1)
end)
test("three grids support an itemized atomic batch purchase",function()
 local p=R.newProfile();local c=visitor();all(c);assert(T.review(p,c,"quote1"))
 assert(c.quote.count==3 and c.quote.subtotal==121 and c.quote.total==121 and #c.quote.lines==3)
 assert(T.confirm(p,c,"quote1"));assert(p.cash==39 and p.costs==121 and #p.inventory==3 and #c.goods==0 and #c.basket==0 and R.validate(p))
end)
test("replayed confirmations cannot duplicate stock or spend twice",function()
 local p=R.newProfile();local c=visitor();all(c);T.review(p,c,"q");assert(T.confirm(p,c,"q"));local cash=p.cash
 assert(not T.confirm(p,c,"q"));assert(p.cash==cash and #p.inventory==3)
end)
test("forged quote ID cannot complete checkout",function()
 local p=R.newProfile();local c=visitor();all(c);T.review(p,c,"real")
 assert(not T.confirm(p,c,"forged"));assert(p.cash==160 and #p.inventory==0)
end)
test("insufficient funds leaves the whole basket unpurchased",function()
 local p=R.newProfile();p.cash=1;local c=visitor();all(c);T.review(p,c,"q")
 assert(not T.confirm(p,c,"q"));assert(p.cash==1 and #p.inventory==0 and #c.goods==3)
end)
test("no fitting storage rejects review without spending",function()
 local p=R.newProfile();p.cash=1000
 for i=1,10 do R.purchase(p,item("owned"..i,"filter"),24) end
 local c=visitor();T.stage(c,"f",0,0,0,0);local cash=p.cash
 assert(not T.review(p,c,"q"));assert(p.cash==cash and c.quote==nil and #p.inventory==10)
end)
test("inventory changes invalidate an earlier plan",function()
 local p=R.newProfile();local c=visitor();T.stage(c,"c",0,0,0,0);T.review(p,c,"q")
 R.purchase(p,item("new","chip"),10);assert(not T.confirm(p,c,"q"));assert(#p.inventory==1 and p.cash==150)
end)
test("returning a selected item invalidates the quote",function()
 local p=R.newProfile();local c=visitor();T.stage(c,"f",0,0,0,0);T.review(p,c,"q")
 assert(T.unstage(c,"f",c.basketRevision));assert(#c.basket==0 and c.quote==nil);assert(not T.confirm(p,c,"q"))
end)
test("staging rejects collisions bounds and stale revisions",function()
 local c=visitor();assert(T.stage(c,"f",0,0,0,0));local revision=c.basketRevision
 assert(not T.stage(c,"s",0,0,0,revision));assert(not T.stage(c,"c",11,4,0,revision));assert(not T.stage(c,"c",6,0,0,revision-1))
 assert(#c.basket==1 and c.basketRevision==revision)
end)
test("moving an already staged unit does not duplicate it",function()
 local c=visitor();assert(T.stage(c,"c",0,0,0,0));assert(T.stage(c,"c",5,0,1,c.basketRevision));assert(#c.basket==1 and c.basket[1].rotation==1)
end)
test("a departed visitor cannot trade",function()
 local p=R.newProfile();local c=visitor();all(c);T.review(p,c,"q");c.state="Leave"
 assert(not T.confirm(p,c,"q"));assert(not T.stage(c,"c",0,0,0,c.basketRevision));assert(p.cash==160)
end)
test("newly inspected metadata survives checkout",function()
 local p=R.newProfile();R.purchase(p,item("owned","chip"),10);local c=visitor();T.stage(c,"c",0,0,0,0);T.review(p,c,"q")
 R.inspect(p,"owned");c.goods[3].item.inspected=true
 assert(T.confirm(p,c,"q"));assert(p.inventory[1].inspected and p.inventory[2].inspected)
end)
test("clear selection spends nothing and restores all offers",function()
 local p=R.newProfile();local c=visitor();all(c);T.review(p,c,"q");assert(T.clear(c));assert(#c.goods==3 and #c.basket==0 and p.cash==160)
end)
test("quality tags change an item's value without compounding",function()
 local p=R.newProfile();local i=item("f","filter");R.purchase(p,i,24)
 assert(R.value(i)==48);assert(R.setItemTag(p,"f","high"));assert(R.value(i)==60)
 assert(R.setItemTag(p,"f","low"));assert(R.value(i)==36);assert(R.setItemTag(p,"f","high"));assert(R.value(i)==60)
end)
test("quality cannot be set on unowned items or with arbitrary names",function()
 local p=R.newProfile();assert(not R.setItemTag(p,"visitor-item","high"))
 R.purchase(p,item("f","filter"),24);assert(not R.setItemTag(p,"f","infinite"));assert(p.inventory[1].qualityTag=="standard")
end)
test("changing an owned tag invalidates a pending purchase quote",function()
 local p=R.newProfile();R.purchase(p,item("owned","chip"),10);local c=visitor();T.stage(c,"f",0,0,0,0);T.review(p,c,"q")
 R.setItemTag(p,"owned","high");assert(not T.confirm(p,c,"q"));assert(p.cash==150 and #p.inventory==1)
end)
test("owned item tags affect real negotiated sale prices",function()
 local p=R.newProfile();local i=item("f","filter");R.purchase(p,i,24)
 local c={kind="filter",state="Interact",budget=100,tolerance=1,patience=4,offer=40}
 assert(not R.negotiate(p,c,i,55));R.setItemTag(p,"f","high");assert((R.negotiate(p,c,i,55)))
end)
test("old booth labels migrate away without losing inventory",function()
 local p=R.newProfile();R.purchase(p,item("f","filter"),24);p.version=3;p.labels={{id="old",kind="bargain",text="Old board"}};p.labelRevision=7
 p.inventory[1].qualityTag=nil
 local migrated=R.migrate(p)
 assert(migrated and migrated.version==5 and migrated.labels==nil and migrated.labelRevision==nil and migrated.cash==136)
 assert(migrated.inventory[1].qualityTag=="standard" and migrated.inventory[1].id=="f" and p.labels~=nil)
end)
print(count.." cart and item-tag tests passed")
