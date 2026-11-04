--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local Scene = require(Shared.Scene)
local Tags = require(Shared.ItemTags)
local Grid = require(Shared.Grid)(Config, Items.Definitions)
local Rules = require(script.Parent.Rules)(Config, Items.Definitions, Grid, Tags)
local trayConfig: any = table.clone(Config);trayConfig.GridColumns=Config.TradeColumns;trayConfig.GridBaseRows=Config.TradeRows;trayConfig.GridRowsPerUpgrade=0
local TrayGrid = require(Shared.Grid)(trayConfig, Items.Definitions)
local Trade = require(script.Parent.TradeService)(Config, Items.Definitions, Rules, Grid, TrayGrid)
local Persistence = require(script.Parent.Persistence)
local Customers = require(script.Parent.CustomerService)
Players.CharacterAutoLoads = false
local shopTemplate = workspace:FindFirstChild("ShopTemplate") or workspace:FindFirstChild("StagePreview")
if shopTemplate then shopTemplate.Name="ShopTemplate";shopTemplate.Parent=game:GetService("ServerStorage") end
local remotes = Instance.new("Folder"); remotes.Name = "Remotes"; remotes.Parent = RS
local action = Instance.new("RemoteEvent"); action.Name = "Action"; action.Parent = remotes
local state = Instance.new("RemoteEvent"); state.Name = "State"; state.Parent = remotes
local sessions: {[Player]: any} = {}
local loading: {[Player]: boolean} = {}
local slots: {[number]: boolean} = {}
local closing = false
local rng = Random.new()
local function publicItem(item: any): any
 local out: any = {criminality=item.criminality or "none",id=item.id,kind=item.kind,inspected=item.inspected,paid=item.paid,gridX=item.gridX,gridY=item.gridY,rotation=item.rotation,qualityTag=item.qualityTag or Tags.DefaultQuality,categoryTag=Items.Definitions[item.kind].tagCategory,marketPrice=Rules.value(item)}
 if item.inspected then
  out.condition=item.condition; out.authentic=item.authentic
  out.restricted=item.restricted; out.value=Rules.value(item)
 end
 return out
end
local function makeOffer(kind: string,p: any): any
 local qualityRoll=rng:NextInteger(1,100)
 local item={id=Http:GenerateGUID(false),kind=kind,rarity=Items.Definitions[kind].rarity,
  criminality=if kind=="uranium" then "mid" elseif kind=="mythril" then "high" elseif rng:NextNumber()<0.08 then "low" else "none",paid=0,qualityTag=Tags.QualityOrder[if qualityRoll<=20 then 1 elseif qualityRoll>80 then 3 else 2],condition=rng:NextInteger(65,100),
  authentic=rng:NextNumber()>0.17,restricted=kind=="chip" and rng:NextNumber()<0.35,inspected=false}
 local price=math.max(8,math.floor(Rules.value(item)*0.58))
 if p.reputation>=Config.ReputationDiscountAt then price=math.max(1,price-2) end
 return {item=item,price=price}
end
local function push(player: Player,message: string?, moveAck: number?, moveOk: boolean?)
 local s=sessions[player]
 if not s or s.closed then return end
 local inventory,counts,colors={},{},{}
 for _,item in ipairs(s.profile.inventory) do table.insert(inventory,publicItem(item)) end
 for _,kind in ipairs(Items.Order) do
  local count=0
  for _,item in ipairs(s.profile.inventory) do if item.kind==kind then count+=1 end end
  table.insert(counts,count); table.insert(colors,Items.Definitions[kind].color)
 end
 Scene.stock(s.stage,counts,colors)
 Scene.cash(s.stage,s.profile.cash)
 local customer: any=nil
 if s.customer then
  local c=s.customer
  local goods,basket={},{ }
  for _,entry in ipairs(c.goods) do table.insert(goods,{item=publicItem(entry.item),price=entry.price}) end
  for _,selection in ipairs(c.basket) do
   if c.mode=="Buyer" then
    local owned=Rules.find(s.profile,selection.id)
    if owned then local unit=publicItem(owned);unit.gridX=selection.gridX;unit.gridY=selection.gridY;unit.rotation=selection.rotation;table.insert(basket,unit) end
   else
   for _,entry in ipairs(c.goods) do
    if entry.item.id==selection.id then
     local item=publicItem(entry.item);item.gridX=selection.gridX;item.gridY=selection.gridY;item.rotation=selection.rotation;table.insert(basket,item);break
    end
   end
   end
  end
  local quote: any=nil
  if c.quote then
   local q=c.quote;local lines={}
   for _,line in ipairs(q.lines) do table.insert(lines,{id=line.id,kind=line.kind,name=line.name,price=line.price,basePrice=line.basePrice}) end
   quote={id=q.id,mode=q.mode,lines=lines,subtotal=q.subtotal,discount=q.discount,total=q.total,count=q.count,affordable=q.mode=="Sale" or s.profile.cash>=q.total}
  end
  local bulkOriginal,bulkPrice=0,0
  if c.bulkPercent then for _,entry in ipairs(c.goods) do bulkOriginal+=entry.price;bulkPrice+=math.max(1,math.floor(entry.price*(100-c.bulkPercent)/100)) end end
  customer={id=c.id,name=c.name,personality=c.personality,faction=c.faction,kind=c.kind,itemId=c.itemId,requestTag=c.requestTag,
   bulkPercent=c.bulkPercent,bulkOriginal=bulkOriginal,bulkPrice=bulkPrice,
   mode=c.mode,goods=goods,basket=basket,basketRevision=c.basketRevision,quote=quote,
   dialogue=c.dialogue,offer=c.offer,patience=c.patience,state=c.state,color=c.color,deadline=c.deadline}
 end
 local p=s.profile
 local cols,rows=Grid.size(p)
 state:FireClient(player,{cash=p.cash,day=p.day,inventory=inventory,customer=customer,
  capacity=Rules.capacity(p),gridColumns=cols,gridRows=rows,gridUsed=Grid.used(p),gridRevision=p.gridRevision,moveAck=moveAck,moveOk=moveOk,bill=Rules.bill(p),rent=Config.Rent+p.upgrade*5,operating=Config.OperatingCost,
  reputation=p.reputation,upgrade=p.upgrade,legacyRows=p.legacyRows,revenue=p.revenue,costs=p.costs,profit=p.tradeProfit,
  visits=p.visits,maxVisits=Config.VisitsPerDay,aidDay=p.aidDay,origin=s.origin,stageName=s.stage.Name,
  saveStatus=s.saveStatus,message=message,receipts=p.receipts,pendingArrival=s.pendingArrival,working=s.working})
end
local schedule: (Player)->()
local function leave(player: Player,message: string,line: string?,callNext: boolean?)
 local s=sessions[player]
 if not s or s.closed or not s.customer then return end
 local c=s.customer; c.dialogue=line or "See you another time.";c.state="Leave";c.basket={};c.basketRevision+=1;c.quote=nil; push(player,message)
 task.delay(Config.WalkSeconds,function()
  if sessions[player]~=s or s.closed or s.customer~=c then return end
  s.customer=nil; push(player); if callNext then schedule(player) end
 end)
end
schedule=function(player: Player)
 local s=sessions[player]
 if not s or s.closed or s.working or s.customer or s.pendingArrival
  then return end
 s.pendingArrival=true; local epoch=s.epoch; push(player)
 task.delay(Config.ArrivalSeconds,function()
  if sessions[player]~=s or s.closed or s.epoch~=epoch then return end
  s.pendingArrival=false
  if s.customer then push(player); return end
  local c=Customers.create(s.profile,Rules,rng)
  if c.mode=="Seller" and rng:NextNumber()<Tags.BulkSellerChance then
   c.bulkPercent=rng:NextInteger(Tags.BulkDiscountMin,Tags.BulkDiscountMax)
   c.dialogue="I brought a planetary mineral haul. Buy the whole batch and I'll take "..c.bulkPercent.."% off."
  end
  local display={inventory={},upgrade=0,legacyRows=0}
  local repeats: {[string]: number}={}
  local supplyCount=if c.mode=="Seller" then rng:NextInteger(4,10) else 0
  for _=1,supplyCount do
   local total=0
   for _,kind in ipairs(Items.Order) do if (repeats[kind] or 0)<9 then total+=Tags.RarityWeights[Items.Definitions[kind].rarity] end end
   local roll=rng:NextInteger(1,total);local kind=Items.Order[1]
   for _,candidate in ipairs(Items.Order) do
    if (repeats[candidate] or 0)<9 then
     roll-=Tags.RarityWeights[Items.Definitions[candidate].rarity]
     if roll<=0 then kind=candidate;break end
    end
   end
   repeats[kind]=(repeats[kind] or 0)+1
   local entry=makeOffer(kind,s.profile);local x,y,rotation=TrayGrid.firstFit(display,kind)
   if x==nil then break end
   entry.item.gridX=x;entry.item.gridY=y;entry.item.rotation=rotation
   table.insert(display.inventory,entry.item);table.insert(c.goods,entry)
  end
  s.customer=c; s.profile.visits+=1
  push(player,"A customer is approaching the counter.")
  task.delay(Config.WalkSeconds,function()
   if sessions[player]~=s or s.closed or s.customer~=c or c.state~="WalkToCounter" then return end
   c.state="Interact";push(player)
  end)
 end)
end
local function matchingCustomer(s: any,request: any): any
 local c=s.customer
 if c and c.id==request.customerId and c.state=="Interact" then return c end
 return nil
end
action.OnServerEvent:Connect(function(player: Player,request: any)
 local s=sessions[player]
 if not s or s.closed or type(request)~="table" or type(request.action)~="string" or #request.action>20 then return end
 local now=os.clock()
 s.tokens=math.min(Config.RequestBurst,s.tokens+(now-s.lastRequest)*Config.RequestRate); s.lastRequest=now
 if s.tokens<1 then return end
 s.tokens-=1
 if not Persistence.safe(player.UserId) then
  s.closed=true; player:Kick("Your save session expired. Rejoin to safely reopen your shop."); return
 end
 local name=request.action
 if name=="Sync" then push(player); return end
 if name=="NextCustomer" then
  if s.working then push(player,"Freight shift active.");return end
  if s.customer then
   if s.customer.state~="Leave" then leave(player,"",nil,true) end
  else schedule(player) end
  return
 end
 if name=="PlaceItem" then
  if not Rules.integer(request.moveId,1,1000000000) then push(player,"Invalid move request."); return end
  local ok,message=Rules.move(s.profile,request.id,request.x,request.y,request.rotation,request.revision)
  if ok and s.customer then s.customer.quote=nil end
  push(player,message,request.moveId,ok); return
 end
 if name=="SetItemTag" then
  local ok,message=Rules.setItemTag(s.profile,request.id,request.qualityTag)
  if ok and s.customer then
   s.customer.quote=nil
   if s.customer.itemId==request.id then
    local item=Rules.find(s.profile,request.id)
    local value=Rules.value(item)
    s.customer.offer=math.max(1,math.floor(value*0.86))
    s.customer.budget=if s.customer.mode=="Buyer" then Rules.categoryBudget(s.customer.requestTag) else math.floor(value*1.35+math.max(0,s.profile.reputation)*2)
   end
  end
  push(player,message);return
 end
 if s.working then push(player,"Freight shift active."); return end
 if name=="DismissCustomer" then
  local c=matchingCustomer(s,request)
  if c then leave(player,"Customer dismissed.") else push(player,"No customer to dismiss.") end
  return
 end
 if name=="StageOffer" or name=="UnstageOffer" or name=="StageStock" or name=="UnstageStock" then
  if not Rules.integer(request.moveId,1,1000000000) then push(player,"Invalid drag request.");return end
  local c=matchingCustomer(s,request)
  if not c then push(player,"That visitor is no longer trading.",request.moveId,false);return end
  local ok,message
  if name=="StageOffer" then ok,message=Trade.stage(c,request.id,request.x,request.y,request.rotation,request.revision)
  elseif name=="UnstageOffer" then ok,message=Trade.unstage(c,request.id,request.revision)
  elseif name=="StageStock" then ok,message=Trade.stageStock(s.profile,c,request.id,request.x,request.y,request.rotation,request.revision)
  else ok,message=Trade.unstageStock(c,request.id,request.revision) end
  if ok and #c.basket>0 then ok,message=if c.mode=="Buyer" then Trade.reviewSale(s.profile,c,Http:GenerateGUID(false)) else Trade.review(s.profile,c,Http:GenerateGUID(false)) end
  push(player,message,request.moveId,ok);return
 elseif name=="ClearBasket" or name=="ReviewPurchase" or name=="ConfirmPurchase" or name=="BuyBulk" or name=="ReviewSale" or name=="ConfirmSale" then
  local c=matchingCustomer(s,request)
  if not c then push(player,"That visitor is no longer trading.");return end
  local ok,message
  if name=="ClearBasket" then ok,message=Trade.clear(c)
  elseif name=="ReviewPurchase" then ok,message=Trade.review(s.profile,c,Http:GenerateGUID(false))
  elseif name=="BuyBulk" then ok,message=Trade.buyBulk(s.profile,c,Http:GenerateGUID(false));if ok then leave(player,message,"The whole haul is yours.");return end
  elseif name=="ReviewSale" then ok,message=Trade.reviewSale(s.profile,c,Http:GenerateGUID(false))
  elseif name=="ConfirmSale" then ok,message=Trade.confirmSale(s.profile,c,request.quoteId);if ok then leave(player,message,"I'll take these ores. Pleasure trading.");return end
  else ok,message=Trade.confirm(s.profile,c,request.quoteId);if ok then leave(player,message,"Deal. These goods are yours.");return end end
  push(player,message);return
 elseif name=="InspectGoods" then
  local c=matchingCustomer(s,request)
  if not c then push(player,"No visitor at the window.");return end
  for _,entry in ipairs(c.goods) do
   if entry.item.id==request.id then entry.item.inspected=true;push(player,"Visitor's merchandise inspected.");return end
  end
  push(player,"This item is not offered by the current visitor.");return
 end
 local ok,message=false,"That action is unavailable."
 local id=request.id
 if name=="Inspect" and type(id)=="string" and #id<=80 then ok,message=Rules.inspect(s.profile,id)
 elseif name=="Accept" or name=="Counter" then
  local c=matchingCustomer(s,request)
  if c then
   local selectedId=if type(request.id)=="string" then request.id else c.itemId
   local item=Rules.find(s.profile,selectedId)
   if item and Rules.matches(c,item) then
    if item.id~=c.itemId then
     c.itemId=item.id;c.kind=item.kind
     local value=Rules.value(item);c.offer=math.max(1,math.floor(value*0.86));c.budget=if c.mode=="Buyer" then Rules.categoryBudget(c.requestTag) else math.floor(value*1.35+math.max(0,s.profile.reputation)*2)
    end
    local price=c.offer; local exhausted=false
    if name=="Counter" then ok,message,exhausted=Rules.negotiate(s.profile,c,item,request.price);c.dialogue=message; price=request.price
    else ok=true end
    if ok then
     ok,message=Rules.sell(s.profile,c,item.id,price)
     if ok then leave(player,message,"Thanks, that is what I was looking for."); return end
    elseif exhausted then leave(player,message); return end
   end
  end
 elseif name=="Refuse" then
  if matchingCustomer(s,request) then leave(player,"You declined the deal."); return end
 elseif name=="EndDay" then
  if s.customer then message="Finish serving the current customer first."
  else
   ok,message=Rules.endDay(s.profile)
   if ok then
    s.epoch+=1; s.pendingArrival=false
   end
  end
 elseif name=="Work" then
  if s.customer or s.profile.cash>=Rules.bill(s.profile) then message="Freight work is available when bills are unaffordable and the counter is clear."
  else
   s.working=true; s.epoch+=1; s.pendingArrival=false
   push(player,"Freight shift active.")
   task.delay(10,function()
    if sessions[player]~=s or s.closed then return end
    s.working=false; s.profile.cash+=18; s.profile.revenue+=18; s.profile.tradeProfit+=18
    Rules.log(s.profile,"Freight shift income +18")
    push(player,"Freight shift complete. Earned 18 credits."); schedule(player)
   end)
   return
  end
 elseif name=="Aid" then ok,message=Rules.aid(s.profile)
 end
 push(player,message)
 if ok then schedule(player) end
end)
local function join(player: Player)
 if closing or sessions[player] or loading[player] then return end
 loading[player]=true
 local profile,status=Persistence.load(player.UserId,Rules)
 if not profile then loading[player]=nil;if player.Parent then player:Kick(status) end; return end
 loading[player]=nil
 if not player.Parent or closing then Persistence.save(player.UserId,profile,true); return end
 local slot=0
 while slots[slot] do slot+=1 end
 slots[slot]=true
 local origin=Vector3.new(slot*100,0,0)
 local stage=Scene.spawn(shopTemplate,workspace,origin,"Shop_"..player.UserId)
 sessions[player]={profile=profile,origin=origin,stage=stage,slot=slot,customer=nil,
  tokens=Config.RequestBurst,lastRequest=os.clock(),epoch=0,pendingArrival=false,
  saveStatus=status,closed=false,removing=false,working=false}
 push(player)
 schedule(player)
end
local function remove(player: Player)
 local s=sessions[player]
 if not s or s.removing then return end
 s.removing=true; s.closed=true; s.epoch+=1
 local ok,message=Persistence.save(player.UserId,s.profile,true)
 if not ok then warn("Latch Nine final save failed for "..player.UserId..": "..message) end
 s.stage:Destroy(); slots[s.slot]=nil; sessions[player]=nil
end
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(remove)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(join,player) end
task.spawn(function()
 while not closing do
  task.wait(Config.SaveInterval)
  for player,s in pairs(sessions) do
   if not s.closed then task.spawn(function()
    local ok,status=Persistence.save(player.UserId,s.profile,false)
    if sessions[player]~=s or s.closed then return end
    s.saveStatus=status; push(player)
    if not ok and not Persistence.safe(player.UserId) then
     s.closed=true; player:Kick("Save connection interrupted. Rejoin to protect your shop.")
    end
   end) end
  end
 end
end)
game:BindToClose(function()
 closing=true
 for player in pairs(sessions) do task.spawn(remove,player) end
 local deadline=os.clock()+25
 while (next(sessions) or next(loading)) and os.clock()<deadline do task.wait(0.1) end
end)
