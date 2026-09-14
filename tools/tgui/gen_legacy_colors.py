import re, sys

css = open(sys.argv[1], encoding="utf-8", errors="replace").read()
rel = re.compile(r"\b(?:hsl|hwb|oklch|oklab|lab|lch|rgb|color)\(\s*from\s+(var\(--[a-z0-9-]+\)|#[0-9a-fA-F]{3,8}|[a-z]+)", re.I)

rules = []
pos = 0
while True:
    brace = css.find("{", pos)
    if brace < 0:
        break
    end = css.find("}", brace)
    if end < 0:
        break
    selector = css[pos:brace].strip().strip("}").strip()
    body = css[brace + 1 : end]
    if "from " in body and rel.search(body):
        keep = []
        for decl in body.split(";"):
            if not decl.strip():
                continue
            name, _, value = decl.partition(":")
            m = rel.search(value)
            if not m:
                continue
            keep.append((name.strip(), m.group(1)))
        if keep and selector and not selector.startswith("@"):
            rules.append((selector, keep))
    pos = end + 1

out = ["@supports not (color: hsl(from red h s l)) {"]
for selector, decls in rules:
    out.append(f"  {selector} {{")
    for name, base in decls:
        out.append(f"    {name}: {base};")
    out.append("  }")
out.append("}")
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(out) + "\n")
print("правил:", len(rules), "| объявлений:", sum(len(d) for _, d in rules))
