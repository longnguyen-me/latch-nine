#!/usr/bin/env python3
"""Build the place from saved native models without regenerating Studio layouts."""
import argparse,pathlib,subprocess,xml.etree.ElementTree as ET
p=argparse.ArgumentParser();p.add_argument('--luau',default='luau',help='Accepted for compatibility; GUI assets are already authored.');p.add_argument('--rojo',default='rojo');a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1];output=root/'LatchNine.rbxlx'
subprocess.run([a.rojo,'build',str(root/'default.project.json'),'-o',str(output)],check=True)
tree=ET.parse(output);scripts=[n for n in tree.findall('.//Item') if n.get('class') in ('Script','LocalScript','ModuleScript')]
files=list(root.glob('src/**/*.luau'));assert len(scripts)==len(files),len(scripts)
assert {f.read_text() for f in files}=={s.find("Properties/*[@name='Source']").text for s in scripts},'Serialized sources differ from workspace sources'
def name(n):return n.find("Properties/*[@name='Name']").text
nodes={name(n):n for n in tree.findall('.//Item')}
for key in ('InventoryBoard','VisitorBoard','RegisterBox'):assert nodes[key].find("Properties/*[@name='CanQuery']").text=='true',key
for key in ('ShopDeskUI','GuiTemplates','inventorySurface','offersSurface','WalletGrid','MachineMenu','Receipt','InventoryGrid','TradeGrid','EmptyCell','ItemCell','PlacementValid','PlacementBlocked'):assert key in nodes,key
assert nodes['ShopDeskUI'].get('class')=='ScreenGui'
for key in ('inventorySurface','offersSurface'):assert nodes[key].find("Properties/*[@name='Enabled']").text=='true',key
print(f'Verified {len(scripts)} embedded scripts and editable GUI models; {len(tree.findall(".//Item"))} instances; {output.stat().st_size:,} bytes')
