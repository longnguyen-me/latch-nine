#!/usr/bin/env python3
"""Copy saved Edit-mode shop/GUI models from a Studio XML place into Rojo sources."""
import argparse,copy,pathlib,xml.etree.ElementTree as ET
p=argparse.ArgumentParser(description=__doc__);p.add_argument('place',type=pathlib.Path,help='Customized place saved as .rbxlx (XML, not .rbxl).');p.add_argument('--output',type=pathlib.Path,help='Alternate model output folder.');a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1]
try:place=ET.parse(a.place).getroot()
except ET.ParseError:p.error('Save the place as Roblox XML Place (.rbxlx), then try again.')
def named(parent,name):
 return next((n for n in parent.findall('Item') if n.find("Properties/*[@name='Name']") is not None and n.find("Properties/*[@name='Name']").text==name),None)
models=[];output=a.output or root/'assets/gui'
for service,name in [('StarterGui','ShopDeskUI'),('ReplicatedStorage','GuiTemplates'),('Workspace','ShopTemplate')]:
 parent=next((n for n in place.findall('Item') if n.get('class')==service),None)
 model=named(parent,name) if parent is not None else None
 if model is None:p.error(f'Missing {service}.{name}. Save the place with Play stopped.')
 models.append((name,model))
# Validate all three first, then write the same native model files mapped by Rojo.
output.mkdir(parents=True,exist_ok=True)
for name,model in models:
 doc=ET.Element('roblox',version='4');ET.SubElement(doc,'External').text='null';ET.SubElement(doc,'External').text='nil';doc.append(copy.deepcopy(model));ET.indent(doc,space='  ')
 target=output/f'{name}.rbxmx';ET.ElementTree(doc).write(target,encoding='utf-8',xml_declaration=True);print(f'Saved {target}')
print('Run tools/build.py, then commit the three model files to keep these Studio changes in Git.')
