--!strict
local RS=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local Shared=RS:WaitForChild("Shared")
local Config=require(Shared.Config)
local Scene=require(Shared.Scene)
local Camera=require(script.Parent.CameraController)
local Desk=require(script.Parent.DeskController)
local remotes=RS:WaitForChild("Remotes")
local action=remotes:WaitForChild("Action") :: RemoteEvent
local state=remotes:WaitForChild("State") :: RemoteEvent
local ui=Desk.new(function(request: any) action:FireServer(request) end)
local visual: Model?=nil
local customerId: string?=nil
local phase: string?=nil
local stopMove: (()->())?=nil
local received=false
local folder=Instance.new("Folder"); folder.Name="LocalCustomer"; folder.Parent=workspace
local function markerPosition(snapshot: any,name: string,fallback: Vector3): Vector3
 local stage=workspace:FindFirstChild(snapshot.stageName)
 local marker=if stage then stage:FindFirstChild(name,true) else nil
 return if marker and marker:IsA("BasePart") then marker.Position else snapshot.origin+fallback
end
local function destroyVisual()
 if stopMove then stopMove(); stopMove=nil end
 if visual then visual:Destroy(); visual=nil end
end
state.OnClientEvent:Connect(function(snapshot: any)
 received=true; Camera.setOrigin(snapshot.origin);Camera.setStage(snapshot.stageName)
 local c=snapshot.customer
 if not c then destroyVisual(); customerId=nil; phase=nil
 else
  if customerId~=c.id then
   destroyVisual(); customerId=c.id; phase=nil
   visual=Scene.character(folder,markerPosition(snapshot,"VisitorEntry",Vector3.new(-14,5.2,-1.8)),Color3.fromRGB(c.color[1],c.color[2],c.color[3]))
   visual:ScaleTo(1.75)
  end
  if phase~=c.state and visual then
   if stopMove then stopMove(); stopMove=nil end
   phase=c.state
   if c.state=="WalkToCounter" then
    stopMove=Scene.move(visual,markerPosition(snapshot,"VisitorStand",Vector3.new(-2,5.2,-1.8)),Config.WalkSeconds)
   elseif c.state=="Interact" then
    visual:PivotTo(CFrame.new(markerPosition(snapshot,"VisitorStand",Vector3.new(-2,5.2,-1.8))))
   elseif c.state=="Leave" then
    stopMove=Scene.move(visual,markerPosition(snapshot,"VisitorExit",Vector3.new(14,5.2,-1.8)),Config.WalkSeconds)
   end
  end
 end
 ui.render(snapshot)
end)
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,false) end)
action:FireServer({action="Sync"})
for attempt=1,3 do
 task.delay(attempt*5,function() if not received then action:FireServer({action="Sync"}) end end)
end
