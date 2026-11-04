-- A build-time API double evaluates the real scene builder into a Rojo JSON model.
-- It does not render or simulate Roblox.
local children={}
local meta={}
function meta.__newindex(self,key,value)
 rawset(self,key,value)
 if key=="Parent" then table.insert(children[value],self) end
end
local Instance={}
function Instance.new(class)
 local obj=setmetatable({ClassName=class,Name=class},meta); children[obj]={}; return obj
end
local vmeta={}
function vmeta.__add(a,b) return setmetatable({a[1]+b[1],a[2]+b[2],a[3]+b[3],kind="Vector3"},vmeta) end
local Vector3={new=function(x,y,z) return setmetatable({x,y,z,kind="Vector3"},vmeta) end}
local Vector2={new=function(x,y) return {x,y,kind="Vector2"} end}
local Color3={fromRGB=function(r,g,b) return {r/255,g/255,b/255,kind="Color3"} end}
local UDim2={fromScale=function(x,y) return {x,0,y,0,kind="UDim2"} end}
local UDim={new=function(s,o) return {s,o,kind="UDim"} end}
local Enum=setmetatable({},{__index=function(_,name)
 return setmetatable({},{__index=function(_,value) return {enum=value} end})
end})
local env=setmetatable({game={GetService=function() return {} end},Instance=Instance,Vector3=Vector3,
 Vector2=Vector2,Color3=Color3,UDim2=UDim2,UDim=UDim,Enum=Enum},{__index=getfenv()})
local fn=assert(loadstring(SCENE_SOURCE)); setfenv(fn,env); local Scene=fn()
local root=Instance.new("Folder")
local scene=Scene.build(root,Vector3.new(0,0,0),"StagePreview")
local function quote(s) return '"'..s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"' end
local function encode(value)
 if type(value)=="string" then return quote(value) end
 if type(value)=="number" or type(value)=="boolean" then return tostring(value) end
 if value.enum then return quote(value.enum) end
 if value.kind=="UDim" then return '{"UDim":['..value[1]..','..value[2]..']}' end
 if value.kind=="UDim2" then return '{"UDim2":[['..value[1]..','..value[2]..'],['..value[3]..','..value[4]..']]}' end
 local out={}
 if value.kind or #value>0 then
  for _,v in ipairs(value) do table.insert(out,encode(v)) end
  return '['..table.concat(out,',')..']'
 end
 local keys={}; for k in pairs(value) do table.insert(keys,k) end; table.sort(keys)
 for _,k in ipairs(keys) do table.insert(out,quote(k)..':'..encode(value[k])) end
 return '{'..table.concat(out,',')..'}'
end
local total=0
local function export(obj)
 total+=1
 local props={}
 for key,value in pairs(obj) do
  if key~="ClassName" and key~="Name" and key~="Parent" and key~="PrimaryPart" then
   if key=="Position" and value.kind=="Vector3" then props.CFrame={value[1],value[2],value[3],1,0,0,0,1,0,0,0,1}
   else props[key]=value end
  end
 end
 -- Orientation is a derived engine property; serialize its actual CFrame instead.
 if obj.Orientation then
  assert(obj.Orientation[2]==0 and obj.Orientation[3]==0,"Build shim supports X tilt only")
  local angle=math.rad(obj.Orientation[1]);local c,s=math.cos(angle),math.sin(angle)
  local v=obj.Position;props.CFrame={v[1],v[2],v[3],1,0,0,0,c,-s,0,s,c};props.Orientation=nil
 end
 local out={ClassName=obj.ClassName,Name=obj.Name,Properties=props}
 if #children[obj]>0 then out.Children={}; for _,child in ipairs(children[obj]) do table.insert(out.Children,export(child)) end end
 return out
end
print(encode(export(scene)))
