"""Score the generated fit against the hand-drawn species sheets.

    python measure.py --target icons/mob/human_races/r_swine.dmi \
        --pair icons/mob/clothing/suit.dmi:icons/mob/clothing/species/swine/suit.dmi

Only pixels the player can actually see are counted: rows hidden behind the head
sprite are subtracted, and fully transparent pixels are never compared by colour
(their RGB is garbage and inflates every metric).
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from dmi import DIR_ORDER, LIMB_STATES, TRUNK_STATES, body_mask, frame_for_dir, read_dmi
from fit import SpeciesFit

REFERENCE = "icons/mob/human_races/r_human.dmi"


def _visible_body(target_sheet, dir_index, width, height):
    body = body_mask(target_sheet, TRUNK_STATES + LIMB_STATES, dir_index, width, height)
    head = body_mask(target_sheet, ("head_m",), dir_index, width, height)
    return body - head


def _frame_pixels(image, width, height):
    pixels = image.load()
    out = {}
    for y in range(height):
        for x in range(width):
            pixel = pixels[x, y]
            out[(x, y)] = pixel if pixel[3] > 0 else None
    return out


def score(target_path, pairs, git_ref=None, target_git_ref=None, trim="none"):
    reference_sheet, width, height = read_dmi(REFERENCE)
    target_sheet, _, _ = read_dmi(target_path, target_git_ref)
    fitter = SpeciesFit(reference_sheet, target_sheet, width, height, trim)
    visible = {index: _visible_body(target_sheet, index, width, height) for index in range(4)}

    full_body = {index: body_mask(target_sheet, TRUNK_STATES + LIMB_STATES + ("head_m",), index, width, height)
                 for index in range(4)}
    totals = {"frames": 0, "generated_bare": 0, "vanilla_bare": 0, "manual_bare": 0,
              "generated_erased": 0, "manual_erased": 0, "exact": 0, "untouched_by_hand": 0,
              "vanilla_off_body": 0, "generated_off_body": 0, "manual_off_body": 0}

    for vanilla_path, manual_path in pairs:
        vanilla_sheet, _, _ = read_dmi(vanilla_path)
        manual_sheet, _, _ = read_dmi(manual_path, git_ref)
        for state, (dirs, frames) in vanilla_sheet.items():
            if state not in manual_sheet:
                continue
            if frames[0].size != (width, height):
                continue
            for dir_index in range(4):
                vanilla_frame = frame_for_dir(vanilla_sheet, state, dir_index)
                manual_frame = frame_for_dir(manual_sheet, state, dir_index)
                vanilla = _frame_pixels(vanilla_frame, width, height)
                manual = _frame_pixels(manual_frame, width, height)
                generated, _ = fitter.fit_frame(vanilla_frame, dir_index)
                skin = visible[dir_index]
                totals["frames"] += 1
                totals["vanilla_bare"] += sum(1 for key in skin if vanilla[key] is None)
                totals["manual_bare"] += sum(1 for key in skin if manual[key] is None)
                totals["generated_bare"] += sum(1 for key in skin if generated[key] is None)
                totals["generated_erased"] += sum(
                    1 for key in vanilla if vanilla[key] is not None and generated[key] is None)
                totals["manual_erased"] += sum(
                    1 for key in vanilla if vanilla[key] is not None and manual[key] is None)
                off = [key for key in vanilla if key not in full_body[dir_index]]
                totals["vanilla_off_body"] += sum(1 for key in off if vanilla[key] is not None)
                totals["manual_off_body"] += sum(1 for key in off if manual[key] is not None)
                totals["generated_off_body"] += sum(1 for key in off if generated[key] is not None)
                if all(generated[key] == manual[key] for key in manual):
                    totals["exact"] += 1
                if all(vanilla[key] == manual[key] for key in manual):
                    totals["untouched_by_hand"] += 1
    return totals


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", required=True)
    parser.add_argument("--pair", action="append", required=True,
                        help="vanilla.dmi:manual.dmi")
    parser.add_argument("--git-ref", help="read the manual sheets from this git ref")
    parser.add_argument("--target-git-ref", help="read the body sheet from this git ref")
    parser.add_argument("--trim", default="none", choices=("none", "rows", "body", "shrink"))
    arguments = parser.parse_args()
    pairs = [tuple(item.split(":", 1)) for item in arguments.pair]
    totals = score(arguments.target, pairs, arguments.git_ref, arguments.target_git_ref, arguments.trim)

    print(f"frames compared            {totals['frames']}")
    print(f"already vanilla by hand    {totals['untouched_by_hand']}")
    print(f"exact match with hand work {totals['exact']}")
    print()
    print(f"{'visible bare skin':<26} vanilla {totals['vanilla_bare']:>7}"
          f" | generated {totals['generated_bare']:>7} | hand {totals['manual_bare']:>7}")
    print(f"{'erased clothing pixels':<26} vanilla {0:>7}"
          f" | generated {totals['generated_erased']:>7} | hand {totals['manual_erased']:>7}")
    print(f"{'cloth hanging off body':<26} vanilla {totals['vanilla_off_body']:>7}"
          f" | generated {totals['generated_off_body']:>7} | hand {totals['manual_off_body']:>7}")


if __name__ == "__main__":
    main()
