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
local Tray=GridFactory(trayConfig,Items.Definitions);local Trade=load("TradeService")(Config,Items.Definitions,Rules,Grid,Tray,load("Wallet"))
local profile=Rules.newProfile()
local function item(id,kind,x,y) return {id=id,kind=kind,gridX=x,gridY=y,rotation=0,paid=0,condition=100,authentic=true,restricted=false,inspected=false} end
local function customer(prefix)
 return {id=prefix,name="Mara Venn",faction="Dock Union",personality="Patient",patience=4,state="Interact",mode="Seller",basket={},basketRevision=0,
  goods={{item=item(prefix.."f","filter",0,0),price=24},{item=item(prefix.."s","servo",3,0),price=39},{item=item(prefix.."c","chip",6,0),price=58}}}
end
local c=customer("visitor1");c.bulkPercent=10;c.bulkOriginal=121;c.bulkPrice=108
local playerGui=Instance.new("PlayerGui")
local Input={InputChanged=signal(),InputEnded=signal(),InputBegan=signal(),WindowFocusReleased=signal(),GetFocusedTextBox=function() return nil end,GetMouseLocation=function() return cursor end}
local services={Players={LocalPlayer={WaitForChild=function() return playerGui end}},UserInputService=Input,
 GuiService={GetGuiInset=function() return inset end},TweenService={Create=function(_,object,_,props) return {Play=function() for k,v in pairs(props) do object[k]=v end end,Cancel=function() end} end},
 ReplicatedStorage={WaitForChild=function() return {Config="Config",Items="Items",Grid="Grid",ItemTags="ItemTags",GridSnap="GridSnap",Wallet="Wallet"} end}}
local modules={Config=Config,Items=Items,Grid=GridFactory,ItemTags=Tags,GridSnap=Snap,Wallet=load("Wallet")}
local boards={
 VisitorBoard={Name="VisitorBoard",Parent=true,rect={x=800,y=70,w=310,h=150}},
 BuyBoard={Name="BuyBoard",Parent=true,rect={x=800,y=290,w=310,h=150}},
 InventoryBoard={Name="InventoryBoard",Parent=true,rect={x=300,y=510,w=750,h=260}},
 RegisterBox={Name="RegisterBox",Parent=true,rect={x=40,y=320,w=160,h=100}},
 NextCustomerButton={Name="NextCustomerButton",Parent=true,rect={x=40,y=440,w=160,h=40}},
 DismissCustomerButton={Name="DismissCustomerButton",Parent=true,rect={x=40,y=480,w=160,h=40}}}
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
local function find(name,node)
 if node.Name==name then return node end
 for _,child in ipairs(node:GetChildren()) do local result=find(name,child);if result then return result end end
 return nil
end
local base={stageName="Shop_Test",cash=160,suspicion=0,inventory=profile.inventory,gridRows=7,gridColumns=15,gridRevision=0,shopOpen=false,walletTier=0,walletSlots={},walletStacks=load("Wallet").stacks(160,0),receipts={}}
desk.render(base)
assert(find("GridBoard",playerGui) and find("Item_starter-wallet",playerGui),"stock grid did not render")
local arrival=table.clone(base)
arrival.customer={id="visitor-1",name="Mara Venn",faction="Dock Union",state="Interact",mode="Seller",dialogue="I have stock to sell.",goods={{item={id="offer-1",kind="blank1",gridX=0,gridY=0,rotation=0,qualityTag="standard",marketPrice=10},price=8}},basket={},basketRevision=0,color={86,181,177}}
desk.render(arrival)
assert(find("VisitorDialogue",playerGui).Visible and find("Item_offer-1",playerGui),"visitor board or dialogue did not render")
local function boardPoint(name,x,y,cols)
 local board=find("GridBoard",find(name,playerGui));local size=board.Size.X.Offset/cols
 local part=boards[if name=="03 / YOUR INVENTORY" then "InventoryBoard" else "VisitorBoard"]
 local layer=find(name,playerGui).Parent.Parent
 return {X=part.rect.x+(board.Position.X.Offset+(x+0.5)*size)/layer.CanvasSize.X*part.rect.w,
  Y=part.rect.y+(board.Position.Y.Offset+(y+0.5)*size)/layer.CanvasSize.Y*part.rect.h}
end
local staged=table.clone(arrival)
staged.customer=table.clone(arrival.customer)
staged.customer.basket={{id="offer-1",kind="blank1",gridX=0,gridY=0,rotation=0,stockX=3,stockY=0,stockRotation=0,qualityTag="standard"}}
staged.customer.basketRevision=1
desk.render(staged)
local pendingView=find("Item_offer-1",find("03 / YOUR INVENTORY",playerGui))
assert(pendingView,"staged purchase preview missing")
local start=boardPoint("03 / YOUR INVENTORY",3,0,15)
local target=boardPoint("01 / VISITOR OFFERS",0,0,12)
cursor=start
find("Hit",pendingView).InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=start})
cursor=target;Input.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=target})
Input.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=target})
assert(requests[#requests] and requests[#requests].action=="UnstageOffer","dragging preview back did not cancel purchase")
local printer={id="printer-test",kind="printer1",gridX=5,gridY=0,rotation=0,qualityTag="standard",condition=100,paid=0,authentic=true,restricted=false,inspected=false}
local withPrinter=table.clone(base);withPrinter.inventory={profile.inventory[1],printer};withPrinter.moveAck=requests[#requests].moveId;desk.render(withPrinter)
local printerView=find("Item_printer-test",find("03 / YOUR INVENTORY",playerGui));assert(printerView)
local pos=boardPoint("03 / YOUR INVENTORY",5,0,15);cursor=pos
find("Hit",printerView).InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=pos})
Input.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=pos})
find("Hit",printerView).InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=pos})
assert(find("MachineMenu",playerGui).Visible,"double click did not open printer menu")
local function center(node)
 local p,b=node.AbsolutePosition,node.AbsoluteSize
 return v(p.X+b.X/2,p.Y+b.Y/2)
end
local menu=find("MachineMenu",playerGui)
local title=find("MachineHandle",menu)
local menuStart=center(title);cursor=menuStart
title.InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=menuStart})
cursor=v(menuStart.X+24,menuStart.Y+15);Input.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=cursor})
Input.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=cursor})
assert(menu.Position.X.Offset>0,"printer menu title did not drag")
local press=item("press-test","mintPress",12,0);press.qualityTag="standard"
local paper=item("paper-test","paperlow",13,0);paper.qualityTag="standard"
local testState=table.clone(withPrinter);testState.inventory={profile.inventory[1],printer,press,paper};desk.render(testState)
local pressStart=boardPoint("03 / YOUR INVENTORY",12,0,15)
local pressTarget=center(find("pressGrid",menu))
cursor=pressStart;find("Hit",find("Item_press-test",find("03 / YOUR INVENTORY",playerGui))).InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=pressStart})
cursor=pressTarget;Input.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=pressTarget})
assert(find("MachinePhantom",menu).Visible,"Mint Press has no slot preview")
Input.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=pressTarget})
assert(requests[#requests].action=="MachineInsert" and requests[#requests].slot=="press" and requests[#requests].id=="press-test","Mint Press drop did not reach press slot")
local ack=table.clone(testState);ack.moveAck=requests[#requests].moveId;desk.render(ack)
local paperStart=boardPoint("03 / YOUR INVENTORY",13,0,15)
local paperTarget=center(find("inputGrid",menu))
cursor=paperStart;find("Hit",find("Item_paper-test",find("03 / YOUR INVENTORY",playerGui))).InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=paperStart})
cursor=paperTarget;Input.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=paperTarget})
assert(find("MachinePhantom",menu).Visible,"paper has no input preview")
Input.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=paperTarget})
assert(requests[#requests].action=="MachineInsert" and requests[#requests].slot=="input","paper drop did not reach input grid")
local moved=table.clone(testState);moved.moveAck=requests[#requests].moveId
local loadedPrinter=table.clone(printer);loadedPrinter.machine={input={{id="paper-loaded",kind="paperlow",machineX=0,machineY=0,rotation=0,qualityTag="standard"}},output={},press={id="press-loaded",kind="mintPress",rotation=0,qualityTag="standard"}}
moved.inventory={profile.inventory[1],loadedPrinter,press,paper};desk.render(moved)
local loadedView=find("Item_paper-loaded",find("inputGrid",menu));assert(loadedView,"machine input item missing")
local inputBoard=find("GridBoard",find("inputGrid",menu));local cell=inputBoard.Size.X.Offset
local from=center(loadedView);local to=v(from.X,from.Y+cell)
cursor=from;find("Hit",loadedView).InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=from})
cursor=to;Input.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=to})
assert(find("MachinePhantom",menu).Visible,"moving paper inside printer has no preview")
Input.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=to})
assert(requests[#requests].action=="MachineMove" and requests[#requests].y==1,"printer input does not rearrange")
find("MachineClose",menu).Activated:Fire()
local closed=table.clone(testState);closed.moveAck=requests[#requests].moveId
local cash=item("cash-test","cash100",14,0);cash.qualityTag="standard"
closed.inventory={profile.inventory[1],printer,press,paper,cash};desk.render(closed)
local closedPaperStart=boardPoint("03 / YOUR INVENTORY",13,0,15);local closedPrinterTarget=boardPoint("03 / YOUR INVENTORY",5,0,15)
cursor=closedPaperStart;find("Hit",find("Item_paper-test",find("03 / YOUR INVENTORY",playerGui))).InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=closedPaperStart})
cursor=closedPrinterTarget;Input.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=closedPrinterTarget})
Input.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=closedPrinterTarget})
assert(requests[#requests].action=="MachineInsert" and requests[#requests].machineId=="printer-test" and requests[#requests].slot=="input","closed printer rejected paper")
closed.moveAck=requests[#requests].moveId;desk.render(closed)
local cashStart=boardPoint("03 / YOUR INVENTORY",14,0,15);local walletTarget=boardPoint("03 / YOUR INVENTORY",0,0,15)
cursor=cashStart;find("Hit",find("Item_cash-test",find("03 / YOUR INVENTORY",playerGui))).InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=cashStart})
cursor=walletTarget;Input.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=walletTarget})
assert(find("GridPhantom",find("03 / YOUR INVENTORY",playerGui)),"closed wallet drop has no phantom")
Input.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=walletTarget})
assert(requests[#requests].action=="DepositMoney" and requests[#requests].id=="cash-test","closed wallet rejected clean money")
cursor=walletTarget;find("Hit",find("Item_starter-wallet",find("03 / YOUR INVENTORY",playerGui))).InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=walletTarget})
Input.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=walletTarget})
local walletMenu=find("WalletGrid",playerGui);assert(walletMenu.Visible,"wallet did not open")
assert(not find("Item_wallet-1",walletMenu),"empty denominations appeared as items")
local walletHandle=find("WalletHandle",walletMenu);local origin=center(walletHandle);cursor=origin
walletHandle.InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=origin})
cursor=v(origin.X+30,origin.Y+10);Input.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=cursor})
Input.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=cursor})
assert(walletMenu.Position.X.Offset>0,"wallet menu title did not drag")
print("Desk startup, machine slots, wallet deposits, and draggable menus passed")
