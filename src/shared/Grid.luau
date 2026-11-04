--!strict
-- Shared geometry only. The server owns every accepted placement.
return function(config: any, definitions: any)
 local Grid = {}
 function Grid.integer(n: any, low: number, high: number): boolean
  return type(n)=="number" and n==n and n%1==0 and n>=low and n<=high
 end
 function Grid.size(profile: any): (number, number)
  return config.GridColumns, config.GridBaseRows+profile.upgrade*config.GridRowsPerUpgrade+(profile.legacyRows or 0)
 end
 function Grid.cells(kind: string, rotation: number): ({any}, number, number)
  local cells: {any}={}; local width,height=0,0
  for _,cell in ipairs(definitions[kind].shape) do
   table.insert(cells,{cell[1],cell[2]}); width=math.max(width,cell[1]+1); height=math.max(height,cell[2]+1)
  end
  for _=1,rotation do
   for _,cell in ipairs(cells) do local x=cell[1];cell[1]=height-1-cell[2];cell[2]=x end
   width,height=height,width
  end
  return cells,width,height
 end
 function Grid.occupied(profile: any, ignoreId: string?): {[string]: string}
  local used: {[string]: string}={}
  for _,item in ipairs(profile.inventory) do
   if item.id~=ignoreId then
    local cells=Grid.cells(item.kind,item.rotation)
    for _,cell in ipairs(cells) do used[(item.gridX+cell[1])..","..(item.gridY+cell[2])]=item.id end
   end
  end
  return used
 end
 function Grid.check(profile: any, kind: string, x: any, y: any, rotation: any, ignoreId: string?, cached: {[string]: string}?): (boolean,string)
  local cols,rows=Grid.size(profile)
  if not definitions[kind] or not Grid.integer(rotation,0,3) or not Grid.integer(x,0,cols-1) or not Grid.integer(y,0,rows-1) then
   return false,"Invalid placement."
  end
  local cells=Grid.cells(kind,rotation)
  local used=cached or Grid.occupied(profile,ignoreId)
  for _,cell in ipairs(cells) do
   local cx,cy=x+cell[1],y+cell[2]
   if cx>=cols or cy>=rows then return false,"Out of bounds." end
   if used[cx..","..cy] then return false,"Space occupied." end
  end
  return true,"Placement available."
 end
 function Grid.firstFit(profile: any, kind: string): (number?,number?,number?)
  local cols,rows=Grid.size(profile)
  local used=Grid.occupied(profile)
  for rotation=0,3 do
   for y=0,rows-1 do for x=0,cols-1 do
    if Grid.check(profile,kind,x,y,rotation,nil,used) then return x,y,rotation end
   end end
  end
  return nil,nil,nil
 end
 function Grid.used(profile: any): number
  local count=0
  for _,item in ipairs(profile.inventory) do count+=#definitions[item.kind].shape end
  return count
 end
 function Grid.validate(profile: any,columns: number?,height: number?): boolean
  local used: {[string]: boolean}={}
  local cols,rows=Grid.size(profile)
  cols=columns or cols;rows=height or rows
  for _,item in ipairs(profile.inventory) do
   if not definitions[item.kind] or not Grid.integer(item.rotation,0,3)
    or not Grid.integer(item.gridX,0,cols-1) or not Grid.integer(item.gridY,0,rows-1) then return false end
   local cells=Grid.cells(item.kind,item.rotation)
   for _,cell in ipairs(cells) do
    local x,y=item.gridX+cell[1],item.gridY+cell[2];local key=x..","..y
    if x>=cols or y>=rows or used[key] then return false end
    used[key]=true
   end
  end
  return true
 end
 return Grid
end
