-- Actual surface projection code, deterministic geometry and camera API double.
local fn=assert(loadstring(Sources.SurfaceInput,"SurfaceInput"))
local ray
local env={workspace={CurrentCamera={ViewportPointToRay=function() return ray end}},Vector2={new=function(x,y) return {X=x,Y=y} end}}
setfenv(fn,setmetatable(env,{__index=getfenv()}));local S=fn()
local count=0
local function check(ok,name) assert(ok,name);count+=1;print("PASS surface: "..name) end
local function near(a,b) return a and math.abs(a-b)<0.00001 end
local x,y,t=S.intersect(0,0,10,0,0,-1,20,10,0.4,750,390)
check(near(x,375) and near(y,195) and near(t,9.8),"center ray maps to canvas center and nearest distance")
x,y=S.intersect(-10,5,10,0,0,-1,20,10,0.4,750,390)
check(near(x,0) and near(y,0),"back face top-left maps to zero without mirroring")
x,y=S.intersect(10,-5,10,0,0,-1,20,10,0.4,750,390)
check(near(x,750) and near(y,390),"bottom-right maps to full canvas dimensions")
x,y=S.intersect(12,0,10,0,0,-1,20,10,0.4,750,390)
check(x>750,"outside candidates remain outside for hit testing")
check(S.intersect(0,0,10,1,0,0,20,10,0.4,750,390)==nil,"parallel rays have no target")
check(S.intersect(0,0,-10,0,0,1,20,10,0.4,750,390)==nil,"rear face rays cannot select a board")
check(S.intersect(0,0,-10,0,0,-1,20,10,0.4,750,390)==nil,"intersection behind the camera is rejected")
local angle=math.rad(-22);local c,s=math.cos(angle),math.sin(angle)
local function world(x,y,z) return {X=100+x,Y=6+c*y-s*z,Z=9+s*y+c*z} end
local part={Parent=true,Size={X=13,Y=6,Z=0.4},CFrame={}}
function part.CFrame:PointToObjectSpace(p) local yy,zz=p.Y-6,p.Z-9;return {X=p.X-100,Y=c*yy+s*zz,Z=-s*yy+c*zz} end
function part.CFrame:VectorToObjectSpace(p) return {X=p.X,Y=c*p.Y+s*p.Z,Z=-s*p.Y+c*p.Z} end
local o=world(3,1,10);ray={Origin=o,Direction={X=0,Y=s,Z=-c}}
local point,distance=S.project(part,{X=620,Y=300},{X=10,Y=20})
check(near(point.X,(3/13+0.5)*620) and near(point.Y,100) and near(distance,9.8),"tilted counter and translated booth project into their own canvas")
part.Parent=nil;check(S.project(part,{X=620,Y=300},{X=10,Y=20})==nil,"removed surfaces cannot receive a drop")
print(count.." surface projection checks passed")
