--!strict
local config=require("../src/shared/Config")
local items=require("../src/shared/Items")
local G=require("../src/shared/Grid")(config,items.Definitions)
local R=require("../src/server/Rules")(config,items.Definitions,G,require("../src/shared/ItemTags"))
local count=0
local function test(name: string,fn: ()->())
 local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));count+=1;print("PASS grid: "..name)
end
local function stock(id: string,kind: string): any
 return {id=id,kind=kind,condition=100,authentic=true,restricted=false,inspected=false,paid=0}
end
test("base grid is 15 by 7 with fixed capacity",function()
 local p=R.newProfile();local x,y=G.size(p);assert(x==15 and y==7 and R.capacity(p)==105)
 p.upgrade=2;local _,rows=G.size(p);assert(rows==7 and R.capacity(p)==105)
end)
test("3 by 3 filter occupies exactly nine cells",function()
 local cells,w,h=G.cells("filter",0);assert(#cells==9 and w==3 and h==3)
end)
test("2 by 1 chip rotates to 1 by 2",function()
 local cells,w,h=G.cells("chip",1);assert(#cells==2 and w==1 and h==2)
end)
test("irregular shape retains its empty corner",function()
 local p=R.newProfile();R.purchase(p,stock("servo","servo"),10)
 assert((G.check(p,"chip",1,0,0)))
 assert(not G.check(p,"chip",1,1,0))
end)
test("auto placement uses holes inside irregular outlines",function()
 local p=R.newProfile();R.purchase(p,stock("s","servo"),10);R.purchase(p,stock("c","chip"),10)
 assert(p.inventory[2].gridX==1 and p.inventory[2].gridY==0 and G.used(p)==6)
end)
test("four rotations return the same footprint",function()
 local function signature(rotation: number): string
  local cells=G.cells("servo",rotation);local parts={}
  for _,c in ipairs(cells) do table.insert(parts,c[1]..","..c[2]) end;table.sort(parts);return table.concat(parts,";")
 end
 assert(signature(0)==signature(4));assert(signature(0)~=signature(1))
end)
test("bounds apply to every occupied cell",function()
 local p=R.newProfile();assert(not G.check(p,"filter",13,5,0));assert((G.check(p,"chip",13,6,0)))
 assert(not G.check(p,"chip",14,6,0));assert(not G.check(p,"chip",13,6,1))
end)
test("negative fractional NaN infinite and string coordinates rejected",function()
 local p=R.newProfile()
 for _,x in ipairs({-1,0.5,0/0,math.huge,"2",{}}) do assert(not G.check(p,"chip",x,0,0)) end
 for _,rotation in ipairs({-1,4,0.2,0/0,"1"}) do assert(not G.check(p,"chip",0,0,rotation)) end
end)
test("moving ignores own old cells but rejects occupied cells",function()
 local p=R.newProfile();R.purchase(p,stock("a","chip"),10);R.purchase(p,stock("b","chip"),10)
 assert(R.move(p,"a",0,0,0,p.gridRevision));assert(not R.move(p,"a",2,0,0,p.gridRevision))
end)
test("accepted move stores coordinates orientation and revision",function()
 local p=R.newProfile();R.purchase(p,stock("a","chip"),10);local before=p.gridRevision
 assert(R.move(p,"a",6,3,1,before));local i=p.inventory[1]
 assert(i.gridX==6 and i.gridY==3 and i.rotation==1 and p.gridRevision==before+1 and R.validate(p))
end)
test("failed move has no state or cash side effects",function()
 local p=R.newProfile();R.purchase(p,stock("a","chip"),10);local before=p.gridRevision;local cash=p.cash
 assert(not R.move(p,"a",15,6,1,before));assert(p.gridRevision==before and p.inventory[1].gridX==0 and p.cash==cash)
end)
test("stale layouts and unowned stock IDs cannot be moved",function()
 local p=R.newProfile();R.purchase(p,stock("a","chip"),10)
 assert(not R.move(p,"a",3,2,0,p.gridRevision-1));assert(not R.move(p,"someone-else",3,2,0,p.gridRevision))
end)
test("fragmented free cells do not imply that a large shape fits",function()
 local p=R.newProfile();p.cash=1000
 for i=1,10 do assert(R.purchase(p,stock(tostring(i),"filter"),10)) end
 assert(G.used(p)==90 and R.capacity(p)-G.used(p)==15)
 assert(not R.purchase(p,stock("fifth","filter"),10));assert(p.cash==900)
end)
test("small items fill all but one cell",function()
 local p=R.newProfile();p.cash=10000
 for i=1,52 do assert(R.purchase(p,stock("c"..i,"chip"),10)) end
 assert(G.used(p)==104 and R.validate(p));assert(not R.purchase(p,stock("extra","chip"),10))
end)
test("selling clears occupied cells without moving other stock",function()
 local p=R.newProfile();R.purchase(p,stock("a","filter"),10);R.purchase(p,stock("b","chip"),10)
 local x,y=p.inventory[2].gridX,p.inventory[2].gridY
 assert(R.sell(p,{state="Interact",kind="filter",budget=100,faction="Dock Union"},"a",50))
 assert(G.used(p)==2 and p.inventory[1].gridX==x and p.inventory[1].gridY==y)
end)
test("persisted overlapping and out-of-bounds layouts are rejected",function()
 local p=R.newProfile();R.purchase(p,stock("a","chip"),10);R.purchase(p,stock("b","chip"),10)
 p.inventory[2].gridX=0;assert(not R.validate(p));p.inventory[2].gridX=15;assert(not R.validate(p))
end)
test("version one migration preserves every paid item and balance",function()
 local p=R.newProfile();p.version=1;p.upgrade=2;p.gridRevision=nil;p.legacyRows=nil;p.cash=777
 for i=1,24 do local item=stock("old"..i,"filter");item.paid=24;table.insert(p.inventory,item) end
 local migrated=R.migrate(p)
 assert(migrated and migrated.version==5 and #migrated.inventory==24 and migrated.cash==777 and migrated.upgrade==2)
 assert(migrated.legacyRows>0 and R.validate(migrated));assert(p.version==1 and p.inventory[1].gridX==nil)
 for _,item in ipairs(migrated.inventory) do assert((item :: any).paid==24) end
end)
test("version four layout repacks while preserving tags and money",function()
 local p=R.newProfile();R.purchase(p,stock("old","chip"),10);p.version=4;p.inventory[1].gridX=6;p.inventory[1].gridY=5;p.inventory[1].qualityTag="high"
 local cash=p.cash;local migrated=R.migrate(p)
 assert(migrated and migrated.version==5 and migrated.cash==cash and migrated.inventory[1].id=="old" and migrated.inventory[1].qualityTag=="high" and R.validate(migrated))
 assert(p.version==4 and p.inventory[1].gridX==6)
end)
test("migration is idempotent and does not repair corrupt new layouts",function()
 local p=R.newProfile();R.purchase(p,stock("a","chip"),10);assert(R.migrate(p)==p)
 p.inventory[1].rotation=99;assert(R.migrate(p)==nil)
end)
test("deterministic randomized moves preserve geometry and cash",function()
 local p=R.newProfile();p.cash=1000
 for i=1,10 do R.purchase(p,stock(tostring(i),if i%2==0 then "servo" else "chip"),10) end
 local cash=p.cash
 for n=1,500 do
  local item=p.inventory[(n%#p.inventory)+1]
  R.move(p,item.id,(n*7)%10-1,(n*11)%8-1,n%4,p.gridRevision)
  assert(R.validate(p) and p.cash==cash)
 end
end)
print(count.." grid geometry and migration tests passed")
