-- Actual Scene.spawn clone behavior with model/part API doubles.
local fn=assert(loadstring(Sources.Scene,"Scene"))
setfenv(fn,setmetatable({game={GetService=function() return {} end},Color3={fromRGB=function() return {} end}},{__index=getfenv()}))
local Scene=fn();local count=0
local function check(ok,name) assert(ok,name);count+=1;print("PASS shop: "..name) end
local original={{Name="Moved Board",CFrame=42,IsA=function(_,class) return class=="BasePart" end},{Name="Nested Decoration",CFrame=73,IsA=function(_,class) return class=="BasePart" end},{Name="Folder",IsA=function() return false end}}
local template={Name="ShopTemplate",Parent="workspace",Clone=function()
 local descendants={};for _,obj in ipairs(original) do table.insert(descendants,table.clone(obj)) end
 return {Name="ShopTemplate",GetDescendants=function() return descendants end}
end}
local a=Scene.spawn(template,"workspace",0,"Shop_A");local aa=a:GetDescendants()
check(a.Name=="Shop_A" and aa[1].CFrame==42 and aa[2].CFrame==73,"saved board placement and added nested decorations survive spawning")
local b=Scene.spawn(template,"workspace",100,"Shop_B");local bb=b:GetDescendants()
check(bb[1].CFrame==142 and bb[2].CFrame==173,"additional player shop is a relative offset of the edited template")
check(original[1].CFrame==42 and template.Parent=="workspace" and template.Name=="ShopTemplate","spawning never mutates the authored template")
aa[1].CFrame=900
check(bb[1].CFrame==142 and original[1].CFrame==42,"player clones and source template are independent")
print(count.." editable shop checks passed")
