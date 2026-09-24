import json
import math
from pathlib import Path

from dmi import DIR_ORDER, body_mask, read_dmi


MAP_DIRECTORY = Path("code/modules/mob/living/carbon/human/species/fitting/maps")
BODY_ROWS = ((0, -4), (14, 10), (21, 19), (26, 25), (29, 29), (31, 31))
BODY_COLUMNS = ((0, -3), (10, 7), (13, 11), (18, 19), (21, 23), (31, 35))
LEG_COLUMNS = ((0, -2), (12, 11), (14, 14), (17, 16), (19, 19), (31, 33))


def interpolate(value, anchors):
    for (start, source_start), (end, source_end) in zip(anchors, anchors[1:]):
        if value <= end:
            return source_start + (value - start) * (source_end - source_start) / (end - start)
    end, source_end = anchors[-1]
    return source_end + value - end


def body_map(direction):
    pairs = []
    for y in range(32):
        rows = BODY_ROWS if direction < 2 else ((0, -4), (14, 10), (19, 18), (21, 22), (27, 28), (31, 31))
        source_y = math.floor(interpolate(y, rows) + 0.5)
        for x in range(32):
            if direction < 2:
                shoulders = interpolate(x, BODY_COLUMNS)
                legs = interpolate(x, LEG_COLUMNS)
                blend = min(1, max(0, (y - 21) / 5))
                source_x = shoulders * (1 - blend) + legs * blend
            else:
                source_x = interpolate(x, ((0, -3), (13, 11 if direction == 2 else 12),
                                           (18, 19 if direction == 2 else 20), (31, 35)))
                lower_x = interpolate(x, ((0, -4), (12, 12), (18, 18), (31, 35))) if direction == 2 else interpolate(
                    x, ((0, -4), (14, 13), (19, 19), (31, 35)))
                blend = min(1, max(0, (y - 19) / 3))
                source_x = source_x * (1 - blend) + lower_x * blend
            if y < 14:
                source_x = x - (1 if direction == 2 else -1 if direction == 3 else 0)
            source_x = math.floor(source_x + 0.5)
            origin = {"x": source_x, "y": source_y}
            if not (0 <= source_x < 32 and 0 <= source_y < 32):
                origin = None
            pairs.append({"source": {"x": x, "y": y}, "target": origin})
    return pairs


def main():
    data = {
        "version": 1,
        "resolution": {"width": 32, "height": 32},
        "supportedDirections": "four",
        "mappings": {direction.title(): body_map(index) for index, direction in enumerate(DIR_ORDER)},
    }
    for name in ("uniform", "suit"):
        path = MAP_DIRECTORY / "human-to-resomi" / f"{name}.json"
        path.write_text(json.dumps(data, separators=(",", ":")) + "\n", encoding="utf-8", newline="\n")
    reference = read_dmi("icons/mob/human_races/r_human.dmi")[0]
    target = read_dmi("icons/mob/human_races/r_resomi.dmi")[0]
    data["mappings"] = {direction.title(): hand_map(reference, target, index)
                        for index, direction in enumerate(DIR_ORDER)}
    (MAP_DIRECTORY / "human-to-resomi/hands.json").write_text(
        json.dumps(data, separators=(",", ":")) + "\n", encoding="utf-8", newline="\n")


def hand_map(reference, target, direction):
    mapping = {}
    parts = ("r_hand", "l_hand") if direction == 3 else ("l_hand", "r_hand")
    for part in parts:
        source_mask = body_mask(reference, (part,), direction, 32, 32)
        target_mask = body_mask(target, (part,), direction, 32, 32)
        arm = part.replace("hand", "arm")
        source_arm = body_mask(reference, (arm,), direction, 32, 32)
        target_arm = body_mask(target, (arm,), direction, 32, 32)
        if source_arm and target_arm:
            source_top = min(y for x, y in source_arm)
            target_top = min(y for x, y in target_arm)
            for y in sorted({row for x, row in target_arm}):
                source_y = math.floor(interpolate(y, ((target_top, source_top),
                                                      (max(row for x, row in target_arm),
                                                       max(row for x, row in source_arm)))) + 0.5)
                source_columns = sorted(x for x, row in source_arm if row == source_y)
                target_columns = sorted(x for x, row in target_arm if row == y)
                for x in target_columns:
                    offset = (x - target_columns[0]) / max(1, target_columns[-1] - target_columns[0])
                    source_x = source_columns[math.floor(offset * (len(source_columns) - 1) + 0.5)]
                    mapping[x, y] = {"x": source_x, "y": source_y}
        source_top = min(y for x, y in source_mask)
        source_bottom = max(y for x, y in source_mask)
        target_top = min(y for x, y in target_mask)
        target_bottom = max(y for x, y in target_mask)
        for y in range(target_top - 1, target_bottom + 1):
            source_y = math.floor(interpolate(y, ((target_top, source_top),
                                                  (target_bottom, source_bottom))) + 0.5)
            source_columns = sorted(x for x, row in source_mask if row == max(source_top, source_y))
            target_columns = sorted(x for x, row in target_mask if row == max(target_top, y))
            for x in target_columns:
                if y < target_top and (x, y) in mapping:
                    continue
                offset = (x - target_columns[0]) / max(1, target_columns[-1] - target_columns[0])
                source_x = source_columns[math.floor(offset * (len(source_columns) - 1) + 0.5)]
                mapping[x, y] = {"x": source_x, "y": source_y}
    return [{"source": {"x": x, "y": y}, "target": mapping.get((x, y))}
            for y in range(32) for x in range(32)]


if __name__ == "__main__":
    main()
