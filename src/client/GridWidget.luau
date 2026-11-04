--!strict
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items=require(Shared.Items)
local Tags=require(Shared.ItemTags)
local Widget={}
local C=Color3.fromRGB
local function make(class: string,props: any,parent: Instance): any
 local obj=Instance.new(class);for k,v in pairs(props) do (obj :: any)[k]=v end;obj.Parent=parent;return obj
end
local function clear(parent: Instance) for _,child in ipairs(parent:GetChildren()) do child:Destroy() end end
function Widget.draw(parent: Instance,item: any,cells: {any},w: number,h: number,size: number,ghost: boolean,onBegin: any,onHover: any?,cellHeight: number?): any
 local def=Items.Definitions[item.kind];local sy=cellHeight or size
 local frame=make("Frame",{Name="Item_"..item.id,BackgroundTransparency=1,Size=UDim2.fromOffset(w*size,h*sy),Active=false},parent)
 for index,cell in ipairs(cells) do
  local piece=make("Frame",{Name="ItemCell",Position=UDim2.fromOffset(cell[1]*size+1,cell[2]*sy+1),Size=UDim2.fromOffset(size-2,sy-2),
   BackgroundColor3=C(def.color[1],def.color[2],def.color[3]),BorderSizePixel=0,Active=false,ZIndex=if ghost then 41 else 2,BackgroundTransparency=if ghost then 0.3 else 0},frame)
  if not ghost then
   if index==1 then
    make("TextLabel",{Name="Glyph",Text=def.glyph,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Font=Enum.Font.Code,TextSize=math.max(10,math.floor(size*0.3)),TextColor3=C(24,31,37),Active=false,ZIndex=3},piece)
    local q=Tags.Qualities[item.qualityTag or Tags.DefaultQuality]
    make("TextLabel",{Name="QualityTag",Text=q.badge,Position=UDim2.new(0,2,0.73,0),Size=UDim2.new(1,-4,0.27,-1),BorderSizePixel=0,
     BackgroundColor3=C(q.color[1],q.color[2],q.color[3]),Font=Enum.Font.Code,TextSize=8,TextColor3=C(24,31,37),Active=false,ZIndex=4},piece)
   end
   -- A transparent hit target sits above all text/badges; decorations never intercept the item.
   local hit=make("TextButton",{Name="Hit",Size=UDim2.fromScale(1,1),Text="",BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Active=true,ZIndex=8},piece)
   hit.InputBegan:Connect(function(input: InputObject)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then onBegin(item,input) end
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
 self.frame=make("Frame",{Name=title,BackgroundColor3=C(14,21,31),BorderSizePixel=0,ClipsDescendants=true},parent)
 make("UIStroke",{Color=C(71,93,108),Thickness=1},self.frame)
 self.heading=make("TextLabel",{Name="Heading",Size=UDim2.new(1,0,0,28),BackgroundColor3=C(35,43,52),BorderSizePixel=0,Text="",
  Font=Enum.Font.Code,TextSize=14,TextColor3=C(225,229,207),Active=false},self.frame)
 self.heading.Visible=false
 self.scroll=make("ScrollingFrame",{Name="GridScroll",Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,
  CanvasSize=UDim2.new(),CanvasPosition=Vector2.zero,ScrollBarThickness=4,ScrollBarImageColor3=C(85,99,84),ScrollingDirection=Enum.ScrollingDirection.Y},self.frame)
 self.board=make("Frame",{Name="GridBoard",Position=UDim2.fromOffset(8,4),BackgroundColor3=C(27,42,55),BorderSizePixel=0},self.scroll)
 function self.render(items: {any},cols: number,rows: number,geometry: any,canvas: Vector2?)
  local bounds=canvas or self.frame.AbsoluteSize
  self.canvasWidth=bounds.X;self.canvasHeight=bounds.Y
  local size=math.clamp(math.floor(math.min((bounds.X-20)/cols,(bounds.Y-40)/math.min(rows,7))),12,48)
  local signature=cols..":"..rows..":"..size
  for _,i in ipairs(items) do signature..="|"..i.id..":"..i.gridX..":"..i.gridY..":"..i.rotation..":"..(i.qualityTag or "standard") end
  self.items=items;self.columns=cols;self.rows=rows;self.geometry=geometry
  if self.signature==signature then return end
  self.signature=signature;self.cellSize=size;self.views={};clear(self.board)
  self.board.Size=UDim2.fromOffset(cols*size,rows*size)
  self.boardX=math.max(8,math.floor((bounds.X-cols*size-4)/2));self.board.Position=UDim2.fromOffset(self.boardX,4)
  self.scroll.CanvasSize=UDim2.fromOffset(0,rows*size+10)
  for y=0,rows-1 do for x=0,cols-1 do make("Frame",{Name="EmptyCell",Position=UDim2.fromOffset(x*size+1,y*size+1),Size=UDim2.fromOffset(size-2,size-2),BackgroundColor3=C(29,43,56),BorderSizePixel=0,Active=false},self.board) end end
  for _,item in ipairs(items) do
   local cells,w,h=geometry.cells(item.kind,item.rotation)
   local view=Widget.draw(self.board,item,cells,w,h,size,false,onBegin,onHover);view.Position=UDim2.fromOffset(item.gridX*size,item.gridY*size);self.views[item.id]=view
  end
 end
 function self.origin(): Vector2
  return Vector2.new(self.boardX or 8,4-self.scroll.CanvasPosition.Y)
 end
 function self.contains(point: Vector2): boolean
  local b=self.origin()
  return point.X>=b.X and point.Y>=math.max(0,b.Y) and point.X<math.min(self.canvasWidth,b.X+self.columns*self.cellSize) and point.Y<math.min(self.canvasHeight,b.Y+self.rows*self.cellSize)
 end
 return self
end
return Widget
