#!/usr/bin/env python3
"""Rebuild the editor scene and native place with Luau + Rojo (no Python packages)."""
import argparse,json,pathlib,subprocess,tempfile,xml.etree.ElementTree as ET
p=argparse.ArgumentParser();p.add_argument('--luau',default='luau');p.add_argument('--rojo',default='rojo');a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1]
source=(root/'src/shared/Scene.luau').read_text()
shim=(root/'tools/export_scene.luau').read_text()
with tempfile.NamedTemporaryFile('w',suffix='.luau',delete=False) as f:
 f.write('local SCENE_SOURCE=[====[\n'+source+'\n]====]\n'+shim);temp=pathlib.Path(f.name)
try:
 result=subprocess.run([a.luau,str(temp)],check=True,capture_output=True,text=True)
 scene=json.loads(result.stdout);scene.pop('Name',None)
finally:temp.unlink()
(root/'assets').mkdir(exist_ok=True)
(root/'assets/StagePreview.model.json').write_text(json.dumps(scene,indent=2)+'\n')
output=root/'LatchNine.rbxlx'
subprocess.run([a.rojo,'build',str(root/'default.project.json'),'-o',str(output)],check=True)
# Confirm all scripts survive serialization at their intended locations.
tree=ET.parse(output); scripts=tree.findall('.//Item[@class="Script"]')+tree.findall('.//Item[@class="LocalScript"]')+tree.findall('.//Item[@class="ModuleScript"]')
assert len(scripts)==len(list(root.glob("src/**/*.luau"))), len(scripts)
sources={p.read_text() for p in root.glob('src/**/*.luau')}
embedded={s.find("Properties/*[@name='Source']").text for s in scripts}
assert sources==embedded,'Serialized sources differ from workspace sources'
# Physical surfaces must accept SurfaceGui input; preserve the counter's tilt in the editor scene.
parts={n.find("Properties/*[@name='Name']").text:n for n in tree.findall('.//Item[@class="Part"]')}
for name in ['InventoryBoard','BuyBoard','VisitorBoard','RegisterBox']:
    assert parts[name].find("Properties/*[@name='CanQuery']").text=='true', name
assert abs(float(parts['BuyBoard'].find("Properties/*[@name='CFrame']/R12").text))>0.3
print(f'Verified {len(scripts)} embedded scripts; {len(tree.findall(".//Item"))} serialized instances; {output.stat().st_size:,} bytes')
