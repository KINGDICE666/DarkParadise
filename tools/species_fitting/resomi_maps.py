import json
import math
from pathlib import Path

from dmi import DIR_ORDER, body_mask, read_dmi


MAP_DIRECTORY = Path("code/modules/mob/living/carbon/human/species/fitting/maps")
CLOTHING_ROWS = (
    ((0, -4), (14, 10), (20, 18), (24, 22), (27, 29), (31, 31)),
    ((0, -4), (14, 10), (20, 18), (24, 22), (27, 29), (31, 31)),
    ((0, -5), (16, 11), (20, 18), (24, 22), (27, 29), (31, 31)),
    ((0, -5), (16, 11), (20, 18), (24, 22), (27, 29), (31, 31)),
)
CLOTHING_COLUMNS = ((15, 15.5, 0.6, 0.75), (15, 15.5, 0.6, 0.75),
                    (15, 16, 0.7, 0.7), (16, 15, 0.7, 0.7))
HOOD_MARGIN = 2


def interpolate(value, anchors):
    for (start, source_start), (end, source_end) in zip(anchors, anchors[1:]):
        if value <= end:
            return source_start + (value - start) * (source_end - source_start) / (end - start)
    end, source_end = anchors[-1]
    return source_end + value - end


def main():
    data = {
        "version": 1,
        "resolution": {"width": 32, "height": 32},
        "supportedDirections": "four",
    }
    reference = read_dmi("icons/mob/human_races/r_human.dmi")[0]
    target = read_dmi("icons/mob/human_races/r_resomi.dmi")[0]
    data["mappings"] = {direction.title(): hand_map(reference, target, index)
                        for index, direction in enumerate(DIR_ORDER)}
    (MAP_DIRECTORY / "human-to-resomi/hands.json").write_text(
        json.dumps(data, separators=(",", ":")) + "\n", encoding="utf-8", newline="\n")
    data["mappings"] = {direction.title(): clothing_map(reference, index)
                        for index, direction in enumerate(DIR_ORDER)}
    (MAP_DIRECTORY / "human-to-resomi/suit.json").write_text(
        json.dumps(data, separators=(",", ":")) + "\n", encoding="utf-8", newline="\n")


def clothing_map(reference, direction):
    anchors = CLOTHING_ROWS[direction]
    source_center, target_center, shoulder_scale, hip_scale = CLOTHING_COLUMNS[direction]
    head_shift = round(target_center - source_center)
    head_columns = [x for x, y in body_mask(reference, ("head_m",), direction, 32, 32)]
    head_left, head_right = min(head_columns) - HOOD_MARGIN, max(head_columns) + HOOD_MARGIN
    mapping = []
    for y in range(32):
        source_y = math.floor(interpolate(y, anchors) + 0.5)
        scale = shoulder_scale if y < anchors[2][0] else hip_scale
        for x in range(32):
            source_x = math.floor(source_center + (x - target_center) / scale + 0.5)
            if y < anchors[1][0] and head_left <= x - head_shift <= head_right:
                source_x = x - head_shift
            target = {"x": source_x, "y": source_y} if 0 <= source_x < 32 and 0 <= source_y < 32 else None
            mapping.append({"source": {"x": x, "y": y}, "target": target})
    return mapping


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
