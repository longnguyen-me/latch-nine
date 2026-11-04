#!/usr/bin/env python3
"""Compile sources, analyze pure rules, then execute tests with an official Luau CLI."""
import argparse, pathlib, subprocess, tempfile
p=argparse.ArgumentParser(); p.add_argument('--luau',default='luau'); args=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1]
cli=pathlib.Path(args.luau)
compiler=str(cli.with_name('luau-compile')) if cli.parent!=pathlib.Path('.') else 'luau-compile'
analyzer=str(cli.with_name('luau-analyze')) if cli.parent!=pathlib.Path('.') else 'luau-analyze'
files=sorted(root.glob('src/**/*.luau'))
for file in files: subprocess.run([compiler,'--null',str(file)],check=True,stdout=subprocess.DEVNULL)
print(f'Compiled {len(files)} Luau scripts',flush=True)
subprocess.run([analyzer,str(root/'src/server/Rules.luau'),str(root/'src/shared/Grid.luau'),str(root/'tests/Rules.spec.luau'),str(root/'tests/Grid.spec.luau'),str(root/'src/server/TradeService.luau'),str(root/'tests/Trade.spec.luau'),str(root/'src/shared/GridSnap.luau'),str(root/'tests/Snap.spec.luau')],check=True)
subprocess.run([str(cli),str(root/'tests/Rules.spec.luau')],check=True)
subprocess.run([str(cli),str(root/'tests/Grid.spec.luau')],check=True)
subprocess.run([str(cli),str(root/'tests/Trade.spec.luau')],check=True)
subprocess.run([str(cli),str(root/'tests/Snap.spec.luau')],check=True)
sources={f.stem:f.read_text() for f in files}
for test in ['Runtime.spec.luau','Persistence.spec.luau','Desk.spec.luau','Surface.spec.luau','Shop.spec.luau','Customers.spec.luau','Scene.spec.luau','Camera.spec.luau']:
 path=root/'tests'/test
 if not path.exists(): continue
 header='local Sources = {\n'+''.join(f'[{k!r}]=[====[\n{v}\n]====],\n' for k,v in sources.items())+'}\n'
 with tempfile.NamedTemporaryFile('w',suffix='.luau',dir=root/'tests',delete=False) as f:
  f.write(header+path.read_text()); generated=pathlib.Path(f.name)
 try: subprocess.run([str(cli),str(generated)],check=True)
 finally: generated.unlink()
print('All local checks passed. Studio/device/cloud playtests still required.',flush=True)
