-- Execute the actual physical money display update function.
local function object(name,children)
 return {Name=name,FindFirstChild=function(_,key) return children and children[key] end}
end
local label={Text="--- CR",IsA=function(_,class) return class=="TextLabel" end}
local stage=object("Booth",{MoneyDisplay=object("MoneyDisplay",{CashSurface=object("CashSurface",{Balance=label})})})
local fn=assert(loadstring(Sources.Scene,"Scene"));setfenv(fn,setmetatable({game={GetService=function() return {} end},Color3={fromRGB=function() return {} end}},{__index=getfenv()}))
local Scene=fn()
Scene.cash(stage,160);assert(label.Text=="160 CR");print("PASS scene: cash appears on the physical block's SurfaceGui")
Scene.cash(stage,78);assert(label.Text=="78 CR");print("PASS scene: transaction balance updates the same physical display")
Scene.cash(stage,0);assert(label.Text=="0 CR");print("PASS scene: zero cash displays correctly")
print("3 physical money display checks passed")
