# Genera i colori dei temi (Material 3, HCT). Uso: pip install materialyoucolor; python tools/generate_themes.py
# Ruoli: bg, t1 (cifre ora), t2 (testo secondario), ac (icone), pill, fill (pill ora), amb (cifre AoD). Vedi AGENTS.md.
from materialyoucolor.hct import Hct
def lum(h):
    r,g,b=[int(h[i:i+2],16)/255 for i in(1,3,5)]
    f=lambda c:c/12.92 if c<=.03928 else ((c+.055)/1.055)**2.4
    return .2126*f(r)+.7152*f(g)+.0722*f(b)
def cr(a,b):
    x,y=sorted((lum(a),lum(b)),reverse=True); return (x+.05)/(y+.05)
def hexof(h): return '#%06X'%(h.to_int()&0xFFFFFF)
def mk(hue,ch,tone):
    return hexof(Hct.from_hct(hue,ch,tone))
def seed(x): return Hct.from_int(0xFF000000|int(x,16))
THEMES=[("Neon Plum","F72585","C77DFF"),("Electric Berry","9933FF","00F5D4"),("Sunset Apricot","FF5500","FF80BF"),
("Cyber Punk Amber","FFAA00","FF3D00"),("Mint Cyan","00F5D4","52B788"),("Emerald Sky","52B788","90E0EF"),
("Pastel Lavender & Butter","C77DFF","FFF3B0"),("Arctic Glacier","0077B6","90E0EF")]
def build(P,T,o=None):
    o=o or {}
    p,t=seed(P),seed(T)
    H=o.get('hue',p.hue)
    pill=mk(H,o.get('pc',min(p.chroma*.45,38)),18)
    bg=mk(H,min(p.chroma*.35,24),6)
    def up(hue,ch,tone,need):
        while cr(mk(hue,ch,tone),pill)<need and tone<98: tone+=1
        return mk(hue,ch,tone)
    fill=mk(H,o.get('fc',max(min(p.chroma,72),40)),o.get('ft',80))
    tone=12
    while cr(mk(H,20,tone),fill)<8 and tone>2: tone-=1
    t1=mk(H,20,tone); ac=fill; amb=fill
    return dict(fill=fill,bg="#000000",t1=t1,t2=up(H,o.get('tc',14),92,7.3),ac=ac,amb=amb,pill=pill)
if __name__=="__main__":
    for n,P,T in THEMES:
        c=build(P,T); print(f"{n:26} {c['bg']} {c['t1']} {c['t2']} {c['ac']} {c['pill']}  ora {cr(c['t1'],c['pill']):4.1f} testo2 {cr(c['t2'],c['pill']):4.1f} icona {cr(c['ac'],c['pill']):4.1f} pill/bg {cr(c['pill'],c['bg']):.2f}")

NEW=[("Cloud Dancer","E8DCCB","8FA3B8",dict(fc=5,ft=93,pc=4,tc=3)),
("Lagoon","0FA3B1","F7B267",dict()),
("Clay","C2855F","F2CC8F",dict(fc=30,ft=72,pc=20,tc=10)),
("Sage","A3B18A","D4C9A8",dict(fc=27,pc=16,tc=8)),
("Lemon Zing","FFE14D","7BE495",dict()),
("Cobalt","4361EE","FF9F1C",dict(ft=68,fc=80))]

OVERRIDE={"Electric Berry":dict(ft=66,fc=90)}

NEW2=[("Fresh Green","8BD44F","C8F27A",dict(ft=82,fc=62)),
("Pine","2D6A4F","9CD5B4",dict(ft=66,fc=45,pc=24,hue=150))]
