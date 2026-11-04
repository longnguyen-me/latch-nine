local function event() return {Connect=function() return {Disconnect=function() end} end} end
local V={}
local mt={__add=function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},getmetatable(a)) end,__mul=function(a,b) return V.new(a.X*b,a.Y*b,a.Z*b) end}
function V.new(x,y,z) return setmetatable({X=x,Y=y,Z=z},mt) end;V.zero=V.new(0,0,0)
local display={CFrame="CUSTOM MONEY POSITION",Size="CUSTOM MONEY SIZE",IsA=function(_,name) return name=="BasePart" end}
local target={Position=V.new(4,6,2),IsA=function(_,name) return name=="BasePart" end}
local camera={ViewportSize={X=1440,Y=900},GetPropertyChangedSignal=event}
local mount=nil
local workspaceMock={CurrentCamera=camera,GetPropertyChangedSignal=event,FindFirstChild=function() return {FindFirstChild=function(_,name) return if name=="ViewTarget" then target elseif name=="CameraMount" then mount else nil end} end}
local fn=assert(loadstring(Sources.CameraController,"CameraController"))
setfenv(fn,setmetatable({workspace=workspaceMock,Vector3=V,CFrame={new=function(value) return {Position=value} end,lookAt=function(from,to) return {Position=from,Target=to} end},
 Enum={CameraType={Scriptable="Scriptable"}}},{__index=getfenv()}))
local control=fn();control.setStage("Shop_1");control.setOrigin(V.zero)
assert(display.CFrame=="CUSTOM MONEY POSITION" and display.Size=="CUSTOM MONEY SIZE" and camera.CFrame.Target==target.Position);print("PASS camera: saved money placement is untouched and ViewTarget controls framing")
local wideDistance=camera.CFrame.Position.Z-target.Position.Z
assert(math.abs(wideDistance-35/(2*math.tan(math.rad(14))))<0.01);print("PASS camera: desktop view zooms out to fit the wider ore counter")
camera.ViewportSize={X=390,Y=844};control.setOrigin(V.new(100,0,0))
assert(display.CFrame=="CUSTOM MONEY POSITION" and camera.CFrame.Target==target.Position);print("PASS camera: portrait framing preserves saved shop geometry")
assert(camera.CFrame.Position.Z-target.Position.Z>wideDistance);print("PASS camera: portrait view expands to fit vertical boards")
mount={Position=V.new(2,8,60),CFrame={LookVector=V.new(0,0,-1)},IsA=function(_,name) return name=="BasePart" end}
control.setStage("Shop_1");assert(camera.CFrame==mount.CFrame and camera.CameraType=="Scriptable");print("PASS camera: authored CameraMount controls position and rotation")
print("5 physical display framing checks passed")
