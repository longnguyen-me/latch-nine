--!strict
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local TweenService=game:GetService("TweenService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config=require(Shared.Config)
local Items=require(Shared.Items)
local Tags=require(Shared.ItemTags)
local Wallet=require(Shared.Wallet)
local Snap=require(Shared.GridSnap)
local Grid=require(Shared.Grid)(Config,Items.Definitions)
local trayConfig: any=table.clone(Config);trayConfig.GridBaseRows=Config.TradeRows;trayConfig.GridColumns=Config.TradeColumns;trayConfig.GridRowsPerUpgrade=0
local Tray=require(Shared.Grid)(trayConfig,Items.Definitions)
local Widget=require(script.Parent.GridWidget)
local Surface=require(script.Parent.SurfaceInput)
local Desk={}
local C=Color3.fromRGB
local P={bg=C(14,21,31),panel=C(28,39,52),raised=C(35,49,63),line=C(71,93,108),ink=C(236,242,239),muted=C(164,187,191),teal=C(111,218,196),gold=C(241,194,116),red=C(242,127,120)}
local function make(class: string,props: any,parent: Instance): any
 local obj=Instance.new(class);for k,v in pairs(props) do (obj :: any)[k]=v end;obj.Parent=parent;return obj
end
local function clear(parent: Instance) for _,child in ipairs(parent:GetChildren()) do child:Destroy() end end
local Templates=game:GetService("ReplicatedStorage"):WaitForChild("GuiTemplates")
local function get(parent: any,name: string): any return parent:WaitForChild(name) end
local function clone(name: string,parent: Instance): any
 local view=get(Templates,name):Clone();view.Parent=parent;return view
end
local function rowText(parent: Instance,value: string,color: Color3?): TextLabel
 local view=clone("RowText",parent);view:SetAttribute("RuntimeRow",true);view.Text=value
 if color then view.TextColor3=color end
 return view
end
local function rowButton(parent: Instance,value: string,fn: ()->()): TextButton
 local view=clone("RowButton",parent);view:SetAttribute("RuntimeRow",true);view.Text=value;view.Activated:Connect(fn);return view
end
local function receiptLine(parent: Instance,name: string,price: number,index: number): Frame
 local row=clone("ReceiptLine",parent);row:SetAttribute("RuntimeRow",true);row.Name="ReceiptItem_"..index;row.LayoutOrder=index
 get(row,"Index").Text=string.format("%02d",index);get(row,"Title").Text=name;get(row,"Price").Text=tostring(price).." E"
 return row
end
local function locate(items: {any},id: string?): any for _,item in ipairs(items) do if item.id==id then return item end end;return nil end
function Desk.new(send: (any)->())
 local self: any={state=nil,selection=nil}
 local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
 -- This game does not spawn an avatar, so StarterGui may not have copied yet.
 local gui=playerGui:FindFirstChild("ShopDeskUI")
 if not gui then gui=game:GetService("StarterGui"):WaitForChild("ShopDeskUI"):Clone();gui.Parent=playerGui end
 local root=get(gui,"DeskRoot")
 -- Mouse button InputObjects keep their initial position. Always sample the live cursor.
 local function pointer(input: InputObject): Vector2
  if input.UserInputType~=Enum.UserInputType.Touch then return Input:GetMouseLocation() end
  local inset=GuiService:GetGuiInset()
  return Vector2.new(input.Position.X+inset.X,input.Position.Y+inset.Y)
 end
 local namePlate=get(root,"VisitorName")
 local dialoguePanel=get(root,"VisitorDialogue");dialoguePanel.Visible=false
 local dialogue=get(dialoguePanel,"Dialogue");local visitorName=get(namePlate,"Title")
 local receipt=get(root,"Receipt");receipt.Visible=false
 local receiptDrag: any=nil;local menuDrag: any=nil;local movedReceipt=false;local receiptCustomer: string?=nil
 local title=get(receipt,"ReceiptHandle")
 local close=get(receipt,"CloseButton");close.Activated:Connect(function() receipt.Visible=false;receiptDrag=nil end)
 title.InputBegan:Connect(function(input: InputObject)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   receiptDrag={input=input,start=pointer(input),position=receipt.AbsolutePosition};movedReceipt=true
  end
 end)
 local body=get(receipt,"ReceiptLines");local total=get(receipt,"Total");local status=get(root,"Status")
 local tooltip=get(root,"ItemTooltip");tooltip.Visible=false
 local tipTitle=get(tooltip,"Title");local tipPrice=get(tooltip,"Price");local tipText=get(tooltip,"Tags")
 local tipTween: any=nil
 local ghost=get(root,"TradeDragPreview");ghost.Visible=false
 local surfaces: any={};local mountedStage: any=nil;local mountEpoch=0
 local widgets: any={};local drag: any=nil;local pending: any=nil;local serial=0;local scrolling=false
 local phantom: any=nil;local phantomWidget: any=nil
 local selectedOrigin="inventory"
 local render: ()->();local preview: ()->();local startDrag: (string,any,any)->();local emitMove: (any)->()
 local function notice(value: string,color: Color3?) status.Text=value;status.TextColor3=color or P.gold end
 local function request(name: string,extra: any?) local r=extra or {};r.action=name;send(r) end
 local function cancel()
  drag=nil;receiptDrag=nil;ghost.Visible=false;clear(ghost);tooltip.Visible=false
  if phantom then phantom:Destroy();phantom=nil;phantomWidget=nil end
  for _,widget in pairs(widgets) do for _,view in pairs(widget.views or {}) do view.Visible=true end end
  for _,widget in pairs(widgets) do widget.scroll.ScrollingEnabled=true end
 end
 local function covered(point: Vector2): boolean
  local p,b=receipt.AbsolutePosition,receipt.AbsoluteSize
  return receipt.Visible and point.X>=p.X and point.Y>=p.Y and point.X<p.X+b.X and point.Y<p.Y+b.Y
 end
 local function inside(frame: GuiObject,point: Vector2): boolean
  local p,b=frame.AbsolutePosition,frame.AbsoluteSize
  return frame.Visible and point.X>=p.X and point.Y>=p.Y and point.X<p.X+b.X and point.Y<p.Y+b.Y
 end
 local function moveMenu(frame: Frame,handle: GuiObject)
  handle.Active=true
  handle.InputBegan:Connect(function(input: InputObject)
   if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
    menuDrag={frame=frame,input=input,start=pointer(input),position=frame.AbsolutePosition}
   end
  end)
 end
 local function placeMenu(frame: Frame,x: number,y: number)
  local bounds=frame.AbsoluteSize;local size=root.AbsoluteSize;local origin=root.AbsolutePosition
  local anchor=frame.AnchorPoint or Vector2.zero
  frame.Position=UDim2.fromOffset(math.clamp(x-origin.X,0,math.max(0,size.X-bounds.X))+anchor.X*bounds.X,math.clamp(y-origin.Y,0,math.max(0,size.Y-bounds.Y))+anchor.Y*bounds.Y)
 end
 local function hover(origin: string,item: any,x: number,y: number)
  tooltip.Visible=false
  if tipTween then tipTween:Cancel();tipTween=nil end
  if not item or drag or not self.state or covered(Vector2.new(x,y)) then return end
  local current=if origin=="inventory" then locate(self.state.inventory,item.id) else nil
  local price=nil
  if origin~="inventory" and self.state.customer then
   for _,entry in ipairs(self.state.customer.goods) do if entry.item.id==item.id then current=entry.item;price=entry.price;break end end
   if not current and self.state.customer.mode=="Buyer" then
    current=locate(self.state.inventory,item.id)
    local quote=self.state.customer.quote
    if quote then for _,line in ipairs(quote.lines) do if line.id==item.id then price=line.price;break end end end
   end
  end
  if not current and origin=="inventory" and self.state.customer then
   for _,entry in ipairs(self.state.customer.goods) do if entry.item.id==item.id then current=entry.item;price=entry.price;break end end
  end
  if not current then return end
  local def=Items.Definitions[current.kind];local q=Tags.Qualities[current.qualityTag or Tags.DefaultQuality]
  local crime=Tags.Criminality[current.criminality or "none"].name
  tipTitle.Text=def.name
  tipPrice.Text=tostring(price or current.marketPrice or current.value or current.paid).." E"
  tipText.Text=Tags.Categories[def.tagCategory].name.."  •  "..q.name.."\n"..crime
  local tx=math.clamp(x+16,0,math.max(0,root.AbsoluteSize.X-tooltip.AbsoluteSize.X-4))
  local ty=math.clamp(y+18,0,math.max(0,root.AbsoluteSize.Y-tooltip.AbsoluteSize.Y-4))
  tooltip.Position=UDim2.fromOffset(tx,math.max(0,ty-8))
  tooltip.Visible=true
  tipTween=TweenService:Create(tooltip,TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(tx,ty)})
  tipTween:Play()
 end
 local surfaceTemplates=game:GetService("ReplicatedStorage"):WaitForChild("ShopSurfaces")
 local function surface(name: string): any
  local layer=get(surfaceTemplates,name.."Surface"):Clone();layer.Enabled=false;layer.Parent=playerGui
  local container=get(layer,"SurfaceRoot")
  local value={gui=layer,root=container,canvas=layer.CanvasSize,part=nil};surfaces[name]=value;return value
 end
 for _,name in ipairs({"offers","inventory"}) do
  local layer=surface(name)
  widgets[name]=Widget.new(layer.root,if name=="offers" then "TradeGrid" else "InventoryGrid",function(item: any,input: any) startDrag(name,item,input) end,function(item: any,x: number,y: number)
   local pointer=Input:GetMouseLocation();hover(name,item,pointer.X,pointer.Y)
  end)
 end
 local register=surface("register")
 local registerButton=get(register.root,"RegisterButton");registerButton.Activated:Connect(function()
  if drag then return end
  receipt.Visible=true;tooltip.Visible=false;render()
 end)
 local outline=make("Highlight",{Name="RegisterOutline",Enabled=false,FillTransparency=1,OutlineTransparency=0,OutlineColor=P.teal,DepthMode=Enum.HighlightDepthMode.Occluded},workspace)
 registerButton.MouseEnter:Connect(function() outline.Enabled=true end)
 registerButton.MouseLeave:Connect(function() outline.Enabled=false end)
 local nextSurface=surface("next")
 local nextButton=get(nextSurface.root,"CallCustomerButton");nextButton.Activated:Connect(function() cancel();request("NextCustomer") end)
 local nextOutline=make("Highlight",{Name="NextCustomerOutline",Enabled=false,FillTransparency=1,OutlineTransparency=0,OutlineColor=P.teal,DepthMode=Enum.HighlightDepthMode.Occluded},workspace)
 nextButton.MouseEnter:Connect(function() nextOutline.Enabled=true end)
 nextButton.MouseLeave:Connect(function() nextOutline.Enabled=false end)
 local dismissSurface=surface("dismiss")
 local dismissButton=get(dismissSurface.root,"DismissCustomerButton");dismissButton.Activated:Connect(function()
  local c=self.state and self.state.customer
  if c and c.state=="Interact" then cancel();request("DismissCustomer",{customerId=c.id}) end
 end)
 local dismissOutline=make("Highlight",{Name="DismissCustomerOutline",Enabled=false,FillTransparency=1,OutlineTransparency=0,OutlineColor=P.red,DepthMode=Enum.HighlightDepthMode.Occluded},workspace)
 dismissButton.MouseEnter:Connect(function() dismissOutline.Enabled=true end)
 dismissButton.MouseLeave:Connect(function() dismissOutline.Enabled=false end)
 local toggleSurface=surface("toggle")
 local toggleButton=get(toggleSurface.root,"ShopToggleButton");toggleButton.Activated:Connect(function() request("ToggleShop") end)
 local toggleOutline=make("Highlight",{Name="ShopToggleOutline",Enabled=false,FillTransparency=1,OutlineColor=P.teal,DepthMode=Enum.HighlightDepthMode.Occluded},workspace)
 toggleButton.MouseEnter:Connect(function() toggleOutline.Adornee=toggleSurface.part;toggleOutline.Enabled=true end)
 toggleButton.MouseLeave:Connect(function() toggleOutline.Enabled=false end)
 local shopLabel=get(root,"ShopStatus");local suspicionLabel=get(root,"SuspicionLabel")
 local suspicionTrack=get(root,"SuspicionTrack");local suspicionFill=get(suspicionTrack,"SuspicionFill")
 local walletPanel=get(root,"WalletGrid");walletPanel.Visible=false
 local walletTitle=get(walletPanel,"WalletHandle");moveMenu(walletPanel,walletTitle)
 get(walletPanel,"CloseButton").Activated:Connect(function() walletPanel.Visible=false end)
 local walletBody=get(walletPanel,"Slots");local walletUpgrade=get(walletPanel,"WalletInfo")
 local walletDrag: number?=nil
 local walletWidget: any
 local moneyGhost=get(root,"WalletNoteDrag");moneyGhost.Visible=false
 Input.InputChanged:Connect(function(input: InputObject)
  if walletDrag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
   local point=pointer(input);moneyGhost.Position=UDim2.fromOffset(point.X-walletWidget.cellSize/2,point.Y-walletWidget.cellSize/2)
  end
 end)
 walletWidget=Widget.new(walletBody,"WalletCells",function(item: any,input: InputObject)
  if item.walletCount<=0 then return end
  walletDrag=item.denomination;clear(moneyGhost)
  Widget.draw(moneyGhost,item,Grid.cells(item.kind,0),1,1,walletWidget.cellSize,false,function() end)
  moneyGhost.Size=UDim2.fromOffset(walletWidget.cellSize,walletWidget.cellSize);moneyGhost.Visible=true
  local point=pointer(input);moneyGhost.Position=UDim2.fromOffset(point.X-walletWidget.cellSize/2,point.Y-walletWidget.cellSize/2)
 end)
 local walletPhantom=get(walletBody,"WalletPhantom");walletPhantom.Visible=false
 Input.InputChanged:Connect(function(input: InputObject)
  if not walletDrag or not walletPanel.Visible then walletPhantom.Visible=false;return end
  if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
  local point=pointer(input)-walletBody.AbsolutePosition;local origin=walletWidget.origin()
  local x=math.floor((point.X-origin.X)/walletWidget.cellSize);local y=math.floor((point.Y-origin.Y)/walletWidget.cellSize)
  walletPhantom.Visible=x>=0 and x<walletWidget.columns and y>=0 and y<walletWidget.rows
  walletPhantom.Position=UDim2.fromOffset(origin.X+x*walletWidget.cellSize,origin.Y+y*walletWidget.cellSize)
  walletPhantom.Size=UDim2.fromOffset(walletWidget.cellSize,walletWidget.cellSize)
 end)
 local function drawWallet(s: any)
  local tier=s.walletTier or 0;local dims=Wallet.Sizes[tier+1];local cols,rows=dims[1],dims[2]
  local items={}
  for index,stack in ipairs(s.walletStacks or {}) do
   if stack.count>0 then
   local slot=(s.walletSlots or {})[tostring(stack.denomination)] or index
   table.insert(items,{id="wallet-"..stack.denomination,kind="cash"..stack.denomination,denomination=stack.denomination,walletCount=stack.count,
    gridX=(slot-1)%cols,gridY=math.floor((slot-1)/cols),rotation=0,qualityTag="standard"})
   end
  end
  walletWidget.render(items,cols,rows,Grid)
  walletUpgrade.Text=Wallet.Rarities[tier+1]:upper().." WALLET / "..cols.." × "..rows
 end
 Input.InputEnded:Connect(function(input: InputObject)
  if walletDrag and not walletPanel.Visible then walletDrag=nil;moneyGhost.Visible=false;return end
  if not walletDrag or not walletPanel.Visible or (input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch) then return end
  local denomination=walletDrag;walletDrag=nil;moneyGhost.Visible=false;walletPhantom.Visible=false
  local screenPoint=pointer(input)
  local point=screenPoint-walletBody.AbsolutePosition
  if walletWidget.contains(point) then
   local origin=walletWidget.origin();local col=math.floor((point.X-origin.X)/walletWidget.cellSize);local row=math.floor((point.Y-origin.Y)/walletWidget.cellSize)
   request("MoveMoney",{denomination=denomination,slot=row*walletWidget.columns+col+1});return
  end
  local c=self.state and self.state.customer
  if c and c.mode=="Seller" and c.state=="Interact" then
   local surfacePoint=Surface.project(surfaces.offers.part,surfaces.offers.canvas,screenPoint)
   if surfacePoint and widgets.offers.contains(surfacePoint) then request("StagePayment",{customerId=c.id,denomination=denomination});receipt.Visible=true;return end
  end
  local stockPoint=Surface.project(surfaces.inventory.part,surfaces.inventory.canvas,screenPoint)
  if stockPoint and widgets.inventory.contains(stockPoint) then
   local widget=widgets.inventory;local origin=widget.origin()
   local x=math.floor((stockPoint.X-origin.X)/widget.cellSize);local y=math.floor((stockPoint.Y-origin.Y)/widget.cellSize)
   request("WithdrawMoney",{denomination=denomination,x=x,y=y});return
  end
 end)
 local machinePanel=get(root,"MachineMenu");machinePanel.Visible=false
 local machineTitle=get(machinePanel,"MachineHandle");moveMenu(machinePanel,machineTitle)
 local machineClose=get(machinePanel,"MachineClose");machineClose.Activated:Connect(function() machinePanel.Visible=false end)
 local machineProgress=get(machinePanel,"Progress")
 local machineWidgets: any={};local machineDrag: any=nil;local activeMachine: string?=nil;local lastMachineClick: any=nil
 local machineGhost=get(root,"MachineDragPreview");machineGhost.Visible=false
 local machinePhantom=get(machinePanel,"MachinePhantom");machinePhantom.Visible=false
 local function machineCell(slot: string,point: Vector2): (number?,number?,any?)
  local widget=machineWidgets[slot];local holder=widget.frame.Parent
  local localPoint=Vector2.new(point.X-holder.AbsolutePosition.X,point.Y-holder.AbsolutePosition.Y)
  if not widget.frame.Visible or not widget.contains(localPoint) then return nil,nil,nil end
  local origin=widget.origin()
  return math.floor((localPoint.X-origin.X)/widget.cellSize),math.floor((localPoint.Y-origin.Y)/widget.cellSize),widget
 end
 local function machineAccept(machine: any,item: any,slot: string,x: number,y: number): boolean
  local def=Items.Definitions[machine.kind];local m=machine.machine or {input={},output={}}
  if slot=="press" then return def.machine=="printer" and item.kind=="mintPress" and m.press==nil end
  if slot~="input" or not (if def.machine=="printer" then Items.Definitions[item.kind].paperQuality else item.kind=="dirty100") then return false end
  if x<0 or y<0 or x>=def.inputColumns or y>=def.inputRows then return false end
  for _,entry in ipairs(m.input) do if entry.machineX==x and entry.machineY==y then return false end end
  return true
 end
 for _,slot in ipairs({"input","press","output"}) do
  local holder=get(machinePanel,slot.."Grid")
  machineWidgets[slot]=Widget.new(holder,slot,function(item: any,input: InputObject)
   machineDrag={item=item,slot=slot,input=input};machineGhost.Text=Items.Definitions[item.kind].glyph;machineGhost.Visible=true
  end)
 end
 local function renderMachine(s: any)
  if not machinePanel.Visible or not activeMachine then return end
  local machine=locate(s.inventory,activeMachine)
  if not machine then machinePanel.Visible=false;activeMachine=nil;return end
  local def=Items.Definitions[machine.kind];if not def.machine then machinePanel.Visible=false;return end
  local m=machine.machine or {input={},output={}}
  machineTitle.Text=def.name:upper()
  machineProgress.Text=if m.nextAt then "Next cycle: "..math.max(0,m.nextAt-os.time()).."s  •  Output "..#m.output.."/"..def.outputCapacity else "Idle / blocked  •  Output "..#m.output.."/"..def.outputCapacity
  local inputs={};for _,entry in ipairs(m.input) do local item=table.clone(entry);item.gridX=entry.machineX;item.gridY=entry.machineY;item.rotation=0;table.insert(inputs,item) end
  machineWidgets.input.render(inputs,def.inputColumns,def.inputRows,Grid)
  local presses={};if m.press then local item=table.clone(m.press);item.gridX=0;item.gridY=0;item.rotation=0;table.insert(presses,item) end
  machineWidgets.press.render(presses,1,1,Grid)
  local outputs={};for index,entry in ipairs(m.output) do local item=table.clone(entry);item.gridX=0;item.gridY=index-1;item.rotation=0;table.insert(outputs,item) end
  machineWidgets.output.render(outputs,1,def.outputCapacity,Grid)
  machineWidgets.press.frame.Visible=def.machine=="printer"
 end
 Input.InputChanged:Connect(function(input: InputObject)
  if machineDrag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
   local point=pointer(input);machineGhost.Position=UDim2.fromOffset(point.X-machineGhost.AbsoluteSize.X/2,point.Y-machineGhost.AbsoluteSize.Y/2)
   machinePhantom.Visible=false
   local x,y,widget=machineCell(machineDrag.slot,point)
   if x and y and widget and machineDrag.slot~="press" then
    local machine=locate(self.state.inventory,activeMachine)
    local entry=machine and machine.machine and machine.machine[machineDrag.slot] or {}
    local occupied=false
    for index,other in ipairs(entry) do
     local ox=if machineDrag.slot=="input" then other.machineX else 0
     local oy=if machineDrag.slot=="input" then other.machineY else index-1
     if ox==x and oy==y and other.id~=machineDrag.item.id then occupied=true end
    end
    machinePhantom.BackgroundColor3=Widget.previewColor(not occupied)
    machinePhantom.Position=UDim2.fromOffset((widget.frame.Parent.AbsolutePosition.X-machinePanel.AbsolutePosition.X)+widget.origin().X+x*widget.cellSize,(widget.frame.Parent.AbsolutePosition.Y-machinePanel.AbsolutePosition.Y)+widget.origin().Y+y*widget.cellSize)
    machinePhantom.Size=UDim2.fromOffset(widget.cellSize,widget.cellSize);machinePhantom.Visible=true
   end
  end
 end)
 Input.InputEnded:Connect(function(input: InputObject)
  if not machineDrag or (input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch) then return end
  local d=machineDrag;machineDrag=nil;machineGhost.Visible=false;machinePhantom.Visible=false
  if activeMachine then
   local x,y=machineCell(d.slot,pointer(input))
   if x and y and d.slot~="press" then
    emitMove({action="MachineMove",machineId=activeMachine,id=d.item.id,slot=d.slot,x=x,y=y});return
   end
  end
  local point=Surface.project(surfaces.inventory.part,surfaces.inventory.canvas,pointer(input))
  local widget=widgets.inventory
  if not point or not widget.contains(point) or not activeMachine then return end
  local origin=widget.origin();local x=math.floor((point.X-origin.X)/widget.cellSize);local y=math.floor((point.Y-origin.Y)/widget.cellSize)
  emitMove({action="MachineExtract",machineId=activeMachine,id=d.item.id,slot=d.slot,x=x,y=y})
 end)
 local function bindStage(name: string?)
  if mountedStage==name then return end
  mountedStage=name;mountEpoch+=1;local epoch=mountEpoch
  for _,layer in pairs(surfaces) do layer.part=nil;layer.gui.Adornee=nil;layer.gui.Enabled=false end
  outline.Enabled=false;outline.Adornee=nil;nextOutline.Enabled=false;nextOutline.Adornee=nil;dismissOutline.Enabled=false;dismissOutline.Adornee=nil;toggleOutline.Enabled=false;toggleOutline.Adornee=nil
  local function attempt()
   if epoch~=mountEpoch then return end
   local stage=if name then workspace:FindFirstChild(name) else nil
   local complete=true
   for key,partName in pairs({inventory="InventoryBoard",offers="VisitorBoard",register="RegisterBox",next="NextCustomerButton",dismiss="DismissCustomerButton",toggle="ShopToggle"}) do
    local part=if stage then stage:FindFirstChild(partName,true) else nil
    local layer=surfaces[key];layer.part=part;layer.gui.Adornee=part;layer.gui.Enabled=part~=nil
    if part and (key=="inventory" or key=="offers") then
     layer.canvas=Vector2.new(layer.canvas.X,math.max(80,math.floor(layer.canvas.X*part.Size.Y/part.Size.X+0.5)))
     layer.gui.CanvasSize=layer.canvas
    end
    if key=="register" then outline.Adornee=part elseif key=="next" then nextOutline.Adornee=part elseif key=="dismiss" then dismissOutline.Adornee=part end
    if not part then complete=false end
   end
   if not complete then task.delay(0.25,attempt) end
  end
  attempt()
 end
 local function canvasPoint(name: string,point: Vector2): Vector2?
  local layer=surfaces[name];return Surface.project(layer.part,layer.canvas,point)
 end
 local buy=get(receipt,"BuyButton");buy.Activated:Connect(function()
  local c=self.state and self.state.customer
  if not c or c.state~="Interact" then return end
  if c.quote then request(if c.mode=="Buyer" then "ConfirmSale" else "ConfirmPurchase",{customerId=c.id,quoteId=c.quote.id})
  else request(if c.mode=="Buyer" then "ReviewSale" else "ReviewPurchase",{customerId=c.id}) end
 end)
 local bulk=get(receipt,"BuyBulkButton");bulk.Visible=false;bulk.Activated:Connect(function()
  local c=self.state and self.state.customer
  if c and c.mode=="Seller" and c.bulkPercent and c.state=="Interact" then request("BuyBulk",{customerId=c.id}) end
 end)
 local clearButton=get(receipt,"ClearButton");clearButton.Activated:Connect(function() local c=self.state and self.state.customer;if c then request("ClearBasket",{customerId=c.id}) end end)
 local function rotate()
  if drag then
   local _,_,h=Grid.cells(drag.item.kind,drag.rotation)
   local oldX=drag.grabX;drag.grabX=h-drag.grabY;drag.grabY=oldX;drag.rotation=(drag.rotation+1)%4
   clear(ghost);local cells,w,height=Grid.cells(drag.item.kind,drag.rotation);Widget.draw(ghost,drag.item,cells,w,height,drag.sourceSize,true,nil,nil,drag.sourceHeight)
   if phantom then phantom:Destroy();phantom=nil;phantomWidget=nil end
   preview()
  elseif self.state and self.selection and not pending then
   local item=locate(self.state.inventory,self.selection)
   if selectedOrigin=="inventory" and item then request("PlaceItem",{id=item.id,x=item.gridX,y=item.gridY,rotation=(item.rotation+1)%4,revision=self.state.gridRevision}) end
   local c=self.state.customer
   if selectedOrigin=="offers" and c and c.state=="Interact" then
    if c.mode=="Seller" then request("RotateOffer",{customerId=c.id,id=self.selection,revision=c.basketRevision})
    else
     local staged=locate(c.basket,self.selection)
     if staged then emitMove({action="StageStock",customerId=c.id,id=staged.id,x=staged.gridX,y=staged.gridY,rotation=(staged.rotation+1)%4,revision=c.basketRevision}) end
    end
   end
  end
 end
 -- Rotation remains bound to R without a screen button.
 emitMove=function(data: any)
  serial+=1;data.moveId=serial;pending=serial;send(data)
  task.delay(5,function() if pending==data.moveId then pending=nil;cancel();request("Sync");notice("Connection delayed.",P.red) end end)
 end
 local function positionOf(widget: any,point: Vector2,gx: number,gy: number): (number,number)
  local p=widget.origin()
  return Snap.project(point.X,point.Y,p.X,p.Y,widget.cellSize,gx,gy)
 end
 local function closedContainer(s: any,item: any,point: Vector2): any
  local widget=widgets.inventory;local origin=widget.origin()
  local col=math.floor((point.X-origin.X)/widget.cellSize);local row=math.floor((point.Y-origin.Y)/widget.cellSize)
  local occupantId=Grid.occupied(s,item.id)[col..","..row]
  local occupant=if occupantId then locate(s.inventory,occupantId) else nil
  if not occupant then return nil end
  local definition=Items.Definitions[item.kind];local containerDef=Items.Definitions[occupant.kind]
  if containerDef.walletTier~=nil and definition.denomination and not definition.dirty then return {action="DepositMoney",id=item.id} end
  if not containerDef.machine then return nil end
  local m=occupant.machine or {input={},output={}}
  if item.kind=="mintPress" and containerDef.machine=="printer" and not m.press then
   return {action="MachineInsert",machineId=occupant.id,id=item.id,slot="press",x=0,y=0}
  end
  if (containerDef.machine=="printer" and definition.paperQuality) or (containerDef.machine=="laundry" and item.kind=="dirty100") then
   for y=0,containerDef.inputRows-1 do for x=0,containerDef.inputColumns-1 do
    if machineAccept(occupant,item,"input",x,y) then return {action="MachineInsert",machineId=occupant.id,id=item.id,slot="input",x=x,y=y} end
   end end
  end
  return nil
 end
 preview=function()
  if not drag or not drag.active then return end
  local s=self.state;local c=s.customer;local target: string?=nil
  local nearest=math.huge;local surfaceName: string?=nil;local projected: Vector2?=nil
  if not covered(drag.point) then
   for _,name in ipairs({"inventory","offers"}) do
    local layer=surfaces[name];local point,distance=Surface.project(layer.part,layer.canvas,drag.point)
    if point and point.X>=0 and point.Y>=0 and point.X<layer.canvas.X and point.Y<layer.canvas.Y and (distance or 0)<nearest then
     nearest=distance or 0;surfaceName=name;projected=point
    end
   end
  end
  if surfaceName and projected and widgets[surfaceName].contains(projected) then target=surfaceName end
  local valid=false;local x,y=0,0
  local widget=if target then widgets[target] else nil
  drag.container=nil;machinePhantom.Visible=false;walletPhantom.Visible=false
  if drag.origin=="inventory" then
   if walletPanel.Visible and inside(walletBody,drag.point) then
    local localPoint=Vector2.new(drag.point.X-walletBody.AbsolutePosition.X,drag.point.Y-walletBody.AbsolutePosition.Y)
    local accepts=Items.Definitions[drag.item.kind].denomination~=nil and not Items.Definitions[drag.item.kind].dirty and walletWidget.contains(localPoint)
    if accepts then drag.container={action="DepositMoney",id=drag.item.id} end
    drag.target="wallet";drag.valid=accepts
    local wx,wy=positionOf(walletWidget,localPoint,0.5,0.5)
    walletPhantom.Position=UDim2.fromOffset(walletWidget.origin().X+wx*walletWidget.cellSize,walletWidget.origin().Y+wy*walletWidget.cellSize)
    walletPhantom.Size=UDim2.fromOffset(walletWidget.cellSize,walletWidget.cellSize)
    walletPhantom.BackgroundColor3=Widget.previewColor(accepts)
    walletPhantom.Visible=walletWidget.contains(localPoint)
    ghost.Position=UDim2.fromOffset(drag.point.X-drag.grabX*drag.sourceSize,drag.point.Y-drag.grabY*drag.sourceHeight)
    if phantom then phantom:Destroy();phantom=nil;phantomWidget=nil end
    return
   end
   if machinePanel.Visible and activeMachine and inside(machinePanel,drag.point) then
    local machine=locate(s.inventory,activeMachine)
    for _,slot in ipairs({"press","input"}) do
     local mx,my,mwidget=machineCell(slot,drag.point)
     if mx and my and mwidget and machine then
      local accepts=machineAccept(machine,drag.item,slot,mx,my)
      if accepts then drag.container={action="MachineInsert",machineId=activeMachine,id=drag.item.id,slot=slot,x=mx,y=my} end
      drag.target="machine";drag.valid=accepts
      machinePhantom.Position=UDim2.fromOffset((mwidget.frame.Parent.AbsolutePosition.X-machinePanel.AbsolutePosition.X)+mwidget.origin().X+mx*mwidget.cellSize,(mwidget.frame.Parent.AbsolutePosition.Y-machinePanel.AbsolutePosition.Y)+mwidget.origin().Y+my*mwidget.cellSize)
      machinePhantom.Size=UDim2.fromOffset(mwidget.cellSize,mwidget.cellSize);machinePhantom.BackgroundColor3=Widget.previewColor(accepts);machinePhantom.Visible=true
      ghost.Position=UDim2.fromOffset(drag.point.X-drag.grabX*drag.sourceSize,drag.point.Y-drag.grabY*drag.sourceHeight)
      if phantom then phantom:Destroy();phantom=nil;phantomWidget=nil end
      return
     end
    end
    target=nil;widget=nil
   end
  end
  if widget and target then local point=canvasPoint(target,drag.point);if point then x,y=positionOf(widget,point,drag.grabX,drag.grabY) end end
  if drag.item.pending and target=="offers" and c and c.mode=="Seller" and c.state=="Interact" then valid=true
  elseif drag.origin=="inventory" and target=="inventory" and not drag.item.pending then
   local point=canvasPoint("inventory",drag.point)
   if point then drag.container=closedContainer(s,drag.item,point) end
   valid=drag.container~=nil or Grid.check(s,drag.item.kind,x,y,drag.rotation,drag.item.id)
  elseif drag.origin=="inventory" and target=="offers" and c and c.state=="Interact" then
   if c.mode=="Seller" then valid=Items.Definitions[drag.item.kind].denomination~=nil and #c.basket>0
   elseif Items.Definitions[drag.item.kind].tagCategory==c.requestTag then valid=Tray.check({inventory=c.basket,upgrade=0,legacyRows=0},drag.item.kind,x,y,drag.rotation,drag.item.id) end
  elseif drag.origin=="offers" and target=="inventory" and c and c.state=="Interact" then
   valid=Grid.check(s,drag.item.kind,x,y,drag.rotation,if c.mode=="Buyer" then drag.item.id else nil)
  elseif drag.origin=="offers" and target=="offers" and c and c.mode=="Buyer" and c.state=="Interact" then
   valid=Tray.check({inventory=c.basket,upgrade=0,legacyRows=0},drag.item.kind,x,y,drag.rotation,drag.item.id)
  end
  drag.valid=valid;drag.target=target;drag.x=x;drag.y=y
  ghost.Position=UDim2.fromOffset(drag.point.X-drag.grabX*drag.sourceSize,drag.point.Y-drag.grabY*drag.sourceHeight);ghost.Visible=true
  if not widget then
   if phantom then phantom:Destroy();phantom=nil;phantomWidget=nil end
   return
  end
  if phantomWidget~=widget then
   if phantom then phantom:Destroy() end
   phantom=clone("ItemView",widget.board);phantom.Name="GridPhantom";phantom.ZIndex=30
   local cells,w,h=Grid.cells(drag.item.kind,drag.rotation)
   Widget.draw(phantom,drag.item,cells,w,h,widget.cellSize,true,nil);phantomWidget=widget
  end
  phantom.Position=UDim2.fromOffset(x*widget.cellSize,y*widget.cellSize)
  local view=phantom:GetChildren()[1]
  for _,piece in ipairs(view:GetChildren()) do
   if piece:IsA("GuiObject") then piece.BackgroundColor3=Widget.previewColor(valid) end
  end
 end
 local function updateDrag(point: Vector2)
  if not drag then return end
  drag.point=point
  if not drag.active and Snap.started(point.X,point.Y,drag.start.X,drag.start.Y,drag.input.UserInputType==Enum.UserInputType.Touch) then
   drag.active=true
   local widget=widgets[drag.origin]
   if widget.views[drag.item.id] then widget.views[drag.item.id].Visible=false end
   for _,value in pairs(widgets) do value.scroll.ScrollingEnabled=false end
   local cells,w,h=Grid.cells(drag.item.kind,drag.rotation)
   local view=Widget.draw(ghost,drag.item,cells,w,h,drag.sourceSize,true,nil,nil,drag.sourceHeight)
   for _,piece in ipairs(view:GetChildren()) do if piece:IsA("GuiObject") then piece.BackgroundTransparency=0.78 end end
  end
  preview()
 end
 local function autoScroll()
  if scrolling or not drag or not drag.active then return end;scrolling=true
  local function step()
   if not drag or not drag.active then scrolling=false;return end
   local widget=widgets[drag.origin]
   local p,size=Vector2.new(0,0),Vector2.new(widget.canvasWidth,widget.canvasHeight)
   local pointer=canvasPoint(drag.origin,drag.point)
   local delta=0
   if pointer and pointer.X>=p.X and pointer.X<p.X+size.X then
    delta=if pointer.Y<p.Y+24 and pointer.Y>=p.Y then -widget.cellSize*0.4 elseif pointer.Y>p.Y+size.Y-24 and pointer.Y<p.Y+size.Y then widget.cellSize*0.4 else 0
   end
   local maxY=math.max(0,widget.rows*widget.cellSize+12-size.Y)
   local y=math.clamp(widget.scroll.CanvasPosition.Y+delta,0,maxY)
   if delta==0 or y==widget.scroll.CanvasPosition.Y then scrolling=false;return end
   widget.scroll.CanvasPosition=Vector2.new(0,y);preview();task.delay(0.08,step)
  end;step()
 end
 startDrag=function(origin: string,item: any,input: any)
  if item.payment then return end
  if drag or pending or receiptDrag or not self.state or covered(pointer(input)) then return end
  if origin=="inventory" and not item.pending and Items.Definitions[item.kind].machine then
   if lastMachineClick and lastMachineClick.id==item.id and os.clock()-lastMachineClick.at<0.55 then
    activeMachine=item.id;machinePanel.Visible=true;renderMachine(self.state);lastMachineClick=nil;return
   end
   lastMachineClick={id=item.id,at=os.clock()}
  end
  local c=self.state.customer
  if origin~="inventory" and (not c or c.state~="Interact") then return end
  self.selection=item.id;selectedOrigin=origin;tooltip.Visible=false;render()
  local widget=widgets[origin];local point=pointer(input)
  local p=widget.origin()
  local projected=canvasPoint(origin,point);if not projected then return end
  local sx,sy=Surface.cellPixels(surfaces[origin].part,surfaces[origin].canvas,projected,widget.cellSize)
  drag={origin=origin,item=item,input=input,point=point,start=point,active=false,rotation=item.rotation,sourceSize=sx,sourceHeight=sy,
   grabX=(projected.X-p.X)/widget.cellSize-item.gridX,grabY=(projected.Y-p.Y)/widget.cellSize-item.gridY,
   gridRevision=self.state.gridRevision,customerId=if c then c.id else nil,basketRevision=if c then c.basketRevision else nil}
 end
 local function clampReceipt(x: number,y: number)
  placeMenu(receipt,x,y)
 end
 local function layout()
  if movedReceipt then clampReceipt(receipt.AbsolutePosition.X,receipt.AbsolutePosition.Y) end
 end
 render=function()
  local s=self.state;if not s then return end;bindStage(s.stageName);layout()
  shopLabel.Text=if s.pendingArrival then "CUSTOMER EN ROUTE" elseif s.shopOpen then "SHOP OPEN" else "SHOP CLOSED / CLICK SWITCH OR CALL BUTTON"
  if walletPanel.Visible then drawWallet(s) end
  renderMachine(s)
  local suspicion=s.suspicion or 0
  suspicionLabel.Text="SUSPICION "..suspicion.."/100"..(if suspicion>=90 then " / CRITICAL" elseif suspicion>=75 then " / WATCHED" elseif suspicion>=50 then " / FEWER VISITORS" else "")
  suspicionLabel.TextColor3=if suspicion>=75 then P.red elseif suspicion>=50 then P.gold else P.muted
  suspicionFill.Size=UDim2.fromScale(suspicion/100,1)
  suspicionFill.BackgroundColor3=if suspicion>=75 then P.red elseif suspicion>=50 then P.gold else P.teal
  local c=s.customer
  visitorName.Text=if c then c.name.." / "..(if c.requestTag then "WANTS "..Tags.Categories[c.requestTag].name else c.faction) else "SERVICE WINDOW"
  dialoguePanel.Visible=c~=nil;dialogue.Text=if c then c.dialogue or "" else ""
  local cid=if c then c.id else nil
  if receiptCustomer~=cid or (c and c.state=="Leave") then receipt.Visible=false;receiptCustomer=cid end
  local offered,basket={},{}
  local staged: {[string]: boolean}={}
  if c then
   -- Hide staged stock from its source grid until returned or sold.
for _,item in ipairs(c.basket) do staged[item.id]=true;table.insert(basket,item) end
   for _,entry in ipairs(c.goods) do if not staged[entry.item.id] then local item=table.clone(entry.item);item.offerPrice=entry.price;table.insert(offered,item) end end
   if c.mode=="Seller" then
    local display={inventory=table.clone(offered),upgrade=0,legacyRows=0}
    for index,payment in ipairs(c.payment or {}) do
     local kind="cash"..payment.denomination
     local x,y,rotation=Tray.firstFit(display,kind)
     if x then
      local note={id="payment-"..index,kind=kind,gridX=x,gridY=y,rotation=rotation,qualityTag="standard",payment=true}
      table.insert(display.inventory,note);table.insert(offered,note)
     end
    end
   end
  end
  widgets.offers.render(if c and c.mode=="Buyer" then basket else offered,Config.TradeColumns,Config.TradeRows,Tray,surfaces.offers.canvas)
  local owned={}
  local paidIds={}
  if c then for _,payment in ipairs(c.payment or {}) do if payment.id then paidIds[payment.id]=true end end end
  for _,item in ipairs(s.inventory) do if not paidIds[item.id] and not (c and c.mode=="Buyer" and staged and staged[item.id]) then table.insert(owned,item) end end
  if c and c.mode=="Seller" then
   for _,item in ipairs(c.basket) do
    if item.stockX~=nil then
     local preview=table.clone(item);preview.gridX=item.stockX;preview.gridY=item.stockY;preview.rotation=item.stockRotation;preview.pending=true
     table.insert(owned,preview)
    end
   end
  end
  widgets.inventory.render(owned,s.gridColumns,s.gridRows,Grid,surfaces.inventory.canvas)
  for _,child in ipairs(body:GetChildren()) do if child:GetAttribute("RuntimeRow") then child:Destroy() end end
  local q=c and c.quote
  total.Text=(if c and c.mode=="Buyer" then "RECEIVE " else "TOTAL ")..tostring(if q then q.total else 0).." E"
  buy.Text=(if c and c.mode=="Buyer" then "SELL" else "BUY")..(if q then " / "..q.total.." E" else "")
  bulk.Visible=c~=nil and c.mode=="Seller" and c.bulkPercent~=nil and c.state=="Interact"
  if bulk.Visible then
   bulk.Text="BUY BULK / "..c.bulkOriginal.." → "..c.bulkPrice.." E (-"..c.bulkPercent.."%)"
   if not q then rowText(body,"BULK OFFER / "..#c.goods.." ITEMS",P.gold) end
  end
  if q then
   for index,line in ipairs(q.lines) do receiptLine(body,line.name,line.price,index) end
   if c and c.mode=="Seller" then rowText(body,"NOTES GIVEN: "..(c.paymentTotal or 0).." E",P.gold) end
   if not q.affordable then rowText(body,"Insufficient funds",P.red) end
  elseif c and c.state=="Interact" and (c.itemId or c.requestTag) then
   rowText(body,"WANTED: "..(if c.requestTag then Tags.Categories[c.requestTag].name else Items.Definitions[c.kind].name),P.gold)
   if c.itemId and c.mode~="Buyer" then
   rowButton(body,"SELL / "..c.offer.." E",function() request("Accept",{customerId=c.id}) end)
   local ask=clone("AskPrice",body);ask:SetAttribute("RuntimeRow",true)
   rowButton(body,"COUNTER",function() request("Counter",{customerId=c.id,price=tonumber(ask.Text)}) end)
  end
  end
  local selected=if selectedOrigin=="inventory" then locate(s.inventory,self.selection) else nil
  if selected then
   rowText(body,Items.Definitions[selected.kind].name,P.ink)
   for _,quality in ipairs(Tags.QualityOrder) do
    local tag=Tags.Qualities[quality]
    rowButton(body,tag.name.." / x"..string.format("%.2f",tag.multiplier),function() request("SetItemTag",{id=selected.id,qualityTag=quality}) end)
   end
  end
  notice(s.message or "")
 end
 Input.InputChanged:Connect(function(input: InputObject)
  if menuDrag then
   local d=menuDrag
   if (d.input.UserInputType==Enum.UserInputType.Touch and input==d.input) or (d.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then
    local point=pointer(input);placeMenu(d.frame,d.position.X+point.X-d.start.X,d.position.Y+point.Y-d.start.Y)
   end
   return
  end
  if receiptDrag then
   local d=receiptDrag
   if (d.input.UserInputType==Enum.UserInputType.Touch and input==d.input) or (d.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then
    local point=pointer(input);clampReceipt(d.position.X+point.X-d.start.X,d.position.Y+point.Y-d.start.Y)
   end
   return
  end
  if not drag then return end
  if (drag.input.UserInputType==Enum.UserInputType.Touch and input==drag.input) or
   (drag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then
   updateDrag(pointer(input));autoScroll()
  end
 end)
 Input.InputEnded:Connect(function(input: InputObject)
  if menuDrag then
   local d=menuDrag
   if (d.input.UserInputType==Enum.UserInputType.Touch and input==d.input) or (d.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1) then menuDrag=nil end
   return
  end
  if receiptDrag then
   local d=receiptDrag
   if (d.input.UserInputType==Enum.UserInputType.Touch and input==d.input) or (d.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1) then receiptDrag=nil end
   return
  end
  if not drag then return end
  if not ((drag.input.UserInputType==Enum.UserInputType.Touch and input==drag.input) or
   (drag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then return end
  updateDrag(pointer(input));local d=drag;cancel()
  if not d.active then
   if d.origin=="inventory" and Items.Definitions[d.item.kind].walletTier~=nil then walletPanel.Visible=true;drawWallet(self.state) end
   return
  end
  if d.container and d.valid then
   if d.container.action=="DepositMoney" then request("DepositMoney",{id=d.item.id}) else emitMove(d.container) end
   return
  end
  if not d.valid then notice("Placement blocked.",P.red);return end
  if d.item.pending and d.target=="offers" then
   emitMove({action="UnstageOffer",customerId=d.customerId,id=d.item.id,revision=d.basketRevision})
  elseif d.origin=="inventory" and d.target=="inventory" then
   if d.x==d.item.gridX and d.y==d.item.gridY and d.rotation==d.item.rotation then return end
   emitMove({action="PlaceItem",id=d.item.id,x=d.x,y=d.y,rotation=d.rotation,revision=d.gridRevision})
  elseif d.origin=="inventory" and d.target=="offers" then
   receipt.Visible=true
   local amount=Items.Definitions[d.item.kind].denomination
   if amount then request("StagePayment",{customerId=d.customerId,id=d.item.id,denomination=amount})
   else emitMove({action="StageStock",customerId=d.customerId,id=d.item.id,x=d.x,y=d.y,rotation=d.rotation,revision=d.basketRevision}) end
  elseif d.origin=="offers" and d.target=="inventory" then
   receipt.Visible=true
   if self.state.customer.mode=="Buyer" then
    emitMove({action="UnstageStock",customerId=d.customerId,id=d.item.id,x=d.x,y=d.y,rotation=d.rotation,revision=d.basketRevision})
   else
    local x,y,rotation=Tray.firstFit({inventory=self.state.customer.basket,upgrade=0,legacyRows=0},d.item.kind)
    if x then emitMove({action="StageOffer",customerId=d.customerId,id=d.item.id,x=x,y=y,rotation=rotation,stockX=d.x,stockY=d.y,stockRotation=d.rotation,revision=d.basketRevision}) else notice("Trade selection is full.",P.red) end
   end
  elseif d.origin=="offers" and d.target=="offers" and self.state.customer.mode=="Buyer" then
   emitMove({action="StageStock",customerId=d.customerId,id=d.item.id,x=d.x,y=d.y,rotation=d.rotation,revision=d.basketRevision})
  end
 end)
 Input.InputBegan:Connect(function(input: InputObject)
  if input.KeyCode==Enum.KeyCode.Escape then cancel();receipt.Visible=false
  elseif input.KeyCode==Enum.KeyCode.R and not Input:GetFocusedTextBox() then rotate() end
 end)
 Input.WindowFocusReleased:Connect(cancel)
 root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() cancel();if self.state then render() end end)
 function self.render(s: any)
  self.state=s;tooltip.Visible=false
  if pending and s.moveAck==pending then pending=nil end
  if drag then
   local c=s.customer
   if s.gridRevision~=drag.gridRevision or (drag.origin~="inventory" and (not c or c.id~=drag.customerId or c.basketRevision~=drag.basketRevision or c.state~="Interact")) then cancel()
   else return end
  end
  render()

 end
 return self
end
return Desk
