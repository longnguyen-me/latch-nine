--!strict
-- Staging is not ownership. Checkout commits an entire quoted basket atomically.
return function(config: any, definitions: any, rules: any, inventoryGrid: any, trayGrid: any, walletModule: any?)
 local Trade={}
 local wallet=walletModule or require("../shared/Wallet")
 local function clone(value: any): any
  if type(value)~="table" then return value end
  local out: any={};for k,v in pairs(value) do out[k]=clone(v) end;return out
 end
 local function offer(customer: any,id: string): any
  for _,entry in ipairs(customer.goods or {}) do if (entry :: any).item.id==id then return entry end end
  return nil
 end
 local function tray(customer: any): any return {inventory=customer.basket,upgrade=0,legacyRows=0} end
 local function ready(customer: any,revision: any): boolean
  return customer and customer.state=="Interact" and rules.integer(revision,0,1000000000) and revision==customer.basketRevision
 end
 function Trade.stage(customer: any,id: any,x: any,y: any,rotation: any,revision: any,profile: any?,stockX: any?,stockY: any?,stockRotation: any?): (boolean,string)
  if not ready(customer,revision) then return false,"Trade changed." end
  if type(id)~="string" or #id>80 then return false,"Invalid offered stock ID." end
  local entry=offer(customer,id)
  if not entry then return false,"This visitor is not offering that item." end
  local ok,reason=trayGrid.check(tray(customer),(entry :: any).item.kind,x,y,rotation,id)
  if not ok then return false,reason end
  if profile then
   local fits,why=inventoryGrid.check(profile,(entry :: any).item.kind,stockX,stockY,stockRotation)
   if not fits then return false,why end
  end
  local placed: any=nil
  for _,item in ipairs(customer.basket) do if item.id==id then placed=item;break end end
  if not placed then placed={id=id,kind=(entry :: any).item.kind};table.insert(customer.basket,placed) end
  placed.gridX=x;placed.gridY=y;placed.rotation=rotation
  if profile then placed.stockX=stockX;placed.stockY=stockY;placed.stockRotation=stockRotation end
  customer.basketRevision+=1;customer.quote=nil
  return true,"Selected."
 end
 function Trade.unstage(customer: any,id: any,revision: any): (boolean,string)
  if not ready(customer,revision) then return false,"Trade changed." end
  for index,item in ipairs(customer.basket) do
   if item.id==id then table.remove(customer.basket,index);customer.basketRevision+=1;customer.quote=nil;return true,"Item returned to the visitor's offer grid." end
  end
  return false,"That item is not selected."
 end
 function Trade.clear(customer: any): (boolean,string)
  if not customer or customer.state~="Interact" then return false,"No visitor is serving a trade." end
  customer.basket={};customer.payment={};customer.paymentTotal=0;customer.basketRevision+=1;customer.quote=nil
  return true,"Selection cleared."
 end
 function Trade.stagePayment(profile: any,customer: any,denomination: any,id: any): (boolean,string)
  if not customer or customer.mode~="Seller" or customer.state~="Interact" or #customer.basket==0 then return false,"Select goods first." end
  if not rules.integer(denomination,1,1000) or (id~=nil and (type(id)~="string" or #id>80)) then return false,"Invalid note." end
  local valid=false
  if id then
   local item=rules.find(profile,id)
   if item and definitions[item.kind].denomination==denomination then
    valid=true
    for _,entry in ipairs(customer.payment or {}) do if entry.id==id then valid=false end end
   end
  else
   for _,stack in ipairs(wallet.stacks(profile.cash,profile.walletTier or 0)) do
    if stack.denomination==denomination then
     local used=0
     for _,entry in ipairs(customer.payment or {}) do if not entry.id and entry.denomination==denomination then used+=1 end end
     valid=used<stack.count;break
    end
   end
  end
  if not valid then return false,"This note is not available." end
  customer.payment=customer.payment or {}
  table.insert(customer.payment,{id=id,denomination=denomination})
  customer.paymentTotal=(customer.paymentTotal or 0)+denomination
  return true,"Payment staged: "..customer.paymentTotal.." E."
 end
 function Trade.review(profile: any,customer: any,quoteId: string): (boolean,string)
  if not customer or customer.mode=="Buyer" or customer.state~="Interact" or #customer.basket==0 then return false,"No items selected." end
  local lines,plan={},{inventory=clone(profile.inventory),upgrade=profile.upgrade,legacyRows=profile.legacyRows}
  local subtotal,total=0,0
  for _,selection in ipairs(customer.basket) do
   local entry=offer(customer,(selection :: any).id)
   if not entry then customer.quote=nil;return false,"An offered item is no longer available." end
   local price=(entry :: any).price
   local item=clone((entry :: any).item);item.qualityTag=item.qualityTag or rules.DefaultQuality
   local x,y,rotation=inventoryGrid.firstFit(plan,item.kind)
   local desired: any=selection
   if desired.stockX~=nil then
    local fits=inventoryGrid.check(plan,item.kind,desired.stockX,desired.stockY,desired.stockRotation)
    if not fits then customer.quote=nil;return false,"The chosen stock space is occupied." end
    x,y,rotation=desired.stockX,desired.stockY,desired.stockRotation
   end
   if x==nil then customer.quote=nil;return false,"Insufficient storage space." end
   item.gridX=x;item.gridY=y;item.rotation=rotation;item.paid=price
   table.insert(plan.inventory,item)
   table.insert(lines,{id=item.id,kind=item.kind,name=definitions[item.kind].name,basePrice=(entry :: any).price,price=price,item=item})
   subtotal+=(entry :: any).price;total+=price
  end
  customer.quote={id=quoteId,basketRevision=customer.basketRevision,gridRevision=profile.gridRevision,
   lines=lines,subtotal=subtotal,discount=subtotal-total,total=total,count=#lines,plan=plan.inventory}
  return true,"Purchase review."
 end
 function Trade.reviewBulk(profile: any,customer: any,quoteId: string): (boolean,string)
  if not customer or customer.mode~="Seller" or customer.state~="Interact" or not customer.bulkPercent or #customer.goods==0 then return false,"No bulk offer." end
  local discount=customer.bulkPercent
  if not rules.integer(discount,5,15) then return false,"Invalid bulk offer." end
  local plan={inventory=clone(profile.inventory),upgrade=profile.upgrade,legacyRows=profile.legacyRows}
  local lines={};local subtotal,total=0,0
  for _,raw in ipairs(customer.goods) do
   local entry: any=raw
   local item=clone(entry.item);item.qualityTag=item.qualityTag or rules.DefaultQuality
   local x,y,rotation=inventoryGrid.firstFit(plan,item.kind)
   if x==nil then customer.quote=nil;return false,"Insufficient storage space for the entire batch." end
   local price=math.max(1,math.floor(entry.price*(100-discount)/100))
   item.gridX=x;item.gridY=y;item.rotation=rotation;item.paid=price
   table.insert(plan.inventory,item)
   table.insert(lines,{id=item.id,kind=item.kind,name=definitions[item.kind].name,basePrice=entry.price,price=price,item=item})
   subtotal+=entry.price;total+=price
  end
  customer.quote={id=quoteId,mode="Bulk",basketRevision=customer.basketRevision,gridRevision=profile.gridRevision,
   lines=lines,subtotal=subtotal,discount=subtotal-total,total=total,count=#lines,plan=plan.inventory}
  return true,"Whole batch review."
 end
 function Trade.buyBulk(profile: any,customer: any,quoteId: string): (boolean,string)
  local ok,message=Trade.reviewBulk(profile,customer,quoteId)
  if not ok then return false,message end
  local bought,reason=Trade.confirm(profile,customer,quoteId)
  if not bought then customer.quote=nil end
  return bought,reason
 end
 function Trade.confirm(profile: any,customer: any,quoteId: any): (boolean,string)
  if not customer or customer.mode=="Buyer" or customer.state~="Interact" then return false,"The visitor has left." end
  local q=customer.quote
  if not q or type(quoteId)~="string" or quoteId~=q.id then return false,"That purchase review has expired." end
  if q.basketRevision~=customer.basketRevision or q.gridRevision~=profile.gridRevision then
   customer.quote=nil;return false,"Trade changed."
  end
  local walletCash=profile.cash;local looseIds: {[string]: boolean}={};local paid=0
  local reserved: {[number]: number}={}
  for _,payment in ipairs(customer.payment or {}) do
   local denomination=payment.denomination
   if payment.id then
    local money=rules.find(profile,payment.id)
    if not money or definitions[money.kind].denomination~=denomination or looseIds[payment.id] then return false,"Payment changed." end
    looseIds[payment.id]=true
   else reserved[denomination]=(reserved[denomination] or 0)+1 end
   paid+=denomination
  end
  for _,stack in ipairs(wallet.stacks(walletCash,profile.walletTier or 0)) do
   if (reserved[stack.denomination] or 0)>stack.count then return false,"Wallet payment changed." end
  end
  local walletUsed=0
  for denomination,count in pairs(reserved) do walletUsed+=denomination*count end
  if paid<q.total then
   local needed=q.total-paid
   local fromWallet=math.min(needed,walletCash-walletUsed)
   walletUsed+=fromWallet;paid+=fromWallet
   if paid<q.total then
    for _,item in ipairs(profile.inventory) do
     local amount=definitions[item.kind].denomination
     if amount and not looseIds[item.id] then looseIds[item.id]=true;paid+=amount;if paid>=q.total then break end end
    end
   end
  end
  if paid<q.total then return false,"Not enough Eddies for this purchase." end
  -- Preserve live metadata (for example inspections performed after the quote).
  local committed={}
  for _,item in ipairs(profile.inventory) do if not looseIds[item.id] then table.insert(committed,item) end end
  local bought: {[string]: boolean}={}
  local newWalletTier=profile.walletTier or 0
  for _,line in ipairs(q.lines) do
   local entry=offer(customer,(line :: any).id)
   if not entry or rules.find(profile,(line :: any).id) then customer.quote=nil;return false,"An item is already owned or no longer offered." end
   local item=clone((entry :: any).item);item.qualityTag=item.qualityTag or rules.DefaultQuality;item.gridX=(line :: any).item.gridX;item.gridY=(line :: any).item.gridY;item.rotation=(line :: any).item.rotation;item.paid=(line :: any).price
   local tier=definitions[item.kind].walletTier
   if tier and tier>newWalletTier then
    for index=#committed,1,-1 do if definitions[committed[index].kind].walletTier~=nil then table.remove(committed,index) end end
    newWalletTier=tier
   end
   table.insert(committed,item);bought[(line :: any).id]=true
  end
  local plan={inventory=committed,upgrade=profile.upgrade,legacyRows=profile.legacyRows}
  if not inventoryGrid.validate(plan) then customer.quote=nil;return false,"The purchase layout is no longer valid." end
  local change=paid-q.total
  profile.cash=walletCash-walletUsed+change;profile.costs+=q.total;profile.inventory=committed;profile.walletTier=newWalletTier;profile.gridRevision+=1
  local remaining={}
  for _,entry in ipairs(customer.goods) do if not bought[(entry :: any).item.id] then table.insert(remaining,entry) end end
  customer.goods=remaining;customer.quote=nil;customer.basket={};customer.payment={};customer.paymentTotal=0;customer.basketRevision+=1
  rules.log(profile,"Bought "..q.count.." item(s) from "..customer.name.." for "..q.total)
  return true,"Bought "..q.count.." item(s) for "..q.total.." Eddies."..(if change>0 then " Customer returned "..change.." E in change." else "")
 end
 -- A buyer uses the same middle tray to hold stock from the shop.
 function Trade.stageStock(profile: any,customer: any,id: any,x: any,y: any,rotation: any,revision: any): (boolean,string)
  if not ready(customer,revision) or customer.mode~="Buyer" then return false,"Trade changed." end
  if type(id)~="string" or #id>80 then return false,"Invalid stock ID." end
  local item=rules.find(profile,id)
  if not item or not rules.matches(customer,item) then return false,"The buyer does not want that stock." end
  local ok,reason=trayGrid.check(tray(customer),item.kind,x,y,rotation,id)
  if not ok then return false,reason end
  local selected: any=nil
  for _,entry in ipairs(customer.basket) do if (entry :: any).id==id then selected=entry;break end end
  if not selected then selected={id=id,kind=item.kind};table.insert(customer.basket,selected) end
  selected.gridX=x;selected.gridY=y;selected.rotation=rotation
  customer.basketRevision+=1;customer.quote=nil
  return true,"Stock offered to buyer."
 end
 function Trade.unstageStock(profile: any,customer: any,id: any,x: any,y: any,rotation: any,revision: any): (boolean,string)
  if customer.mode~="Buyer" or not ready(customer,revision) then return false,"Trade changed." end
  local item=rules.find(profile,id)
  if not item then return false,"Stock changed." end
  local staged=false
  for _,entry in ipairs(customer.basket) do if (entry :: any).id==id then staged=true;break end end
  if not staged then return false,"Item is not staged." end
  local ok,reason=inventoryGrid.check(profile,item.kind,x,y,rotation,id)
  if not ok then return false,reason end
  local moved,message=rules.move(profile,id,x,y,rotation,profile.gridRevision)
  if not moved then return false,message end
  return Trade.unstage(customer,id,revision)
 end
 function Trade.reviewSale(profile: any,customer: any,quoteId: string): (boolean,string)
  if customer.mode~="Buyer" or customer.state~="Interact" or #customer.basket==0 then return false,"No stock selected." end
  local lines={};local total=0;local seen={}
  for _,selection in ipairs(customer.basket) do
   local item=rules.find(profile,(selection :: any).id)
   if seen[(selection :: any).id] or not item or not rules.matches(customer,item) then customer.quote=nil;return false,"Stock changed." end
   seen[(selection :: any).id]=true
   local price=if customer.itemId==item.id then customer.offer else math.max(1,math.floor(rules.value(item)*0.86))
   total+=price;table.insert(lines,{id=item.id,kind=item.kind,name=definitions[item.kind].name,price=price})
  end
  if total>customer.budget then customer.quote=nil;return false,"Buyer cannot afford this selection." end
  customer.quote={id=quoteId,mode="Sale",basketRevision=customer.basketRevision,gridRevision=profile.gridRevision,lines=lines,subtotal=total,total=total,count=#lines}
  return true,"Sale review."
 end
 function Trade.confirmSale(profile: any,customer: any,quoteId: any): (boolean,string)
  local q=customer and customer.quote
  if not customer or customer.mode~="Buyer" or customer.state~="Interact" or not q or q.mode~="Sale" or type(quoteId)~="string" or quoteId~=q.id then return false,"That sale review has expired." end
  if q.basketRevision~=customer.basketRevision or q.gridRevision~=profile.gridRevision then customer.quote=nil;return false,"Trade changed." end
  local working=clone(profile);local committed=clone(customer);local total=0
  for _,line in ipairs(q.lines) do
   local item=rules.find(working,(line :: any).id)
   if not item or not rules.matches(customer,item) then customer.quote=nil;return false,"Stock changed." end
   local expected=if customer.itemId==item.id then customer.offer else math.max(1,math.floor(rules.value(item)*0.86))
   if expected~=(line :: any).price then customer.quote=nil;return false,"Prices changed." end
   local ok=rules.sell(working,committed,item.id,(line :: any).price)
   if not ok then customer.quote=nil;return false,"Sale failed." end
   total+=(line :: any).price
  end
  if total~=q.total or total>customer.budget then customer.quote=nil;return false,"Buyer cannot afford this selection." end
  for _,key in ipairs({"cash","inventory","revenue","costs","tradeProfit","reputation","receipts","gridRevision"}) do profile[key]=working[key] end
  customer.quote=nil;customer.basket={};customer.basketRevision+=1
  return true,"Sold "..q.count.." item(s) for "..total.." Eddies."
 end
 return Trade
end
