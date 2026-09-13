"""Score the generated fit against the hand-drawn species sheets.

    python measure.py --target icons/mob/human_races/r_resomi.dmi --trim shrink \
        --target-git-ref ResomiNEWVodka --git-ref ResomiNEWVodka \
        --pair icons/mob/clothing/suit.dmi:icons/mob/clothing/species/resomi/suit.dmi

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


def _head_mask(sheet, dir_index, width, height):
    return body_mask(sheet, ("head_m",), dir_index, width, height)


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


def _state_scores(target_path, pairs, git_ref=None, target_git_ref=None, trim="none", remap="none",
                  max_squash=1, head_trim=True):
    reference_sheet, width, height = read_dmi(REFERENCE)
    target_sheet, _, _ = read_dmi(target_path, target_git_ref)
    fitter = SpeciesFit(reference_sheet, target_sheet, width, height, trim, remap, max_squash, head_trim)
    visible = {index: _visible_body(target_sheet, index, width, height) for index in range(4)}
    reference_head = {index: _head_mask(reference_sheet, index, width, height) for index in range(4)}
    target_head = {index: _head_mask(target_sheet, index, width, height) for index in range(4)}
    full_body = {index: body_mask(target_sheet, TRUNK_STATES + LIMB_STATES + ("head_m",), index, width, height)
                 for index in range(4)}

    for vanilla_path, manual_path in pairs:
        vanilla_sheet, _, _ = read_dmi(vanilla_path)
        manual_sheet, _, _ = read_dmi(manual_path, git_ref)
        for state, (dirs, frames) in vanilla_sheet.items():
            if state not in manual_sheet:
                continue
            if frames[0].size != (width, height):
                continue
            dresses_head = fitter.dresses_head(vanilla_sheet, state)
            stats = {key: 0 for key in ("frames", "generated_bare", "vanilla_bare", "manual_bare",
                                        "generated_erased", "manual_erased", "exact", "untouched_by_hand",
                                        "vanilla_off_body", "generated_off_body", "manual_off_body",
                                        "vanilla_head_cloth", "generated_head_cloth", "manual_head_cloth")}
            for dir_index in range(4):
                vanilla_frame = frame_for_dir(vanilla_sheet, state, dir_index)
                manual_frame = frame_for_dir(manual_sheet, state, dir_index)
                vanilla = _frame_pixels(vanilla_frame, width, height)
                manual = _frame_pixels(manual_frame, width, height)
                generated, _ = fitter.fit_frame(vanilla_frame, dir_index, dresses_head)
                skin = visible[dir_index]
                stats["frames"] += 1
                stats["vanilla_bare"] += sum(1 for key in skin if vanilla[key] is None)
                stats["manual_bare"] += sum(1 for key in skin if manual[key] is None)
                stats["generated_bare"] += sum(1 for key in skin if generated[key] is None)
                stats["generated_erased"] += sum(
                    1 for key in vanilla if vanilla[key] is not None and generated[key] is None)
                stats["manual_erased"] += sum(
                    1 for key in vanilla if vanilla[key] is not None and manual[key] is None)
                off = [key for key in vanilla if key not in full_body[dir_index]]
                stats["vanilla_off_body"] += sum(1 for key in off if vanilla[key] is not None)
                stats["manual_off_body"] += sum(1 for key in off if manual[key] is not None)
                stats["generated_off_body"] += sum(1 for key in off if generated[key] is not None)
                stats["vanilla_head_cloth"] += sum(
                    1 for key in reference_head[dir_index] if vanilla[key] is not None)
                stats["generated_head_cloth"] += sum(
                    1 for key in target_head[dir_index] if generated[key] is not None)
                stats["manual_head_cloth"] += sum(
                    1 for key in target_head[dir_index] if manual[key] is not None)
                if all(generated[key] == manual[key] for key in manual):
                    stats["exact"] += 1
                if all(vanilla[key] == manual[key] for key in manual):
                    stats["untouched_by_hand"] += 1
            yield vanilla_path, manual_path, state, stats


def replaceable(stats, tolerance=0):
    """The generator may take over a hand-drawn state only if it is no worse on every axis."""
    return (stats["generated_bare"] <= stats["manual_bare"] + tolerance
            and stats["generated_erased"] <= stats["manual_erased"] + tolerance
            and stats["generated_off_body"] <= stats["manual_off_body"] + tolerance
            and stats["generated_head_cloth"] <= stats["manual_head_cloth"] + tolerance)


def score(target_path, pairs, git_ref=None, target_git_ref=None, trim="none", remap="none", max_squash=1,
          head_trim=True):
    totals = {"frames": 0, "generated_bare": 0, "vanilla_bare": 0, "manual_bare": 0,
              "generated_erased": 0, "manual_erased": 0, "exact": 0, "untouched_by_hand": 0,
              "vanilla_off_body": 0, "generated_off_body": 0, "manual_off_body": 0,
              "vanilla_head_cloth": 0, "generated_head_cloth": 0, "manual_head_cloth": 0}
    for _, _, _, stats in _state_scores(target_path, pairs, git_ref, target_git_ref, trim, remap, max_squash, head_trim):
        for key in totals:
            totals[key] += stats[key]
    return totals


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", required=True)
    parser.add_argument("--pair", action="append", required=True,
                        help="vanilla.dmi:manual.dmi")
    parser.add_argument("--git-ref", help="read the manual sheets from this git ref")
    parser.add_argument("--target-git-ref", help="read the body sheet from this git ref")
    parser.add_argument("--trim", default="none", choices=("none", "rows", "body", "shrink"))
    parser.add_argument("--remap", default="none", choices=("none", "auto"))
    parser.add_argument("--no-head-trim", dest="head_trim", action="store_false",
                        help="keep fitter-added cloth on a head the garment does not dress")
    parser.add_argument("--max-squash", type=int, default=1,
                        help="rows a body part may lose before the remap leaves it alone")
    parser.add_argument("--per-state", action="store_true",
                        help="print a keep/drop verdict for every hand-drawn state")
    parser.add_argument("--tolerance", type=int, default=0,
                        help="pixels per state the generator may lose before a state is kept by hand")
    arguments = parser.parse_args()
    pairs = [tuple(item.split(":", 1)) for item in arguments.pair]
    if arguments.per_state:
        per_state(arguments, pairs)
        return
    totals = score(arguments.target, pairs, arguments.git_ref, arguments.target_git_ref,
                   arguments.trim, arguments.remap, arguments.max_squash, arguments.head_trim)

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
    print(f"{'cloth over the head':<26} vanilla {totals['vanilla_head_cloth']:>7}"
          f" | generated {totals['generated_head_cloth']:>7} | hand {totals['manual_head_cloth']:>7}")


def per_state(arguments, pairs):
    kept = {}
    for _, manual_path, state, stats in _state_scores(
            arguments.target, pairs, arguments.git_ref, arguments.target_git_ref,
            arguments.trim, arguments.remap, arguments.max_squash, arguments.head_trim):
        sheet = kept.setdefault(manual_path, {"keep": [], "drop": 0})
        if replaceable(stats, arguments.tolerance):
            sheet["drop"] += 1
            continue
        sheet["keep"].append((state, stats))

    for manual_path, sheet in kept.items():
        total = sheet["drop"] + len(sheet["keep"])
        print(f"{manual_path}  {sheet['drop']}/{total} states can be generated")
        for state, stats in sorted(sheet["keep"], key=lambda item: item[0]):
            print(f"    keep {state:<34}"
                  f" bare {stats['generated_bare']:>5}/{stats['manual_bare']:<5}"
                  f" erased {stats['generated_erased']:>5}/{stats['manual_erased']:<5}"
                  f" off-body {stats['generated_off_body']:>5}/{stats['manual_off_body']:<5}")


if __name__ == "__main__":
    main()
