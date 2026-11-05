local Wallet=require("../src/shared/Wallet")
for tier=0,3 do
 local size=Wallet.Sizes[tier+1]
 local count=size[1]*size[2]
 assert(#Wallet.stacks(0,tier)==math.min(count,#Wallet.Denominations))
 for _,cash in ipairs({0,1,160,999,100000}) do
  local total=0
  for _,stack in ipairs(Wallet.stacks(cash,tier)) do
   assert(stack.count>=0 and stack.count%1==0)
   total+=stack.count*stack.denomination
  end
  assert(total==cash)
 end
end
print("Wallet denomination and capacity checks passed")
