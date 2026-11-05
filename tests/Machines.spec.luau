local config=require("../src/shared/Config")
local items=require("../src/shared/Items")
local grid=require("../src/shared/Grid")(config,items.Definitions)
local machines=require("../src/server/MachineService")(items.Definitions,grid)
local suspicion=require("../src/server/Suspicion")(items.Definitions)
local function item(id,kind,x,y)
 return {id=id,kind=kind,paid=0,condition=100,authentic=true,restricted=false,inspected=false,qualityTag="standard",gridX=x,gridY=y,rotation=0}
end
local p={inventory={item("printer","printer2",0,0),item("press","mintPress",4,0),item("paper1","paperhigh",5,0),item("paper2","paperlow",6,0),item("paper3","papermid",7,0),item("paper4","paperlow",8,0)},upgrade=0,legacyRows=0,gridRevision=0,cash=160,costs=0,tradeProfit=0,suspicion=0,suspicionAt=1000}
assert(machines.insert(p,"printer","press","press",0,0,1000))
for i=1,4 do assert(machines.insert(p,"printer","paper"..i,"input",(i-1)%2,math.floor((i-1)/2),1000)) end
assert(machines.validate(p.inventory[1]))
local serial=0
local function newId() serial+=1;return "new-"..serial end
local function roll(a,b) return 100 end
assert(machines.tick(p,1000+10000,newId,roll))
assert(#p.inventory[1].machine.output==3 and #p.inventory[1].machine.input==1 and not p.inventory[1].machine.nextAt)
assert(not machines.tick(p,1000+20000,newId,roll))
assert(machines.extract(p,"printer","new-1","output",9,0))
assert(machines.tick(p,1000+20000,newId,roll))
assert(p.inventory[1].machine.nextAt==1000+20000+180)
assert(machines.tick(p,1000+20180,newId,roll))
assert(#p.inventory[1].machine.output==3)
local laundry=item("laundry","laundry",0,3)
table.insert(p.inventory,laundry)
assert(machines.insert(p,"laundry","new-1","input",0,0,30000))
assert(machines.tick(p,30120,newId,function() return 100 end))
assert(#laundry.machine.output==0 and p.cash==150)
local dirty=item("dirty-2","dirty100",10,0);dirty.paperQuality="high";table.insert(p.inventory,dirty)
assert(machines.insert(p,"laundry","dirty-2","input",0,0,30200))
assert(machines.tick(p,30320,newId,function() return 1 end))
assert(#laundry.machine.output==1 and laundry.machine.output[1].kind=="cash100" and p.cash==140)
p.suspicion=60;p.suspicionAt=1000
assert(suspicion.decay(p,1000+6*3600) and p.suspicion==30)
assert(suspicion.spend(p,4,24000,function() return 1 end))
assert(p.suspicion==40 and not suspicion.spend(p,0,24000,function() return 1 end))
print("Offline production cap, laundry outcomes, and offline suspicion checks passed")
