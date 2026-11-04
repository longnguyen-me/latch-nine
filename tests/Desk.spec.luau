-- Actual drag controller + in-memory layout/input API doubles. Not an engine playtest.
local count=0
local function check(ok,name) assert(ok,name);count+=1;print("PASS desk UI: "..name) end
local function signal()
 local callbacks={};local event={}
 function event:Connect(fn) local entry={fn=fn,active=true};table.insert(callbacks,entry);return {Disconnect=function() entry.active=false end} end
 function event:Fire(...) for _,e in ipairs(callbacks) do if e.active then e.fn(...) end end end
 return event
end
local viewport={X=1200,Y=800}
local cursor={X=0,Y=0};local inset={X=0,Y=0}
local surfaceShift={X=431,Y=173}
local function v(x,y) return {X=x,Y=y} end
local function dim(a,b,c,d) return {X={Scale=a,Offset=b},Y={Scale=c,Offset=d}} end
local Enum=setmetatable({},{__index=function(_,name) return setmetatable({},{__index=function(_,value) return name.."."..value end}) end})
local Instance={}
function Instance.new(class)
 local data={ClassName=class,children={},events={},Activated=signal(),InputBegan=signal(),MouseEnter=signal(),MouseLeave=signal(),CanvasPosition=v(0,0),Visible=true}
 local obj={};local methods={}
 local function absoluteSize()
  if data.override then return data.override end
  if class=="ScreenGui" or class=="PlayerGui" then return viewport end
  if class=="SurfaceGui" then return data.CanvasSize or viewport end
  local parent=if data.Parent then data.Parent.AbsoluteSize else viewport
  local size=data.Size or dim(0,100,0,100)
  return v(size.X.Scale*parent.X+size.X.Offset,size.Y.Scale*parent.Y+size.Y.Offset)
 end
 setmetatable(obj,{__index=function(_,key)
  if methods[key] then return methods[key] end
  if key=="AbsoluteSize" then return absoluteSize() end
  if key=="AbsolutePosition" then
   if class=="SurfaceGui" then return surfaceShift end
   if not data.Parent then return v(0,0) end
   local p=data.Parent.AbsolutePosition;local size=data.Parent.AbsoluteSize;local pos=data.Position or dim(0,0,0,0)
   local scroll=if data.Parent.ClassName=="ScrollingFrame" then data.Parent.CanvasPosition else v(0,0)
   return v(p.X+size.X*pos.X.Scale+pos.X.Offset-scroll.X,p.Y+size.Y*pos.Y.Scale+pos.Y.Offset-scroll.Y)
  end
  return data[key]
 end,__newindex=function(_,key,value)
  if key=="AbsoluteSize" then data.override=value else data[key]=value end
  if key=="Parent" and value then table.insert(value.children,obj) end
  if data.events[key] then data.events[key]:Fire() end
 end})
 function methods:GetChildren() return table.clone(data.children) end
 function methods:IsA(kind) return class==kind or (kind=="GuiObject" and (class=="Frame" or class=="TextButton" or class=="TextLabel" or class=="ScrollingFrame")) end
 function methods:GetPropertyChangedSignal(key) if not data.events[key] then data.events[key]=signal() end;return data.events[key] end
 function methods:Destroy()
  for _,child in ipairs(table.clone(data.children)) do child:Destroy() end
  if data.Parent then for i,child in ipairs(data.Parent.children) do if child==obj then table.remove(data.Parent.children,i);break end end end
 end
 return obj
end
local clock=0;local queue={}
local taskMock={delay=function(t,fn) table.insert(queue,{at=clock+t,fn=fn}) end}
local function advance(t)
 local target=clock+t
 while true do
  table.sort(queue,function(a,b) return a.at<b.at end)
  if not queue[1] or queue[1].at>target then break end
  local event=table.remove(queue,1);clock=event.at;event.fn()
 end
 clock=target
end
local function load(name,env)
 local fn=assert(loadstring(Sources[name],name));setfenv(fn,setmetatable(env or {},{__index=getfenv()}));return fn()
end
local Tags=load("ItemTags");local Snap=load("GridSnap");local Config=load("Config");local Items=load("Items");local GridFactory=load("Grid")
local Grid=GridFactory(Config,Items.Definitions);local Rules=load("Rules")(Config,Items.Definitions,Grid,Tags)
local trayConfig=table.clone(Config);trayConfig.GridBaseRows=Config.TradeRows;trayConfig.GridColumns=Config.TradeColumns;trayConfig.GridRowsPerUpgrade=0
local Tray=GridFactory(trayConfig,Items.Definitions);local Trade=load("TradeService")(Config,Items.Definitions,Rules,Grid,Tray)
local profile=Rules.newProfile()
local function item(id,kind,x,y) return {id=id,kind=kind,gridX=x,gridY=y,rotation=0,paid=0,condition=100,authentic=true,restricted=false,inspected=false} end
local function customer(prefix)
 return {id=prefix,name="Mara Venn",faction="Dock Union",personality="Patient",patience=4,state="Interact",mode="Seller",basket={},basketRevision=0,
  goods={{item=item(prefix.."f","filter",0,0),price=24},{item=item(prefix.."s","servo",3,0),price=39},{item=item(prefix.."c","chip",6,0),price=58}}}
end
local c=customer("visitor1")
local playerGui=Instance.new("PlayerGui")
local Input={InputChanged=signal(),InputEnded=signal(),InputBegan=signal(),WindowFocusReleased=signal(),GetFocusedTextBox=function() return nil end,GetMouseLocation=function() return cursor end}
local services={Players={LocalPlayer={WaitForChild=function() return playerGui end}},UserInputService=Input,
 GuiService={GetGuiInset=function() return inset end},TweenService={Create=function(_,object,_,props) return {Play=function() for k,v in pairs(props) do object[k]=v end end,Cancel=function() end} end},
 ReplicatedStorage={WaitForChild=function() return {Config="Config",Items="Items",Grid="Grid",ItemTags="ItemTags",GridSnap="GridSnap"} end}}
local modules={Config=Config,Items=Items,Grid=GridFactory,ItemTags=Tags,GridSnap=Snap}
local boards={
 VisitorBoard={Name="VisitorBoard",Parent=true,rect={x=800,y=70,w=310,h=150}},
 BuyBoard={Name="BuyBoard",Parent=true,rect={x=800,y=290,w=310,h=150}},
 InventoryBoard={Name="InventoryBoard",Parent=true,rect={x=300,y=510,w=750,h=260}},
 RegisterBox={Name="RegisterBox",Parent=true,rect={x=40,y=320,w=160,h=100}},
 NextCustomerButton={Name="NextCustomerButton",Parent=true,rect={x=40,y=440,w=160,h=40}}}
for _,part in pairs(boards) do
 local r=part.rect;part.Size={X=r.w,Y=r.h,Z=0.35};part.CFrame={}
 function part.CFrame:PointToObjectSpace(p) return {X=p.X-r.x-r.w/2,Y=p.Y+r.y+r.h/2,Z=p.Z} end
 function part.CFrame:VectorToObjectSpace(p) return p end
 function part.CFrame:PointToWorldSpace(p) return {X=p.X+r.x+r.w/2,Y=p.Y-r.y-r.h/2,Z=p.Z} end
end
local camera={ViewportPointToRay=function(_,x,y) return {Origin={X=x,Y=-y,Z=10},Direction={X=0,Y=0,Z=-1}} end,
 WorldToViewportPoint=function(_,p) return {X=p.X,Y=-p.Y,Z=p.Z} end}
local env={workspace={CurrentCamera=camera,children={},GetChildren=function(self) return self.children end,FindFirstChild=function(_,name) if name=="Shop_Test" then return {FindFirstChild=function(_,key) return boards[key] end} end end},game={GetService=function(_,name) return services[name] end},require=function(name) return modules[name] end,
 Instance=Instance,Enum=Enum,Vector2={new=v,zero=v(0,0)},Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end},Color3={fromRGB=function(...) return {...} end},UDim={new=function(s,o) return {Scale=s,Offset=o} end},
 UDim2={new=dim,fromScale=function(a,b) return dim(a,0,b,0) end,fromOffset=function(a,b) return dim(0,a,0,b) end},TweenInfo={new=function(...) return {...} end},task=taskMock,script={Parent={GridWidget="GridWidget",SurfaceInput="SurfaceInput"}}}
modules.SurfaceInput=load("SurfaceInput",env)
modules.GridWidget=load("GridWidget",env)
local Controller=load("DeskController",env)
local requests={}
local desk=Controller.new(function(request) table.insert(requests,request) end)
local function snapshot(ack,ok)
 local rows=Config.GridBaseRows+profile.upgrade*2
 local basket={}
 for _,selected in ipairs(c.basket) do
  for _,entry in ipairs(if c.mode=="Buyer" then {{item=Rules.find(profile,selected.id)}} else c.goods) do if entry.item and entry.item.id==selected.id then
   local unit=table.clone(entry.item);unit.gridX=selected.gridX;unit.gridY=selected.gridY;unit.rotation=selected.rotation;table.insert(basket,unit)
  end end
 end
 local visitor=table.clone(c);visitor.basket=basket
 if c.quote then visitor.quote=table.clone(c.quote);visitor.quote.affordable=c.mode=="Buyer" or profile.cash>=c.quote.total end
 return {stageName="Shop_Test",cash=profile.cash,day=profile.day,bill=Rules.bill(profile),rent=18,operating=6,reputation=profile.reputation,profit=profile.tradeProfit,
  inventory=profile.inventory,capacity=15*rows,gridRows=rows,gridColumns=15,gridUsed=Grid.used(profile),gridRevision=profile.gridRevision,upgrade=profile.upgrade,
  legacyRows=0,customer=visitor,visits=1,maxVisits=5,aidDay=profile.aidDay,saveStatus="TEST SAVE",
  receipts=profile.receipts,moveAck=ack,moveOk=ok}
end
local function find(predicate,node)
 node=node or playerGui;if predicate(node) then return node end
 for _,child in ipairs(node:GetChildren()) do local found=find(predicate,child);if found then return found end end
end
local function named(name,node) return assert(find(function(obj) return obj.Name==name end,node) or find(function(obj) return obj.Name==name end,env.workspace),name) end
local function button(prefix)
 return assert(find(function(obj) return obj.ClassName=="TextButton" and type(obj.Text)=="string" and obj.Text:sub(1,#prefix)==prefix end),prefix)
end
local function widget(name) return named(if name=="offers" then "01 / VISITOR OFFERS" elseif name=="basket" then "02 / TO BUY" else "03 / YOUR INVENTORY") end
local function unit(name,id) return named("Hit",named("Item_"..id,widget(name))) end
local function point(name,x,y)
 local b=named("GridBoard",widget(name));local size=b.Size.X.Offset/(if name=="inventory" then 15 else 12);local p={X=b.Position.X.Offset,Y=b.Position.Y.Offset-b.Parent.CanvasPosition.Y}
 local layer=widget(name).Parent.Parent;local r=layer.Adornee.rect
 return {X=r.x+(p.X+(x+0.5)*size)/layer.CanvasSize.X*r.w,Y=r.y+(p.Y+(y+0.5)*size)/layer.CanvasSize.Y*r.h,Z=0}
end
local function mouse(pos) cursor=pos;return {UserInputType=Enum.UserInputType.MouseButton1,Position=pos} end
local function move(pos) cursor=pos;Input.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=pos}) end
local function release(pos) Input.InputEnded:Fire(mouse(pos)) end
local function stageAck()
 local req=requests[#requests];local ok,message=if c.mode=="Buyer" then Trade.stageStock(profile,c,req.id,req.x,req.y,req.rotation,req.revision) else Trade.stage(c,req.id,req.x,req.y,req.rotation,req.revision)
 if ok then if c.mode=="Buyer" then Trade.reviewSale(profile,c,"quote"..req.moveId) else Trade.review(profile,c,"quote"..req.moveId) end end
 desk.render(snapshot(req.moveId,ok));return ok
end
desk.render(snapshot())
check(widget("offers").Parent.Parent.Adornee==boards.VisitorBoard and widget("basket").Parent.Parent.Adornee==boards.BuyBoard and widget("inventory").Parent.Parent.Adornee==boards.InventoryBoard,"three grids bind to their physical surfaces")
check(named("GridBoard",widget("inventory")).AbsolutePosition.X~=named("GridBoard",widget("inventory")).Position.X.Offset,"test supplies non-canvas absolute positions to surface objects")
check(button("NEXT CUSTOMER").Parent==named("nextSurface").children[1] and named("nextSurface").Adornee==boards.NextCustomerButton,"Next Customer is mounted on the physical button")
check(not named("Receipt").Visible,"receipt starts hidden")
local reg=named("RegisterButton")
reg.MouseEnter:Fire();check(named("RegisterOutline").Enabled and named("RegisterOutline").Adornee==boards.RegisterBox,"hover outlines the physical register")
reg.MouseLeave:Fire();check(not named("RegisterOutline").Enabled,"register outline clears on hover exit")
reg.Activated:Fire();check(named("Receipt").Visible,"register click opens the receipt")
local receipt=named("Receipt");local handle=named("ReceiptHandle");local old=receipt.AbsolutePosition
handle.InputBegan:Fire(mouse({X=old.X+10,Y=old.Y+10,Z=0}));move({X=old.X+110,Y=old.Y+50,Z=0});release({X=old.X+110,Y=old.Y+50,Z=0})
check(receipt.AbsolutePosition.X==old.X+100 and receipt.AbsolutePosition.Y==old.Y+40,"receipt handle drags the window")
local touchHandle={UserInputType=Enum.UserInputType.Touch,Position={X=receipt.AbsolutePosition.X+10,Y=receipt.AbsolutePosition.Y+10,Z=0}}
old=receipt.AbsolutePosition;handle.InputBegan:Fire(touchHandle)
Input.InputChanged:Fire({UserInputType=Enum.UserInputType.Touch,Position={X=800,Y=800,Z=0}})
check(receipt.AbsolutePosition.X==old.X and receipt.AbsolutePosition.Y==old.Y,"another finger cannot hijack the receipt handle")
touchHandle.Position={X=old.X+60,Y=old.Y+30,Z=0};Input.InputChanged:Fire(touchHandle);Input.InputEnded:Fire(touchHandle)
check(receipt.AbsolutePosition.X==old.X+50 and receipt.AbsolutePosition.Y==old.Y+20,"receipt also moves with its owning touch pointer")
button("X").Activated:Fire();check(not receipt.Visible,"receipt close button hides it")
check(not find(function(o) return o.Name=="LabelBoard" end),"booth label board and editor are absent")
check(not find(function(o) return o.ClassName=="TextButton" and o.Text and o.Text:find("ROTATE") end),"rotation GUI removed")
check(not find(function(o) return o.ClassName=="TextButton" and type(o.Text)=="string" and (o.Text:find("INSPECT") or o.Text:find("BOOTH") or o.Text:find("RENT") or o.Text:find("EXPAND")) end),"removed controls are absent")
check(named("GridBoard",widget("inventory")).AbsoluteSize.X/15==named("GridBoard",widget("inventory")).AbsoluteSize.Y/7,"inventory has exactly 15 columns and 7 rows")
unit("offers",c.goods[1].item.id).MouseEnter:Fire(800,160)
check(named("ItemTooltip").Visible and named("ItemTooltip").Active==false and find(function(o) return o.Text=="Water filter" end,named("ItemTooltip")) and find(function(o) return o.Text=="24 CR" end,named("ItemTooltip")) and find(function(o) return o.Text and o.Text:find("Household good") end,named("ItemTooltip")),"hover card separates title, price and tags")
check(named("TooltipDivider",named("ItemTooltip")).AbsoluteSize.Y==1,"hover card has a visible divider")
unit("offers",c.goods[1].item.id).MouseLeave:Fire(801,160)
check(not named("ItemTooltip").Visible,"hover details disappear immediately on leave")
local buy=named("BuyButton");local lines=named("ReceiptLines")
check(lines.AbsolutePosition.Y+lines.AbsoluteSize.Y<=buy.AbsolutePosition.Y,"scrolling receipt text cannot cover purchase button")
button("NEXT CUSTOMER").Activated:Fire();check(requests[#requests].action=="NextCustomer","next customer button is connected")
check(not find(function(o) return o.ClassName=="TextLabel" and type(o.Text)=="string" and (o.Text:find("Drag ") or o.Text:find("Press ") or o.Text:find("Top:")) end),"instructional guide text is absent")
check(not find(function(o) return o.ClassName=="TextLabel" and type(o.Text)=="string" and (o.Text:find("160 cr") or o.Text:find("CASH")) end),"balance is not drawn in the screen HUD")
local start=point("offers",0,0);local before=0
-- GUI MouseButton1 objects may report old/inset-adjusted positions; live cursor wins.
local sourcePoint=point("offers",0,0);local stale=mouse(sourcePoint)
stale.Position={X=sourcePoint.X,Y=sourcePoint.Y-36,Z=0}
unit("offers",c.goods[1].item.id).InputBegan:Fire(stale);move(point("basket",0,0))
local heldPreview=named("TradeDragPreview")
check(named("GridPhantom",widget("basket")).Position.X.Offset==0 and named("GridPhantom",widget("basket")).Position.Y.Offset==0,"canvas bounds project onto buy grid despite non-canvas absolute positions and stale GUI input")
local projectedTarget=point("basket",0,0)
check(math.abs(heldPreview.Position.X.Offset-(projectedTarget.X-12))<0.001 and math.abs(heldPreview.Position.Y.Offset-(projectedTarget.Y-12))<0.001,"held preview keeps the grabbed point using projected 24 pixel cells")
Input.InputEnded:Fire(stale)
check(requests[#requests].action=="StageOffer" and requests[#requests].x==0 and requests[#requests].y==0 and stageAck(),"stale button release position still drops at the live cursor")
Trade.clear(c);desk.render(snapshot())
inset=v(0,36)
local touchStart=point("offers",0,0);local touchDrop=point("basket",0,0)
local insetTouch={UserInputType=Enum.UserInputType.Touch,Position={X=touchStart.X,Y=touchStart.Y-36,Z=0}}
unit("offers",c.goods[1].item.id).InputBegan:Fire(insetTouch)
insetTouch.Position={X=touchDrop.X,Y=touchDrop.Y-36,Z=0};Input.InputChanged:Fire(insetTouch)
check(named("GridPhantom",widget("basket")).Position.Y.Offset==0,"touch inset is normalized before world projection")
Input.InputEnded:Fire(insetTouch);assert(stageAck());Trade.clear(c);desk.render(snapshot());inset=v(0,0)
before=#requests
unit("offers",c.goods[1].item.id).InputBegan:Fire(mouse(start))
move({X=start.X+2,Y=start.Y+1,Z=0});release({X=start.X+2,Y=start.Y+1,Z=0})
check(#requests==before and not find(function(o) return o.Name=="GridPhantom" end),"small click movement does not start a drag")
unit("offers",c.goods[1].item.id).InputBegan:Fire(mouse(point("offers",0,0)));move(point("basket",0,0))
local phantom=named("GridPhantom",widget("basket"));local px,py=phantom.Position.X.Offset,phantom.Position.Y.Offset
check(phantom.Parent==named("GridBoard",widget("basket")) and px==0 and py==0,"phantom is projected as a child of the actual destination grid")
check(phantom.children[1].children[1].BackgroundColor3[1]==111,"valid snapped phantom uses the accepted placement color")
release(point("basket",0,0));local req=requests[#requests]
check(req.action=="StageOffer" and req.x==0 and req.y==0 and profile.cash==160,"drop submits the exact phantom cells without spending")
check(not find(function(o) return o.Name=="GridPhantom" end) and stageAck(),"phantom cleans up before server confirmation")
check(button("BUY / 24")~=nil and not named("Receipt").Visible,"staging goods never opens the receipt automatically")
-- Grab the second chip cell: its one-cell anchor offset must be retained.
unit("offers",c.goods[3].item.id).InputBegan:Fire(mouse(point("offers",7,0)));move(point("basket",4,0))
phantom=named("GridPhantom",widget("basket"));local cell=named("GridBoard",widget("basket")).AbsoluteSize.X/12
check(phantom.Position.X.Offset==3*cell,"grabbing another occupied cell preserves the full item anchor")
release(point("basket",4,0));check(requests[#requests].x==3 and stageAck() and c.quote.total==82,"multi-item quote uses the projected chip position")
reg.Activated:Fire();check(named("Receipt").Visible,"register opens the latest multi-item quote")
local firstLine=named("ReceiptItem_1",named("ReceiptLines"));local secondLine=named("ReceiptItem_2",named("ReceiptLines"))
check(firstLine.Size.Y.Offset==52 and secondLine.Size.Y.Offset==52 and find(function(o) return o.Text=="24 CR" end,firstLine) and find(function(o) return o.Text=="58 CR" end,secondLine),"receipt gives each quoted item its own fixed-height row and price")
button("BUY / 82").Activated:Fire();req=requests[#requests];assert(Trade.confirm(profile,c,req.quoteId));c.state="Leave";desk.render(snapshot())
check(#profile.inventory==2 and profile.cash==78 and not named("Receipt").Visible,"confirmed merchandise appears in bottom storage")
unit("inventory",profile.inventory[1].id).InputBegan:Fire(mouse(point("inventory",0,0)));release(point("inventory",0,0))
button("High tier /").Activated:Fire();req=requests[#requests]
check(req.action=="SetItemTag" and req.id==profile.inventory[1].id and req.qualityTag=="high","quality tag selector targets the selected owned unit")
assert(Rules.setItemTag(profile,req.id,req.qualityTag));desk.render(snapshot())
check(find(function(o) return o.Name=="QualityTag" and o.Text=="HQ" end,widget("inventory"))~=nil,"quality badge is physically attached to the inventory item cell")
check(not find(function(o) return o.Name=="ItemReport" end),"fixed inspection panel is absent")
unit("inventory",profile.inventory[1].id).InputBegan:Fire(mouse(point("inventory",0,0)));move(point("inventory",3,3))
Input.InputBegan:Fire({KeyCode=Enum.KeyCode.R},false);release(point("inventory",3,3));req=requests[#requests]
check(req.action=="PlaceItem" and req.y==3 and req.rotation==1,"R rotates the held item and preserves snapped placement")
Rules.move(profile,req.id,req.x,req.y,req.rotation,req.revision);desk.render(snapshot(req.moveId,true))
c=customer("visitor2");desk.render(snapshot())
local touch={UserInputType=Enum.UserInputType.Touch,Position=point("offers",6,0)}
unit("offers",c.goods[3].item.id).InputBegan:Fire(touch)
local second={UserInputType=Enum.UserInputType.Touch,Position=point("basket",4,0)}
Input.InputChanged:Fire(second);Input.InputEnded:Fire(second)
check(not find(function(o) return o.Name=="GridPhantom" end),"another finger cannot move or end the active touch")
touch.Position=point("basket",6,0);Input.InputChanged:Fire(touch)
check(named("GridPhantom",widget("basket")).Position.X.Offset==6*named("GridBoard",widget("basket")).AbsoluteSize.X/12,"touch shows the same snapped destination phantom")
Input.InputBegan:Fire({KeyCode=Enum.KeyCode.R},false)
local held=named("TradeDragPreview").children[1]
check(held.AbsoluteSize.Y==2*held.AbsoluteSize.X,"R turns a held 2 by 1 chip into 1 by 2")
for i=1,3 do Input.InputBegan:Fire({KeyCode=Enum.KeyCode.R},false) end
check(named("GridPhantom",widget("basket")).Position.X.Offset==6*named("GridBoard",widget("basket")).AbsoluteSize.X/12,"four touch rotations restore the original grab anchor")
Input.InputEnded:Fire(touch);check(requests[#requests].rotation==0 and stageAck(),"touch placement works after keyboard rotation")

unit("basket",c.goods[3].item.id).InputBegan:Fire(mouse(point("basket",6,0)));move(point("offers",6,0));release(point("offers",6,0))
req=requests[#requests];check(req.action=="UnstageOffer","middle-to-top drag returns selected goods")
Trade.unstage(c,req.id,req.revision);desk.render(snapshot(req.moveId,true))
before=#requests
unit("offers",c.goods[1].item.id).InputBegan:Fire(mouse(point("offers",0,0)));move({X=0,Y=0,Z=0})
check(not find(function(o) return o.Name=="GridPhantom" end),"phantom hides when the cursor leaves all grids")
release({X=0,Y=0,Z=0});check(#requests==before,"outside release restores the source without sending a mutation")
unit("offers",c.goods[1].item.id).InputBegan:Fire(mouse(point("offers",0,0)));move(point("basket",0,0));Input.WindowFocusReleased:Fire()
check(not find(function(o) return o.Name=="GridPhantom" end) and not named("TradeDragPreview").Visible,"focus loss clears both cursor and grid previews")
local root=named("DeskRoot");viewport=v(390,844);root.AbsoluteSize=viewport
check(widget("offers").Parent.Parent.Enabled and widget("basket").Parent.Parent.Enabled and widget("inventory").Parent.Parent.Enabled,"portrait keeps all physical surfaces bound")
reg.Activated:Fire();check(receipt.AbsolutePosition.X>=0 and receipt.AbsolutePosition.X+receipt.AbsoluteSize.X<=390,"moved receipt clamps inside portrait viewport")
check(not widget("offers").children[2].Visible and not widget("basket").children[2].Visible and not widget("inventory").children[2].Visible,"surface grids display without numbered title bars")
viewport=v(1200,800);root.AbsoluteSize=viewport
c={id="oreBuyer",name="Rin",faction="Miners",mode="Buyer",requestTag="household",budget=1000,state="Interact",goods={},basket={},basketRevision=0,quote=nil,itemId=nil,dialogue="I'm looking for household goods."}
desk.render(snapshot())
local ownedUnit=profile.inventory[1];local originPoint=point("inventory",ownedUnit.gridX,ownedUnit.gridY)
unit("inventory",ownedUnit.id).InputBegan:Fire(mouse(originPoint));move(point("basket",0,0))
check(named("GridPhantom",widget("basket")).Position.X.Offset==0,"owned merchandise projects into shared buy/sell tray")
release(point("basket",0,0));local saleReq=requests[#requests]
check(saleReq.action=="StageStock" and saleReq.x==0 and stageAck(),"inventory-to-middle drag stages a buyer sale")
unit("basket",ownedUnit.id).MouseEnter:Fire(850,380)
check(named("ItemTooltip").Visible and find(function(o) return o.Text=="Water filter" end,named("ItemTooltip")),"staged buyer stock retains its hover details")
unit("basket",ownedUnit.id).MouseLeave:Fire(850,380)
check(not find(function(o) return o.Name=="Item_"..ownedUnit.id end,widget("inventory")) and find(function(o) return o.Name=="Item_"..ownedUnit.id end,widget("basket")),"staged stock moves visually from inventory to middle tray")
reg.Activated:Fire();check(button("SELL /")~=nil and receipt.Visible,"register presents a sell receipt for the buyer")
button("SELL /").Activated:Fire();saleReq=requests[#requests]
check(saleReq.action=="ConfirmSale" and saleReq.quoteId==c.quote.id,"receipt submits current server sale quote")
print(count.." seller-desk interaction checks passed")
