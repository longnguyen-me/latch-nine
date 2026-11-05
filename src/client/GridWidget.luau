--!strict
-- The saved GUI owns appearance; this module only fills it with live grid data.
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Templates=game:GetService("ReplicatedStorage"):WaitForChild("GuiTemplates")
local Items=require(Shared.Items)
local Tags=require(Shared.ItemTags)
local Widget={}
local C=Color3.fromRGB
local function clone(name: string,parent: Instance): any
 local view=Templates:WaitForChild(name):Clone();view.Parent=parent;return view
end
local function clear(parent: Instance)
 for _,child in ipairs(parent:GetChildren()) do
  if child.Name=="PreviewCell" or child:GetAttribute("RuntimeGrid") then child:Destroy() end
 end
end
function Widget.previewColor(valid: boolean): Color3
 return (Templates:WaitForChild(if valid then "PlacementValid" else "PlacementBlocked") :: Frame).BackgroundColor3
end
function Widget.draw(parent: Instance,item: any,cells: {any},w: number,h: number,size: number,ghost: boolean,onBegin: any,onHover: any?,cellHeight: number?): any
 local def=Items.Definitions[item.kind];local sy=cellHeight or size
 local frame=clone("ItemView",parent);frame.Name="Item_"..item.id;frame.Size=UDim2.fromOffset(w*size,h*sy);frame:SetAttribute("RuntimeGrid",true)
 for index,cell in ipairs(cells) do
  local piece=clone(if ghost then "PlacementValid" else "ItemCell",frame)
  piece.Name="ItemCell";piece.Position=UDim2.fromOffset(cell[1]*size+1,cell[2]*sy+1);piece.Size=UDim2.fromOffset(size-2,sy-2)
  if not ghost then
   local tint=piece:FindFirstChild("UseCatalogColor")
   if tint and tint.Value then piece.BackgroundColor3=C(def.color[1],def.color[2],def.color[3]) end
   if item.pending then piece.BackgroundTransparency=math.max(piece.BackgroundTransparency,0.45) end
   local glyph=piece:WaitForChild("Glyph");local badge=piece:WaitForChild("QualityTag")
   glyph.Visible=index==1;badge.Visible=index==1
   if index==1 then
    glyph.Text=def.glyph
    local q=Tags.Qualities[item.qualityTag or Tags.DefaultQuality]
    badge.Text=if item.walletCount~=nil then "×"..item.walletCount else q.badge
    local useTagColor=badge:FindFirstChild("UseTagColor")
    if useTagColor and useTagColor.Value then badge.BackgroundColor3=C(q.color[1],q.color[2],q.color[3]) end
   end
   local hit=piece:WaitForChild("Hit")
   hit.InputBegan:Connect(function(input: InputObject)
    if onBegin and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then onBegin(item,input) end
   end)
   if onHover then
    hit.MouseEnter:Connect(function(x: number,y: number) onHover(item,x,y) end)
    hit.MouseLeave:Connect(function(x: number,y: number) onHover(nil,x,y) end)
   end
  end
 end
 return frame
end
function Widget.new(parent: Instance,title: string,onBegin: any,onHover: any?): any
 local self: any={cellSize=24,items={},columns=15,rows=7}
 self.frame=parent:WaitForChild(title)
 self.heading=self.frame:WaitForChild("Heading")
 self.scroll=self.frame:WaitForChild("GridScroll")
 self.board=self.scroll:WaitForChild("GridBoard")
 function self.render(items: {any},cols: number,rows: number,geometry: any,canvas: Vector2?)
  local parentBounds=canvas or parent.AbsoluteSize
  local fsize=self.frame.Size;local fpos=self.frame.Position;local ssize=self.scroll.Size;local spos=self.scroll.Position
  local fw=parentBounds.X*fsize.X.Scale+fsize.X.Offset;local fh=parentBounds.Y*fsize.Y.Scale+fsize.Y.Offset
  local fa=self.frame.AnchorPoint or Vector2.zero;local sa=self.scroll.AnchorPoint or Vector2.zero
  local width=math.max(1,fw*ssize.X.Scale+ssize.X.Offset);local height=math.max(1,fh*ssize.Y.Scale+ssize.Y.Offset)
  self.viewX=parentBounds.X*fpos.X.Scale+fpos.X.Offset-fw*fa.X+fw*spos.X.Scale+spos.X.Offset-width*sa.X
  self.viewY=parentBounds.Y*fpos.Y.Scale+fpos.Y.Offset-fh*fa.Y+fh*spos.Y.Scale+spos.Y.Offset-height*sa.Y
  self.canvasWidth=width;self.canvasHeight=height
  local size=math.max(4,math.floor(math.min((width-8)/cols,(height-8)/rows)))
  local signature=cols..":"..rows..":"..size..":"..width..":"..height
  for _,i in ipairs(items) do signature..="|"..i.id..":"..i.gridX..":"..i.gridY..":"..i.rotation..":"..(i.qualityTag or "standard")..":"..(i.walletCount or "") end
  self.items=items;self.columns=cols;self.rows=rows;self.geometry=geometry
  if self.signature==signature then return end
  self.signature=signature;self.cellSize=size;self.views={};clear(self.board)
  self.board.Size=UDim2.fromOffset(cols*size,rows*size)
  self.boardX=math.max(4,math.floor((width-cols*size)/2));self.boardY=math.max(4,math.floor((height-rows*size)/2))
  self.board.Position=UDim2.fromOffset(self.boardX,self.boardY)
  self.scroll.CanvasSize=UDim2.fromOffset(0,rows*size+self.boardY*2)
  for y=0,rows-1 do for x=0,cols-1 do
   local cell=clone("EmptyCell",self.board);cell:SetAttribute("RuntimeGrid",true);cell.Position=UDim2.fromOffset(x*size,y*size);cell.Size=UDim2.fromOffset(size,size)
  end end
  for _,item in ipairs(items) do
   local cells,w,h=geometry.cells(item.kind,item.rotation)
   local view=Widget.draw(self.board,item,cells,w,h,size,false,onBegin,onHover);view.Position=UDim2.fromOffset(item.gridX*size,item.gridY*size);self.views[item.id]=view
  end
 end
 function self.origin(): Vector2
  return Vector2.new((self.viewX or 0)+(self.boardX or 4),(self.viewY or 0)+(self.boardY or 4)-self.scroll.CanvasPosition.Y)
 end
 function self.contains(point: Vector2): boolean
  local b=self.origin();local vx,vy=self.viewX or 0,self.viewY or 0
  return point.X>=math.max(vx,b.X) and point.Y>=math.max(vy,b.Y) and point.X<math.min(vx+self.canvasWidth,b.X+self.columns*self.cellSize) and point.Y<math.min(vy+self.canvasHeight,b.Y+self.rows*self.cellSize)
 end
 return self
end
return Widget
