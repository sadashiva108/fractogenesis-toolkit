#!/usr/bin/env python3
"""Regenerate the measured blocks of iris/status.md from the tree it describes.
Run from a repository root. Rewrites only between the MEASURED markers, so the
prose around them is written once and the numbers are never hand-carried."""
import io,os,sys,json,glob,collections,re
ROOT=sys.argv[1] if len(sys.argv)>1 else "."
DOC=sys.argv[2] if len(sys.argv)>2 else os.path.join(ROOT,"iris/status.md")
LEGAL={"accepted","rejected","superseded","voided","deferred","withdrawn","split"}
# NB: test the RELATIVE path. The container's own root contains "/sessions/",
# so filtering the absolute path excluded every dossier and reported zero.
D=[p for p in glob.glob(os.path.join(ROOT,'docs/**/metadata.json'),recursive=True)
   if not os.path.relpath(p,ROOT).startswith('docs/sessions/')]
g=collections.Counter(); ek=collections.Counter(); ms=collections.Counter()
outc=collections.Counter(); nulls=collections.Counter(); n_m=n_dec=0
byroot=collections.Counter()
for p in D:
    d=json.load(open(p)); g[d.get('genus')]+=1
    byroot['/'.join(os.path.relpath(p,ROOT).split('/')[:-2])]+=1
    for k,v in d.items():
        if v is None: nulls[k]+=1
    for m in d.get('members',[]):
        ms[m.get('status')]+=1; n_m+=1
        for k,v in m.items():
            if v is None: nulls['members[].'+k]+=1
    for e in d.get('edges',[]): ek[e.get('kind')]+=1
    for x in d.get('decisions',[]):
        n_dec+=1; outc[x.get('outcome')]+=1
        for k,v in x.items():
            if v is None: nulls['decisions[].'+k]+=1
pop=lambda k: n_m if k.startswith('members[]') else n_dec if k.startswith('decisions[]') else len(D)
always=[(k,v) for k,v in nulls.items() if v==pop(k)]
SCHEMA6={'subKind','members[].statusReason','members[].reopened','members[].withdrawn','decisions[].voidedReason'}
ZERO=[k for k in ('contradicts','duplicates','generalises','serves') if ek.get(k,0)==0]
illegal={k:v for k,v in outc.items() if k not in LEGAL}
man=os.path.join(ROOT,'APPLY-MANIFEST.md')
mb=os.path.getsize(man); ml=sum(1 for _ in open(man,encoding='utf-8',errors='replace'))
me=len(re.findall(r'^(?:\*\*Revision \d+\*\*|## Revision \d+)', open(man,encoding='utf-8',errors='replace').read(), re.M))

blocks={}
blocks['RECORD']=("**%d dossiers, %d members, %d edges.** Sessions are excluded — `docs/sessions/`\n"
  "holds session records, not dossiers.\n\n| Genus | Dossiers |\n|---|---:|\n"%(len(D),n_m,sum(ek.values()))
  + "".join("| `%s` | %s |\n"%(k,("**%d**"%v if k=='findings' else v)) for k in ('findings','commission','charter','remedy') for v in [g.get(k,0)])
  + "\n| Member status | Count |\n|---|---:|\n"
  + "".join("| `%s` | %d |\n"%(k,ms.get(k,0)) for k in ('resolved','framing','un-started','decided','withdrawn'))
  + "\n| Edge kind | Instances |\n|---|---:|\n"
  + "".join("| `%s` | %s |\n"%(k,("**%d**"%v if k=='evidences' else v)) for k,v in ek.most_common())
  + ("| %s | **0 each** |\n"%" · ".join("`%s`"%z for z in ZERO) if ZERO else "")
  + "\n**The manifest itself is the largest thing in the repository.**\n"
    "`APPLY-MANIFEST.md` is **%.2f MB, %s lines, %d entries**. Every session reads it\n"
    "to take a revision number.\n\n| Root | Dossiers |\n|---|---:|\n"%(mb/1048576, format(ml,","), me)
  + "".join("| `%s/` | %d |\n"%(k,v) for k,v in sorted(byroot.items(), key=lambda x:-x[1])))
blocks['NULLS']=("**%d fields are `null` on every record that carries them.** Populations differ\n"
  "— %d dossiers, %d members, %d decisions — so each is stated against its own:\n\n"
  "| Field | Null on | In [schema.md](schema.md) §6's list |\n|---|---|---|\n"%(len(always),len(D),n_m,n_dec)
  + "".join("| `%s` | %d of %d | %s |\n"%(k,v,pop(k),"yes" if k in SCHEMA6 else "**no**")
            for k,v in sorted(always,key=lambda x:-x[1])))
blocks['OUTCOMES']=("**%d decision outcomes are outside the closed set and nothing catches them.**\n"
  "`vocabulary.md` names seven legal outcomes; the tree contains %s.\n"
  "`superseded` is the legal word for what they mean. **There is no `OUTCOME` check.**\n"
  %(sum(illegal.values()), ", ".join("`%s` ×%d"%(k,v) for k,v in sorted(illegal.items()))))

s=io.open(DOC,encoding='utf-8').read(); n=0
for name,body in blocks.items():
    pat=re.compile(r'(<!-- MEASURED:%s -->\n).*?(<!-- /MEASURED:%s -->)'%(name,name), re.S)
    if pat.search(s): s=pat.sub(lambda m: m.group(1)+body+m.group(2), s); n+=1
io.open(DOC,'w',encoding='utf-8').write(s)
print("  measure.py: %d/%d blocks regenerated -- %d dossiers, %d members, %d edges"%(n,len(blocks),len(D),n_m,sum(ek.values())))
