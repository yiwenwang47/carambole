/* Carambole book marks: one die-cut mark per book, drawn with the language marks' exact recipes (marks.js).
   Cut paper: white die-cut sheet, a face with a soft torn edge, the quiet colour printed off register over one part,
   the book number in the deep colour. Script sticker: a die-cut base with one thin line and the loud sparkle.
   The face takes a palette colour (the user asked for colour, not black and white); "ink" is the marks' own black. */
import { PALETTES, wobbly, mix } from "./marks.js";

const sparkle = (x, y, r) => `M${x},${y - r} Q${x},${y} ${x + r},${y} Q${x},${y} ${x},${y + r} Q${x},${y} ${x - r},${y} Q${x},${y} ${x},${y - r} Z`;

/* five rounded lobes (the fruit cut across), quadratic curves through the tips */
function slice(cx, cy, R, r, rot = -90) {
  const pts = [];
  for (let i = 0; i < 10; i++) {
    const a = (rot + i * 36) * Math.PI / 180, rad = i % 2 ? r : R;
    pts.push([cx + rad * Math.cos(a), cy + rad * Math.sin(a)]);
  }
  const f = p => p.map(v => v.toFixed(1)).join(","), mid = (p, q) => [(p[0] + q[0]) / 2, (p[1] + q[1]) / 2];
  let d = `M${f(mid(pts[9], pts[0]))} `;
  for (let i = 0; i < 10; i++) d += `Q${f(pts[i])} ${f(mid(pts[i], pts[(i + 1) % 10]))} `;
  return d + "Z";
}

/* Shapes in a 100 × 100 box, like marks.js `G`. `parts` = face pieces; `over` = which part gets the off-register
   print and how it is shifted; `num` = where the number sits (the marks put it right of the shape); `line` = the
   script sticker's inner line. */
export const SHAPES = {
  fondations: [
    {
      id: "pebbles", name: "Two pebbles", idea: "A small pebble resting on a big one: the ground everything else stands on. Two lobes, like the Français link.",
      parts: ["M12,72 C12,58 28,51 50,51 C74,51 88,59 88,73 C88,87 72,95 50,95 C27,95 12,87 12,72 Z",
              "M30,29 C30,15 41,7 54,7 C68,7 76,15 76,28 C76,40 66,47 53,47 C39,47 30,41 30,29 Z"],
      over: { part: 1, t: "translate(9 -6) rotate(8 53 27)" }, num: [70, 50],
      line: ["M22,74 C34,66 62,64 80,72", "M40,28 C46,20 60,18 68,24"],
    },
    {
      id: "seed", name: "Seed", idea: "A carambole seed: where the fruit starts. One lobe with a curved fold, like the English petal.",
      parts: ["M50,5 C71,17 81,44 75,69 C71,86 59,95 47,94 C32,93 24,80 26,62 C28,38 36,18 50,5 Z"],
      over: { part: 0, d: "M50,5 C66,20 72,44 66,66 C62,80 56,88 50,92 C58,72 58,40 50,5 Z", t: "translate(12 -3) rotate(6 60 50)" }, num: [70, 86],
      line: ["M50,10 C58,36 58,70 47,90"],
    },
    {
      id: "slice", name: "Carambole slice", idea: "The fruit the app is named after, cut across. Round lobes, no points.",
      parts: [slice(50, 50, 45, 30)],
      over: { part: 0, d: slice(50, 50, 18, 12), t: "translate(7 -6) rotate(14 50 50)" }, num: [72, 90],
      line: [slice(50, 50, 18, 12)],
    },
  ],
  situation: [
    {
      id: "bubbles", name: "Two bubbles", idea: "Two speech bubbles, one answering the other. Two lobes that overlap, like the Français link.",
      parts: ["M34,8 C52,8 64,20 64,34 C64,48 52,58 36,58 C32,58 28,57 24,56 L10,64 L15,52 C8,47 4,41 4,34 C4,20 16,8 34,8 Z",
              "M64,40 C82,40 96,51 96,66 C96,73 92,79 86,83 L90,95 L76,88 C72,89 68,90 64,90 C46,90 34,79 34,65 C34,51 46,40 64,40 Z"],
      over: { part: 1, t: "translate(8 -7) rotate(6 64 65)" }, num: [2, 96],
      line: ["M16,32 C26,26 46,26 54,32", "M46,64 C56,58 76,58 84,64"],
    },
    {
      id: "bubble", name: "One bubble", idea: "One round bubble with its tail to the side, and a smaller reply printed over it.",
      parts: ["M50,8 C76,8 94,24 94,46 C94,68 76,82 52,82 C46,82 40,81 35,79 L14,92 L20,72 C11,65 6,56 6,46 C6,24 24,8 50,8 Z"],
      over: { part: 0, d: "M66,4 C82,4 94,13 94,26 C94,39 82,47 68,47 C65,47 62,47 59,46 L48,52 L51,42 C45,38 41,33 41,26 C41,13 52,4 66,4 Z", t: "translate(8 -8)" }, num: [72, 100],
      line: ["M22,44 C34,34 66,34 78,44"],
    },
    {
      id: "guillemet", name: "Guillemet «", idea: "French dialogue opens with «. Two soft chevrons, cut as one piece.",
      parts: ["M48,18 C52,22 52,27 48,31 L33,50 L48,69 C52,73 52,78 48,82 C44,86 38,85 35,81 L16,57 C13,53 13,47 16,43 L35,19 C38,15 44,14 48,18 Z",
              "M80,18 C84,22 84,27 80,31 L65,50 L80,69 C84,73 84,78 80,82 C76,86 70,85 67,81 L48,57 C45,53 45,47 48,43 L67,19 C70,15 76,14 80,18 Z"],
      over: { part: 1, t: "translate(8 -6)" }, num: [72, 98],
      line: ["M42,24 L24,50 L42,76", "M74,24 L56,50 L74,76"],
    },
  ],
};

export const BOOKS = {
  fondations: { title: "Fondations", kicker: "01 · Grammaire A1 → B1", num: "01", pct: 76 },
  situation: { title: "En situation", kicker: "02 · Dialogues", num: "02", pct: 0 },
};

/* face colour choices. Round 1: the full star colour read "too bright"; round 2: the button-fill pale read "a little
   too grey", so Pale is the button fill moved 30 % back toward the palette colour.
   Each face sets its own overprint and number colour; `on` = the script sticker's line on that face. */
const grey = "#8D8D8A";
export const FACES = {
  pale: { name: "Pale", get: c => mix(c.paleLoud, c.loud, .3), over: c => mix(c.paleQuiet, c.quiet, .3), num: c => mix(c.deep, grey, .2), on: () => "#141414" },
  dusty: { name: "Dusty", get: c => mix(c.loud, grey, .35), over: c => mix(c.quiet, grey, .25), num: c => mix(c.deep, grey, .35), on: () => "#141414" },
  ink: { name: "Ink (as the marks)", get: () => "#0F0F0F", over: c => c.quiet, num: c => c.deep, on: () => "#F1EBDF" },
};

const P = d => `<path d="${d}"/>`;
const pick = pal => PALETTES[pal] || PALETTES.acide;

function cutArt(shape, book, c, face) {
  const blk = shape.parts.map((d, i) => wobbly(d, .8, 6, 3 + i * 2));
  const sheet = `<g fill="#FFFFFF" stroke="#FFFFFF" stroke-width="10" stroke-linejoin="round">${blk.map(P).join("")}</g>`;
  const body = `<g fill="${FACES[face].get(c)}">${blk.map(P).join("")}</g>`;
  const o = shape.over, od = wobbly(o.d || shape.parts[o.part], .8, 6, 9);
  const over = `<path d="${od}" transform="${o.t}" fill="${FACES[face].over(c)}" style="mix-blend-mode:multiply" opacity=".9"/>`;
  const num = `<text x="${shape.num[0]}" y="${shape.num[1]}" font-family="Manrope, sans-serif" font-weight="300" font-size="34" letter-spacing="-1.8" fill="${FACES[face].num(c)}">${BOOKS[book].num}</text>`;
  return sheet + body + over + num;
}

function scriptArt(shape, book, c, face) {
  const star = sparkle(90, 14, 6);
  const base = `<g fill="${FACES[face].get(c)}" stroke="${FACES[face].get(c)}" stroke-width="18" stroke-linejoin="round" stroke-linecap="round">${shape.parts.map(P).join("")}${P(star)}</g>`;
  const line = shape.line.map(d => `<path d="${d}" fill="none" stroke="${FACES[face].on(c)}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>`).join("");
  const sp = `<path d="${star}" fill="${FACES[face].over(c)}"/>`;
  return base + line + sp;
}

export function bookSVG({ style = "cut", book, shape, size, pal = "acide", face = "pale" }) {
  const s = SHAPES[book].find(x => x.id === shape) || SHAPES[book][0], c = pick(pal);
  const box = style === "cut" ? "-22 -18 140 136" : "-20 -20 140 140";
  const art = style === "cut" ? cutArt(s, book, c, face) : scriptArt(s, book, c, face);
  return `<svg viewBox="${box}" width="${size}" height="${size}" role="img" aria-label="${BOOKS[book].title}: ${s.name}" style="isolation:isolate;overflow:visible">${art}</svg>`;
}
