"""Python mirror of /datum/species_fit, used to measure fit quality before writing DM.

Pipeline order and every heuristic here must stay identical to
code/modules/mob/living/carbon/human/species/fitting/, otherwise the numbers lie.
"""
from dmi import LIMB_STATES, TRUNK_STATES, body_mask

FULL_STATES = TRUNK_STATES + LIMB_STATES + ("head_m",)

TRANSPARENT = None


def _nearest_line(lines, line):
    best, best_distance = line, 1 << 30
    for candidate in lines:
        distance = abs(candidate - line)
        if distance < best_distance:
            best, best_distance = candidate, distance
    return best


def _row_runs(pixels, y, width):
    runs, start = [], None
    for x in range(width):
        if pixels[(x, y)] is not None:
            if start is None:
                start = x
        elif start is not None:
            runs.append((start, x - 1))
            start = None
    if start is not None:
        runs.append((start, width - 1))
    return runs


def _stretch_segments(counts, extra):
    if extra <= 0:
        return
    first = 1 if len(counts) > 2 else 0
    last = len(counts) - 2 if len(counts) > 2 else len(counts) - 1
    weight = sum(counts[first:last + 1])
    if not weight:
        counts[max(len(counts) // 2, 0)] += extra
        return
    given, remainders = 0, [0] * len(counts)
    for segment in range(first, last + 1):
        share = round(extra * counts[segment] / weight)
        remainders[segment] = (extra * counts[segment]) % weight
        counts[segment] += share
        given += share
    while given < extra:
        best = max(range(first, last + 1), key=lambda index: remainders[index])
        counts[best] += 1
        remainders[best] = -1
        given += 1
    while given > extra:
        best = max(range(first, last + 1), key=lambda index: counts[index])
        counts[best] -= 1
        given -= 1


def _rebuild_run(source, y, from_column, to_column, target_width):
    colors, counts = [], []
    for x in range(from_column, to_column + 1):
        pixel = source[(x, y)]
        if colors and colors[-1] == pixel:
            counts[-1] += 1
            continue
        colors.append(pixel)
        counts.append(1)
    _stretch_segments(counts, target_width - (to_column - from_column + 1))
    rebuilt = []
    for color, count in zip(colors, counts):
        rebuilt.extend([color] * count)
    return rebuilt[:target_width]


class SpeciesFit:
    def __init__(self, reference_sheet, target_sheet, width=32, height=32, trim="none"):
        self.width, self.height = width, height
        self.trim = trim
        self.floating_rows = {}
        self.target_full = {}
        self.reference_full = {}
        self.shrunk = {}
        self.reference_trunk, self.reference_body = {}, {}
        self.target_trunk, self.target_body = {}, {}
        self.warp_maps, self.row_maps = {}, {}
        for dir_index in range(4):
            self.reference_trunk[dir_index] = body_mask(reference_sheet, TRUNK_STATES, dir_index, width, height)
            self.reference_body[dir_index] = body_mask(
                reference_sheet, TRUNK_STATES + LIMB_STATES, dir_index, width, height)
            self.target_trunk[dir_index] = body_mask(target_sheet, TRUNK_STATES, dir_index, width, height)
            self.target_body[dir_index] = body_mask(
                target_sheet, TRUNK_STATES + LIMB_STATES, dir_index, width, height)
            self.warp_maps[dir_index] = self._build_warp_map(dir_index)
            self.row_maps[dir_index] = self._build_row_map(dir_index)
            reference_rows = {y for _, y in body_mask(reference_sheet, FULL_STATES, dir_index, width, height)}
            target_rows = {y for _, y in body_mask(target_sheet, FULL_STATES, dir_index, width, height)}
            self.floating_rows[dir_index] = reference_rows - target_rows
            self.target_full[dir_index] = body_mask(target_sheet, FULL_STATES, dir_index, width, height)
            self.reference_full[dir_index] = body_mask(reference_sheet, FULL_STATES, dir_index, width, height)
            self.shrunk[dir_index] = self.reference_full[dir_index] - self.target_full[dir_index]

    def _build_warp_map(self, dir_index):
        reference_trunk, reference_body = self.reference_trunk[dir_index], self.reference_body[dir_index]
        target_trunk, target_body = self.target_trunk[dir_index], self.target_body[dir_index]
        warp_map = {}
        for y in range(self.height):
            trunk_columns = [x for x in range(self.width) if (x, y) in reference_trunk]
            body_columns = [x for x in range(self.width) if (x, y) in reference_body]
            for x in range(self.width):
                if (x, y) in target_trunk and trunk_columns:
                    warp_map[(x, y)] = _nearest_line(trunk_columns, x)
                elif (x, y) in target_body and body_columns:
                    warp_map[(x, y)] = _nearest_line(body_columns, x)
                else:
                    warp_map[(x, y)] = x
        return warp_map

    def _build_row_map(self, dir_index):
        reference_trunk, reference_body = self.reference_trunk[dir_index], self.reference_body[dir_index]
        target_trunk, target_body = self.target_trunk[dir_index], self.target_body[dir_index]
        row_map = {}
        for x in range(self.width):
            trunk_rows = [y for y in range(self.height) if (x, y) in reference_trunk]
            body_rows = [y for y in range(self.height) if (x, y) in reference_body]
            for y in range(self.height):
                if (x, y) in target_trunk:
                    rows = trunk_rows
                elif (x, y) in target_body:
                    rows = body_rows
                else:
                    rows = None
                if not rows or rows[0] <= y <= rows[-1]:
                    continue
                row_map[(x, y)] = _nearest_line(rows, y)
        return row_map

    def fit_frame(self, image, dir_index):
        pixels = image.load()
        source = {}
        for y in range(self.height):
            for x in range(self.width):
                pixel = pixels[x, y]
                source[(x, y)] = pixel if pixel[3] > 0 else None
        dirty = self._mark_bare_skin(source, dir_index)
        working = self._warp(dict(source), dirty, dir_index)
        working = self._edge_repair(working, source, dirty, dir_index)
        working = self._vertical_warp(working, dir_index)
        working = self._cover_skin(working, dir_index)
        floating = self.floating_rows[dir_index] if self.trim == "rows" else frozenset()
        for key, pixel in source.items():
            if working[key] is None and pixel is not None and key[1] not in floating:
                working[key] = pixel
        for y in floating:
            for x in range(self.width):
                working[(x, y)] = None
        if self.trim == "body":
            for key in working:
                if key not in self.target_full[dir_index]:
                    working[key] = None
        elif self.trim == "shrink":
            for key in self.shrunk[dir_index]:
                working[key] = None
        return working, any(dirty)

    def _mark_bare_skin(self, working, dir_index):
        reference_body, target_body = self.reference_body[dir_index], self.target_body[dir_index]
        dirty = [False] * self.height
        for y in range(self.height):
            for x in range(self.width):
                if (x, y) in target_body and (x, y) not in reference_body and working[(x, y)] is None:
                    dirty[y] = True
                    break
        return dirty

    def _warp(self, working, dirty, dir_index):
        warp_map = self.warp_maps[dir_index]
        warped = dict(working)
        for y in range(self.height):
            if not dirty[y]:
                continue
            for x in range(self.width):
                warped[(x, y)] = working[(warp_map[(x, y)], y)]
        return warped

    def _edge_repair(self, working, source, dirty, dir_index):
        warp_map = self.warp_maps[dir_index]
        for y in range(self.height):
            if not dirty[y]:
                continue
            for start, end in _row_runs(working, y, self.width):
                from_column, to_column = warp_map[(start, y)], warp_map[(end, y)]
                while from_column > 0 and source[(from_column - 1, y)] is not None:
                    from_column -= 1
                while to_column < self.width - 1 and source[(to_column + 1, y)] is not None:
                    to_column += 1
                new_width = end - start + 1
                if new_width <= to_column - from_column + 1:
                    continue
                rebuilt = _rebuild_run(source, y, from_column, to_column, new_width)
                for offset, pixel in enumerate(rebuilt):
                    if pixel is not None:
                        working[(start + offset, y)] = pixel
        return working

    def _vertical_warp(self, working, dir_index):
        stretched = dict(working)
        for (x, y), source_row in self.row_maps[dir_index].items():
            if working[(x, y)] is None:
                stretched[(x, y)] = working[(x, source_row)]
        return stretched

    def _cover_skin(self, working, dir_index):
        reference_body, target_body = self.reference_body[dir_index], self.target_body[dir_index]
        for y in range(self.height):
            for x in range(self.width):
                if working[(x, y)] is not None or (x, y) not in target_body or (x, y) in reference_body:
                    continue
                if x > 0 and working[(x - 1, y)] is not None:
                    working[(x, y)] = working[(x - 1, y)]
                elif x < self.width - 1 and working[(x + 1, y)] is not None:
                    working[(x, y)] = working[(x + 1, y)]
        return working
