-- Test the actual server entry point against an in-memory Roblox API double.
-- This is not a Roblox engine playtest.
local count=0
local function check(ok,name) assert(ok,name); count+=1; print("PASS server: "..name) end
local now=0
local queue={}
local function schedule(t,fn) table.insert(queue,{at=now+t,fn=fn}) end
local function resume(co,...)
 local ok,delay=coroutine.resume(co,...); assert(ok,delay)
 if coroutine.status(co)~="dead" then schedule(delay or 0,function() resume(co) end) end
end
local taskMock={}
function taskMock.spawn(fn,...) resume(coroutine.create(fn),...) end
function taskMock.delay(t,fn) schedule(t,function() taskMock.spawn(fn) end) end
function taskMock.wait(t) return coroutine.yield(t or 0.01) end
local function advance(t)
 local finish=now+t
 while true do
  table.sort(queue,function(a,b) return a.at<b.at end)
  if not queue[1] or queue[1].at>finish then break end
  local next=table.remove(queue,1); now=next.at; next.fn()
 end
 now=finish
end
local function signal()
 local listeners={}; local e={}
 function e:Connect(fn) table.insert(listeners,fn); return {Disconnect=function() end} end
 function e:Fire(...) for _,fn in ipairs(listeners) do fn(...) end end
 return e
end
local vec={}; vec.__index=vec
function vec.__add(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},vec) end
local Vector={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vec) end}
local objects={}
local snapshots={}
local InstanceMock={new=function(class)
 local obj={ClassName=class,OnServerEvent=signal()}
 function obj:Destroy() self.destroyed=true end
 function obj:FireClient(player,snapshot) snapshots[player.UserId]=snapshot end
 table.insert(objects,obj); return obj
end}
local function player(id) return {UserId=id,Parent=true,Kick=function(self,msg) self.kicked=msg end} end
local a,b=player(1),player(2)
local players={PlayerAdded=signal(),PlayerRemoving=signal()}
function players:GetPlayers() return {a,b} end
local shared={Config="Config",Items="Items",Scene="Scene",Grid="Grid",ItemTags="ItemTags"}
local services={TextService={FilterStringAsync=function(_,caption) return {GetNonChatStringForBroadcastAsync=function() return caption:gsub("blocked","####") end} end},Players=players,ReplicatedStorage={WaitForChild=function() return shared end},Lighting={},HttpService={}}
local guid=0
function services.HttpService:GenerateGUID() guid+=1; return "guid"..guid end
local profiles={}
local modules={}
local function load(name,env)
 local fn=assert(loadstring(Sources[name],name)); setfenv(fn,setmetatable(env or {},{__index=getfenv()})); return fn()
end
modules.ItemTags=load("ItemTags");modules.Config=load("Config"); modules.Items=load("Items"); modules.Rules=load("Rules");modules.Grid=load("Grid");modules.TradeService=load("TradeService")
local spawnCalls={}
modules.Scene={spawn=function(template,parent,origin,name) table.insert(spawnCalls,{template=template,origin=origin});return {Name=name,Destroy=function() end} end,build=function() return {Name="MockStage",Destroy=function() end} end,stock=function() end,cash=function() end}
local rules=modules.Rules(modules.Config,modules.Items.Definitions,modules.Grid(modules.Config,modules.Items.Definitions),modules.ItemTags)
modules.Persistence={load=function(id) profiles[id]=rules.newProfile(); return profiles[id],"TEST" end,
 safe=function() return true end,save=function() return true,"TEST" end}
modules.CustomerService=load("CustomerService",{require=function(name) return modules[name] end,game={GetService=function(_,name) return services[name] end}})
local authored={Name="ShopTemplate",Parent="workspace"};services.ServerStorage={}
local workspaceMock={FindFirstChild=function(_,name) return if name=="ShopTemplate" then authored else nil end,GetServerTimeNow=function() return now end}
local gameMock={GetService=function(_,name) return services[name] end,BindToClose=function() end}
local random={NextInteger=function(_,low) return low end,NextNumber=function() return 0.9 end}
load("Main.server",{game=gameMock,workspace=workspaceMock,Instance=InstanceMock,Vector3=Vector,
 Color3={fromRGB=function(...) return {...} end},Random={new=function() return random end},task=taskMock,
 os={clock=function() return now end},script={Parent={Rules="Rules",Persistence="Persistence",CustomerService="CustomerService",TradeService="TradeService"}},
 require=function(name) return assert(modules[name],name) end})
local remote
for _,obj in ipairs(objects) do if obj.Name=="Action" then remote=obj end end
local function request(p,name,extra)
 advance(0.21); local r=extra or {}; r.action=name; remote.OnServerEvent:Fire(p,r); return snapshots[p.UserId]
end
check(authored.Parent==services.ServerStorage and spawnCalls[1].template==authored and spawnCalls[2].template==authored,"server preserves the authored shop and spawns both players from it")
check(snapshots[1].cash==160 and snapshots[2].cash==160,"players load independent cash and inventory")
check(snapshots[1].origin.X~=snapshots[2].origin.X,"each player has a separate seller booth")
advance(4.1)
local s=snapshots[1];local visitor=s.customer;local first=visitor.goods[1]
check(visitor.mode=="Seller" and visitor.state=="Interact" and #visitor.goods>=4 and #visitor.goods<=10,"empty shops receive a seller carrying a random supply")
local distribution={};for _,entry in ipairs(visitor.goods) do distribution[entry.item.kind]=(distribution[entry.item.kind] or 0)+1;check(entry.item.rarity==nil and entry.item.marketCondition==nil and entry.item.criminality~=nil,"ore has no market tag and hides rarity") end
for _,n in pairs(distribution) do check(n<10,"seller carries fewer than ten of the same ore") end
check(visitor.dialogue:find("Looking to sell")~=nil,"seller intent is included in the public dialogue")
local bypass=request(a,"Buy",{id=first.item.id})
check(bypass.cash==160 and #bypass.inventory==0,"legacy instant-buy action cannot bypass purchase confirmation")
local foreign=request(b,"StageOffer",{customerId=snapshots[2].customer.id,id=first.item.id,x=0,y=0,rotation=0,revision=0,moveId=1})
check(not foreign.moveOk and #foreign.customer.basket==0,"another visitor's offer IDs cannot be selected")
s=request(a,"StageOffer",{customerId=visitor.id,id=first.item.id,x=0,y=0,rotation=0,revision=0,moveId=1})
check(s.cash==160 and #s.inventory==0 and #s.customer.basket==1,"staging changes selection without transferring money or ownership")
check(s.customer.quote.count==1 and s.customer.quote.total==first.price,"server creates the itemized review total")
check(s.customer.quote.plan==nil and s.customer.goods[1].item.condition==nil,"public review hides server plans and uninspected item details")
local token=s.customer.quote.id
local bad=request(a,"ConfirmPurchase",{customerId=visitor.id,quoteId="fake",total=0})
check(bad.cash==160 and #bad.inventory==0,"forged review token cannot charge or award goods")
s=request(a,"InspectGoods",{customerId=visitor.id,id=first.item.id})
check(s.customer.goods[1].item.inspected,"visitor merchandise can be inspected before purchase")
s=request(a,"ConfirmPurchase",{customerId=visitor.id,quoteId=token,total=0})
local paidCash=s.cash
check(s.cash==160-first.price and #s.inventory==1 and s.customer.state=="Leave","confirmed purchase charges the server quote and stores the item")
check(s.inventory[1].inspected,"inspection performed after quoting survives the transfer")
s=request(a,"ConfirmPurchase",{customerId=visitor.id,quoteId=token})
check(s.cash==paidCash and #s.inventory==1,"replayed purchase confirmation cannot duplicate stock")
local owned=s.inventory[1];local rev=s.gridRevision
s=request(a,"PlaceItem",{id=owned.id,x=5,y=3,rotation=0,revision=rev,moveId=2})
check(s.moveOk and s.inventory[1].gridX==5 and s.inventory[1].gridY==3,"owned stock can be repositioned with server acknowledgement")
s=request(a,"PlaceItem",{id=owned.id,x=0,y=0,rotation=0,revision=rev,moveId=3})
check(not s.moveOk and s.inventory[1].gridX==5,"stale inventory revisions cannot overwrite a newer placement")
foreign=request(b,"PlaceItem",{id=owned.id,x=0,y=0,rotation=0,revision=snapshots[2].gridRevision,moveId=4})
check(not foreign.moveOk and profiles[1].inventory[1].gridX==5,"players cannot rearrange another player's stock")
s=request(a,"PlaceItem",{id=owned.id,x=0/0,y=0,rotation=0,revision=s.gridRevision,moveId=5})
check(not s.moveOk and rules.validate(profiles[1]),"NaN placement coordinates are rejected without corrupting the profile")
advance(6.1);visitor=snapshots[1].customer
check(visitor.state=="Interact" and visitor.itemId==owned.id,"the next visitor may buy an actual owned unit")
local patience=visitor.patience
s=request(a,"Counter",{customerId=visitor.id,price=0/0})
check(s.customer.patience==patience and s.cash==paidCash,"malformed sale price does not consume patience or money")
s=request(a,"Accept",{customerId="forged"})
check(#s.inventory==1 and s.cash==paidCash,"forged buyer identity cannot complete a sale")
local market=s.inventory[1].value
s=request(a,"Counter",{customerId=visitor.id,price=market})
check(#s.inventory==0 and s.cash==paidCash+market and s.customer.state=="Leave","negotiated sale atomically removes stock and pays credits")
local soldCash=s.cash
s=request(a,"Accept",{customerId=visitor.id});check(s.cash==soldCash,"replayed sale cannot pay twice")
advance(1.6);s=request(a,"EndDay")
check(s.day==2 and s.visits==0 and s.cash==soldCash-24,"daily expense payment advances day and resets visits")
check(snapshots[2].cash==160 and #snapshots[2].inventory==0,"transactions leave the other shop's balance unchanged")
local tagged=player(3);players.PlayerAdded:Fire(tagged)
advance(4.1);visitor=snapshots[3].customer;first=visitor.goods[1]
s=request(tagged,"StageOffer",{customerId=visitor.id,id=first.item.id,x=0,y=0,rotation=0,revision=0,moveId=10})
s=request(tagged,"ConfirmPurchase",{customerId=visitor.id,quoteId=s.customer.quote.id})
local taggedId=s.inventory[1].id;local price=s.inventory[1].value
s=request(tagged,"SetItemTag",{id=taggedId,qualityTag="high",categoryTag="gun",multiplier=999})
check(s.inventory[1].qualityTag=="high" and s.inventory[1].categoryTag=="ore","quality changes apply to owned items while fixed category cannot be spoofed")
request(tagged,"Inspect",{id=taggedId});s=snapshots[3]
check(s.inventory[1].value==rules.value(profiles[3].inventory[1]),"server pricing uses catalog multiplier rather than client amount")
local other=request(b,"SetItemTag",{id=taggedId,qualityTag="low"})
check(profiles[3].inventory[1].qualityTag=="high","another player cannot retag owned goods")
local cash=profiles[3].cash
request(tagged,"SaveLabel",{kind="bargain",text="old",labelRevision=0})
request(tagged,"Upgrade")
check(profiles[3].cash==cash and profiles[3].upgrade==0 and profiles[3].labels==nil,"removed booth-label and expansion actions remain unavailable")
advance(6.1);visitor=snapshots[3].customer
local previous=visitor.offer
s=request(tagged,"SetItemTag",{id=taggedId,qualityTag="low"})
check(s.customer.offer<previous,"retagging updates the current buyer's real offer")
local timeout=player(4);players.PlayerAdded:Fire(timeout);advance(4.1);advance(modules.Config.ServiceSeconds)
check(snapshots[4].customer.state=="Leave","a visitor leaves after the service deadline")
local broke=player(5);players.PlayerAdded:Fire(broke);profiles[5].cash=0;profiles[5].aidDay=1
request(broke,"Work");advance(9)
check(profiles[5].cash==0 and snapshots[5].working,"recovery work cannot pay before its server timer")
request(broke,"Work");advance(1)
check(profiles[5].cash==18 and not snapshots[5].working,"duplicate work requests produce one reward")
request(broke,"Work");advance(10.1);s=request(broke,"EndDay")
check(s.day==2 and s.cash==12,"a bankrupt player can recover and pay expenses")
local gone=player(6);players.PlayerAdded:Fire(gone);profiles[6].cash=0
request(gone,"Work");players.PlayerRemoving:Fire(gone);advance(10.1)
check(profiles[6].cash==0,"disconnecting cancels outstanding work rewards")
local caller=player(7);players.PlayerAdded:Fire(caller);advance(4.1)
local old=snapshots[7].customer
request(caller,"StageOffer",{customerId=old.id,id=old.goods[1].item.id,x=0,y=0,rotation=0,revision=0,moveId=30})
s=request(caller,"NextCustomer")
check(s.customer.state=="Leave" and #s.customer.basket==0 and s.customer.quote==nil and s.cash==160,"calling next clears the old selection without buying it")
request(caller,"NextCustomer");advance(6)
check(snapshots[7].visits==2 and snapshots[7].customer.id~=old.id,"repeated next presses schedule only one replacement")
for i=1,6 do request(caller,"NextCustomer");advance(6) end
check(snapshots[7].visits==8 and snapshots[7].customer.state=="Interact" and rules.validate(profiles[7]),"next customer continues past five visits without the removed day tab")
check(snapshots[7].customer.mode=="Buyer" and snapshots[7].customer.itemId==nil and #snapshots[7].customer.goods==0 and snapshots[7].customer.dialogue:find("ore"),"buyer request and dialogue do not require matching stock or carry seller merchandise")
check(first.item.marketPrice~=nil and first.item.condition==nil,"hover price is public without exposing hidden condition")
local approaching=player(8);players.PlayerAdded:Fire(approaching);advance(modules.Config.ArrivalSeconds+0.1)
request(approaching,"NextCustomer");advance(modules.Config.WalkSeconds-0.3)
check(snapshots[8].customer.state=="Leave","dismissing an approaching customer cannot reactivate their trade window")
local categoryShop=player(9);players.PlayerAdded:Fire(categoryShop)
local function categoryUnit(id,kind,quality)
 return {id=id,kind=kind,paid=0,condition=100,authentic=true,restricted=false,inspected=false,qualityTag=quality}
end
rules.purchase(profiles[9],categoryUnit("cat-a","genericOre","standard"),10)
rules.purchase(profiles[9],categoryUnit("cat-b","genericOre","high"),10)
rules.purchase(profiles[9],categoryUnit("cat-c","cobalt","standard"),10)
profiles[9].visits=1;advance(4.1);s=snapshots[9];visitor=s.customer
check(visitor.requestTag=="ore" and visitor.itemId=="cat-a","alternating customer requests a basic category tag")
local catCash=s.cash
s=request(categoryShop,"Accept",{customerId=visitor.id,id="cat-c"})
check(s.cash==catCash and #s.inventory==3,"tag customer cannot be sold an owned item with the wrong category")
s=request(categoryShop,"Accept",{customerId=visitor.id,id="someone-elses-stock"})
check(s.cash==catCash and #s.inventory==3,"tag sale rejects unowned item IDs")
s=request(categoryShop,"Accept",{customerId=visitor.id,id="cat-b",price=999999})
check(s.customer.state=="Leave" and #s.inventory==2 and s.cash==catCash+math.floor(rules.value(categoryUnit("calc","genericOre","high"))*0.86) and rules.find(profiles[9],"cat-a")~=nil,"tag buyer accepts an alternate matching unit with its server quality-adjusted price")
local oreShop=player(10);players.PlayerAdded:Fire(oreShop)
local function oreUnit(id,kind) return {id=id,kind=kind,paid=9,condition=100,authentic=true,restricted=false,inspected=false,qualityTag="standard",marketCondition="retailer",marketPercent=15,criminality="none",rarity=modules.Items.Definitions[kind].rarity} end
rules.purchase(profiles[10],oreUnit("o1","genericOre"),9)
rules.purchase(profiles[10],oreUnit("o2","genericOre"),9)
rules.purchase(profiles[10],oreUnit("m1","cobalt"),9)
profiles[10].visits=1;advance(4.1);s=snapshots[10];visitor=s.customer
check(visitor.mode=="Buyer" and visitor.requestTag=="ore" and #visitor.goods==0,"ore buyer arrives without seller supply")
local beforeSaleCash=s.cash
s=request(oreShop,"StageStock",{customerId=visitor.id,id="m1",x=0,y=0,rotation=0,revision=0,moveId=51})
check(not s.moveOk and s.cash==beforeSaleCash,"wrong basic-tag stock cannot enter buyer tray")
s=request(oreShop,"StageStock",{customerId=visitor.id,id="o1",x=0,y=0,rotation=0,revision=0,moveId=52})
check(s.moveOk and s.customer.quote.mode=="Sale" and s.customer.quote.total>0 and #s.customer.basket==1 and s.cash==beforeSaleCash,"staging first ore produces an unpaid server sale quote")
s=request(oreShop,"StageStock",{customerId=visitor.id,id="o2",x=2,y=0,rotation=0,revision=s.customer.basketRevision,moveId=53})
check(s.moveOk and #s.customer.basket==2 and s.customer.quote.count==2 and s.customer.quote.affordable,"same sell tray holds multiple owned ores")
local saleToken=s.customer.quote.id;local saleTotal=s.customer.quote.total
s=request(oreShop,"ConfirmSale",{customerId=visitor.id,quoteId="forged"})
check(s.cash==beforeSaleCash and #s.inventory==3,"forged sale quote cannot pay")
s=request(oreShop,"ConfirmSale",{customerId=visitor.id,quoteId=saleToken})
check(s.cash==beforeSaleCash+saleTotal and #s.inventory==1 and s.inventory[1].id=="m1" and s.customer.state=="Leave","confirmed sale transfers both ores atomically and pays shop")
s=request(oreShop,"ConfirmSale",{customerId=visitor.id,quoteId=saleToken})
check(s.cash==beforeSaleCash+saleTotal and #s.inventory==1,"replayed sale cannot pay twice")
local before=profiles[1].cash
for i=1,100 do remote.OnServerEvent:Fire(a,{action="GiveCash",amount=99999999}) end
check(profiles[1].cash==before,"spammed unknown actions cannot award currency")
check(rules.validate(profiles[1]) and rules.validate(profiles[3]),"resulting purchased sold and labeled profiles satisfy all invariants")
print(count.." server integration checks passed")
