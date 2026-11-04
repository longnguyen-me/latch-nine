local count=0
local function check(ok,name) assert(ok,name);count+=1;print("PASS customers: "..name) end
local function load(name,env) local fn=assert(loadstring(Sources[name],name));setfenv(fn,setmetatable(env or {},{__index=getfenv()}));return fn() end
local Tags=load("ItemTags");local C=load("Config");local Items=load("Items");local G=load("Grid")(C,Items.Definitions);local R=load("Rules")(C,Items.Definitions,G,Tags)
local Customers=load("CustomerService",{game={GetService=function(_,name)
 if name=="HttpService" then return {GenerateGUID=function() return "visitor" end} end
 return {WaitForChild=function() return {ItemTags="ItemTags"} end}
end},require=function() return Tags end})
local rng={NextInteger=function(_,low) return low end}
local p=R.newProfile();local seller=Customers.create(p,R,rng)
check(seller.mode=="Seller" and seller.requestTag==nil and seller.dialogue:find("Looking to sell"),"seller explains that they brought merchandise")
p.visits=1;local buyer=Customers.create(p,R,rng)
check(buyer.mode=="Buyer" and buyer.requestTag=="ore" and buyer.itemId==nil and buyer.dialogue:find("ore"),"empty shop still receives a buyer asking for a basic category")
local medicineRng={NextInteger=function(_,low,high) return if high==#Tags.BuyerCategories then 3 else low end}
buyer=Customers.create(p,R,medicineRng)
check(buyer.requestTag=="gem" and buyer.dialogue:find("gemstone") and buyer.budget>0,"buyer may request gems without any matching stock")
p.visits=2;check(Customers.create(p,R,rng).mode=="Seller","selling visits continue between independent buying visits")
print(count.." customer intent and dialogue checks passed")
