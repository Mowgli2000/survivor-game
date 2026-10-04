/*
 * KAGE — parametric character rig + style renderers (art direction showcase).
 *
 * One character model (proportions, directions, poses) rendered by several
 * "style engines". Everything is vector (SVG strings), so the same file runs
 * in the browser (index.html) and in Node (tools/export_assets.js).
 *
 * Coordinates: sprite box 200 x 260, feet on y = FEET, centered on x = CX.
 */
(function (global) {
  "use strict";

  const CX = 100;
  const FEET = 236;
  const HEIGHT = 196; // top of the head (without hair spikes) to the soles
  const VIEW_W = 200;
  const VIEW_H = 260;

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------
  let uidCounter = 0;
  function uid(prefix) {
    uidCounter += 1;
    return prefix + uidCounter.toString(36);
  }

  function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
  function lerp(a, b, t) { return a + (b - a) * t; }
  function fmt(n) { return Math.round(n * 100) / 100; }

  function hexToRgb(hex) {
    const h = hex.replace("#", "");
    const v = parseInt(h.length === 3 ? h.split("").map((c) => c + c).join("") : h, 16);
    return [(v >> 16) & 255, (v >> 8) & 255, v & 255];
  }
  function rgbToHex(rgb) {
    return "#" + rgb.map((c) => clamp(Math.round(c), 0, 255).toString(16).padStart(2, "0")).join("");
  }
  function mix(a, b, t) {
    const ca = hexToRgb(a);
    const cb = hexToRgb(b);
    return rgbToHex([lerp(ca[0], cb[0], t), lerp(ca[1], cb[1], t), lerp(ca[2], cb[2], t)]);
  }
  /** amount < 0 darkens (toward a cool ink), > 0 lightens (toward warm white). */
  function shade(hex, amount) {
    if (amount < 0) return mix(hex, "#0b0820", -amount);
    return mix(hex, "#fff6e8", amount);
  }
  function luminance(hex) {
    const c = hexToRgb(hex).map((v) => {
      const s = v / 255;
      return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
  }
  function saturate(hex, amount) {
    const [r, g, b] = hexToRgb(hex);
    const grey = 0.3 * r + 0.59 * g + 0.11 * b;
    return rgbToHex([grey + (r - grey) * amount, grey + (g - grey) * amount, grey + (b - grey) * amount]);
  }

  function rot(p, c, a) {
    const s = Math.sin(a);
    const co = Math.cos(a);
    const x = p[0] - c[0];
    const y = p[1] - c[1];
    return [c[0] + x * co - y * s, c[1] + x * s + y * co];
  }

  /** Smooth closed path through points (Catmull-Rom -> cubic Bezier). */
  function smoothPath(pts, tension) {
    const t = tension === undefined ? 1 : tension;
    const n = pts.length;
    let d = "M" + fmt(pts[0][0]) + " " + fmt(pts[0][1]);
    for (let i = 0; i < n; i++) {
      const p0 = pts[(i - 1 + n) % n];
      const p1 = pts[i];
      const p2 = pts[(i + 1) % n];
      const p3 = pts[(i + 2) % n];
      const c1 = [p1[0] + ((p2[0] - p0[0]) / 6) * t, p1[1] + ((p2[1] - p0[1]) / 6) * t];
      const c2 = [p2[0] - ((p3[0] - p1[0]) / 6) * t, p2[1] - ((p3[1] - p1[1]) / 6) * t];
      d += "C" + fmt(c1[0]) + " " + fmt(c1[1]) + " " + fmt(c2[0]) + " " + fmt(c2[1]) + " " + fmt(p2[0]) + " " + fmt(p2[1]);
    }
    return d + "Z";
  }
  function polyPath(pts) {
    return "M" + pts.map((p) => fmt(p[0]) + " " + fmt(p[1])).join("L") + "Z";
  }

  function ellipsePts(cx, cy, rx, ry, n, a0) {
    const out = [];
    const start = a0 || 0;
    for (let i = 0; i < n; i++) {
      const a = start + (i / n) * Math.PI * 2;
      out.push([cx + Math.cos(a) * rx, cy + Math.sin(a) * ry]);
    }
    return out;
  }

  /** Tapered capsule from p0 (radius r0) to p1 (radius r1). */
  function capsulePts(p0, p1, r0, r1, seg) {
    const n = seg || 5;
    const ang = Math.atan2(p1[1] - p0[1], p1[0] - p0[0]);
    const out = [];
    for (let i = 0; i <= n; i++) {
      const a = ang - Math.PI / 2 - (i / n) * Math.PI;
      out.push([p0[0] + Math.cos(a) * r0, p0[1] + Math.sin(a) * r0]);
    }
    for (let i = 0; i <= n; i++) {
      const a = ang + Math.PI / 2 - (i / n) * Math.PI;
      out.push([p1[0] + Math.cos(a) * r1, p1[1] + Math.sin(a) * r1]);
    }
    return out;
  }

  function mirrorPts(pts) { return pts.map((p) => [2 * CX - p[0], p[1]]); }

  // ---------------------------------------------------------------------------
  // Palettes (structure never changes, only colors)
  // ---------------------------------------------------------------------------
  const PALETTES = {
    neon: {
      name: "Néon cyan (identité)",
      skin: "#a86c48", hair: "#2b2340", suit: "#242638", suit2: "#323853", wrap: "#d9d0c2",
      scarf: "#d8304a", accent: "#3ff0ff", metal: "#c9a24a", boot: "#121019", leather: "#5a3a2a",
    },
    violet: {
      name: "Ombre violette",
      skin: "#c98d63", hair: "#120f1c", suit: "#1a1626", suit2: "#2a2240", wrap: "#cfc6d8",
      scarf: "#6c3cff", accent: "#c79bff", metal: "#b8b2c8", boot: "#0e0b16", leather: "#3b2b4a",
    },
    oni: {
      name: "Oni rouge",
      skin: "#8a553a", hair: "#1a0f10", suit: "#2a1214", suit2: "#3d1a1e", wrap: "#e0d2c0",
      scarf: "#f0b23a", accent: "#ff4d3a", metal: "#d9a648", boot: "#140a0b", leather: "#4a2a1a",
    },
    jade: {
      name: "Spectre jade",
      skin: "#e2b894", hair: "#eef2f4", suit: "#1b2a2c", suit2: "#26393b", wrap: "#e8ece6",
      scarf: "#1d6b5d", accent: "#3dffb0", metal: "#b9c7c2", boot: "#0f1716", leather: "#2f3d3a",
    },
    storm: {
      name: "Tempête blanche",
      skin: "#6e4630", hair: "#f2f4f8", suit: "#151821", suit2: "#232838", wrap: "#f0ece4",
      scarf: "#f4f4f6", accent: "#4fb3ff", metal: "#c7cfdc", boot: "#0d0f15", leather: "#2b2f3d",
    },
    shogun: {
      name: "Or du shogun",
      skin: "#d79f78", hair: "#1c1410", suit: "#5a1218", suit2: "#2a1a14", wrap: "#efe2c6",
      scarf: "#1a1a1f", accent: "#ffd34d", metal: "#e8b84a", boot: "#160e0b", leather: "#5a3a1a",
    },
  };

  // ---------------------------------------------------------------------------
  // Directions (5 drawn views; W/SW/NW are mirrors)
  // ---------------------------------------------------------------------------
  const DIRECTIONS = {
    S: { back: false, t: 0, mirror: false, label: "Face (S)" },
    SE: { back: false, t: 0.55, mirror: false, label: "3/4 avant (SE)" },
    E: { back: false, t: 1, mirror: false, label: "Profil (E)" },
    NE: { back: true, t: 0.55, mirror: false, label: "3/4 arrière (NE)" },
    N: { back: true, t: 0, mirror: false, label: "Dos (N)" },
    SW: { back: false, t: 0.55, mirror: true, label: "3/4 avant (SW)" },
    W: { back: false, t: 1, mirror: true, label: "Profil (W)" },
    NW: { back: true, t: 0.55, mirror: true, label: "3/4 arrière (NW)" },
  };

  // ---------------------------------------------------------------------------
  // Poses (animation-ready: the rig never changes size, only angles/offsets)
  // ---------------------------------------------------------------------------
  function pose(kind, phase) {
    const p = {
      bob: 0, lean: 0, armNear: 0.12, armFar: -0.12, stepNear: 0, stepFar: 0,
      liftNear: 0, liftFar: 0, sway: 0, sword: null, flash: 0, fall: 0, opacity: 1, squash: 1,
    };
    const tau = Math.PI * 2;
    const ph = phase || 0;
    if (kind === "idle") {
      p.bob = Math.sin(ph * tau) * 1.6;
      p.squash = 1 + Math.sin(ph * tau) * 0.008;
      p.sway = Math.sin(ph * tau + 0.8) * 0.06;
      p.armNear = 0.12 + Math.sin(ph * tau) * 0.03;
      p.armFar = -0.12 - Math.sin(ph * tau) * 0.03;
    } else if (kind === "walk") {
      const s = Math.sin(ph * tau);
      p.bob = -Math.abs(Math.cos(ph * tau)) * 3 + 1.5;
      p.stepNear = s * 7;
      p.stepFar = -s * 7;
      p.liftNear = Math.max(0, -Math.cos(ph * tau)) * 5;
      p.liftFar = Math.max(0, Math.cos(ph * tau)) * 5;
      p.armNear = 0.12 - s * 0.45;
      p.armFar = -0.12 + s * 0.45;
      p.sway = 0.12 + Math.sin(ph * tau * 2) * 0.08;
      p.lean = 0.03;
    } else if (kind === "attack") {
      // windup (0-0.3), slash (0.3-0.55), follow-through (0.55-1)
      let a;
      if (ph < 0.3) a = lerp(-0.2, -2.0, ph / 0.3);
      else if (ph < 0.55) a = lerp(-2.0, 1.2, (ph - 0.3) / 0.25);
      else a = lerp(1.2, 0.4, (ph - 0.55) / 0.45);
      p.sword = { angle: a, trail: ph >= 0.3 && ph < 0.7 ? 1 - Math.abs(ph - 0.45) / 0.25 : 0 };
      p.armNear = 0.1;
      p.armFar = a;
      p.lean = ph < 0.3 ? -0.04 : 0.06;
      p.stepNear = -3;
      p.stepFar = 4;
      p.sway = 0.25;
    } else if (kind === "hit") {
      const k = Math.sin(clamp(ph / 0.6, 0, 1) * Math.PI);
      p.flash = ph < 0.25 ? 1 - ph / 0.25 : 0;
      p.lean = -0.12 * k;
      p.bob = 2 * k;
      p.armNear = 0.5 * k + 0.12;
      p.armFar = -0.5 * k - 0.12;
      p.sway = -0.3 * k;
    } else if (kind === "death") {
      const k = clamp(ph / 0.7, 0, 1);
      p.fall = k;
      p.opacity = ph < 0.75 ? 1 : 1 - (ph - 0.75) / 0.25;
      p.armNear = 0.12 + k * 0.8;
      p.armFar = -0.12 - k * 0.8;
      p.sway = -0.5 * k;
    }
    return p;
  }

  // ---------------------------------------------------------------------------
  // The character model: returns ordered parts (back to front)
  // ---------------------------------------------------------------------------
  const DEFAULT_LOOK = {
    heads: 3,          // total height / head height
    build: 1,          // shoulder width multiplier
    headShape: "round", // round | square | sharp
    hair: "ponytail",  // ponytail | spiky | short
    mask: true,
    scarf: 1,          // scarf tail length multiplier (0 = no tails)
    cape: false,
    armor: false,
    detail: 1,         // 0 minimal, 1 normal, 2 high
    eyes: "anime",     // anime | glow | dot
    lowPoly: false,
  };

  /**
   * Part: { id, pts, color (palette key or hex), kind, smooth, glow, noShade, z }
   * kind: "skin" | "cloth" | "hair" | "metal" | "accent" | "detail" (thin lines)
   */
  function buildCharacter(look, dirKey, ps) {
    const L = Object.assign({}, DEFAULT_LOOK, look || {});
    const dir = DIRECTIONS[dirKey] || DIRECTIONS.S;
    const t = dir.t;
    const back = dir.back;
    const P = ps || pose("idle", 0);
    const seg = L.lowPoly ? 3 : 6;
    const ell = L.lowPoly ? 7 : 18;

    const headH = HEIGHT / L.heads;
    const hr = headH * 0.5 * (L.headShape === "square" ? 1.04 : 1);
    const rest = HEIGHT - headH;
    const torsoLen = rest * 0.44;
    const legLen = rest - torsoLen;
    const top = FEET - HEIGHT + P.bob;
    const headCX = CX + (back ? -1 : 1) * t * hr * 0.12;
    const headCY = top + hr;
    const neckY = headCY + hr * 0.9;
    const shoulderY = neckY + torsoLen * 0.12;
    const waistY = neckY + torsoLen * 0.78;
    const hipY = neckY + torsoLen;
    const ankleY = FEET - Math.max(6, legLen * 0.14);
    const sw = Math.max(hr * 0.74, HEIGHT * 0.115) * L.build;
    const ww = sw * 0.7;
    const wf = 1 - 0.42 * t; // body width as the character turns
    const fx = (back ? -1 : 1) * t * hr * 0.55; // facial feature shift
    const parts = [];
    const add = (part) => { parts.push(part); return part; };
    const bx = (x) => CX + x * wf; // body x relative to center

    // --- Ground shadow (separate, drawn by renderer) ---------------------------
    const ground = { cx: CX, cy: FEET + 1, rx: sw * 1.25, ry: sw * 0.3 };

    // --- Shapes --------------------------------------------------------------
    // Head
    function headPts() {
      const pts = ellipsePts(headCX, headCY, hr * (1 - 0.06 * t), hr, ell, -Math.PI / 2);
      if (L.headShape === "square") {
        return pts.map((p) => {
          const dx = p[0] - headCX;
          const dy = p[1] - headCY;
          const k = 1 + 0.12 * Math.abs(Math.sin(2 * Math.atan2(dy, dx)));
          return [headCX + dx * k, headCY + dy * Math.min(k, 1.06)];
        });
      }
      if (L.headShape === "sharp") {
        return pts.map((p) => {
          const dy = p[1] - headCY;
          if (dy > 0) {
            const dx = p[0] - headCX;
            return [headCX + dx * (1 - (dy / hr) * 0.32), p[1] + dy * 0.08];
          }
          return p;
        });
      }
      return pts;
    }

    // Scarf tails (behind in front views, over the back in back views)
    function scarfTails() {
      if (L.scarf <= 0) return [];
      const out = [];
      const len = hr * 2.4 * L.scarf;
      const baseX = back ? headCX + hr * 0.1 : headCX - hr * 0.55 * wf;
      const baseY = neckY + hr * 0.05;
      const dirX = back ? 0.35 : -1;
      const sway = P.sway;
      for (let k = 0; k < 2; k++) {
        const off = k * hr * 0.28;
        const wv = hr * (0.26 - k * 0.05) * (back ? 1.35 : 1);
        const pts = [];
        const n = L.lowPoly ? 3 : 6;
        const spine = [];
        for (let i = 0; i <= n; i++) {
          const s = i / n;
          const ang = (back ? 1.35 : 0.55) + sway * (0.6 + s) + Math.sin(s * 3 + k + sway * 4) * 0.12 + k * 0.18;
          const x = baseX + dirX * Math.cos(ang) * len * s * (back ? 0.5 : 1) - off * dirX;
          const y = baseY + Math.sin(ang) * len * s + off * 0.3;
          spine.push([x, y]);
        }
        for (let i = 0; i <= n; i++) {
          const s = i / n;
          const w = wv * (1 - s * 0.45);
          pts.push([spine[i][0], spine[i][1] - w]);
        }
        const tip = spine[n];
        pts.push([tip[0] + dirX * hr * 0.12, tip[1] + hr * 0.18]); // swallow-tail notch
        pts.push([tip[0] - dirX * hr * 0.02, tip[1] + hr * 0.05]);
        for (let i = n; i >= 0; i--) {
          const s = i / n;
          const w = wv * (1 - s * 0.45);
          pts.push([spine[i][0] + dirX * w * 0.3, spine[i][1] + w]);
        }
        out.push({ id: "scarfTail" + k, pts, color: k === 0 ? "scarf" : shadeKey("scarf", -0.18), kind: "cloth", smooth: !L.lowPoly });
      }
      return out;
    }

    // Ponytail: a quadratic spine from the tie, thick in the middle, spiky tip.
    function bez(p0, p1, p2, s) {
      const u = 1 - s;
      return [u * u * p0[0] + 2 * u * s * p1[0] + s * s * p2[0], u * u * p0[1] + 2 * u * s * p1[1] + s * s * p2[1]];
    }
    function ponytail() {
      if (L.hair !== "ponytail") return null;
      const len = hr * 2.0;
      const sway = P.sway;
      let tie;
      let c;
      let end;
      if (back) {
        tie = [headCX - fx * 0.3, headCY - hr * 0.8];
        c = [tie[0] + hr * 0.5 - sway * hr * 0.8, tie[1] + len * 0.3];
        end = [tie[0] + hr * 0.35 - sway * hr * 1.4 - t * hr * 0.4, tie[1] + len * 0.95];
      } else if (t > 0.8) {
        tie = [headCX - hr * 0.62, headCY - hr * 0.72];
        c = [tie[0] - hr * 1.15, tie[1] - hr * 0.15];
        end = [tie[0] - hr * 1.35 - sway * hr * 0.8, tie[1] + len * 0.85];
      } else {
        tie = [headCX - hr * (0.1 + 0.45 * t), headCY - hr * 0.95];
        c = [tie[0] - hr * 1.3, tie[1] - hr * 0.6];
        end = [tie[0] - hr * 1.6 - sway * hr * 0.8, tie[1] + len * 0.82];
      }
      const n = L.lowPoly ? 4 : 9;
      const spine = [];
      for (let i = 0; i <= n; i++) spine.push(bez(tie, c, end, i / n));
      const width = (s) => hr * (0.14 + 0.3 * Math.sin(Math.PI * Math.min(1, 0.12 + s * 0.95))) * (1 - s * 0.3);
      const nrm = (i) => {
        const a = spine[Math.max(0, i - 1)];
        const b = spine[Math.min(n, i + 1)];
        const dx = b[0] - a[0];
        const dy = b[1] - a[1];
        const l = Math.hypot(dx, dy) || 1;
        return [-dy / l, dx / l];
      };
      const sideA = [];
      const sideB = [];
      for (let i = 0; i <= n; i++) {
        const w = width(i / n);
        const nv = nrm(i);
        sideA.push([spine[i][0] + nv[0] * w, spine[i][1] + nv[1] * w]);
        sideB.push([spine[i][0] - nv[0] * w, spine[i][1] - nv[1] * w]);
      }
      const nv = nrm(n);
      const tv = [nv[1], -nv[0]];
      const tip = spine[n];
      const w = width(1);
      const spikes = [
        [tip[0] + nv[0] * w * 1.6 + tv[0] * hr * 0.2, tip[1] + nv[1] * w * 1.6 + tv[1] * hr * 0.2],
        [tip[0] + nv[0] * w * 0.3 + tv[0] * hr * 0.12, tip[1] + nv[1] * w * 0.3 + tv[1] * hr * 0.12],
        [tip[0] + tv[0] * hr * 0.42, tip[1] + tv[1] * hr * 0.42],
        [tip[0] - nv[0] * w * 0.5 + tv[0] * hr * 0.1, tip[1] - nv[1] * w * 0.5 + tv[1] * hr * 0.1],
        [tip[0] - nv[0] * w * 1.4 + tv[0] * hr * 0.26, tip[1] - nv[1] * w * 1.4 + tv[1] * hr * 0.26],
      ];
      return { pts: sideA.concat(spikes, sideB.reverse()), tie };
    }

    // Katana in its sheath, on the back (diagonal), or drawn in hand when attacking.
    function katanaOnBack() {
      if (P.sword) return [];
      const out = [];
      let hilt;
      let tip;
      if (back) {
        hilt = [headCX - hr * 0.95 * wf + fx * 0.3, shoulderY - hr * 0.55];
        tip = [CX + sw * 1.05 * wf, hipY + legLen * 0.35];
      } else if (t > 0.8) {
        hilt = [CX - sw * 0.75, shoulderY - hr * 0.6];
        tip = [CX - sw * 0.2, hipY + legLen * 0.55];
        hilt = [hilt[0] - hr * 0.2, hilt[1]];
      } else {
        hilt = [CX + sw * 1.0 * wf, shoulderY - hr * 0.62];
        tip = [CX - sw * 1.25 * wf, hipY + legLen * 0.48];
      }
      const ang = Math.atan2(tip[1] - hilt[1], tip[0] - hilt[0]);
      const guard = [hilt[0] + Math.cos(ang) * hr * 0.5, hilt[1] + Math.sin(ang) * hr * 0.5];
      const sheathW = Math.max(2.6, hr * 0.13);
      out.push({ id: "sheath", pts: capsulePts(guard, tip, sheathW, sheathW * 0.9, 2), color: "suit2", kind: "cloth", smooth: false });
      if (L.detail >= 1) {
        out.push({ id: "sheathBand", pts: capsulePts(lerpP(guard, tip, 0.55), lerpP(guard, tip, 0.62), sheathW * 1.08, sheathW * 1.08, 1), color: "metal", kind: "metal", smooth: false });
      }
      out.push({ id: "hilt", pts: capsulePts(hilt, guard, sheathW * 0.85, sheathW * 0.85, 2), color: "wrap", kind: "cloth", smooth: false });
      const gx = guard[0];
      const gy = guard[1];
      out.push({ id: "tsuba", pts: ellipsePts(gx, gy, sheathW * 1.9, sheathW * 1.9, L.lowPoly ? 5 : 10, ang), color: "metal", kind: "metal", smooth: false });
      out.push({ id: "kashira", pts: ellipsePts(hilt[0], hilt[1], sheathW * 0.95, sheathW * 0.95, 6, 0), color: "metal", kind: "metal", smooth: !L.lowPoly });
      return out;
    }

    function lerpP(a, b, k) { return [lerp(a[0], b[0], k), lerp(a[1], b[1], k)]; }

    // Hakama: one wide flared shape (triangle silhouette), split at the hem.
    function hakama() {
      const topY = waistY + (hipY - waistY) * 0.1;
      const hemY = ankleY;
      const topW = ww * 1.05;
      const hemW = ww * 1.8;
      const sL = P.stepNear * Math.max(t, 0.25);
      const sR = P.stepFar * Math.max(t, 0.25);
      const lL = P.liftNear;
      const lR = P.liftFar;
      const crotchY = lerp(hipY, hemY, 0.42);
      const midY = lerp(topY, hemY, 0.5);
      const midW = lerp(topW, hemW, 0.55);
      const pts = [
        [CX - topW * wf, topY],
        [CX + topW * wf, topY],
        [CX + midW * wf + 1.5, midY],
        [CX + hemW * wf + sR, hemY - lR],
        [CX + hemW * 0.5 * wf + sR, hemY - lR + 3],
        [CX + hr * 0.1 + sR * 0.5, hemY - lR * 0.6 - 1],
        [CX + (sL + sR) * 0.25, lerp(crotchY, hemY, 0.5)],
        [CX - hr * 0.1 + sL * 0.5, hemY - lL * 0.6 - 1],
        [CX - hemW * 0.5 * wf + sL, hemY - lL + 3],
        [CX - hemW * wf + sL, hemY - lL],
        [CX - midW * wf - 1.5, midY],
      ];
      const feet = {
        near: { foot: [CX - hemW * 0.5 * wf + sL, hemY - lL], lift: lL },
        far: { foot: [CX + hemW * 0.5 * wf + sR, hemY - lR], lift: lR },
      };
      const pleats = [
        [[CX - topW * 0.45 * wf, topY + 4], [CX - hemW * 0.62 * wf + sL, hemY - lL - 3]],
        [[CX + topW * 0.45 * wf, topY + 4], [CX + hemW * 0.62 * wf + sR, hemY - lR - 3]],
      ];
      return { pts, feet, pleats };
    }

    function boot(footInfo, near) {
      const fw = Math.max(hr * 0.5, 8) * (t > 0.8 ? 1.15 : 1);
      const fh = Math.max(hr * 0.34, 6);
      const x = footInfo.foot[0];
      const y = FEET - footInfo.lift;
      const toe = back ? 0 : t * fw * 0.6;
      const top = footInfo.foot[1] - fh * 0.6;
      const pts = [
        [x - fw * 0.5, top],
        [x + fw * 0.5, top],
        [x + fw * 0.58 + toe, y - fh * 0.38],
        [x + fw * 0.46 + toe, y],
        [x - fw * 0.58, y],
        [x - fw * 0.62, y - fh * 0.4],
      ];
      return { id: near ? "bootNear" : "bootFar", pts, color: "boot", kind: "cloth", smooth: !L.lowPoly };
    }

    function arm(side, near, angleExtra) {
      // Positive angles swing toward image left (SVG y points down).
      const shoulderX = CX + side * sw * 0.86 * (1 - 0.85 * t);
      const sh = [shoulderX, shoulderY + hr * 0.08];
      const upLen = torsoLen * 0.5 + hr * 0.05;
      const foreLen = torsoLen * 0.42 + hr * 0.1;
      const a = -side * 0.2 * (1 - t) + angleExtra;
      const el = rot([sh[0], sh[1] + upLen], sh, a);
      const straight = P.sword && !near;
      const bend = straight ? 0 : -side * 0.3 * (1 - t) - 0.35 * t;
      const hand = rot([el[0], el[1] + foreLen], el, a + bend);
      const r0 = Math.max(hr * 0.25, 4) * L.build;
      const r1 = r0 * 0.86;
      const key = near ? "Near" : "Far";
      const out = [
        { id: "shoulder" + key, pts: ellipsePts(sh[0], sh[1], r0 * 1.18, r0 * 1.1, L.lowPoly ? 6 : 12, 0), color: "skin", kind: "skin", smooth: !L.lowPoly },
        { id: "upper" + key, pts: capsulePts(sh, el, r0, r1, seg), color: "skin", kind: "skin", smooth: !L.lowPoly },
        { id: "fore" + key, pts: capsulePts(el, hand, r1 * 1.08, r1 * 0.95, seg), color: "wrap", kind: "cloth", smooth: !L.lowPoly },
        { id: "fist" + key, pts: ellipsePts(hand[0], hand[1] + r1 * 0.2, r1 * 1.02, r1 * 0.98, L.lowPoly ? 6 : 12, 0), color: "suit", kind: "cloth", smooth: !L.lowPoly },
      ];
      if (L.detail >= 1) {
        const ang = Math.atan2(hand[1] - el[1], hand[0] - el[0]) - Math.PI / 2;
        [0.35, 0.68].forEach((k, i) => {
          const m = lerpP(el, hand, k);
          out.push({ id: "wrapLine" + key + i, line: [rot([m[0] - r1, m[1] - 1], m, ang), rot([m[0] + r1, m[1] + 2], m, ang)], color: "wrapShadow", kind: "detail" });
        });
      }
      if (L.armor && near) {
        out.splice(1, 0, { id: "pauldron", pts: ellipsePts(sh[0] + side * 1.5, sh[1] - 2, r0 * 1.7, r0 * 1.3, L.lowPoly ? 6 : 14, 0), color: "metal", kind: "metal", smooth: !L.lowPoly });
      }
      return { parts: out, hand, angle: a };
    }

    function torso() {
      const neckW = hr * 0.3;
      if (t > 0.8) {
        return [
          [CX - neckW, neckY - 2], [CX + neckW, neckY - 2], [CX + sw * 0.6, shoulderY + hr * 0.15],
          [CX + sw * 0.62, waistY - 4], [CX + ww * 0.62, hipY + 1], [CX - ww * 0.72, hipY + 1],
          [CX - sw * 0.58, waistY], [CX - sw * 0.62, shoulderY + hr * 0.2],
        ];
      }
      return [
        [bx(-neckW), neckY - 2], [bx(neckW), neckY - 2],
        [bx(sw * 0.8), shoulderY + hr * 0.02], [bx(sw * 0.88), shoulderY + hr * 0.4],
        [bx(ww * 0.88), waistY], [bx(ww * 1.0), hipY + 1],
        [bx(-ww * 1.0), hipY + 1], [bx(-ww * 0.88), waistY],
        [bx(-sw * 0.88), shoulderY + hr * 0.4], [bx(-sw * 0.8), shoulderY + hr * 0.02],
      ];
    }

    function belt() {
      const h = Math.max(hr * 0.3, 5);
      const y = waistY + (hipY - waistY) * 0.15;
      const w = (t > 0.8 ? ww * 0.7 : ww * 1.08) * (t > 0.8 ? 1 : wf);
      return { id: "obi", pts: [[CX - w, y - h / 2], [CX + w, y - h / 2 - 1], [CX + w, y + h / 2], [CX - w, y + h / 2 + 1]], color: "scarf", kind: "cloth", smooth: false };
    }

    function strap() {
      if (L.detail < 1 || t > 0.8) return null;
      const a = back ? [bx(-sw * 0.8), shoulderY] : [bx(sw * 0.82), shoulderY];
      const b = back ? [bx(ww * 0.95), waistY + 2] : [bx(-ww * 0.95), waistY + 2];
      return { id: "strap", pts: capsulePts(a, b, Math.max(2, hr * 0.09), Math.max(2, hr * 0.09), 1), color: "leather", kind: "cloth", smooth: false };
    }

    function collar() {
      // Scarf wrapped around the neck: a thick band.
      const w = hr * 0.78 * (1 - 0.25 * t);
      const y0 = neckY - hr * 0.22;
      const y1 = neckY + hr * 0.22;
      const cx = CX + (back ? -1 : 1) * t * hr * 0.08;
      return {
        id: "collar",
        pts: [[cx - w, y0 + 2], [cx - w * 0.3, y0 - 1], [cx + w * 0.4, y0], [cx + w, y0 + 3], [cx + w * 1.04, y1 - 1], [cx + w * 0.2, y1 + 3], [cx - w * 0.6, y1 + 1], [cx - w * 1.06, y1 - 2]],
        color: "scarf", kind: "cloth", smooth: !L.lowPoly,
      };
    }

    // Hair mass behind the face (front views) or covering the head (back views).
    function hairBack() {
      const pts = [];
      const n = L.lowPoly ? 8 : 14;
      const R = hr * 1.1;
      const spike = L.hair === "spiky" ? 1.34 : 1.2;
      const cx = headCX + (back ? fx * 0.15 : -fx * 0.3 - (t > 0.8 ? hr * 0.18 : 0));
      const a0 = Math.PI * 0.84;
      const a1 = Math.PI * 2.16;
      for (let i = 0; i <= n; i++) {
        const a = lerp(a0, a1, i / n);
        const k = i % 2 === 1 ? spike : 1;
        pts.push([cx + Math.cos(a) * R * k * (1 - 0.05 * t), headCY - hr * 0.05 + Math.sin(a) * R * k]);
      }
      if (back) {
        const m = L.lowPoly ? 3 : 6;
        for (let i = 0; i <= m; i++) {
          const s = i / m;
          pts.push([cx + R * 0.95 - s * R * 1.9, headCY + hr * (i % 2 === 0 ? 0.72 : 0.42)]);
        }
      } else {
        pts.push([cx, headCY + hr * 0.35]);
      }
      return pts;
    }

    // Fringe over the forehead (front views only): hairline arc + jagged locks.
    function bangs() {
      const pts = [];
      const R = hr * 1.07;
      const shift = fx * 0.25;
      const m = L.lowPoly ? 4 : 8;
      const aL = Math.PI * 1.06;
      const aR = Math.PI * 1.94;
      for (let i = 0; i <= m; i++) {
        const a = lerp(aL, aR, i / m);
        pts.push([headCX + shift + Math.cos(a) * R * (1 - 0.05 * t), headCY - hr * 0.02 + Math.sin(a) * R]);
      }
      pts.push([headCX + shift + R * 0.9 * (1 - 0.35 * t), headCY + hr * 0.12]);
      const right = headCX + fx * 0.6 + R * 0.78 * (1 - 0.3 * t);
      const left = headCX + fx * 0.6 - R * 0.86 * (1 - 0.45 * t);
      const locks = L.lowPoly ? 3 : 5;
      for (let i = 0; i <= locks * 2; i++) {
        const s = i / (locks * 2);
        const tipDown = i % 2 === 0;
        pts.push([lerp(right, left, s) - (tipDown ? hr * 0.06 : 0), headCY + (tipDown ? -hr * 0.14 : -hr * 0.46)]);
      }
      pts.push([headCX + shift - R * 0.95 * (1 - 0.5 * t), headCY + hr * 0.1 * (1 - t)]);
      return pts;
    }

    function faceParts() {
      const out = [];
      if (back) return out;
      const eyeY = headCY + hr * 0.06;
      const eyeGap = hr * 0.38 * (1 - 0.5 * t);
      const ex = headCX + fx;
      const eyeW = hr * (L.eyes === "dot" ? 0.11 : 0.22);
      const eyeH = hr * (L.eyes === "glow" ? 0.09 : L.eyes === "dot" ? 0.11 : 0.2);
      const eyes = t > 0.8 ? [[ex + hr * 0.12, eyeY]] : [[ex - eyeGap, eyeY], [ex + eyeGap * (1 - 0.3 * t), eyeY]];
      eyes.forEach((e, i) => {
        const far = i === 0 && t > 0.2 && t <= 0.8;
        const w = eyeW * (far ? 0.75 : 1);
        if (L.eyes === "anime") {
          out.push({ id: "eyeWhite" + i, pts: [[e[0] - w, e[1] - eyeH * 0.2], [e[0] - w * 0.2, e[1] - eyeH * 0.75], [e[0] + w, e[1] - eyeH * 0.55], [e[0] + w * 0.8, e[1] + eyeH * 0.5], [e[0] - w * 0.6, e[1] + eyeH * 0.55]], color: "#f4f1ea", kind: "flat", smooth: true });
          out.push({ id: "iris" + i, pts: ellipsePts(e[0] + w * 0.15, e[1] - eyeH * 0.02, w * 0.48, eyeH * 0.52, 10, 0), color: "accent", kind: "accent", glow: true, smooth: true });
          out.push({ id: "pupil" + i, pts: ellipsePts(e[0] + w * 0.17, e[1], w * 0.2, eyeH * 0.3, 8, 0), color: "#0b0b12", kind: "flat", smooth: true });
          out.push({ id: "eyeShine" + i, pts: ellipsePts(e[0] + w * 0.32, e[1] - eyeH * 0.25, w * 0.12, w * 0.12, 6, 0), color: "#ffffff", kind: "flat", smooth: true });
        } else if (L.eyes === "glow") {
          out.push({ id: "eyeGlow" + i, pts: [[e[0] - w, e[1] - eyeH * 0.2], [e[0] + w, e[1] - eyeH * 0.9], [e[0] + w * 0.7, e[1] + eyeH * 0.6], [e[0] - w * 0.8, e[1] + eyeH * 0.5]], color: "accent", kind: "accent", glow: true, smooth: false });
        } else {
          out.push({ id: "eyeDot" + i, pts: ellipsePts(e[0], e[1], w, eyeH, 8, 0), color: "accent", kind: "accent", glow: true, smooth: true });
        }
        // brow: angry slant
        const bw = w * 1.15;
        const by = e[1] - eyeH * 1.15 - hr * 0.05;
        const inward = i === eyes.length - 1 && eyes.length > 1 ? -1 : 1;
        out.push({ id: "brow" + i, line: [[e[0] - bw * inward, by - hr * 0.04], [e[0] + bw * inward, by + hr * 0.06]], color: "hairDark", kind: "detail", width: Math.max(1.6, hr * 0.08) });
      });
      if (L.mask) {
        const my = headCY + hr * 0.3;
        const mw = hr * 0.98 * (1 - 0.12 * t);
        const mcx = headCX + fx * 0.6;
        const pts = t > 0.8
          ? [[headCX - hr * 0.2, my - hr * 0.02], [headCX + hr * 0.9, my - hr * 0.05], [headCX + hr * 1.06, my + hr * 0.32], [headCX + hr * 0.55, headCY + hr * 0.98], [headCX - hr * 0.3, headCY + hr * 0.92]]
          : [[mcx - mw, my - hr * 0.02], [mcx - mw * 0.2, my - hr * 0.12], [mcx + fx * 0.2 + hr * 0.02, my - hr * 0.16], [mcx + mw * 0.3, my - hr * 0.1], [mcx + mw, my - hr * 0.02], [mcx + mw * 0.82, headCY + hr * 0.78], [mcx + fx * 0.3, headCY + hr * 1.02], [mcx - mw * 0.82, headCY + hr * 0.78]];
        out.push({ id: "mask", pts, color: "suit", kind: "cloth", smooth: !L.lowPoly });
        if (L.detail >= 2) {
          out.push({ id: "maskSeam", line: [[mcx - mw * 0.6, my + hr * 0.25], [mcx + mw * 0.6, my + hr * 0.25]], color: "accent", kind: "accentLine", width: Math.max(1.2, hr * 0.05) });
        }
      }
      return out;
    }

    function cape() {
      if (!L.cape) return null;
      const w0 = sw * 1.05 * wf;
      const w1 = sw * 1.8 * wf;
      const y1 = ankleY - legLen * 0.1;
      const sway = P.sway * hr * 0.6;
      const pts = [[CX - w0, shoulderY], [CX + w0, shoulderY], [CX + w1 - sway, y1], [CX + w1 * 0.5 - sway, y1 + 6], [CX - sway, y1 - 4], [CX - w1 * 0.5 - sway, y1 + 7], [CX - w1 - sway, y1]];
      return { id: "cape", pts, color: "suit2", kind: "cloth", smooth: !L.lowPoly };
    }

    function swordInHand(handPos, angle) {
      if (!P.sword) return [];
      const len = hr * 2.1;
      const a = P.sword.angle + Math.PI / 2;
      const dirv = [Math.cos(a), Math.sin(a)];
      const hiltEnd = [handPos[0] - dirv[0] * hr * 0.3, handPos[1] - dirv[1] * hr * 0.3];
      const guard = [handPos[0] + dirv[0] * hr * 0.18, handPos[1] + dirv[1] * hr * 0.18];
      const tip = [guard[0] + dirv[0] * len, guard[1] + dirv[1] * len];
      const bw = Math.max(2.2, hr * 0.09);
      const out = [];
      if (P.sword.trail > 0) {
        // slash arc VFX
        const c = handPos;
        const arcPts = [];
        const a0 = a - 1.6;
        const n = 10;
        for (let i = 0; i <= n; i++) arcPts.push([c[0] + Math.cos(a0 + (i / n) * 1.6) * len * 1.05, c[1] + Math.sin(a0 + (i / n) * 1.6) * len * 1.05]);
        for (let i = n; i >= 0; i--) arcPts.push([c[0] + Math.cos(a0 + (i / n) * 1.6) * len * (0.72 + 0.25 * (i / n)), c[1] + Math.sin(a0 + (i / n) * 1.6) * len * (0.72 + 0.25 * (i / n))]);
        out.push({ id: "slash", pts: arcPts, color: "accent", kind: "vfx", glow: true, opacity: 0.55 * P.sword.trail, smooth: false });
      }
      out.push({ id: "blade", pts: [[guard[0] - dirv[1] * bw, guard[1] + dirv[0] * bw], [tip[0], tip[1]], [guard[0] + dirv[1] * bw, guard[1] - dirv[0] * bw]], color: "#e8f2f6", kind: "metal", smooth: false });
      out.push({ id: "bladeEdge", line: [guard, tip], color: "accent", kind: "accentLine", width: Math.max(1, bw * 0.45) });
      out.push({ id: "handGrip", pts: capsulePts(hiltEnd, guard, bw * 0.9, bw * 0.9, 2), color: "wrap", kind: "cloth", smooth: false });
      out.push({ id: "tsubaHand", pts: ellipsePts(guard[0], guard[1], bw * 1.8, bw * 1.8, 8, angle), color: "metal", kind: "metal", smooth: false });
      return out;
    }

    // --- Assemble in draw order -------------------------------------------------
    const pony = ponytail();
    const tails = scarfTails();
    const hk = hakama();
    const armNear = arm(-1, true, P.armNear);
    const armFar = arm(1, false, P.armFar);
    const katana = katanaOnBack();
    const capePart = cape();
    const addLegs = () => {
      add(boot(hk.feet.far, false));
      add(boot(hk.feet.near, true));
      add({ id: "hakama", pts: hk.pts, color: "suit2", kind: "cloth", smooth: false });
      if (L.detail >= 1) hk.pleats.forEach((ln, i) => add({ id: "pleat" + i, line: ln, color: { key: "suit2", amount: -0.45 }, kind: "detail", width: Math.max(1, hr * 0.045) }));
    };
    const addRibbon = () => {
      if (pony) add({ id: "ribbon", pts: ellipsePts(pony.tie[0], pony.tie[1], hr * 0.2, hr * 0.14, 8, 0.4), color: "scarf", kind: "cloth", smooth: true });
    };
    const addBody = () => {
      add({ id: "torso", pts: torso(), color: "suit", kind: "cloth", smooth: !L.lowPoly });
      if (!back && L.detail >= 2 && t <= 0.8) {
        add({ id: "seamL", line: [[bx(-sw * 0.45), shoulderY + 4], [bx(-ww * 0.55), waistY - 2]], color: "accent", kind: "accentLine", width: Math.max(1.1, hr * 0.045) });
        add({ id: "seamR", line: [[bx(sw * 0.45), shoulderY + 4], [bx(ww * 0.55), waistY - 2]], color: "accent", kind: "accentLine", width: Math.max(1.1, hr * 0.045) });
      }
      const st = strap();
      if (st) add(st);
      add(belt());
      if (!back && L.detail >= 1) add({ id: "obiKnot", pts: ellipsePts(CX + (t > 0.8 ? -ww * 0.6 : ww * 0.55 * wf), waistY + (hipY - waistY) * 0.15, hr * 0.16, hr * 0.13, 8, 0), color: "metal", kind: "metal", smooth: true });
    };

    if (!back) {
      if (capePart) add(capePart);
      tails.forEach(add);
      katana.forEach(add);
      if (pony) add({ id: "ponytail", pts: pony.pts, color: "hair", kind: "hair", smooth: !L.lowPoly });
      if (t <= 0.8) addRibbon();
      if (t > 0.3) armFar.parts.forEach(add);
      addLegs();
      add({ id: "neck", pts: capsulePts([headCX, headCY + hr * 0.5], [CX, neckY + 2], hr * 0.28, hr * 0.3, 3), color: "skin", kind: "skin", smooth: !L.lowPoly });
      addBody();
      if (t <= 0.3) armFar.parts.forEach(add);
      add({ id: "hairBack", pts: hairBack(), color: "hair", kind: "hair", smooth: false });
      add({ id: "head", pts: headPts(), color: "skin", kind: "skin", smooth: !L.lowPoly });
      add({ id: "bangs", pts: bangs(), color: "hair", kind: "hair", smooth: false });
      faceParts().forEach(add);
      if (t > 0.8) addRibbon();
      add(collar());
      armNear.parts.forEach(add);
      swordInHand(armFar.hand, armFar.angle).forEach(add);
    } else {
      if (t > 0.3) armFar.parts.forEach(add);
      addLegs();
      addBody();
      if (t <= 0.3) armFar.parts.forEach(add);
      armNear.parts.forEach(add);
      add({ id: "head", pts: headPts(), color: "skin", kind: "skin", smooth: !L.lowPoly });
      add({ id: "hairBack", pts: hairBack(), color: "hair", kind: "hair", smooth: false });
      add(collar());
      katana.forEach(add);
      tails.forEach(add);
      if (pony) add({ id: "ponytail", pts: pony.pts, color: "hair", kind: "hair", smooth: !L.lowPoly });
      addRibbon();
      if (capePart) add(capePart);
      swordInHand(armFar.hand, armFar.angle).forEach(add);
    }

    return { parts, ground, hr, headCY, mirror: dir.mirror, pose: P, look: L };
  }

  // Small helper so parts can ask for derived palette colors ("scarf" darkened...)
  function shadeKey(key, amount) { return { key, amount }; }

  // ---------------------------------------------------------------------------
  // A generic enemy (horned imp) built from the same kind of parts, so each
  // style can show how a whole cast would look together.
  // ---------------------------------------------------------------------------
  function buildImp(look, variant) {
    const L = Object.assign({ lowPoly: false }, look || {});
    const ell = L.lowPoly ? 7 : 18;
    const v = variant || 0;
    const parts = [];
    const bodyR = 52;
    const cy = FEET - bodyR - 18;
    parts.push({ id: "impLegL", pts: capsulePts([CX - 18, cy + 30], [CX - 22, FEET - 6], 9, 8, 4), color: "enemyDark", kind: "cloth", smooth: !L.lowPoly });
    parts.push({ id: "impLegR", pts: capsulePts([CX + 18, cy + 30], [CX + 22, FEET - 6], 9, 8, 4), color: "enemyDark", kind: "cloth", smooth: !L.lowPoly });
    parts.push({ id: "impHornL", pts: [[CX - 34, cy - 30], [CX - 58 - v * 6, cy - 78], [CX - 18, cy - 44]], color: "enemyHorn", kind: "metal", smooth: false });
    parts.push({ id: "impHornR", pts: [[CX + 34, cy - 30], [CX + 58 + v * 6, cy - 78], [CX + 18, cy - 44]], color: "enemyHorn", kind: "metal", smooth: false });
    parts.push({ id: "impBody", pts: ellipsePts(CX, cy, bodyR, bodyR * 0.96, ell, -Math.PI / 2), color: "enemy", kind: "skin", smooth: !L.lowPoly });
    parts.push({ id: "impBelly", pts: ellipsePts(CX, cy + 20, bodyR * 0.55, bodyR * 0.4, ell, 0), color: "enemyLight", kind: "skin", smooth: !L.lowPoly });
    parts.push({ id: "impEyeL", pts: [[CX - 30, cy - 12], [CX - 8, cy - 4], [CX - 12, cy + 6], [CX - 28, cy + 2]], color: "#fff2c0", kind: "accent", glow: true, smooth: false });
    parts.push({ id: "impEyeR", pts: [[CX + 30, cy - 12], [CX + 8, cy - 4], [CX + 12, cy + 6], [CX + 28, cy + 2]], color: "#fff2c0", kind: "accent", glow: true, smooth: false });
    parts.push({ id: "impMouth", pts: [[CX - 16, cy + 18], [CX + 16, cy + 18], [CX + 8, cy + 28], [CX, cy + 24], [CX - 8, cy + 28]], color: "#2a0a10", kind: "flat", smooth: false });
    return { parts, ground: { cx: CX, cy: FEET + 1, rx: 60, ry: 14 }, hr: bodyR, headCY: cy, mirror: false, pose: pose("idle", 0), look: L };
  }

  const ENEMY_COLORS = {
    enemy: "#d6384a", enemyDark: "#7a1a2c", enemyLight: "#f08a78", enemyHorn: "#2a1a24",
  };

  // ---------------------------------------------------------------------------
  // Styles
  // ---------------------------------------------------------------------------
  /*
   * outline: { outer (silhouette width), inner (part lines), color: "ink"|"dark"|"white"|"accent"|"none" }
   * shading: "flat" | "cel" | "cel3" | "soft" | "clay" | "facet" | "ink" | "neon" | "emboss"
   * light: direction the light comes from (unit-ish vector, screen space)
   */
  const STYLES = [
    {
      id: "style_01", key: "A", name: "Stylized Hand-Painted",
      tagline: "Peint à la main, couleurs riches, lumière chaude.",
      look: { heads: 4, eyes: "anime", detail: 2 },
      outline: { outer: 2.2, inner: 0, color: "dark", soft: true },
      shading: "soft", light: [-0.6, -0.8], rim: "#ffd9a0", texture: "paint", wobble: 1.6,
      sat: 1.05, ground: 0.35,
      scores: { detail: 5, readability: 3, personality: 4, commercial: 4, difficulty: 5 },
      pros: ["Rendu premium, chaleureux", "Très beau en gros plan, menus, cartes de perso"],
      cons: ["Détails qui fondent sous 64 px", "Coût énorme par perso et par frame (peint)", "Difficile à garder cohérent sur 25+ persos"],
      honest: "Prototype vectoriel : texture de peinture simulée par filtres SVG. Un vrai rendu peint nécessite un illustrateur.",
    },
    {
      id: "style_02", key: "B", name: "Modern Cartoon",
      tagline: "Formes propres, tête large, couleurs franches.",
      look: { heads: 2.8, eyes: "anime", detail: 1, headShape: "round" },
      outline: { outer: 6, inner: 2.2, color: "ink" },
      shading: "cel", light: [-0.55, -0.75], rim: null, sat: 1.2, ground: 0.4,
      scores: { detail: 3, readability: 5, personality: 4, commercial: 5, difficulty: 2 },
      pros: ["Lisible à toutes les tailles", "Très « Steam friendly » (Brotato, Vampire Survivors chibi)", "Animation simple (pièces rigides)"],
      cons: ["Peut paraître générique si la palette est mal tenue", "Moins de gravité/ambiance"],
      honest: "Rendu vectoriel complet : c'est déjà quasiment la qualité finale atteignable par code.",
    },
    {
      id: "style_03", key: "C", name: "High-End 2D RPG (anime cel)",
      tagline: "Le plus proche des références : anime cel-shading, 3 tons, traits fins.",
      look: { heads: 4.2, eyes: "anime", detail: 2, headShape: "sharp" },
      outline: { outer: 3.2, inner: 1.4, color: "ink" },
      shading: "cel3", light: [-0.6, -0.7], rim: "#9ef7ff", sat: 1.1, ground: 0.35,
      scores: { detail: 4, readability: 3, personality: 5, commercial: 5, difficulty: 4 },
      pros: ["Colle aux références (Bleach, sheets anime)", "Look « jeu sérieux », très vendeur sur les captures"],
      cons: ["Proportions longues : silhouette fine, moins lisible en foule", "Chaque perso/boss demande beaucoup de détails"],
      honest: "Prototype vectoriel : un vrai sprite anime haut de gamme est dessiné à la main (lignes, mèches, plis).",
    },
    {
      id: "style_04", key: "D", name: "Stylized Isometric (low-poly)",
      tagline: "Facettes nettes, lumière zénithale, pensé pour la vue 3/4.",
      look: { heads: 3.4, eyes: "glow", detail: 1, lowPoly: true },
      outline: { outer: 0, inner: 0, color: "none" },
      shading: "facet", light: [-0.4, -0.9], rim: null, sat: 1.0, ground: 0.5, iso: true,
      scores: { detail: 3, readability: 4, personality: 4, commercial: 3, difficulty: 3 },
      pros: ["Volume lisible sans contour", "Se marie bien avec un décor isométrique", "Facile à garder cohérent (règles de facettes)"],
      cons: ["Peut faire « asset store »", "Visages peu expressifs", "Demande un décor isométrique pour être crédible"],
      honest: "Facettes générées automatiquement depuis le même squelette ; un vrai low-poly serait modélisé en 3D puis rendu.",
    },
    {
      id: "style_05", key: "E", name: "2.5D",
      tagline: "Sprite 2D avec relief : éclairage de bosse, ombre portée marquée.",
      look: { heads: 3.2, eyes: "anime", detail: 1 },
      outline: { outer: 4, inner: 1.2, color: "dark" },
      shading: "emboss", light: [-0.6, -0.8], rim: "#ffffff", sat: 1.08, ground: 0.6, depth: true,
      scores: { detail: 4, readability: 4, personality: 3, commercial: 4, difficulty: 3 },
      pros: ["Sensation de volume forte à petite taille", "Ombre au sol = excellent ancrage dans la foule"],
      cons: ["Filtres d'éclairage coûteux s'ils sont calculés en temps réel (à précalculer en texture)", "Style moins identitaire"],
      honest: "Relief obtenu par filtre d'éclairage SVG ; en jeu il serait précalculé (normal map ou texture).",
    },
    {
      id: "style_06", key: "F", name: "Stylized 3D Look",
      tagline: "Comme un modèle 3D stylisé : matières lisses, dégradés, reflets.",
      look: { heads: 3, eyes: "anime", detail: 1 },
      outline: { outer: 0, inner: 0, color: "none" },
      shading: "clay", light: [-0.55, -0.8], rim: "#bff6ff", sat: 1.05, ground: 0.55,
      scores: { detail: 4, readability: 4, personality: 3, commercial: 4, difficulty: 4 },
      pros: ["Look moderne « figurine »", "Se produit bien avec de la 3D (Blender) rendue en sprites"],
      cons: ["Sans contour, se perd sur les sols chargés", "Pipeline 3D à mettre en place"],
      honest: "Imitation de rendu 3D en dégradés vectoriels. La vraie version passerait par Blender → sprites.",
    },
    {
      id: "style_07", key: "G", name: "Premium Indie",
      tagline: "Simple mais très travaillé : contour coloré, ombres franches, palette tenue.",
      look: { heads: 3, eyes: "glow", detail: 1 },
      outline: { outer: 5, inner: 1.4, color: "dark" },
      shading: "cel", light: [-0.6, -0.75], rim: "accent", sat: 1.08, ground: 0.4,
      scores: { detail: 3, readability: 5, personality: 5, commercial: 5, difficulty: 2 },
      pros: ["Silhouette forte, lecture immédiate", "Yeux néon = signature du jeu", "Produisible par code pour 25+ persos cohérents"],
      cons: ["Exige une discipline de palette stricte", "Moins spectaculaire en gros plan qu'un rendu peint"],
      honest: "Rendu vectoriel complet : atteignable tel quel dans le jeu (même pipeline que les sprites actuels).",
    },
    {
      id: "style_08", key: "H", name: "Cinematic Stylized",
      tagline: "Contre-jour néon, contraste fort, ambiance de trailer.",
      look: { heads: 4, eyes: "glow", detail: 2, cape: false },
      outline: { outer: 2, inner: 0.8, color: "ink" },
      shading: "cel3", light: [0.7, -0.5], rim: "accent", rimStrong: true, bloom: true, sat: 0.95, contrast: 1.25, ground: 0.55,
      scores: { detail: 4, readability: 3, personality: 5, commercial: 4, difficulty: 4 },
      pros: ["Superbe pour trailer, key art, écran titre", "Ambiance unique"],
      cons: ["Éclairage dramatique illisible en jeu (lumière qui dépend de la scène)", "Coûteux en VFX/bloom"],
      honest: "Prototype : en jeu, le contre-jour serait un shader de rim light, pas peint dans le sprite.",
    },
    {
      id: "style_09", key: "I", name: "Minimal Stylized",
      tagline: "Peu de détails, formes géométriques, palette réduite.",
      look: { heads: 2.5, eyes: "glow", detail: 0, mask: true, scarf: 0.8 },
      outline: { outer: 0, inner: 0, color: "none" },
      shading: "flat", light: [-0.6, -0.8], rim: null, sat: 1.0, ground: 0.35, flatShadow: true,
      scores: { detail: 1, readability: 5, personality: 3, commercial: 3, difficulty: 1 },
      pros: ["Lisible même à 32 px", "Coût de production minimal", "Parfait pour 650 ennemis à l'écran"],
      cons: ["Peu de personnalité seul", "Peut paraître pauvre sur les captures Steam"],
      honest: "Rendu vectoriel complet.",
    },
    {
      id: "style_10", key: "J", name: "Experimental — Sumi-Neon",
      tagline: "Encre noire, halo papier, un seul néon. Une identité propre au jeu.",
      look: { heads: 3.4, eyes: "glow", detail: 1 },
      outline: { outer: 3.5, inner: 0, color: "white" },
      shading: "ink", light: [-0.6, -0.75], rim: "#efe6d6", wobble: 1.1, sat: 1, ground: 0.5,
      scores: { detail: 2, readability: 5, personality: 5, commercial: 4, difficulty: 2 },
      pros: ["Identité immédiatement reconnaissable", "Silhouette parfaite par construction", "Très bon marché à produire (formes + 1 couleur)"],
      cons: ["Risque de monotonie (tout le monde en noir)", "Les ennemis doivent se distinguer par couleur et forme"],
      honest: "Rendu vectoriel complet ; le grain d'encre est un filtre SVG (en jeu : précalculé).",
    },
    {
      id: "style_11", key: "K", name: "Neon Line (piste du GDD)",
      tagline: "Silhouette sombre + contours néon : la piste notée au début du projet.",
      look: { heads: 3, eyes: "glow", detail: 2 },
      outline: { outer: 3, inner: 1.2, color: "accent" },
      shading: "neon", light: [-0.6, -0.75], rim: "accent", sat: 1, ground: 0.4,
      scores: { detail: 2, readability: 4, personality: 4, commercial: 3, difficulty: 2 },
      pros: ["Cohérent avec les projectiles néon du jeu", "Très lisible sur fond sombre"],
      cons: ["Se confond avec les tirs et les VFX néon", "Lisibilité faible sur fond clair"],
      honest: "Rendu vectoriel complet.",
    },
  ];

  // ---------------------------------------------------------------------------
  // Renderer
  // ---------------------------------------------------------------------------
  function resolveColor(c, pal, style) {
    let hex;
    if (typeof c === "object" && c !== null) hex = shade(resolveColor(c.key, pal, style), c.amount);
    else if (c === "wrapShadow") hex = shade(pal.wrap, -0.35);
    else if (c === "hairDark") hex = shade(pal.hair, -0.4);
    else if (c && c[0] === "#") hex = c;
    else if (pal[c]) hex = pal[c];
    else if (ENEMY_COLORS[c]) hex = ENEMY_COLORS[c];
    else hex = "#ff00ff";
    if (style && style.sat && style.sat !== 1) hex = saturate(hex, style.sat);
    return hex;
  }

  function outlineColor(style, pal, base) {
    switch (style.outline.color) {
      case "ink": return "#0d0a14";
      case "dark": return shade(base, -0.62);
      case "white": return "#efe6d6";
      case "accent": return pal.accent;
      default: return "none";
    }
  }

  function partPath(part, style) {
    if (part.line) return "M" + fmt(part.line[0][0]) + " " + fmt(part.line[0][1]) + "L" + fmt(part.line[1][0]) + " " + fmt(part.line[1][1]);
    return part.smooth && style.shading !== "facet" ? smoothPath(part.pts, 1) : polyPath(part.pts);
  }

  /**
   * Renders a model to an SVG string.
   * opts: { palette, size (px height), bg, silhouette (color or null), showGround, viewBox, grid }
   */
  function render(model, style, opts) {
    const o = Object.assign({ palette: "neon", showGround: true, silhouette: null, bg: null, grid: false, extraDefs: "" }, opts || {});
    const pal = Object.assign({}, typeof o.palette === "string" ? PALETTES[o.palette] : o.palette);
    const id = uid("k");
    const defs = [];
    const body = [];
    const L = style.light;
    const ln = Math.hypot(L[0], L[1]) || 1;
    const lx = L[0] / ln;
    const ly = L[1] / ln;
    const hr = model.hr;
    const P = model.pose;

    // Filters
    if (style.texture === "paint") {
      defs.push(`<filter id="${id}paint" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="4" result="n"/><feDisplacementMap in="SourceGraphic" in2="n" scale="${style.wobble}" xChannelSelector="R" yChannelSelector="G" result="d"/><feTurbulence type="fractalNoise" baseFrequency="0.035 0.25" numOctaves="3" seed="7" result="s"/><feColorMatrix in="s" type="matrix" values="0 0 0 0 0.5  0 0 0 0 0.45  0 0 0 0 0.4  0 0 0 0.55 -0.12" result="sc"/><feComposite in="sc" in2="d" operator="in" result="st"/><feBlend in="st" in2="d" mode="soft-light"/></filter>`);
    }
    if (style.shading === "ink" || (style.wobble && style.texture !== "paint")) {
      defs.push(`<filter id="${id}wob" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency="0.6" numOctaves="2" seed="11" result="n"/><feDisplacementMap in="SourceGraphic" in2="n" scale="${style.wobble || 1}" xChannelSelector="R" yChannelSelector="G"/></filter>`);
    }
    defs.push(`<filter id="${id}glow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="${fmt(Math.max(1.2, hr * 0.06))}" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>`);
    if (style.bloom) {
      defs.push(`<filter id="${id}bloom" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur in="SourceGraphic" stdDeviation="5" result="b"/><feColorMatrix in="b" type="matrix" values="1.3 0 0 0 0  0 1.3 0 0 0  0 0 1.3 0 0  0 0 0 0.55 0" result="bb"/><feMerge><feMergeNode in="bb"/><feMergeNode in="SourceGraphic"/></feMerge></filter>`);
    }
    if (style.shading === "emboss") {
      defs.push(`<filter id="${id}emb" x="-5%" y="-5%" width="110%" height="110%"><feGaussianBlur in="SourceAlpha" stdDeviation="${fmt(hr * 0.12)}" result="h"/><feDiffuseLighting in="h" surfaceScale="${fmt(hr * 0.12)}" diffuseConstant="1.1" lighting-color="#ffffff" result="l"><feDistantLight azimuth="${fmt((Math.atan2(ly, lx) * 180) / Math.PI)}" elevation="38"/></feDiffuseLighting><feComposite in="l" in2="SourceAlpha" operator="in" result="lc"/><feBlend in="SourceGraphic" in2="lc" mode="multiply" result="m"/><feComponentTransfer in="m"><feFuncR type="linear" slope="1.35"/><feFuncG type="linear" slope="1.35"/><feFuncB type="linear" slope="1.35"/></feComponentTransfer></filter>`);
    }

    const partsDefs = [];
    const layers = []; // per part rendered group

    // Pre-pass: silhouette backing (outer outline) for styles with an outer contour.
    const outerW = style.outline.outer;
    const silBack = [];
    const silBack2 = [];

    model.parts.forEach((part, i) => {
      const pid = id + "p" + i;
      const d = partPath(part, style);
      const isLine = !!part.line;
      const base = resolveColor(part.color, pal, style);
      if (isLine) {
        if (o.silhouette) return;
        let stroke = base;
        if (style.shading === "ink" && part.kind === "detail") stroke = "#2c2834";
        if (style.shading === "neon" && part.kind === "detail") stroke = pal.accent;
        const w = part.width || Math.max(1, hr * 0.05);
        const glow = part.kind === "accentLine" ? ` filter="url(#${id}glow)"` : "";
        layers.push(`<path d="${d}" stroke="${stroke}" stroke-width="${fmt(w)}" stroke-linecap="round" fill="none"${glow}/>`);
        return;
      }
      partsDefs.push(`<path id="${pid}" d="${d}"/>`);
      if (part.kind === "vfx") {
        if (o.silhouette) return;
        layers.push(`<use href="#${pid}" fill="${base}" opacity="${fmt(part.opacity || 0.5)}" filter="url(#${id}glow)"/>`);
        return;
      }
      if (outerW > 0 && style.outline.color !== "none") {
        const oc = o.silhouette || outlineColor(style, pal, base);
        silBack.push(`<use href="#${pid}" fill="${oc}" stroke="${oc}" stroke-width="${fmt(outerW * 2)}" stroke-linejoin="round"/>`);
        if (style.shading === "ink" && !o.silhouette) silBack2.push(`<use href="#${pid}" fill="#0d0a12" stroke="#0d0a12" stroke-width="${fmt(outerW * 0.7)}" stroke-linejoin="round"/>`);
      }
      if (o.silhouette) {
        layers.push(`<use href="#${pid}" fill="${o.silhouette}"/>`);
        return;
      }
      layers.push(renderPart(part, pid, base, style, pal, id, defs, lx, ly, hr));
    });

    defs.push(partsDefs.join(""));

    // Ground shadow
    const g = model.ground;
    let ground = "";
    if (o.showGround) {
      const alpha = style.ground || 0.35;
      if (style.iso) {
        ground = `<path d="M${fmt(g.cx - g.rx * 1.1)} ${fmt(g.cy)}L${fmt(g.cx)} ${fmt(g.cy - g.ry * 1.2)}L${fmt(g.cx + g.rx * 1.1)} ${fmt(g.cy)}L${fmt(g.cx)} ${fmt(g.cy + g.ry * 1.2)}Z" fill="#000" opacity="${alpha}"/>`;
      } else if (style.depth) {
        ground = `<ellipse cx="${fmt(g.cx + 10)}" cy="${fmt(g.cy + 2)}" rx="${fmt(g.rx * 1.25)}" ry="${fmt(g.ry * 1.1)}" fill="#000" opacity="${alpha}"/><ellipse cx="${fmt(g.cx)}" cy="${fmt(g.cy)}" rx="${fmt(g.rx * 0.8)}" ry="${fmt(g.ry * 0.7)}" fill="#000" opacity="${alpha * 0.6}"/>`;
      } else {
        ground = `<ellipse cx="${fmt(g.cx)}" cy="${fmt(g.cy)}" rx="${fmt(g.rx)}" ry="${fmt(g.ry)}" fill="#000" opacity="${alpha}"/>`;
      }
      if (style.shading === "neon" && !o.silhouette) {
        ground += `<ellipse cx="${fmt(g.cx)}" cy="${fmt(g.cy)}" rx="${fmt(g.rx)}" ry="${fmt(g.ry)}" fill="none" stroke="${pal.accent}" stroke-width="2" opacity="0.6" filter="url(#${id}glow)"/>`;
      }
    }

    // Cinematic: colored back-light halo behind the character.
    let halo = "";
    if (style.rimStrong && !o.silhouette) {
      defs.push(`<radialGradient id="${id}halo" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="${pal.accent}" stop-opacity="0.45"/><stop offset="1" stop-color="${pal.accent}" stop-opacity="0"/></radialGradient>`);
      halo = `<ellipse cx="${CX + 18}" cy="${fmt(model.headCY + hr * 2)}" rx="${fmt(hr * 3)}" ry="${fmt(hr * 3.6)}" fill="url(#${id}halo)"/>`;
    }

    let figure = (silBack.length ? `<g>${silBack.join("")}</g>` : "") + (silBack2.length ? `<g>${silBack2.join("")}</g>` : "") + layers.join("");
    let filterAttr = "";
    if (!o.silhouette) {
      if (style.texture === "paint") filterAttr = ` filter="url(#${id}paint)"`;
      else if (style.shading === "emboss") filterAttr = ` filter="url(#${id}emb)"`;
      else if (style.shading === "ink" || style.wobble) filterAttr = ` filter="url(#${id}wob)"`;
    }
    figure = `<g${filterAttr}>${figure}</g>`;
    if (style.bloom && !o.silhouette) figure = `<g filter="url(#${id}bloom)">${figure}</g>`;
    if (style.contrast && !o.silhouette) {
      defs.push(`<filter id="${id}ct"><feComponentTransfer><feFuncR type="linear" slope="${style.contrast}" intercept="${fmt(-(style.contrast - 1) * 0.3)}"/><feFuncG type="linear" slope="${style.contrast}" intercept="${fmt(-(style.contrast - 1) * 0.3)}"/><feFuncB type="linear" slope="${style.contrast}" intercept="${fmt(-(style.contrast - 1) * 0.3)}"/></feComponentTransfer></filter>`);
      figure = `<g filter="url(#${id}ct)">${figure}</g>`;
    }

    // Pose transforms: lean, death fall, hit flash, squash.
    const pivot = `${CX} ${FEET}`;
    let tr = "";
    if (P.lean) tr += ` rotate(${fmt(P.lean * 57.3)} ${pivot})`;
    // Death: collapse (not a full fall: the sprite stays inside its box).
    if (P.fall) tr += ` translate(0 ${fmt(P.fall * 8)}) rotate(${fmt(-P.fall * 50)} ${CX + 28} ${FEET})`;
    if (P.squash && P.squash !== 1) tr += ` translate(0 ${fmt(FEET * (1 - P.squash))}) scale(1 ${fmt(P.squash)})`;
    if (P.flash > 0 && !o.silhouette) {
      defs.push(`<filter id="${id}flash"><feColorMatrix type="matrix" values="1 0 0 0 ${fmt(P.flash)}  0 1 0 0 ${fmt(P.flash)}  0 0 1 0 ${fmt(P.flash)}  0 0 0 1 0"/></filter>`);
      figure = `<g filter="url(#${id}flash)">${figure}</g>`;
    }
    figure = `<g transform="${tr.trim()}" opacity="${fmt(P.opacity)}">${halo}${figure}</g>`;
    if (model.mirror) figure = `<g transform="translate(${VIEW_W} 0) scale(-1 1)">${figure}</g>`;

    const vb = o.viewBox || `0 0 ${VIEW_W} ${VIEW_H}`;
    let bg = "";
    if (o.bg) bg = `<rect x="-1000" y="-1000" width="3000" height="3000" fill="${o.bg}"/>`;
    let grid = "";
    if (o.grid) {
      grid = `<g stroke="#7f88a8" stroke-opacity="0.22" stroke-width="0.6">`;
      for (let x = 0; x <= VIEW_W; x += 10) grid += `<line x1="${x}" y1="0" x2="${x}" y2="${VIEW_H}"/>`;
      for (let y = 0; y <= VIEW_H; y += 10) grid += `<line x1="0" y1="${y}" x2="${VIEW_W}" y2="${y}"/>`;
      grid += `<line x1="0" y1="${FEET}" x2="${VIEW_W}" y2="${FEET}" stroke="#ff5470" stroke-opacity="0.6"/><line x1="${CX}" y1="0" x2="${CX}" y2="${VIEW_H}" stroke="#ff5470" stroke-opacity="0.35"/></g>`;
    }
    const size = o.size ? ` width="${fmt((o.size * VIEW_W) / VIEW_H)}" height="${o.size}"` : "";
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}"${size} overflow="visible"><defs>${defs.join("")}${o.extraDefs}</defs>${bg}${grid}${o.silhouette ? "" : ground}${figure}</svg>`;
  }

  /** One part with the style's shading. Returns an SVG fragment. */
  function renderPart(part, pid, base, style, pal, id, defs, lx, ly, hr) {
    const inner = style.outline.inner;
    const lineColor = style.outline.color === "none" ? "none" : (style.outline.color === "accent" ? pal.accent : (style.outline.color === "white" ? "#1a1620" : (style.outline.color === "ink" ? "#0d0a14" : shade(base, -0.62))));
    const strokeAttr = inner > 0 && lineColor !== "none" ? ` stroke="${lineColor}" stroke-width="${fmt(inner)}" stroke-linejoin="round"` : "";
    const glowAttr = part.glow ? ` filter="url(#${id}glow)"` : "";
    const flatKinds = part.kind === "flat" || part.kind === "accent";
    const k = Math.max(2.2, hr * 0.16); // crescent size
    const out = [];

    function crescent(color, dx, dy, opacity) {
      const mid = uid("m");
      defs.push(`<mask id="${mid}" maskUnits="userSpaceOnUse" x="-50" y="-50" width="300" height="360"><use href="#${pid}" fill="#fff"/><use href="#${pid}" fill="#000" transform="translate(${fmt(dx)} ${fmt(dy)})"/></mask>`);
      return `<use href="#${pid}" fill="${color}" mask="url(#${mid})"${opacity !== undefined ? ` opacity="${fmt(opacity)}"` : ""}/>`;
    }

    if (style.shading === "ink") {
      // Ink: everything black except accents; cream rim highlight for volume.
      if (part.kind === "accent" || part.glow) {
        out.push(`<use href="#${pid}" fill="${base}"${glowAttr}/>`);
        return out.join("");
      }
      const isScarf = part.color === "scarf" || (typeof part.color === "object" && part.color.key === "scarf") || part.id === "ribbon";
      const fill = isScarf ? base : (part.kind === "skin" ? "#2a2230" : (part.kind === "metal" ? "#3a3440" : "#0d0a12"));
      out.push(`<use href="#${pid}" fill="${fill}"/>`);
      if (part.kind !== "flat") out.push(crescent(style.rim, -lx * k * 0.9, -ly * k * 0.9, part.kind === "skin" ? 0.55 : 0.85));
      return out.join("");
    }

    if (style.shading === "neon") {
      if (part.kind === "accent" || part.glow) {
        out.push(`<use href="#${pid}" fill="${base}"${glowAttr}/>`);
        return out.join("");
      }
      const fill = part.kind === "skin" ? mix(base, "#0c0d18", 0.72) : mix(base, "#07080f", 0.8);
      out.push(`<use href="#${pid}" fill="${fill}" stroke="${pal.accent}" stroke-width="${fmt(Math.max(0.8, inner))}" stroke-opacity="0.85" stroke-linejoin="round"/>`);
      return out.join("");
    }

    if (flatKinds || style.shading === "flat") {
      out.push(`<use href="#${pid}" fill="${base}"${strokeAttr}${glowAttr}/>`);
      if (style.flatShadow && !flatKinds) out.push(crescent(shade(base, -0.28), lx * k * 1.2, ly * k * 1.2));
      return out.join("");
    }

    if (style.shading === "soft" || style.shading === "clay") {
      const gid = uid("g");
      if (style.shading === "clay") {
        defs.push(`<radialGradient id="${gid}" cx="${fmt(0.5 + lx * 0.22)}" cy="${fmt(0.5 + ly * 0.25)}" r="0.85"><stop offset="0" stop-color="${shade(base, 0.35)}"/><stop offset="0.45" stop-color="${base}"/><stop offset="1" stop-color="${shade(base, -0.45)}"/></radialGradient>`);
      } else {
        defs.push(`<linearGradient id="${gid}" x1="${fmt(0.5 + lx * 0.5)}" y1="${fmt(0.5 + ly * 0.5)}" x2="${fmt(0.5 - lx * 0.5)}" y2="${fmt(0.5 - ly * 0.5)}"><stop offset="0" stop-color="${shade(base, 0.22)}"/><stop offset="0.5" stop-color="${base}"/><stop offset="1" stop-color="${shade(base, -0.38)}"/></linearGradient>`);
      }
      out.push(`<use href="#${pid}" fill="url(#${gid})"${strokeAttr}${glowAttr}/>`);
      if (style.shading === "clay" && part.kind !== "detail") {
        // specular dot + ambient occlusion rim
        out.push(crescent(shade(base, -0.55), lx * k * 0.6, ly * k * 0.6, 0.45));
      }
      if (style.rim) {
        const rc = style.rim === "accent" ? pal.accent : style.rim;
        // clay: cool rim on the shadow side; soft paint: warm light on the lit side
        const sgn = style.shading === "clay" ? 1 : -1;
        out.push(crescent(rc, sgn * lx * k * 0.55, sgn * ly * k * 0.55, style.shading === "clay" ? 0.35 : 0.4));
      }
      if (style.outline.soft) out.push(`<use href="#${pid}" fill="none" stroke="${shade(base, -0.55)}" stroke-width="1.3" stroke-opacity="0.55"/>`);
      return out.join("");
    }

    if (style.shading === "facet") {
      // Low poly: base + darker half on the side away from the light, cut through the centroid.
      const cxp = part.pts.reduce((s, p) => s + p[0], 0) / part.pts.length;
      const cyp = part.pts.reduce((s, p) => s + p[1], 0) / part.pts.length;
      const cid = uid("c");
      const nx = -ly;
      const ny = lx;
      const far = 400;
      const half = [[cxp + nx * far, cyp + ny * far], [cxp - nx * far, cyp - ny * far], [cxp - nx * far - lx * far, cyp - ny * far - ly * far], [cxp + nx * far - lx * far, cyp + ny * far - ly * far]];
      defs.push(`<clipPath id="${cid}"><use href="#${pid}"/></clipPath>`);
      out.push(`<use href="#${pid}" fill="${shade(base, 0.12)}"/>`);
      out.push(`<g clip-path="url(#${cid})"><path d="${polyPath(half)}" fill="${shade(base, -0.3)}"/></g>`);
      // top facet: lighter cap
      out.push(crescent(shade(base, 0.3), -lx * k * 0.8, -ly * k * 0.8, 0.8));
      return out.join("");
    }

    // cel / cel3 / emboss: base + shadow crescent (+ highlight)
    const shadowColor = style.shading === "emboss" ? shade(base, -0.22) : mix(shade(base, -0.42), "#3a1f6a", 0.12);
    out.push(`<use href="#${pid}" fill="${base}"${strokeAttr}/>`);
    // crescent(c, dx, dy) keeps the part minus its copy shifted by (dx, dy):
    // shifting toward the light (lx, ly) leaves the shadow side, and vice versa.
    out.push(crescent(shadowColor, lx * k * 1.1, ly * k * 1.1));
    if (style.shading === "cel3") out.push(crescent(shade(base, -0.62), lx * k * 0.45, ly * k * 0.45, 0.7));
    if (style.shading === "cel3" || style.shading === "cel") {
      out.push(crescent(shade(base, 0.3), -lx * k * 0.5, -ly * k * 0.5, style.shading === "cel3" ? 0.9 : 0.55));
    }
    if (style.rim && (part.kind === "hair" || part.kind === "skin" || part.kind === "metal" || style.rimStrong)) {
      // rim light: thin band on the shadow side (back light)
      const rc = style.rim === "accent" ? pal.accent : style.rim;
      const f = style.rimStrong ? 0.55 : 0.3;
      out.push(crescent(rc, lx * k * f, ly * k * f, style.rimStrong ? 0.95 : 0.6));
    }
    if (strokeAttr && inner > 0) out.push(`<use href="#${pid}" fill="none"${strokeAttr}/>`);
    return out.join("");
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------
  function styleById(id) { return STYLES.find((s) => s.id === id || s.key === id) || STYLES[0]; }

  /** Convenience: render the character of `style` in `dir` with `poseKind`/`phase`. */
  function character(styleOrId, dir, opts) {
    const style = typeof styleOrId === "string" ? styleById(styleOrId) : styleOrId;
    const o = opts || {};
    const look = Object.assign({}, style.look, o.look || {});
    const model = buildCharacter(look, dir || "SE", o.pose || pose(o.poseKind || "idle", o.phase || 0));
    return render(model, style, o);
  }

  function imp(styleOrId, opts) {
    const style = typeof styleOrId === "string" ? styleById(styleOrId) : styleOrId;
    const o = opts || {};
    const model = buildImp({ lowPoly: !!style.look.lowPoly }, o.variant || 0);
    return render(model, style, o);
  }

  const KAGE = {
    CX, FEET, HEIGHT, VIEW_W, VIEW_H,
    STYLES, PALETTES, DIRECTIONS, DEFAULT_LOOK,
    pose, buildCharacter, buildImp, render, character, imp, styleById,
    color: { mix, shade, luminance, saturate },
  };

  if (typeof module !== "undefined" && module.exports) module.exports = KAGE;
  global.KAGE = KAGE;
})(typeof window !== "undefined" ? window : globalThis);
