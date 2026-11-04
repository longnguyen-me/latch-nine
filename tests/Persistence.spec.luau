-- Execute actual persistence code with an in-memory UpdateAsync API double.
local count=0
local function check(ok,name) assert(ok,name); count+=1; print("PASS saves: "..name) end
local function loadModule(name,env)
 local fn=assert(loadstring(Sources[name],name)); setfenv(fn,setmetatable(env or {},{__index=getfenv()})); return fn()
end
local config=loadModule("Config")
local items=loadModule("Items")
local rules=loadModule("Rules")(config,items.Definitions,loadModule("Grid")(config,items.Definitions),loadModule("ItemTags"))
local records={}; local clock=1000; local calls=0; local fail=0
local function copy(value)
 if type(value)~="table" then return value end
 local out={}; for k,v in pairs(value) do out[k]=copy(v) end; return out
end
local store={}
function store:UpdateAsync(key,fn)
 calls+=1
 if fail>0 then fail-=1; error("Transient datastore failure") end
 -- Invoke twice like a retried transform; callbacks must not mutate profiles.
 fn(copy(records[key]))
 local result=fn(copy(records[key]))
 if result~=nil then records[key]=copy(result) end
 return copy(result)
end
local function server(id,studio)
 local services={DataStoreService={GetDataStore=function() return store end},RunService={IsStudio=function() return studio end},
  HttpService={GenerateGUID=function() return id end},ReplicatedStorage={WaitForChild=function() return {Config="Config"} end}}
 return loadModule("Persistence",{game={JobId=id,GetService=function(_,name) return services[name] end},
  require=function() return config end,os={time=function() return clock end},task={wait=function(t) clock+=t end}})
end
local a,b=server("serverA",false),server("serverB",false)
local profile,status=a.load(1,rules)
check(profile and profile.cash==160 and status=="CLOUD SAVE / active","first load creates profile and lock")
check(a.load(1,rules)==nil,"same-server rejoin cannot acquire an already loaded key")
local blocked=b.load(1,rules)
check(blocked==nil and records.player_1.lock.id:find("serverA")~=nil,"second server cannot load active session")
profile.cash=123; check(a.save(1,profile,false),"owned session autosaves")
check(records.player_1.data.cash==123,"saved snapshot matches live data")
profile.cash=77; check(records.player_1.data.cash==123,"stored copy cannot change through shared references")
check(a.save(1,profile,true) and records.player_1.lock==nil,"final save releases lock")
local fromB=b.load(1,rules)
check(fromB.cash==77,"next server loads most recent final save")
check(not a.save(1,profile,false) and records.player_1.data.cash==77,"released owner cannot overwrite next server")
clock+=config.LockSeconds+1
check(not b.safe(1),"expired lease blocks further gameplay")
local c=server("serverC",false); local fromC=c.load(1,rules)
check(fromC and records.player_1.lock.id:find("serverC")~=nil,"expired lock can be reclaimed")
check(not b.save(1,fromB,false),"old owner cannot save after takeover")
records.player_2={data={version=999,cash=999},lock=nil}
local corrupt=c.load(2,rules)
check(corrupt==nil and records.player_2.data.cash==999,"corrupt or future-version save preserved without overwrite")
fail=2; local retry=c.load(3,rules)
check(retry and records.player_3.data.cash==160,"transient failures retry and recover")
fail=3; local failed=c.load(4,rules)
check(failed==nil and records.player_4==nil,"live failures never substitute an unsaved fresh profile")
local before=calls; local studio=server("studio",true); local localProfile,localStatus=studio.load(5,rules)
check(localProfile.cash==160 and localStatus=="SESSION ONLY / Studio","Studio defaults to clearly labeled memory mode")
check(studio.save(5,localProfile,true) and calls==before,"Studio memory mode makes no cloud requests")
local gridProfile=c.load(6,rules)
rules.purchase(gridProfile,{id="grid-unit",kind="chip",condition=100,paid=0,authentic=true,restricted=false,inspected=false},20)
rules.move(gridProfile,"grid-unit",4,3,1,gridProfile.gridRevision)
check(c.save(6,gridProfile,true),"positioned inventory can be saved and ownership released")
local reloaded=server("serverD",false).load(6,rules)
check(reloaded.inventory[1].gridX==4 and reloaded.inventory[1].gridY==3 and reloaded.inventory[1].rotation==1,"grid coordinates and rotation survive cloud-code reload")
local legacy=rules.newProfile();legacy.version=1;legacy.gridRevision=nil;legacy.legacyRows=nil
legacy.inventory={{id="legacy",kind="filter",condition=100,paid=24,authentic=true,restricted=false,inspected=true}}
records.player_7={data=legacy,lock=nil}
local upgraded=c.load(7,rules)
check(upgraded and upgraded.version==5 and upgraded.inventory[1].gridX==0 and records.player_7.data.version==5,"UpdateAsync atomically migrates legacy inventory to grid data")
local tagged=c.load(8,rules)
rules.purchase(tagged,{id="tagged",kind="filter",condition=100,paid=0,authentic=true,restricted=false,inspected=false},24)
rules.setItemTag(tagged,"tagged","high")
check(c.save(8,tagged,true),"item quality tags save with owned inventory")
local restored=server("serverE",false).load(8,rules)
check(restored.version==5 and restored.inventory[1].qualityTag=="high" and rules.value(restored.inventory[1])==60,"saved quality tag and price effect survive reload")
print(count.." persistence checks passed")
