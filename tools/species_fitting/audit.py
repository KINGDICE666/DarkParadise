"""Score a species body against the vanilla clothing sheets, with no hand-drawn sheets needed.

    python audit.py --target icons/mob/human_races/r_swine.dmi
    python audit.py --target icons/mob/human_races/r_resomi.dmi --target-git-ref ResomiNEWVodka --sweep

measure.py answers "is the generator as good as the artist", so it only works for a
species somebody already drew by hand. This answers "what does the fitter do to this
body", which is all the author of a new species has: a body sheet and nothing else.

Axes, all measured against the vanilla sheet on the same body:

    skin closed       body pixels the fitter covered that vanilla leaves bare - the win
    coverage deficit  body pixels still bare that the garment covers on the same body
                      part of a human; body parts line up between bodies, rows do not
    erased            garment pixels removed where the body did not get narrower; damage on
                      a body that only grew, but on a shifted body it also counts cloth
                      correctly carried off a part that moved, so read it next to head excess
    cloth off body    fitted cloth hanging outside the silhouette
    cloth over head   fitted cloth on the head the garment does not put on a human head

Picking which states still want a hand-drawn patch is not something these axes answer:
measured against the swine, where the artist's sheets say which states the fitter loses,
their ranges overlap the states it handles fine. Use --sweep to pick max_squash, then
read the worst states here and judge them by eye.
"""
import argparse
import glob
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from dmi import LIMB_STATES, TRUNK_STATES, body_mask, frame_for_dir, read_dmi
from fit import TIER_STATES, SpeciesFit

REFERENCE = "icons/mob/human_races/r_human.dmi"
FULL_STATES = TRUNK_STATES + LIMB_STATES + ("head_m",)
AXES = ("skin_closed", "coverage_deficit", "erased", "off_body", "head_excess")
DEFECTS = ("coverage_deficit", "erased", "off_body", "head_excess")


def _pixels(image, width, height):
    loaded = image.load()
    out = {}
    for y in range(height):
        for x in range(width):
            pixel = loaded[x, y]
            out[(x, y)] = pixel if pixel[3] > 0 else None
    return out


def _covered(pixels, mask):
    return sum(1 for key in mask if pixels[key] is not None)


class Auditor:
    def __init__(self, target_path, target_git_ref=None, max_squash=1):
        self.reference_sheet, self.width, self.height = read_dmi(REFERENCE)
        self.target_sheet, _, _ = read_dmi(target_path, target_git_ref)
        self.fitter = SpeciesFit(self.reference_sheet, self.target_sheet,
                                 self.width, self.height, "shrink", "auto", max_squash, True)
        self.target_body, self.reference_head, self.target_head, self.visible = {}, {}, {}, {}
        self.reference_tiers, self.target_tiers = {}, {}
        for dir_index in range(4):
            self.target_body[dir_index] = body_mask(
                self.target_sheet, FULL_STATES, dir_index, self.width, self.height)
            self.reference_head[dir_index] = body_mask(
                self.reference_sheet, ("head_m",), dir_index, self.width, self.height)
            self.target_head[dir_index] = body_mask(
                self.target_sheet, ("head_m",), dir_index, self.width, self.height)
            self.visible[dir_index] = body_mask(
                self.target_sheet, TRUNK_STATES + LIMB_STATES, dir_index,
                self.width, self.height) - self.target_head[dir_index]
            self.reference_tiers[dir_index] = [
                body_mask(self.reference_sheet, states, dir_index, self.width, self.height)
                for states in TIER_STATES]
            self.target_tiers[dir_index] = [
                body_mask(self.target_sheet, states, dir_index, self.width, self.height)
                for states in TIER_STATES]

    def frame_scores(self, frame, dir_index, dresses_head):
        vanilla = _pixels(frame, self.width, self.height)
        fitted, _ = self.fitter.fit_frame(frame, dir_index, dresses_head)
        scores = dict.fromkeys(AXES, 0)
        for tier in range(len(TIER_STATES)):
            reference_mask = self.reference_tiers[dir_index][tier]
            target_mask = self.target_tiers[dir_index][tier]
            if not reference_mask or not target_mask:
                continue
            reference_share = _covered(vanilla, reference_mask) / len(reference_mask)
            target_share = _covered(fitted, target_mask) / len(target_mask)
            scores["coverage_deficit"] += round(
                max(0.0, reference_share - target_share) * len(target_mask))
        skin = self.visible[dir_index]
        scores["skin_closed"] = (sum(1 for key in skin if vanilla[key] is None)
                                 - sum(1 for key in skin if fitted[key] is None))
        scores["erased"] = sum(1 for key in vanilla if vanilla[key] is not None
                               and fitted[key] is None
                               and key not in self.fitter.shrunk[dir_index])
        scores["off_body"] = sum(1 for key in fitted if fitted[key] is not None
                                 and key not in self.target_body[dir_index])
        scores["head_excess"] = max(0, _covered(fitted, self.target_head[dir_index])
                                    - _covered(vanilla, self.reference_head[dir_index]))
        return scores

    def state_scores(self, sheets):
        for sheet_path in sheets:
            sheet, _, _ = read_dmi(sheet_path)
            for state, (_, frames) in sheet.items():
                if frames[0].size != (self.width, self.height):
                    continue
                totals = dict.fromkeys(AXES, 0)
                dresses_head = self.fitter.dresses_head(sheet, state)
                for dir_index in range(4):
                    for axis, value in self.frame_scores(
                            frame_for_dir(sheet, state, dir_index), dir_index, dresses_head).items():
                        totals[axis] += value
                yield sheet_path, state, totals


def report(auditor, sheets, worst):
    scored = list(auditor.state_scores(sheets))
    totals = dict.fromkeys(AXES, 0)
    for _, _, scores in scored:
        for axis in AXES:
            totals[axis] += scores[axis]
    print(f"{len(scored)} states scored across {len(sheets)} sheets")
    print(f"  skin closed by the fitter   {totals['skin_closed']}")
    for axis in DEFECTS:
        print(f"  {axis:<26} {totals[axis]}")
    for axis in DEFECTS:
        ranked = sorted(scored, key=lambda item: -item[2][axis])[:worst]
        if not ranked or not ranked[0][2][axis]:
            continue
        print()
        print(f"worst states by {axis}:")
        for sheet_path, state, scores in ranked:
            print(f"    {Path(sheet_path).name:<16} {state:<30}" + "  ".join(
                f"{name} {scores[name]:>5}" for name in AXES))


def sweep(target_path, target_git_ref, sheets, span):
    print("max_squash sweep: close the most skin without erasing cloth you meant to keep")
    for max_squash in range(span + 1):
        auditor = Auditor(target_path, target_git_ref, max_squash)
        totals = dict.fromkeys(AXES, 0)
        for _, _, scores in auditor.state_scores(sheets):
            for axis in AXES:
                totals[axis] += scores[axis]
        print(f"  max_squash {max_squash}: " + "  ".join(
            f"{axis} {totals[axis]:>8}" for axis in AXES))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", required=True)
    parser.add_argument("--target-git-ref", help="read the body sheet from this git ref")
    parser.add_argument("--sheet", action="append",
                        help="vanilla sheet to score (default: every sheet in icons/mob/clothing)")
    parser.add_argument("--max-squash", type=int, default=1)
    parser.add_argument("--worst", type=int, default=6, help="states to list per axis")
    parser.add_argument("--sweep", action="store_true", help="score a range of max_squash instead")
    parser.add_argument("--sweep-span", type=int, default=4, help="highest max_squash to sweep")
    arguments = parser.parse_args()
    sheets = arguments.sheet or sorted(glob.glob("icons/mob/clothing/*.dmi"))
    if arguments.sweep:
        sweep(arguments.target, arguments.target_git_ref, sheets, arguments.sweep_span)
        return
    report(Auditor(arguments.target, arguments.target_git_ref, arguments.max_squash),
           sheets, arguments.worst)


if __name__ == "__main__":
    main()
