#!/usr/bin/env python3
"""Optional guarded installation into a COPY of EXO-Murim. No automatic merge."""
import argparse,hashlib,json,shutil,tempfile,os
from pathlib import Path
MOD=Path(__file__).resolve().parents[1]
ROOT=MOD.parent

def install(project:Path,register:bool=False):
    project=project.resolve()
    if not (project/'project.godot').is_file() or not (project/'exo_core/modules.json').is_file():
        raise RuntimeError('Pasta selecionada não é um projeto EXO com EXO Core')
    # A later R14 / C3 is NOT automatically considered compatible with R13.
    refs=json.loads((MOD/'data/reference_index.json').read_text())
    for f,sha in refs['catalog_sha256'].items():
        p=project/f
        if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=sha:
            raise RuntimeError('Bloqueado: diferença de contrato R13 em '+f)
    folder=project/'exo_skill_forge'
    if folder.exists():raise RuntimeError('Destino já existe. Nada foi sobrescrito.')
    index=project/'exo_core/modules.json'
    mods=json.loads(index.read_text(encoding='utf-8'))
    if any(m.get('id')=='exo_skill_forge' or 'skill_forge' in m.get('services',[]) for m in mods):raise RuntimeError('Módulo ou serviço já registrado')
    shutil.copytree(MOD,folder,ignore=shutil.ignore_patterns('__pycache__','*.pyc'))
    if register:
        content=json.dumps(mods+[json.loads((MOD/'manifest.json').read_text())],ensure_ascii=False,indent=2)+'\n'
        backup=index.with_suffix('.json.pre_skill_forge01.bak')
        if backup.exists():
            shutil.rmtree(folder)
            raise RuntimeError('Backup existente; instalação interrompida')
        shutil.copy2(index,backup)
        fd,tmp=tempfile.mkstemp(prefix='modules-',suffix='.json',dir=index.parent)
        try:
            with os.fdopen(fd,'w',encoding='utf-8') as fp:fp.write(content)
            os.replace(tmp,index)
        except Exception:
            Path(tmp).unlink(missing_ok=True)
            shutil.copy2(backup,index)
            shutil.rmtree(folder)
            raise
    print('Módulo copiado:',folder)
    print('Registro EXO Core:', 'adicionado (somente leitura; novos casts bloqueados)' if register else 'inalterado')
    print('Arquivos de combate, progressão e save NÃO foram alterados.')

if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--project',type=Path,required=True)
    ap.add_argument('--register',action='store_true',help='Adicionar uma entrada segura ao exo_core/modules.json (backup obrigatório)')
    args=ap.parse_args()
    install(args.project,args.register)
