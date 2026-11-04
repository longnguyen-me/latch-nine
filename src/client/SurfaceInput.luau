--!strict
-- All interactive boards use the Back face. Transform rays into each board's local plane.
local Surface={}
function Surface.intersect(ox: number,oy: number,oz: number,dx: number,dy: number,dz: number,width: number,height: number,depth: number,cw: number,ch: number): (number?,number?,number?)
 if dz>=-0.000001 then return nil,nil end
 local t=(depth/2-oz)/dz
 if t<0 then return nil,nil end
 local x,y=ox+dx*t,oy+dy*t
 return (x/width+0.5)*cw,(0.5-y/height)*ch,t
end
function Surface.project(part: BasePart?,canvas: Vector2,point: Vector2): (Vector2?,number?)
 local camera=workspace.CurrentCamera
 if not part or not part.Parent or not camera then return nil end
 local ray=camera:ViewportPointToRay(point.X,point.Y)
 local o=part.CFrame:PointToObjectSpace(ray.Origin);local d=part.CFrame:VectorToObjectSpace(ray.Direction)
 local x,y,t=Surface.intersect(o.X,o.Y,o.Z,d.X,d.Y,d.Z,part.Size.X,part.Size.Y,part.Size.Z,canvas.X,canvas.Y)
 return if x and y then Vector2.new(x,y) else nil,t
end
-- Canvas deltas projected back to the viewport size the held preview at its grab point.
function Surface.cellPixels(part: BasePart?,canvas: Vector2,point: Vector2,cell: number): (number,number)
 local camera=workspace.CurrentCamera
 if not part or not camera then return 26,26 end
 local function at(x: number,y: number): Vector3
  return part.CFrame:PointToWorldSpace(Vector3.new((x/canvas.X-0.5)*part.Size.X,(0.5-y/canvas.Y)*part.Size.Y,part.Size.Z/2))
 end
 local a=camera:WorldToViewportPoint(at(point.X,point.Y))
 local x=camera:WorldToViewportPoint(at(point.X+cell,point.Y))
 local y=camera:WorldToViewportPoint(at(point.X,point.Y+cell))
 return math.clamp(math.sqrt((x.X-a.X)^2+(x.Y-a.Y)^2),4,160),math.clamp(math.sqrt((y.X-a.X)^2+(y.Y-a.Y)^2),4,160)
end
return Surface
