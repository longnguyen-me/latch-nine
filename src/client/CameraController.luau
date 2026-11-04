--!strict
local CameraController = {}
local origin = Vector3.zero
local stageName: string? = nil
local viewportConnection: RBXScriptConnection? = nil
local function apply()
 local camera=workspace.CurrentCamera
 if not camera then return end
 local v=camera.ViewportSize
 local aspect=math.max(0.3,v.X/math.max(1,v.Y))
 local viewHeight=math.max(34,56/aspect)
 local distance=viewHeight/(2*math.tan(math.rad(14)))
 local stage=if stageName then workspace:FindFirstChild(stageName) else nil
 local mount=if stage then stage:FindFirstChild("CameraMount",true) else nil
 if mount and mount:IsA("BasePart") then
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=mount.CFrame;camera.Focus=CFrame.new(mount.Position+mount.CFrame.LookVector*20)
  return
 end
 local marker=if stage then stage:FindFirstChild("ViewTarget",true) else nil
 local target=if marker and marker:IsA("BasePart") then marker.Position else origin+Vector3.new(0,4.5,0)
 camera.CameraType=Enum.CameraType.Scriptable
 camera.FieldOfView=28
 camera.CFrame=CFrame.lookAt(target+Vector3.new(0,0,distance),target)
 camera.Focus=CFrame.new(target)
end
function CameraController.setStage(name: string) stageName=name;apply() end
function CameraController.setOrigin(value: Vector3) origin=value; apply() end
local function bind()
 if viewportConnection then viewportConnection:Disconnect() end
 if workspace.CurrentCamera then
  viewportConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
 end
 apply()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bind)
bind()
return CameraController
