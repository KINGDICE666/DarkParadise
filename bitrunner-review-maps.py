from collections import Counter
from pathlib import Path
import json
from avulto import DME, DMI, DMM

tree = DME.from_file('paradise.dme')
states = {}
results = []
for filename in [*Path('_maps/virtual_domains').glob('*.dmm'), *Path('_maps/safehouses').glob('*.dmm')]:
    map_data = DMM.from_file(filename)
    issues = Counter()
    examples = {}
    for coord in map_data.coords():
        tile = map_data.tiledef(*coord)
        for index in tile.find('/'):
            path = str(tile.prefab_path(index))
            try:
                decl = tree.type_decl(path)
            except Exception:
                issues['missing type: ' + path] += 1
                continue
            values = {}
            for name in ['icon', 'icon_state', 'smooth', 'base_icon_state']:
                try:
                    values[name] = tile.prefab_var(index, name) if name in tile.prefab_vars(index) else decl.var_decl(name, True).const_val
                except Exception:
                    values[name] = None
            if values['icon'] is None or values['icon_state'] is None:
                continue
            icon = str(values['icon'])
            if not Path(icon).is_file():
                continue
            if icon not in states:
                states[icon] = set(DMI.from_file(icon).state_names())
            if values['icon_state'] not in states[icon]:
                issue = f"{path}: icon_state={values['icon_state']} missing in {icon}"
                issues[issue] += 1
                examples.setdefault(issue, coord)
    results.append({'map': str(filename), 'issues': [{'issue': key, 'count': count, 'coordinate': examples.get(key)} for key, count in issues.items()]})
print(json.dumps(results, indent=2))
