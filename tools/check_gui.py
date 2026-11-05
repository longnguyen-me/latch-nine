#!/usr/bin/env python3
"""Test the controller against the actual authored GUI models (no Roblox engine)."""
import argparse,json,pathlib,subprocess,tempfile,xml.etree.ElementTree as ET
p=argparse.ArgumentParser();p.add_argument('--luau',default='luau');a=p.parse_args();root=pathlib.Path(__file__).resolve().parents[1]
def prop(n):
 if n.tag=='bool':return n.text=='true'
 if n.tag in ('float','double','int','int64','token'):return float(n.text) if '.' in n.text else int(n.text)
 if n.tag in ('UDim2','UDim','Vector2','Color3'):return {'kind':n.tag,'values':[float(c.text) for c in n]}
 if n.tag in ('string','ProtectedString'):return n.text or ''
 return None

def model(n):return {'class':n.attrib['class'],'properties':{x.attrib['name']:prop(x) for x in n.find('Properties') if prop(x) is not None},'children':[model(c) for c in n.findall('Item')]}
def lua(value):
 if isinstance(value,str):return json.dumps(value,ensure_ascii=False)
 if isinstance(value,bool):return str(value).lower()
 if isinstance(value,(float,int)):return repr(value)
 if isinstance(value,list):return '{'+','.join(lua(v) for v in value)+'}'
 if isinstance(value,dict):return '{'+','.join('['+lua(k)+']='+lua(v) for k,v in value.items())+'}'
 raise ValueError(value)
sources={f.stem:f.read_text() for f in root.glob('src/**/*.luau')}
header='local Sources = {\n'+''.join(f'[{k!r}]=[====[\n{v}\n]====],\n' for k,v in sources.items())+'}\n'
models={n:model(ET.parse(root/'assets/gui'/f'{n}.rbxmx').find('Item')) for n in ('ShopDeskUI','GuiTemplates','ShopTemplate')}
header+='local GuiModels='+lua(models)+'\n'
with tempfile.NamedTemporaryFile('w',suffix='.luau',dir=root/'tests',delete=False) as f:
 f.write(header+(root/'tests/DeskSmoke.spec.luau').read_text());generated=pathlib.Path(f.name)
try:subprocess.run([a.luau,str(generated)],check=True)
finally:generated.unlink()
