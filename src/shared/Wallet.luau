--!strict
local Wallet={}
Wallet.Denominations={1,5,10,25,50,100,250,500,1000}
Wallet.Sizes={{2,3},{3,3},{3,4},{4,4}}
Wallet.Prices={0,150,350,700}
Wallet.Rarities={"Common","Uncommon","Rare","Legendary"}
function Wallet.stacks(cash: number,tier: number): {any}
 local capacity=math.min(#Wallet.Denominations,Wallet.Sizes[tier+1][1]*Wallet.Sizes[tier+1][2])
 local remaining=cash;local counts={}
 for i=capacity,1,-1 do
  local denomination=Wallet.Denominations[i]
  counts[i]=math.floor(remaining/denomination);remaining%=denomination
 end
 local result={}
 for i=1,capacity do table.insert(result,{denomination=Wallet.Denominations[i],count=counts[i]}) end
 return result
end
return Wallet
