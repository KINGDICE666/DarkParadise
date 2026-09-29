import json
import math
from pathlib import Path

from dmi import DIR_ORDER, body_mask, read_dmi


MAP_DIRECTORY = Path("code/modules/mob/living/carbon/human/species/fitting/maps")
REFERENCE_CENTER = 15
TARGET_CENTER = 15.5
PROFILE_PARTS = ("torso_m", "groin_m", "l_arm", "r_arm", "l_hand", "r_hand")


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
    for slot in ("uniform", "suit"):
        slot_path = MAP_DIRECTORY / f"human-to-resomi/{slot}.json"
        clothing = json.loads(slot_path.read_text(encoding="utf-8"))
        for direction in ("South", "North"):
            clothing["mappings"][direction] = mirrored_map(clothing["mappings"][direction])
        if slot == "uniform":
            for index, direction in enumerate(DIR_ORDER[2:], start=2):
                clothing["mappings"][direction.title()] = narrow_profile_map(
                    clothing["mappings"][direction.title()], reference, target, index)
        slot_path.write_text(
            json.dumps(clothing, separators=(",", ":")) + "\n", encoding="utf-8", newline="\n")
    suit = json.loads((MAP_DIRECTORY / "human-to-resomi/suit.json").read_text(encoding="utf-8"))
    data["mappings"] = {direction.title(): long_hem_map(suit["mappings"][direction.title()], target, index)
                        for index, direction in enumerate(DIR_ORDER)}
    (MAP_DIRECTORY / "human-to-resomi/suit_long.json").write_text(
        json.dumps(data, separators=(",", ":")) + "\n", encoding="utf-8", newline="\n")


def mirrored_map(mapping):
    targets = {(pair["source"]["x"], pair["source"]["y"]): pair["target"] for pair in mapping}
    mirrored = []
    for y in range(32):
        for x in range(32):
            target = targets[x, y]
            if x > TARGET_CENTER:
                target = targets[31 - x, y]
                if target and 0 <= 2 * REFERENCE_CENTER - target["x"] < 32:
                    target = {"x": 2 * REFERENCE_CENTER - target["x"], "y": target["y"]}
                else:
                    target = None
            mirrored.append({"source": {"x": x, "y": y}, "target": target})
    return mirrored


def narrow_profile_map(mapping, reference, target, direction):
    targets = {(pair["source"]["x"], pair["source"]["y"]): pair["target"] for pair in mapping}
    reference_body = body_mask(reference, PROFILE_PARTS, direction, 32, 32)
    target_body = body_mask(target, PROFILE_PARTS, direction, 32, 32)
    reference_trunk = body_mask(reference, ("torso_m", "groin_m"), direction, 32, 32)
    reference_hands = body_mask(reference, ("l_hand", "r_hand"), direction, 32, 32)
    target_trunk = body_mask(target, ("torso_m", "groin_m"), direction, 32, 32)
    arm_rows = sorted({y for x, y in body_mask(target, ("l_arm", "r_arm", "l_hand", "r_hand"), direction, 32, 32)})
    for y in range(arm_rows[0] - 1, arm_rows[-1] + 1):
        span_row = max(y, arm_rows[0])
        columns = sorted(x for x, row in target_body if row == span_row)
        source_rows = [targets[x, y]["y"] for x in columns if targets[x, y]]
        source_y = max(set(source_rows), key=source_rows.count)
        source_columns = sorted(x for x, row in reference_body if row == source_y)
        if not source_columns:
            continue
        first, last = columns[0], columns[-1]
        source_first, source_last = source_columns[0], source_columns[-1]
        narrower = last - first < source_last - source_first
        for x in range(32):
            if first <= x <= last and narrower:
                source_x = source_first + math.floor((x - first) * (source_last - source_first) / (last - first) + 0.5)
                targets[x, y] = {"x": source_x, "y": source_y}
            elif not first <= x <= last and targets[x, y] and source_first <= targets[x, y]["x"] <= source_last:
                targets[x, y] = None
        for x in range(32):
            source = targets[x, y]
            if (x, y) not in target_trunk or not source or (source["x"], source["y"]) not in reference_hands:
                continue
            trunk_columns = [column for column, row in reference_trunk
                             if row == source["y"] and (column, row) not in reference_hands]
            if trunk_columns:
                nearest = min(sorted(trunk_columns), key=lambda column: abs(column - source["x"]))
                targets[x, y] = {"x": nearest, "y": source["y"]}
    return [{"source": {"x": x, "y": y}, "target": targets[x, y]} for y in range(32) for x in range(32)]


def long_hem_map(mapping, target, direction):
    first = min(y for x, y in body_mask(target, ("groin_m",), direction, 32, 32))
    last = min(y for x, y in body_mask(target, ("l_foot", "r_foot"), direction, 32, 32)) - 1
    targets = {(pair["source"]["x"], pair["source"]["y"]): pair["target"] for pair in mapping}
    lifted = []
    for y in range(32):
        source_y = y
        if y > last:
            source_y = None
        elif y > first:
            source_y = first + math.floor((y - first) * (31 - first) / (last - first) + 0.5)
        for x in range(32):
            target = targets[x, source_y] if source_y is not None else None
            lifted.append({"source": {"x": x, "y": y}, "target": target})
    return lifted


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
