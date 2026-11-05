--!strict
return function(definitions: any)
 local Suspicion={}
 function Suspicion.decay(profile: any,now: number): boolean
  local value=profile.suspicion or 0
  local at=profile.suspicionAt or now
  local hours=math.floor(math.max(0,now-at)/3600)
  if hours==0 then profile.suspicionAt=at;return false end
  profile.suspicion=math.max(0,value-hours*5)
  profile.suspicionAt=if profile.suspicion==0 then now else at+hours*3600
  return profile.suspicion~=value
 end
 function Suspicion.spend(profile: any,dirtyNotes: number,now: number,roll: (number,number)->number): string?
  Suspicion.decay(profile,now)
  if dirtyNotes<=0 then return nil end
  profile.suspicion=math.min(100,(profile.suspicion or 0)+dirtyNotes*20)
  profile.suspicionAt=now
  if profile.suspicion<100 then return nil end
  local message: string
  if roll(1,100)<=25 then
   local confiscated=0
   for i=#profile.inventory,1,-1 do
    if definitions[profile.inventory[i].kind].dirty then table.remove(profile.inventory,i);confiscated+=1 end
   end
   for _,machine in ipairs(profile.inventory) do
    local m=machine.machine
    if m then
     for _,slot in ipairs({"input","output"}) do
      for i=#m[slot],1,-1 do if definitions[m[slot][i].kind].dirty then table.remove(m[slot],i);confiscated+=1 end end
     end
    end
   end
   profile.gridRevision+=1
   message="Police warning. "..confiscated.." unlaundered notes confiscated."
  else
   local seized=false
   for i=#profile.inventory,1,-1 do
    if definitions[profile.inventory[i].kind].machine=="printer" then table.remove(profile.inventory,i);seized=true;profile.gridRevision+=1;break end
   end
   local fine=math.min(200,math.floor(profile.cash*0.1+0.5))
   profile.cash-=fine;profile.costs+=fine;profile.tradeProfit-=fine
   message="Police raid. "..(if seized then "A printer was seized. " else "No printer found. ")..fine.." E fine."
  end
  profile.suspicion=40;profile.suspicionAt=now
  return message
 end
 return Suspicion
end
