--!strict
local TweenService = game:GetService("TweenService")
local Scene = {}
local C = Color3.fromRGB

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, neon: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.Position = position; p.Color = color
	p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = false
	p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function sign(parent: Instance, text: string, size: Vector3, position: Vector3, color: Color3)
	local board = part(parent, "Sign", size, position, C(15, 24, 32))
	local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(600, 120); gui.LightInfluence = 0; gui.Parent = board
	local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1; label.Text = text; label.Font = Enum.Font.Code
	label.TextScaled = true; label.TextColor3 = color; label.Parent = gui
	local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.Parent = label
end

function Scene.character(parent: Instance, position: Vector3, color: Color3): Model
	local model = Instance.new("Model"); model.Name = "PixelMerchant"
	local root = part(model, "Root", Vector3.new(0.1, 0.1, 0.1), position, color); root.Transparency = 1
	model.PrimaryPart = root
	local function block(name: string, x: number, y: number, w: number, h: number, c: Color3, z: number?)
		part(model, name, Vector3.new(w, h, 0.4), position + Vector3.new(x, y, z or 0), c)
	end
	block("BootL", -0.45, 0.22, 0.7, 0.45, C(21, 27, 35)); block("BootR", 0.45, 0.22, 0.7, 0.45, C(21, 27, 35))
	block("LegL", -0.4, 0.9, 0.55, 1.1, C(43, 57, 69)); block("LegR", 0.4, 0.9, 0.55, 1.1, C(43, 57, 69))
	block("Coat", 0, 2, 1.65, 1.5, color); block("Shirt", 0, 2.1, 0.35, 1.1, C(32, 42, 49), 0.23)
	block("ArmL", -1.02, 1.9, 0.42, 1.25, color); block("ArmR", 1.02, 1.9, 0.42, 1.25, color)
	block("HandL", -1.02, 1.16, 0.42, 0.36, C(203, 160, 128)); block("HandR", 1.02, 1.16, 0.42, 0.36, C(203, 160, 128))
	block("Head", 0, 3.35, 1.35, 1.2, C(203, 160, 128)); block("Hair", 0, 3.95, 1.5, 0.38, C(27, 32, 43))
	block("EyeL", -0.32, 3.4, 0.18, 0.18, C(20, 27, 33), 0.24); block("EyeR", 0.32, 3.4, 0.18, 0.18, C(20, 27, 33), 0.24)
	block("Badge", 0.48, 2.25, 0.25, 0.32, C(236, 192, 108), 0.24)
	model.Parent = parent
	return model
end

function Scene.move(model: Model, destination: Vector3, seconds: number): () -> ()
	local cf = Instance.new("CFrameValue"); cf.Value = model:GetPivot()
	local connection = cf.Changed:Connect(function(value: CFrame) if model.Parent then model:PivotTo(value) end end)
	local tween = TweenService:Create(cf, TweenInfo.new(seconds, Enum.EasingStyle.Linear), {Value = CFrame.new(destination)})
	local finished = false
	local function clean()
		if finished then return end
		finished = true; connection:Disconnect(); tween:Cancel(); cf:Destroy()
	end
	tween.Completed:Once(function() clean() end)
	tween:Play()
	return clean
end

function Scene.build(parent: Instance, origin: Vector3, name: string): Model
 local m = Instance.new("Model"); m.Name = name
 local function p(n: string,x: number,y: number,z: number,sx: number,sy: number,sz: number,color: Color3,neon: boolean?)
  return part(m,n,Vector3.new(sx,sy,sz),origin+Vector3.new(x,y,z),color,neon)
 end
 -- The viewer stands inside the booth. The service opening looks out onto a corridor.
 p("Hall darkness",-2,10,-6,20,12,0.5,C(14,20,31))
 for i=1,7 do
  p("Hall rib",-11+i*2.5,10,-5.6,0.25,11,0.35,C(36,44,54))
  p("Hall light",-11+i*2.5,14.2,-5.2,1,0.1,0.2,C(83,133,133),true)
 end
 p("Left booth wall",-18,9,0,14,20,0.7,C(48,64,68))
 p("Right booth wall",16,9,0,18,20,0.7,C(48,64,68))
 p("Ceiling beam",0,17,0,50,4,0.7,C(45,41,52))
 p("Lower booth wall",-2,2,0,20,6,0.6,C(48,64,68))
 for _,x in ipairs({-11.5,7.5}) do
  p("Window upright",x,10,0.7,0.7,11,0.8,C(103,83,79))
  p("Window inner trim",x+(if x<0 then 0.42 else -0.42),10,1.05,0.12,10.7,0.15,C(191,151,97),true)
 end
 p("Window lintel",-2,15.5,0.7,20,0.65,0.8,C(103,83,79))
 p("Service sill",-2,4.5,2,20,0.5,5,C(109,113,100))
 p("Counter surface",0,2.8,5,48,0.8,8,C(91,108,108))
 p("Counter front",0,-0.3,8.5,48,5.6,0.8,C(40,47,58))
 for x=-22,22,4 do
  p("Worn counter edge",x,3.23,8.9,1.5,0.07,0.15,C(150,144,119))
 end
 -- Mounted interaction surfaces face the seller. Counter tray is tilted toward the viewer.
 local function board(name: string,x: number,y: number,z: number,w: number,h: number,tilt: number?)
  local b=p(name,x,y,z,w,h,0.35,C(26,34,44));b.CanQuery=true
  if tilt then b.Orientation=Vector3.new(tilt,0,0) end
  return b
 end
 board("InventoryBoard",0,-1.8,9.3,23,10)
 board("VisitorBoard",12,11.1,2,13,5.9)
 local controls=Instance.new("Model");controls.Name="InteractionControls";controls.Parent=m
 local sleep=p("SleepingBag",-17,0.5,11,5,0.5,3,C(70,74,105));sleep.CanQuery=true
 local shutter=p("ShopToggle",-20,8,8,3,1.4,0.4,C(68,128,121));shutter.CanQuery=true
 for _,entry in ipairs({{sleep,Enum.NormalId.Top,C(160,143,215)},{shutter,Enum.NormalId.Back,C(111,218,196)}}) do
  local face=Instance.new("SurfaceGui");face.Name="EditOutline";face.Face=entry[2];face.CanvasSize=Vector2.new(320,100);face.LightInfluence=0;face.Parent=entry[1]
  local border=Instance.new("Frame");border.Name="Border";border.Size=UDim2.fromScale(1,1);border.BackgroundTransparency=1
  border.BorderSizePixel=5;border.BorderColor3=entry[3];border.Parent=face
 end
 local function control(name: string,y: number,z: number,h: number,color: Color3)
  local base=board(name,-14,y,z,4.6,h);base.Parent=controls
  local face=Instance.new("SurfaceGui");face.Name="EditOutline";face.Face=Enum.NormalId.Back
  face.CanvasSize=Vector2.new(320,100);face.LightInfluence=0;face.Parent=base
  local border=Instance.new("Frame");border.Name="Border";border.Size=UDim2.fromScale(1,1)
  border.BackgroundTransparency=1;border.BorderSizePixel=5;border.BorderColor3=color;border.Parent=face
 end
 control("RegisterBox",4.9,7.4,2.8,C(241,194,116))
 control("NextCustomerButton",2.8,9.2,1.1,C(111,218,196))
 control("DismissCustomerButton",1.5,9.2,1.1,C(242,127,120))
 local function marker(name: string,x: number,y: number,z: number)
  local value=p(name,x,y,z,0.2,0.2,0.2,C(113,209,182));value.Transparency=1
 end
 marker("ViewTarget",0,4.5,0)
 local mount=p("CameraMount",0,4.5,70,1.5,1,0.3,C(111,218,196));mount.Transparency=0.25
 marker("VisitorStand",-2,5.2,-1.8)
 marker("VisitorEntry",-14,5.2,-1.8)
 marker("VisitorExit",14,5.2,-1.8)
 p("Status terminal",-17,15.5,0.8,8,2.8,0.6,C(35,42,49))
 p("Status glow",-17,15.5,1.15,7.3,2.1,0.12,C(72,169,146),true)
 local money=p("MoneyDisplay",-17,12.4,0.9,8,3.1,0.6,C(18,36,39))
 local display=Instance.new("SurfaceGui");display.Name="CashSurface";display.Face=Enum.NormalId.Back
 display.CanvasSize=Vector2.new(640,240);display.LightInfluence=0;display.Parent=money
 local balance=Instance.new("TextLabel");balance.Name="Balance";balance.Size=UDim2.fromScale(1,1)
 balance.BackgroundTransparency=1;balance.Text="--- EDDIES";balance.Font=Enum.Font.Code
 balance.TextScaled=true;balance.TextColor3=C(111,231,192);balance.Parent=display
 sign(m,"NIGHT MARKET",Vector3.new(6,1,0.3),origin+Vector3.new(-2,16.7,1.1),C(222,186,113))
 for i=1,4 do
  p("Cable vertical",-23+i*0.3,10,0.6,0.1,18,0.2,C(28+i*5,34,40))
 end
 p("Pipe vertical",21,10,0.7,0.5,17,0.6,C(89,100,99))
 p("Pipe elbow",18,17,0.7,6,0.5,0.6,C(89,100,99))
 p("Radio",-17,4,5,4,2,2,C(44,50,62))
 p("Radio screen",-17,4.2,6.1,2.8,0.65,0.1,C(102,183,154),true)
 p("Desk keypad",-9,3.5,6,3,0.45,2.4,C(43,55,64))
 for x=0,3 do for y=0,2 do
  p("Key",-10+x*0.6,3.8,5.2+y*0.55,0.32,0.1,0.32,C(137,177,164))
 end end
 p("Receipt machine",16,4.1,4.7,6,2.3,3,C(110,120,111))
 p("Receipt paper",16,6,4.5,3.7,2.8,0.2,C(216,196,143))
 for i=1,4 do p("Receipt line",16,5.3+i*0.4,4.64,2.8,0.08,0.04,C(129,118,89)) end
 p("Desk lamp base",11,3.4,4.5,2.5,0.3,2,C(45,50,57))
 p("Desk lamp stem",11,6,4.5,0.25,5,0.25,C(75,80,79))
 p("Desk lamp shade",10.5,8.4,4.5,3,0.6,2,C(57,71,73))
 p("Lamp strip",10.5,8.05,4.5,2.5,0.1,1.5,C(225,196,126),true)
 for i=1,3 do p("Stock"..i,-21+(i-1)*2,4,5,1.2,1.2,1.2,C(63,72,77)) end
 m.Parent=parent;return m
end

-- Clone the saved Studio shop. Only offset the clone; never rebuild or modify the template.
function Scene.spawn(template: Model?,parent: Instance,origin: Vector3,name: string): Model
 if not template then return Scene.build(parent,origin,name) end
 local stage=template:Clone();stage.Name=name
 for _,object in ipairs(stage:GetDescendants()) do
  if object:IsA("BasePart") then object.CFrame=object.CFrame+origin end
 end
 stage.Parent=parent;return stage
end

function Scene.cash(stage: Model,amount: number)
 local part=stage:FindFirstChild("MoneyDisplay",true)
 local surface=if part then part:FindFirstChild("CashSurface") else nil
 local label=if surface then surface:FindFirstChild("Balance") else nil
 if label and label:IsA("TextLabel") then
  local value=tostring(amount).." EDDIES"
  if label.Text~=value then label.Text=value end
 end
end

function Scene.stock(stage: Model, counts: {number}, colors: {{number}})
	for i, count in ipairs(counts) do
		local stock = stage:FindFirstChild("Stock" .. i,true) :: Part?
		if stock then stock.Color = if count > 0 then C(colors[i][1], colors[i][2], colors[i][3]) else C(63, 72, 77) end
	end
end
return Scene
