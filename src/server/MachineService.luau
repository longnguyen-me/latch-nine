--!strict
-- Machine contents live on the owned machine item, so saves are atomic with inventory.
return function(definitions: any, grid: any)
 local Machine={}
 local function validItem(item: any): boolean
  return type(item)=="table" and type(item.id)=="string" and #item.id<=80 and definitions[item.kind]~=nil
   and type(item.condition)=="number" and type(item.paid)=="number" and type(item.authentic)=="boolean"
   and type(item.restricted)=="boolean" and type(item.inspected)=="boolean"
 end
 local function state(machine: any): any
  if not machine.machine then machine.machine={input={},output={},press=nil,nextAt=nil} end
  return machine.machine
 end
 function Machine.validate(machine: any): boolean
  local def=definitions[machine.kind]
  if not def or not def.machine then return false end
  local m=machine.machine
  if m==nil then return true end
  if type(m)~="table" or type(m.input)~="table" or type(m.output)~="table"
   or #m.input>def.inputColumns*def.inputRows or #m.output>def.outputCapacity
   or (m.nextAt~=nil and (type(m.nextAt)~="number" or m.nextAt%1~=0 or m.nextAt<0 or m.nextAt>100000000000)) then return false end
  if m.press and (def.machine~="printer" or not validItem(m.press) or m.press.kind~="mintPress") then return false end
  local seen={}
  for _,item in ipairs(m.input) do
   if not validItem(item) or seen[item.id] or (def.machine=="printer" and not definitions[item.kind].paperQuality)
    or (def.machine=="laundry" and item.kind~="dirty100") then return false end
   seen[item.id]=true
  end
  for _,item in ipairs(m.output) do
   if not validItem(item) or seen[item.id] or (def.machine=="printer" and item.kind~="dirty100")
    or (def.machine=="laundry" and item.kind~="cash100") then return false end
   seen[item.id]=true
  end
  return not m.press or not seen[m.press.id]
 end
 local function find(profile: any,id: any): (any,number?)
  if type(id)~="string" or #id>80 then return nil end
  for i,item in ipairs(profile.inventory) do if item.id==id then return item,i end end
  return nil
 end
 function Machine.insert(profile: any,machineId: any,itemId: any,slot: any,x: any,y: any,now: number): (boolean,string)
  local machine=find(profile,machineId);local item,index=find(profile,itemId)
  if not machine or not item or not index or machine==item then return false,"Item is no longer in stock." end
  local def=definitions[machine.kind];if not def or not def.machine then return false,"Not a machine." end
  local m=state(machine)
  if slot=="press" then
   if def.machine~="printer" or item.kind~="mintPress" or m.press then return false,"Mint Press slot is unavailable." end
   m.press=item
  elseif slot=="input" then
   if (def.machine=="printer" and not definitions[item.kind].paperQuality) or (def.machine=="laundry" and item.kind~="dirty100") then return false,"Wrong input material." end
   if type(x)~="number" or type(y)~="number" or x%1~=0 or y%1~=0 or x<0 or y<0 or x>=def.inputColumns or y>=def.inputRows then return false,"Invalid input cell." end
   if #m.input>=def.inputColumns*def.inputRows then return false,"Input is full." end
   for _,entry in ipairs(m.input) do if entry.machineX==x and entry.machineY==y then return false,"Input cell occupied." end end
   item.machineX=x;item.machineY=y;m.input[#m.input+1]=item
  else return false,"Invalid machine slot." end
  table.remove(profile.inventory,index);profile.gridRevision+=1
  if not m.nextAt and #m.input>0 and (def.machine=="laundry" or m.press) and #m.output<def.outputCapacity then m.nextAt=now+def.seconds end
  return true,"Loaded machine."
 end
 function Machine.extract(profile: any,machineId: any,itemId: any,slot: any,x: any,y: any): (boolean,string)
  local machine=find(profile,machineId);if not machine or not definitions[machine.kind].machine then return false,"Machine missing." end
  local m=state(machine);local item: any=nil;local index: number?=nil;local source: any=nil
  if slot=="press" then if m.press and m.press.id==itemId then item=m.press end
  elseif slot=="input" or slot=="output" then
   source=m[slot]
   for i,entry in ipairs(source) do if entry.id==itemId then item=entry;index=i;break end end
  end
  if not item then return false,"Machine item missing." end
  local fits,reason=grid.check(profile,item.kind,x,y,0)
  if not fits then return false,reason end
  if source and index then table.remove(source,index) else m.press=nil end
  item.machineX=nil;item.machineY=nil;item.gridX=x;item.gridY=y;item.rotation=0
  table.insert(profile.inventory,item);profile.gridRevision+=1
  if #m.input==0 or (definitions[machine.kind].machine=="printer" and not m.press) then m.nextAt=nil end
  return true,"Returned item to stock."
 end
 function Machine.move(profile: any,machineId: any,itemId: any,slot: any,x: any,y: any): (boolean,string)
  local machine=find(profile,machineId)
  local def=machine and definitions[machine.kind]
  if not def or not def.machine or (slot~="input" and slot~="output") then return false,"Machine slot missing." end
  local m=state(machine)
  local columns=if slot=="input" then def.inputColumns else 1
  local rows=if slot=="input" then def.inputRows else def.outputCapacity
  if type(x)~="number" or type(y)~="number" or x%1~=0 or y%1~=0 or x<0 or y<0 or x>=columns or y>=rows then return false,"Invalid machine cell." end
  local source=m[slot];local item: any=nil;local sourceIndex: number?=nil
  for index,entry in ipairs(source) do if entry.id==itemId then item=entry;sourceIndex=index;break end end
  if not item then return false,"Machine item missing." end
  if slot=="output" then
   -- Outputs occupy the first #output cells; swapping keeps collection order and avoids holes.
   local target=y+1
   if target>#source then return false,"Output cell is empty." end
   source[sourceIndex],source[target]=source[target],source[sourceIndex]
  else
   for _,entry in ipairs(source) do if entry~=item and entry.machineX==x and entry.machineY==y then return false,"Input cell occupied." end end
   item.machineX=x;item.machineY=y
  end
  profile.gridRevision+=1
  return true,"Machine items rearranged."
 end
 function Machine.tick(profile: any,now: number,newId: ()->string,roll: (number,number)->number): boolean
  local changed=false
  for _,machine in ipairs(profile.inventory) do
   local def=definitions[machine.kind]
   if def and def.machine then
    local m=state(machine)
    local ready=#m.input>0 and #m.output<def.outputCapacity and (def.machine=="laundry" or m.press~=nil)
    if not ready then m.nextAt=nil
    else
     if not m.nextAt then m.nextAt=now+def.seconds;changed=true end
     while m.nextAt and m.nextAt<=now and #m.input>0 and #m.output<def.outputCapacity and (def.machine=="printer" or profile.cash>=10) do
      local source=table.remove(m.input,1)
      local quality=if def.machine=="printer" then definitions[source.kind].paperQuality else source.paperQuality or "low"
      if def.machine=="printer" or roll(1,100)<=({low=65,mid=80,high=95})[quality] then
       local kind=if def.machine=="printer" then "dirty100" else "cash100"
       local note={id=newId(),kind=kind,paid=0,condition=100,authentic=true,restricted=false,inspected=false,qualityTag="standard",paperQuality=quality,gridX=0,gridY=0,rotation=0}
       m.output[#m.output+1]=note
      end
      if def.machine=="laundry" then profile.cash-=10;profile.costs+=10;profile.tradeProfit-=10 end
      changed=true;m.nextAt+=def.seconds
     end
     if #m.input==0 or #m.output>=def.outputCapacity or (def.machine=="printer" and not m.press) then m.nextAt=nil end
    end
   end
  end
  return changed
 end
 return Machine
end
