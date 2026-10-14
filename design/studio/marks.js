/* Carambole language marks: one die-cut mark per language, drawn in the style of one reference.
   Français = a ribbon link with a half twist (two lobes whose edges cross). English = a petal with its tip folded back.
   Every style returns SVG markup for a 100 × 100 design box; `box` is the viewBox that fits its die-cut edge. */

/* ---------- base geometry (0..100) ---------- */
const G = {
  // twisted link: top lobe leans left, bottom lobe leans right; the two edges cross at the waist
  top: "M54,4 C36,10 28,32 50,50 C62,40 68,18 54,4 Z",
  bot: "M50,50 C32,60 30,84 46,96 C62,88 72,64 50,50 Z",
  edgeL: "M54,4 C36,10 28,32 50,50 C72,64 62,88 46,96",
  edgeR: "M54,4 C68,18 62,40 50,50 C32,60 30,84 46,96",
  // petal with the tip folded back, and a vein
  petal: "M50,95 C30,82 16,56 22,34 C26,18 40,8 56,10 C72,13 82,28 78,48 C74,68 64,84 50,95 Z",
  fold: "M56,10 C70,12 81,26 79,42 C72,34 62,28 52,24 C52,18 54,13 56,10 Z",
  vein: "M50,90 C46,70 47,48 54,30",
};
const sparkle = (x, y, r) => `M${x},${y - r} Q${x},${y} ${x + r},${y} Q${x},${y} ${x},${y + r} Q${x},${y} ${x - r},${y} Q${x},${y} ${x},${y - r} Z`;

/* wobbly copy of a closed path: sample it, push each point along its normal by a seeded wave (torn-paper edge) */
let probe, uid = 0;
function wobbly(d, amp = 1.6, waves = 15, seed = 1) {
  if (!probe) {
    const s = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    s.setAttribute("width", "0"); s.setAttribute("height", "0"); s.style.position = "absolute";
    probe = document.createElementNS("http://www.w3.org/2000/svg", "path");
    s.appendChild(probe); document.body.appendChild(s);
  }
  probe.setAttribute("d", d);
  const L = probe.getTotalLength(), n = 180, pts = [];
  const r = k => Math.sin(seed * 12.9898 + k * 78.233) * 43758.5453 % 1;
  for (let i = 0; i < n; i++) {
    const a = probe.getPointAtLength(L * i / n), b = probe.getPointAtLength(L * ((i + 1) % n) / n);
    const tx = b.x - a.x, ty = b.y - a.y, m = Math.hypot(tx, ty) || 1, t = i / n;
    const off = amp * (Math.sin(2 * Math.PI * waves * t + r(1) * 6) * .7 + Math.sin(2 * Math.PI * waves * 2.3 * t + r(2) * 6) * .3);
    pts.push([a.x - ty / m * off, a.y + tx / m * off]);
  }
  return "M" + pts.map(p => p[0].toFixed(2) + "," + p[1].toFixed(2)).join(" L") + " Z";
}
/* tapered wavy strand (horse-mane streaks) from (x0, y0) leftward */
function strand(x0, y0, len, w0, seed) {
  const n = 24, up = [], dn = [];
  for (let i = 0; i <= n; i++) {
    const t = i / n, x = x0 - len * t, y = y0 + Math.sin(t * 5 + seed) * 2.2 + t * t * (seed % 2 ? 4 : -3), w = w0 * (1 - t * .85);
    up.push(`${x.toFixed(2)},${(y - w / 2).toFixed(2)}`); dn.unshift(`${x.toFixed(2)},${(y + w / 2).toFixed(2)}`);
  }
  return "M" + up.join(" L") + " L" + dn.join(" L") + " Z";
}

const P = d => `<path d="${d}"/>`;
const fills = (lang, extra = []) => (lang === "fr" ? [G.top, G.bot] : [G.petal]).concat(extra).map(P).join("");
const layers = (body, coats) => coats.map(([c, w, o = 1]) => `<g fill="${c}" stroke="${c}" stroke-width="${w}" stroke-linejoin="round" opacity="${o}">${body}</g>`).join("");

/* ---------- app palettes (Theme.swift): loud / quiet object colours, deep line colour, capped pale fills ---------- */
export const PALETTES = {
  acide: { name: "Acide", loud: "#C6EE34", quiet: "#9CC2EF", deep: "#4F8DD6", paleLoud: "#DDE6BC", paleQuiet: "#BCCFE6", tint: "#E9F2FD" },
  iris: { name: "Iris", loud: "#CFC3FF", quiet: "#C9E39A", deep: "#6E56E8", paleLoud: "#D9D3EE", paleQuiet: "#D9E6BC", tint: "#F2EFFF" },
  surimpression: { name: "Surimpression", loud: "#7E98D8", quiet: "#EC93B5", deep: "#D0668F", paleLoud: "#BCC8E6", paleQuiet: "#E6BCCC", tint: "#FBE7EF" },
};
const hex = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
export const mix = (a, b, t) => "#" + hex(a).map((v, i) => Math.round(v + (hex(b)[i] - v) * t).toString(16).padStart(2, "0")).join("");
const pick = pal => PALETTES[pal] || PALETTES.acide;

/* ---------- chosen styles (round 6): cut paper (default) and script sticker; colours from the app palette ---------- */
export const STYLES = [
  {
    id: "cut", name: "Cut paper", ref: "horse",
    look: "Start in 1 Minute: black shapes with a soft torn edge, the palette's quiet colour printed over them as a translucent sheet, numerals in the palette's deep colour.",
    bg: c => c.tint, box: "-22 -18 140 136",
    art(lang, c) {
      const blk = lang === "fr" ? [wobbly(G.top, .8, 6, 3), wobbly(G.bot, .8, 6, 5)] : [wobbly(G.petal, .9, 7, 7)];
      const sheet = `<g fill="#FFFFFF" stroke="#FFFFFF" stroke-width="10" stroke-linejoin="round">${blk.map(P).join("")}</g>`;
      const black = `<g fill="#0F0F0F">${blk.map(P).join("")}</g>`;
      const over = lang === "fr"
        ? `<path d="${wobbly(G.bot, .8, 6, 9)}" transform="translate(9 -7) rotate(8 50 70)" fill="${c.quiet}" style="mix-blend-mode:multiply" opacity=".9"/>`
        : `<path d="${wobbly(G.fold, 1, 8, 2)}" transform="translate(18 -4) scale(1.3) translate(-14 -2)" fill="${c.quiet}" style="mix-blend-mode:multiply" opacity=".9"/>`;
      const num = `<text x="${lang === "fr" ? 66 : 70}" y="${lang === "fr" ? 70 : 84}" font-family="Manrope, sans-serif" font-weight="300" font-size="34" letter-spacing="-1.8" fill="${c.deep}">${lang === "fr" ? "02" : "00"}</text>`;
      return sheet + black + over + num;
    },
  },
  {
    id: "script", name: "Script sticker", ref: "moodboard",
    look: "Acne Studios: black die-cut, one thin cream line with loops and curls. The palette appears only in the small sparkle.",
    bg: c => c.tint, box: "-20 -20 140 140",
    art(lang, c) {
      const curls = lang === "fr"
        ? ["M52,5 C46,-6 32,-4 35,5 C38,13 51,9 52,5", "M48,95 C40,106 24,101 28,92 C31,85 42,89 40,97"]
        : ["M50,95 C52,106 66,108 68,99 C69,92 59,92 61,99", "M22,34 C10,30 6,18 14,14 C20,11 24,20 18,24"];
      const star = lang === "fr" ? sparkle(86, 22, 6) : sparkle(86, 80, 6);
      const base = `<g fill="#171313" stroke="#171313" stroke-width="18" stroke-linejoin="round" stroke-linecap="round">${fills(lang, [star])}${curls.map(d => `<path d="${d}" fill="none"/>`).join("")}</g>`;
      const line = lang === "fr" ? [G.edgeL, G.edgeR] : [G.petal, G.fold, G.vein];
      const ink = line.concat(curls).map(d => `<path d="${d}" fill="none" stroke="#F1EBDF" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>`).join("");
      return base + ink + `<path d="${star}" fill="${c.loud}"/>`;
    },
  },
];

export function markSVG(style, lang, size, pal = "acide", extra = "") {
  const s = typeof style === "string" ? STYLES.find(x => x.id === style) : style;
  return `<svg viewBox="${s.box}" width="${size}" height="${size}" role="img" aria-label="${lang === "fr" ? "Français" : "English"}" style="isolation:isolate;overflow:visible" ${extra}>${s.art(lang, pick(pal))}</svg>`;
}
export const styleBg = (style, pal) => (STYLES.find(x => x.id === style) || STYLES[0]).bg(pick(pal));

export async function loadPrefs(name) {
  try { const r = await fetch(`/api/prefs/${name}`); return r.ok ? await r.json() : {}; } catch { return {}; }
}
export async function savePrefs(name, data) {
  const r = await fetch(`/api/prefs/${name}`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(data) });
  return r.ok ? await r.json() : { ok: false };
}
