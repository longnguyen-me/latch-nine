--!strict
local Snap={}
function Snap.project(px: number,py: number,bx: number,by: number,cell: number,grabX: number,grabY: number): (number,number)
 -- Preserve the exact fractional grab point across grids with different cell sizes.
 return math.floor((px-bx)/cell-grabX+0.5),math.floor((py-by)/cell-grabY+0.5)
end
function Snap.started(px: number,py: number,startX: number,startY: number,touch: boolean): boolean
 local dx,dy=px-startX,py-startY;local threshold=if touch then 8 else 5
 return dx*dx+dy*dy>=threshold*threshold
end
return table.freeze(Snap)
