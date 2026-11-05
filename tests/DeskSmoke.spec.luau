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
 ReplicatedStorage={WaitForChild=function() return {Config="Config",Items="Items",Grid="Grid",ItemTags="ItemTags",GridSnap="GridSnap"} end}}
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
local desk=Controller.new(function() end)
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
print("Desk startup, stock, visitor board, and dialogue render passed")
