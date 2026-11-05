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
local function text(parent: Instance,value: string,pos: UDim2,size: UDim2,fontSize: number,color: Color3?): TextLabel
 return make("TextLabel",{Text=value,Position=pos,Size=size,TextColor3=color or P.ink,Font=Enum.Font.Gotham,TextSize=fontSize,TextWrapped=true,
  TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,BackgroundTransparency=1},parent)
end
local function button(parent: Instance,value: string,pos: UDim2,size: UDim2,fn: ()->()): TextButton
 local b=make("TextButton",{Text=value,Position=pos,Size=size,BackgroundColor3=P.teal,TextColor3=P.bg,Font=Enum.Font.GothamBold,TextSize=13,
  TextWrapped=true,BorderSizePixel=0,AutoButtonColor=true},parent);b.Activated:Connect(fn);return b
end
local function panel(parent: Instance,name: string): Frame
 local frame=make("Frame",{Name=name,BackgroundColor3=P.bg,BackgroundTransparency=0.02,BorderSizePixel=0},parent)
 make("UICorner",{CornerRadius=UDim.new(0,8)},frame)
 make("UIStroke",{Color=P.line,Thickness=1},frame);return frame
end
local function scroll(parent: Instance): ScrollingFrame
 local frame=make("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,
  CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},parent)
 make("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,12)},frame)
 make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},frame);return frame
end
local function rowText(parent: Instance,value: string,color: Color3?,size: number?): TextLabel
 return text(parent,value,UDim2.new(),UDim2.new(1,0,0,38),size or 14,color)
end
local function rowButton(parent: Instance,value: string,fn: ()->()): TextButton
 local b=button(parent,value,UDim2.new(),UDim2.new(1,0,0,38),fn)
 make("UICorner",{CornerRadius=UDim.new(0,5)},b);return b
end
local function receiptLine(parent: Instance,name: string,price: number,index: number): Frame
 local row=make("Frame",{Name="ReceiptItem_"..index,Size=UDim2.new(1,0,0,52),BackgroundColor3=P.raised,BorderSizePixel=0},parent)
 make("UICorner",{CornerRadius=UDim.new(0,5)},row)
 text(row,string.format("%02d",index),UDim2.fromOffset(10,15),UDim2.fromOffset(30,20),12,P.teal)
 local title=text(row,name,UDim2.fromOffset(43,7),UDim2.new(1,-140,0,38),14,P.ink);title.TextYAlignment=Enum.TextYAlignment.Center
 local amount=text(row,tostring(price).." E",UDim2.new(1,-96,0,16),UDim2.fromOffset(86,22),14,P.gold);amount.TextXAlignment=Enum.TextXAlignment.Right
 return row
end
local function locate(items: {any},id: string?): any for _,item in ipairs(items) do if item.id==id then return item end end;return nil end
function Desk.new(send: (any)->())
 local self: any={state=nil,selection=nil}
 local gui=make("ScreenGui",{Name="ShopDeskUI",ResetOnSpawn=false,IgnoreGuiInset=true,ScreenInsets=Enum.ScreenInsets.None,DisplayOrder=5,
  ZIndexBehavior=Enum.ZIndexBehavior.Sibling},Players.LocalPlayer:WaitForChild("PlayerGui"))
 local root=make("Frame",{Name="DeskRoot",Size=UDim2.fromScale(1,1),BackgroundTransparency=1},gui)
 -- Mouse button InputObjects keep their initial position. Always sample the live cursor.
 local function pointer(input: InputObject): Vector2
  if input.UserInputType~=Enum.UserInputType.Touch then return Input:GetMouseLocation() end
  local inset=GuiService:GetGuiInset()
  return Vector2.new(input.Position.X+inset.X,input.Position.Y+inset.Y)
 end
 local namePlate=panel(root,"VisitorName")
 local dialoguePanel=panel(root,"VisitorDialogue");dialoguePanel.Position=UDim2.new(0.27,0,0.40,0);dialoguePanel.Size=UDim2.new(0.40,0,0,72)
 local dialogue=text(dialoguePanel,"",UDim2.fromOffset(10,8),UDim2.new(1,-20,1,-16),15,P.ink)
 local visitorName=text(namePlate,"SERVICE WINDOW",UDim2.fromOffset(10,6),UDim2.new(1,-20,1,-12),16,P.ink)
 local receipt=panel(root,"Receipt");receipt.Visible=false;receipt.ZIndex=20
 local receiptDrag: any=nil;local movedReceipt=false;local receiptCustomer: string?=nil
 local title=button(receipt,"TRADE RECEIPT",UDim2.fromOffset(0,0),UDim2.new(1,-44,0,42),function() end);title.Name="ReceiptHandle";title.BackgroundColor3=P.panel;title.TextColor3=P.ink;title.TextXAlignment=Enum.TextXAlignment.Left;title.TextSize=15
 make("UIPadding",{PaddingLeft=UDim.new(0,14)},title)
 local close=button(receipt,"X",UDim2.new(1,-42,0,5),UDim2.fromOffset(34,32),function() receipt.Visible=false;receiptDrag=nil end);close.BackgroundColor3=P.raised;close.TextColor3=P.ink;make("UICorner",{CornerRadius=UDim.new(0,5)},close)
 title.InputBegan:Connect(function(input: InputObject)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   receiptDrag={input=input,start=pointer(input),position=receipt.AbsolutePosition};movedReceipt=true
  end
 end)
 local body=scroll(receipt);body.Name="ReceiptLines";body.Position=UDim2.fromOffset(0,48);body.Size=UDim2.new(1,0,1,-209)
 make("Frame",{Name="ReceiptDivider",Position=UDim2.new(0,10,1,-153),Size=UDim2.new(1,-20,0,1),BackgroundColor3=P.line,BorderSizePixel=0},receipt)
 local total=text(receipt,"TOTAL 0 E",UDim2.new(0,14,1,-145),UDim2.new(1,-28,0,28),18,P.ink);total.TextXAlignment=Enum.TextXAlignment.Right
 local status=text(root,"",UDim2.new(0.25,0,1,-24),UDim2.new(0.73,0,0,22),12,P.gold)
 local tooltip=panel(root,"ItemTooltip");tooltip.Visible=false;tooltip.Active=false;tooltip.ZIndex=60;tooltip.Size=UDim2.fromOffset(276,158)
 make("Frame",{Name="TooltipAccent",Position=UDim2.fromOffset(0,0),Size=UDim2.new(0,4,1,0),BackgroundColor3=P.teal,BorderSizePixel=0,ZIndex=61},tooltip)
 local tipTitle=text(tooltip,"",UDim2.fromOffset(16,12),UDim2.new(1,-30,0,24),17,P.ink);tipTitle.Font=Enum.Font.GothamBold;tipTitle.ZIndex=61;tipTitle.Active=false
 make("Frame",{Name="TooltipDivider",Position=UDim2.fromOffset(16,43),Size=UDim2.new(1,-32,0,1),BackgroundColor3=P.line,BorderSizePixel=0,ZIndex=61},tooltip)
 local tipPrice=text(tooltip,"",UDim2.fromOffset(16,52),UDim2.new(1,-32,0,26),18,P.gold);tipPrice.Font=Enum.Font.GothamBold;tipPrice.ZIndex=61;tipPrice.Active=false
 local tipText=text(tooltip,"",UDim2.fromOffset(16,87),UDim2.new(1,-32,0,62),13,P.muted);tipText.ZIndex=61;tipText.Active=false
 local tipTween: any=nil
 local ghost=make("Frame",{Name="TradeDragPreview",BackgroundTransparency=1,Visible=false,Active=false,ZIndex=40},root)
 local surfaces: any={};local mountedStage: any=nil;local mountEpoch=0
 local widgets: any={};local drag: any=nil;local pending: any=nil;local serial=0;local scrolling=false
 local phantom: any=nil;local phantomWidget: any=nil
 local selectedOrigin="inventory"
 local render: ()->();local preview: ()->();local startDrag: (string,any,any)->()
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
  if not current then return end
  local def=Items.Definitions[current.kind];local q=Tags.Qualities[current.qualityTag or Tags.DefaultQuality]
  local crime=Tags.Criminality[current.criminality or "none"].name
  tipTitle.Text=def.name
  tipPrice.Text=tostring(price or current.marketPrice or current.value or current.paid).." E"
  tipText.Text=Tags.Categories[def.tagCategory].name.."  •  "..q.name.."\n"..crime
  local tx=math.clamp(x+16,0,math.max(0,root.AbsoluteSize.X-280))
  local ty=math.clamp(y+18,0,math.max(0,root.AbsoluteSize.Y-162))
  tooltip.Position=UDim2.fromOffset(tx,math.max(0,ty-8))
  tooltip.Visible=true
  tipTween=TweenService:Create(tooltip,TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(tx,ty)})
  tipTween:Play()
 end
 local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
 local function surface(name: string,width: number,height: number): any
  local layer=make("SurfaceGui",{Name=name.."Surface",Face=Enum.NormalId.Back,CanvasSize=Vector2.new(width,height),SizingMode=Enum.SurfaceGuiSizingMode.FixedSize,
   Active=true,Enabled=false,AlwaysOnTop=false,LightInfluence=0,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,MaxDistance=500},playerGui)
  local container=make("Frame",{Name="SurfaceRoot",Size=UDim2.fromScale(1,1),BackgroundTransparency=1},layer)
  local value={gui=layer,root=container,canvas=Vector2.new(width,height),part=nil};surfaces[name]=value;return value
 end
 for _,name in ipairs({"offers","basket","inventory"}) do
  local layer=surface(name,if name=="inventory" then 750 else 620,if name=="inventory" then 390 else 300)
  widgets[name]=Widget.new(layer.root,if name=="offers" then "01 / VISITOR OFFERS" elseif name=="basket" then "02 / TO BUY" else "03 / YOUR INVENTORY",function(item: any,input: any) startDrag(name,item,input) end,function(item: any,x: number,y: number)
   local pointer=Input:GetMouseLocation();hover(name,item,pointer.X,pointer.Y)
  end)
  widgets[name].frame.Size=UDim2.fromScale(1,1)
 end
 local register=surface("register",320,160)
 local registerButton=button(register.root,"REGISTER",UDim2.new(),UDim2.fromScale(1,1),function()
  if drag then return end
  receipt.Visible=true;tooltip.Visible=false;render()
 end);registerButton.Name="RegisterButton";registerButton.Text="";registerButton.BackgroundTransparency=1
 local outline=make("Highlight",{Name="RegisterOutline",Enabled=false,FillTransparency=1,OutlineTransparency=0,OutlineColor=P.teal,DepthMode=Enum.HighlightDepthMode.Occluded},workspace)
 registerButton.MouseEnter:Connect(function() outline.Enabled=true end)
 registerButton.MouseLeave:Connect(function() outline.Enabled=false end)
 local nextSurface=surface("next",320,100)
 local nextButton=button(nextSurface.root,"",UDim2.new(),UDim2.fromScale(1,1),function() cancel();request("NextCustomer") end)
 nextButton.Name="CallCustomerButton";nextButton.BackgroundTransparency=1
 local nextOutline=make("Highlight",{Name="NextCustomerOutline",Enabled=false,FillTransparency=1,OutlineTransparency=0,OutlineColor=P.teal,DepthMode=Enum.HighlightDepthMode.Occluded},workspace)
 nextButton.MouseEnter:Connect(function() nextOutline.Enabled=true end)
 nextButton.MouseLeave:Connect(function() nextOutline.Enabled=false end)
 local dismissSurface=surface("dismiss",320,100)
 local dismissButton=button(dismissSurface.root,"",UDim2.new(),UDim2.fromScale(1,1),function()
  local c=self.state and self.state.customer
  if c and c.state=="Interact" then cancel();request("DismissCustomer",{customerId=c.id}) end
 end)
 dismissButton.Name="DismissCustomerButton";dismissButton.BackgroundTransparency=1
 local dismissOutline=make("Highlight",{Name="DismissCustomerOutline",Enabled=false,FillTransparency=1,OutlineTransparency=0,OutlineColor=P.red,DepthMode=Enum.HighlightDepthMode.Occluded},workspace)
 dismissButton.MouseEnter:Connect(function() dismissOutline.Enabled=true end)
 dismissButton.MouseLeave:Connect(function() dismissOutline.Enabled=false end)
 local dayLabel=text(root,"",UDim2.fromOffset(16,14),UDim2.fromOffset(280,26),17,P.gold)
 local shopLabel=text(root,"",UDim2.fromOffset(16,40),UDim2.fromOffset(280,22),12,P.teal)
 local sleepPrompt=panel(root,"SleepConfirmation");sleepPrompt.Size=UDim2.fromOffset(310,150);sleepPrompt.Position=UDim2.new(0.5,-155,0.5,-75);sleepPrompt.Visible=false;sleepPrompt.ZIndex=80
 text(sleepPrompt,"Sleep and advance to the next day?",UDim2.fromOffset(14,12),UDim2.fromOffset(282,60),17)
 button(sleepPrompt,"CANCEL",UDim2.fromOffset(14,98),UDim2.fromOffset(130,36),function() sleepPrompt.Visible=false end)
 button(sleepPrompt,"SLEEP",UDim2.fromOffset(160,98),UDim2.fromOffset(136,36),function() sleepPrompt.Visible=false;request("Sleep") end)
 local sleepSurface=surface("sleep",240,100)
 sleepSurface.gui.Face=Enum.NormalId.Top
 local sleepButton=button(sleepSurface.root,"",UDim2.new(),UDim2.fromScale(1,1),function() if self.state and not self.state.shopOpen then sleepPrompt.Visible=true else notice("Close the shop first.",P.red) end end);sleepButton.BackgroundTransparency=1
 local sleepOutline=make("Highlight",{Name="SleepOutline",Enabled=false,FillTransparency=1,OutlineColor=P.teal,DepthMode=Enum.HighlightDepthMode.Occluded},workspace)
 sleepButton.MouseEnter:Connect(function() sleepOutline.Adornee=sleepSurface.part;sleepOutline.Enabled=true end)
 sleepButton.MouseLeave:Connect(function() sleepOutline.Enabled=false end)
 local toggleSurface=surface("toggle",240,100)
 button(toggleSurface.root,"",UDim2.new(),UDim2.fromScale(1,1),function() request("ToggleShop") end).BackgroundTransparency=1
 local walletPanel=panel(root,"WalletGrid");walletPanel.Position=UDim2.new(0.5,-180,0.5,-190);walletPanel.Size=UDim2.fromOffset(360,380);walletPanel.Visible=false;walletPanel.ZIndex=70
 text(walletPanel,"WALLET / EDDIES",UDim2.fromOffset(12,12),UDim2.fromOffset(265,24),17,P.gold)
 button(walletPanel,"X",UDim2.fromOffset(318,8),UDim2.fromOffset(32,30),function() walletPanel.Visible=false end)
 local walletBody=make("Frame",{Name="Slots",Position=UDim2.fromOffset(12,55),Size=UDim2.fromOffset(336,255),BackgroundTransparency=1},walletPanel)
 local walletUpgrade=button(walletPanel,"",UDim2.fromOffset(12,328),UDim2.fromOffset(336,36),function() request("UpgradeWallet") end)
 local walletSurface=surface("wallet",240,100)
 walletSurface.gui.Face=Enum.NormalId.Top
 button(walletSurface.root,"",UDim2.new(),UDim2.fromScale(1,1),function() walletPanel.Visible=not walletPanel.Visible end).BackgroundTransparency=1
 local walletDrag: number?=nil
 local moneyGhost=text(root,"",UDim2.new(),UDim2.fromOffset(78,38),15,P.gold);moneyGhost.Visible=false;moneyGhost.ZIndex=90;moneyGhost.BackgroundColor3=P.panel;moneyGhost.BackgroundTransparency=0.12
 Input.InputChanged:Connect(function(input: InputObject)
  if walletDrag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
   local point=pointer(input);moneyGhost.Position=UDim2.fromOffset(point.X-39,point.Y-19)
  end
 end)
 local function drawWallet(s: any)
  clear(walletBody)
  local tier=s.walletTier or 0;local dims=Wallet.Sizes[tier+1];local cols,rows=dims[1],dims[2]
  local slotWidth=math.floor(336/cols);local slotHeight=math.floor(255/rows)
  local occupied={}
  for index,stack in ipairs(s.walletStacks or {}) do
   local slot=(s.walletSlots or {})[tostring(stack.denomination)] or index
   occupied[slot]=stack
  end
  for index=1,cols*rows do
   local stack=occupied[index]
   local x=((index-1)%cols)*slotWidth;local y=math.floor((index-1)/cols)*slotHeight
   local cell=button(walletBody,if stack then stack.denomination.." E\n×"..stack.count else "",UDim2.fromOffset(x+2,y+2),UDim2.fromOffset(slotWidth-4,slotHeight-4),function() end)
   cell.Name="WalletSlot"..index;cell.BackgroundColor3=P.raised;cell.TextColor3=P.gold;cell.ZIndex=71
   cell.InputBegan:Connect(function(input: InputObject)
    if stack and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
     walletDrag=stack.denomination;moneyGhost.Text=stack.denomination.." E";moneyGhost.Visible=true
     local point=pointer(input);moneyGhost.Position=UDim2.fromOffset(point.X-39,point.Y-19)
    end
   end)
  end
  walletUpgrade.Text=if tier>=3 then "MAX WALLET / LEGENDARY" else "UPGRADE TO "..Wallet.Rarities[tier+2]:upper().." / "..Wallet.Prices[tier+2].." E"
 end
 Input.InputEnded:Connect(function(input: InputObject)
  if not walletDrag or not walletPanel.Visible or (input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch) then return end
  local denomination=walletDrag;walletDrag=nil;moneyGhost.Visible=false
  local point=pointer(input)-walletBody.AbsolutePosition
  if point.X<0 or point.Y<0 or point.X>=walletBody.AbsoluteSize.X or point.Y>=walletBody.AbsoluteSize.Y then return end
  local dims=Wallet.Sizes[(self.state.walletTier or 0)+1];local cols,rows=dims[1],dims[2]
  local col=math.floor(point.X/(336/cols));local row=math.floor(point.Y/(255/rows))
  request("MoveMoney",{denomination=denomination,slot=row*cols+col+1})
 end)
 local function bindStage(name: string?)
  if mountedStage==name then return end
  mountedStage=name;mountEpoch+=1;local epoch=mountEpoch
  for _,layer in pairs(surfaces) do layer.part=nil;layer.gui.Adornee=nil;layer.gui.Enabled=false end
  outline.Enabled=false;outline.Adornee=nil;nextOutline.Enabled=false;nextOutline.Adornee=nil;dismissOutline.Enabled=false;dismissOutline.Adornee=nil;sleepOutline.Enabled=false;sleepOutline.Adornee=nil
  local function attempt()
   if epoch~=mountEpoch then return end
   local stage=if name then workspace:FindFirstChild(name) else nil
   local complete=true
   for key,partName in pairs({inventory="InventoryBoard",basket="BuyBoard",offers="VisitorBoard",register="RegisterBox",next="NextCustomerButton",dismiss="DismissCustomerButton",sleep="SleepingBag",toggle="ShopToggle",wallet="Wallet"}) do
    local part=if stage then stage:FindFirstChild(partName,true) else nil
    local layer=surfaces[key];layer.part=part;layer.gui.Adornee=part;layer.gui.Enabled=part~=nil
    if part and (key=="inventory" or key=="basket" or key=="offers") then
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
 local buy=button(receipt,"BUY",UDim2.new(0,12,1,-74),UDim2.new(1,-24,0,34),function()
  local c=self.state and self.state.customer
  if not c or c.state~="Interact" then return end
  if c.quote then request(if c.mode=="Buyer" then "ConfirmSale" else "ConfirmPurchase",{customerId=c.id,quoteId=c.quote.id})
  else request(if c.mode=="Buyer" then "ReviewSale" else "ReviewPurchase",{customerId=c.id}) end
 end);buy.Name="BuyButton";make("UICorner",{CornerRadius=UDim.new(0,5)},buy)
 local bulk=button(receipt,"BUY BULK",UDim2.new(0,12,1,-112),UDim2.new(1,-24,0,34),function()
  local c=self.state and self.state.customer
  if c and c.mode=="Seller" and c.bulkPercent and c.state=="Interact" then request("BuyBulk",{customerId=c.id}) end
 end);bulk.Name="BuyBulkButton";bulk.Visible=false;bulk.BackgroundColor3=P.gold;make("UICorner",{CornerRadius=UDim.new(0,5)},bulk)
 local clearButton=button(receipt,"CLEAR",UDim2.new(0,12,1,-36),UDim2.new(1,-24,0,26),function() local c=self.state and self.state.customer;if c then request("ClearBasket",{customerId=c.id}) end end)
 clearButton.BackgroundColor3=P.raised;clearButton.TextColor3=P.muted;make("UICorner",{CornerRadius=UDim.new(0,5)},clearButton)
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
  end
 end
 -- Rotation remains bound to R without a screen button.
 local function emitMove(data: any)
  serial+=1;data.moveId=serial;pending=serial;send(data)
  task.delay(5,function() if pending==data.moveId then pending=nil;cancel();request("Sync");notice("Connection delayed.",P.red) end end)
 end
 local function positionOf(widget: any,point: Vector2,gx: number,gy: number): (number,number)
  local p=widget.origin()
  return Snap.project(point.X,point.Y,p.X,p.Y,widget.cellSize,gx,gy)
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
  if widget and target then local point=canvasPoint(target,drag.point);if point then x,y=positionOf(widget,point,drag.grabX,drag.grabY) end end
  if drag.origin=="inventory" and target=="inventory" then valid=Grid.check(s,drag.item.kind,x,y,drag.rotation,drag.item.id)
  elseif drag.origin=="inventory" and target=="offers" and c and c.mode=="Buyer" and c.state=="Interact" and Items.Definitions[drag.item.kind].tagCategory==c.requestTag then
   valid=Tray.check({inventory=c.basket,upgrade=0,legacyRows=0},drag.item.kind,x,y,drag.rotation,drag.item.id)
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
   phantom=make("Frame",{Name="GridPhantom",BackgroundTransparency=1,Active=false,ZIndex=30},widget.board)
   local cells,w,h=Grid.cells(drag.item.kind,drag.rotation)
   Widget.draw(phantom,drag.item,cells,w,h,widget.cellSize,true,nil);phantomWidget=widget
  end
  phantom.Position=UDim2.fromOffset(x*widget.cellSize,y*widget.cellSize)
  local view=phantom:GetChildren()[1]
  for _,piece in ipairs(view:GetChildren()) do
   if piece:IsA("GuiObject") then piece.BackgroundColor3=if valid then P.teal else P.red;piece.BackgroundTransparency=0.48 end
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
   local widget=widgets[if drag.origin=="inventory" then "inventory" else "basket"]
   local p,size=Vector2.new(0,0),Vector2.new(widget.canvasWidth,widget.canvasHeight)
   local pointer=canvasPoint(if drag.origin=="inventory" then "inventory" else "basket",drag.point)
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
  if drag or pending or receiptDrag or not self.state or covered(pointer(input)) then return end
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
  local size=root.AbsoluteSize;local bounds=receipt.AbsoluteSize
  receipt.Position=UDim2.fromOffset(math.clamp(x,0,math.max(0,size.X-bounds.X)),math.clamp(y,0,math.max(0,size.Y-bounds.Y)))
 end
 local function layout()
  local size=root.AbsoluteSize
  namePlate.Position=UDim2.new(0.28,0,0.06,0);namePlate.Size=UDim2.new(0.40,0,0,34)
  receipt.Size=UDim2.fromOffset(math.min(340,size.X-24),math.min(440,size.Y-48))
  if not movedReceipt then receipt.Position=UDim2.fromOffset(18,math.max(40,size.Y*0.24)) end
  clampReceipt(receipt.AbsolutePosition.X,receipt.AbsolutePosition.Y)
 end
 render=function()
  local s=self.state;if not s then return end;bindStage(s.stageName);layout()
  dayLabel.Text="DAY "..s.day.." / "..s.visits.." OF "..s.maxVisits.." VISITORS"
  shopLabel.Text=if s.shopOpen then "SHOP OPEN" else "SHOP CLOSED"
  if walletPanel.Visible then drawWallet(s) end
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
  end
  widgets.offers.render(if c and c.mode=="Buyer" then basket else offered,Config.TradeColumns,Config.TradeRows,Tray,surfaces.offers.canvas)
  widgets.basket.render({},Config.TradeColumns,Config.TradeRows,Tray,surfaces.basket.canvas)
  surfaces.basket.gui.Enabled=false
  local owned={}
  for _,item in ipairs(s.inventory) do if not (c and c.mode=="Buyer" and staged and staged[item.id]) then table.insert(owned,item) end end
  widgets.inventory.render(owned,s.gridColumns,s.gridRows,Grid,surfaces.inventory.canvas)
  widgets.basket.heading.Text=""
  clear(body)
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
   if not q.affordable then rowText(body,"Insufficient funds",P.red) end
  elseif c and c.state=="Interact" and (c.itemId or c.requestTag) then
   rowText(body,"WANTED: "..(if c.requestTag then Tags.Categories[c.requestTag].name else Items.Definitions[c.kind].name),P.gold)
   if c.itemId and c.mode~="Buyer" then
   rowButton(body,"SELL / "..c.offer.." E",function() request("Accept",{customerId=c.id}) end)
   local ask=make("TextBox",{Name="AskPrice",Size=UDim2.new(1,0,0,32),Text="",PlaceholderText="Sale price",ClearTextOnFocus=false,TextSize=14},body)
   rowButton(body,"COUNTER",function() request("Counter",{customerId=c.id,price=tonumber(ask.Text)}) end)
  end
  end
  local selected=if selectedOrigin=="inventory" then locate(s.inventory,self.selection) else nil
  if selected then
   rowText(body,Items.Definitions[selected.kind].name,P.ink,14)
   for _,quality in ipairs(Tags.QualityOrder) do
    local tag=Tags.Qualities[quality]
    rowButton(body,tag.name.." / x"..string.format("%.2f",tag.multiplier),function() request("SetItemTag",{id=selected.id,qualityTag=quality}) end)
   end
  end
  notice(s.message or "")
 end
 Input.InputChanged:Connect(function(input: InputObject)
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
  if receiptDrag then
   local d=receiptDrag
   if (d.input.UserInputType==Enum.UserInputType.Touch and input==d.input) or (d.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1) then receiptDrag=nil end
   return
  end
  if not drag then return end
  if not ((drag.input.UserInputType==Enum.UserInputType.Touch and input==drag.input) or
   (drag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then return end
  updateDrag(pointer(input));local d=drag;cancel()
  if not d.active then return end
  if not d.valid then notice("Placement blocked.",P.red);return end
  if d.origin=="inventory" and d.target=="inventory" then
   if d.x==d.item.gridX and d.y==d.item.gridY and d.rotation==d.item.rotation then return end
   emitMove({action="PlaceItem",id=d.item.id,x=d.x,y=d.y,rotation=d.rotation,revision=d.gridRevision})
  elseif d.origin=="inventory" and d.target=="offers" then
   receipt.Visible=true;emitMove({action="StageStock",customerId=d.customerId,id=d.item.id,x=d.x,y=d.y,rotation=d.rotation,revision=d.basketRevision})
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
