/* Showcase page: builds every section from KAGE (kage.js). Plain script, works from file://. */
(function () {
  "use strict";
  const K = window.KAGE;
  const $ = (sel) => document.querySelector(sel);
  const el = (tag, cls, html) => {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (html !== undefined) e.innerHTML = html;
    return e;
  };

  const REFERENCES = [
    "02ababd7c9b0ae9a363580e041263471.jpg", "10281331b2b3aa41ce786f741d508eaf.jpg", "1c538393279a60d41f8470aa0e14b69f.jpg",
    "3b1775e84eb3d5dbbd4690d6e6836b48.jpg", "3ce3890eba0ce20a77940ec550c49fe8.jpg", "4141f4df4ce493e5fa596eac7aad778b.jpg",
    "51192e0f841f757929aab6f1d0ddf755.jpg", "56f8bc8b9a71986ff8040e84fdf318ef.jpg", "6e336ecc9939059b93d9784b538c5c3c.jpg",
    "6fec07a967810e5a5d090ab0b7a8fc54.jpg", "72c764b16495be4dad673ebc4a559585.jpg", "7c10c140c0898ac8ae707c54dcf94726.jpg",
    "820776c460b38dc51b145bc9dd76416d.jpg", "861f8457a66c415f49b1c3cbed56da19.jpg", "898fd90a6e78e6774e7ca8b65c9b65dc.jpg",
    "8c44e45993b517a4365ee2bc2c67b1c8.jpg", "a13eead5df919f29d6571e3fa0a0ba3d.jpg", "a1e7be8fa0ea5e414a8b0a755a7c7687.jpg",
    "af640c25b80e332dce65e4aba6602603.jpg", "af89e9d9d922136cc887289647081657.jpg", "def1d4abdd90e2d6d080cd2323919350.jpg",
    "f4cb29ff569d9445e0eceff4dad31f6a.jpg", "t%C3%A9l%C3%A9chargement.png",
  ];
  const DIR_ORDER = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"];
  const TOP3 = ["style_07", "style_10", "style_02"];
  // Character height inside the 200x260 sprite box: an image this many px tall
  // shows a character of `px` px.
  const boxFor = (px) => Math.round((px * K.VIEW_H) / K.HEIGHT);
  const GAME_PX = 102;

  const state = {
    a: "style_07", b: "style_10", palette: "neon", bg: "dark", grid: false, sil: false, zoom: 1,
    dir: "SE", animKind: "walk", animDir: "SE", onion: false,
    lab: {}, mockStyle: "style_07", density: "chaos", mockZoom: false,
  };

  const style = (id) => K.styleById(id);
  const silColor = () => (state.bg === "dark" ? "#efeaf8" : "#0b0a10");
  function charSvg(st, dir, opts) {
    const o = Object.assign({ palette: state.palette, grid: state.grid, silhouette: state.sil ? silColor() : null }, opts || {});
    return K.character(st, dir, o);
  }
  const svgUrl = (svg) => "data:image/svg+xml;charset=utf-8," + encodeURIComponent(svg);
  function img(svg, h, alt) {
    const i = new Image();
    i.src = svgUrl(svg);
    i.style.height = h + "px";
    i.style.width = "auto";
    i.alt = alt || "";
    i.decoding = "async";
    return i;
  }
  function stage(content, cls, label) {
    const s = el("div", "stage" + (cls ? " " + cls : ""));
    if (typeof content === "string") s.innerHTML = content;
    else if (content) s.appendChild(content);
    if (label) s.appendChild(el("span", "mini-label", label));
    return s;
  }

  // --- Lightbox -------------------------------------------------------------
  function lightbox(node) {
    const box = el("div", "lightbox");
    if (typeof node === "string") box.innerHTML = node;
    else box.appendChild(node);
    box.addEventListener("click", () => box.remove());
    document.addEventListener("keydown", function esc(e) {
      if (e.key === "Escape") { box.remove(); document.removeEventListener("keydown", esc); }
    });
    document.body.appendChild(box);
  }

  // --- Toolbar ----------------------------------------------------------------
  function fillStyleSelect(sel, value) {
    sel.innerHTML = K.STYLES.map((s) => `<option value="${s.id}">${s.key} — ${s.name}</option>`).join("");
    sel.value = value;
  }
  function initToolbar() {
    fillStyleSelect($("#selA"), state.a);
    fillStyleSelect($("#selB"), state.b);
    $("#selPalette").innerHTML = Object.entries(K.PALETTES).map(([k, p]) => `<option value="${k}">${p.name}</option>`).join("");
    $("#selA").addEventListener("change", (e) => { state.a = e.target.value; renderCompare(); renderAnim(); renderLab(); markCards(); });
    $("#selB").addEventListener("change", (e) => { state.b = e.target.value; renderCompare(); markCards(); });
    $("#selPalette").addEventListener("change", (e) => { state.palette = e.target.value; renderAll(); });
    $("#selBg").addEventListener("change", (e) => { state.bg = e.target.value; document.body.dataset.bg = state.bg; renderAll(); });
    $("#chkGrid").addEventListener("change", (e) => { state.grid = e.target.checked; renderAll(); });
    $("#chkSil").addEventListener("change", (e) => { state.sil = e.target.checked; renderAll(); });
    $("#rngZoom").addEventListener("input", (e) => { document.documentElement.style.setProperty("--zoom", e.target.value); });
    $("#btnFull").addEventListener("click", () => {
      if (document.fullscreenElement) document.exitFullscreen();
      else document.documentElement.requestFullscreen().catch(() => {});
    });
  }

  // --- Hero + references --------------------------------------------------------
  function renderHero() {
    $("#heroFigure").innerHTML = charSvg(style("style_07"), "SE", { grid: false, silhouette: null });
  }
  function renderRefs() {
    const strip = $("#refStrip");
    strip.innerHTML = "";
    REFERENCES.forEach((f) => {
      const i = new Image();
      i.src = "references/" + f;
      i.alt = "Référence";
      i.loading = "lazy";
      i.onerror = () => i.remove();
      i.addEventListener("click", () => { const big = new Image(); big.src = i.src; lightbox(big); });
      strip.appendChild(i);
    });
  }

  // --- 01 Overview ------------------------------------------------------------------
  function meter(v, cost) {
    let h = `<span class="meter${cost ? " cost" : ""}">`;
    for (let i = 1; i <= 5; i++) h += `<i class="${i <= v ? "on" : ""}"></i>`;
    return h + "</span>";
  }
  function renderCards() {
    const box = $("#cards");
    box.innerHTML = "";
    K.STYLES.forEach((s) => {
      const c = el("article", "card");
      c.dataset.id = s.id;
      const st = stage(charSvg(s, "SE"));
      st.style.cursor = "zoom-in";
      st.addEventListener("click", () => {
        const wrap = el("div");
        wrap.style.cssText = "display:flex;gap:2vw;align-items:flex-end";
        ["S", "SE", "E", "N"].forEach((d) => wrap.appendChild(img(charSvg(s, d), Math.min(window.innerHeight * 0.7, 520))));
        lightbox(wrap);
      });
      c.appendChild(st);
      const sc = s.scores;
      c.appendChild(el("div", "card-body", `
        <div class="card-title"><span class="card-key">${s.key}</span><h3>${s.name}</h3></div>
        <p class="tagline">${s.tagline}</p>
        <div class="meters">
          <span>Détail</span>${meter(sc.detail)}
          <span>Lisibilité</span>${meter(sc.readability)}
          <span>Personnalité</span>${meter(sc.personality)}
          <span>Potentiel commercial</span>${meter(sc.commercial)}
          <span>Difficulté de prod.</span>${meter(sc.difficulty, true)}
        </div>
        <div class="pc">
          <div class="pros"><b>Avantages</b><ul>${s.pros.map((p) => `<li>${p}</li>`).join("")}</ul></div>
          <div class="cons"><b>Inconvénients</b><ul>${s.cons.map((p) => `<li>${p}</li>`).join("")}</ul></div>
        </div>
        <div class="card-honest">${s.honest}</div>
        <div class="card-actions"><button class="a" type="button">Comparer en A</button><button class="b" type="button">Comparer en B</button></div>`));
      c.querySelector(".a").addEventListener("click", () => { state.a = s.id; $("#selA").value = s.id; renderCompare(); renderAnim(); renderLab(); markCards(); $("#compare").scrollIntoView(); });
      c.querySelector(".b").addEventListener("click", () => { state.b = s.id; $("#selB").value = s.id; renderCompare(); markCards(); $("#compare").scrollIntoView(); });
      box.appendChild(c);
    });
    markCards();
  }
  function markCards() {
    document.querySelectorAll(".card").forEach((c) => {
      c.classList.toggle("is-a", c.dataset.id === state.a);
      c.classList.toggle("is-b", c.dataset.id === state.b);
    });
  }

  // --- 02 Comparison --------------------------------------------------------------
  function renderDirBar() {
    const bar = $("#dirBar");
    bar.innerHTML = "";
    DIR_ORDER.forEach((d) => {
      const b = el("button", d === state.dir ? "on" : "", K.DIRECTIONS[d].label);
      b.type = "button";
      b.addEventListener("click", () => { state.dir = d; renderDirBar(); renderCompare(); });
      bar.appendChild(b);
    });
  }
  function compareCol(box, id, tag) {
    const s = style(id);
    box.className = "compare-col " + tag;
    box.innerHTML = "";
    box.appendChild(el("div", "tag", `${tag} · ${s.key} — ${s.name}`));
    const main = el("div", "compare-main");
    main.appendChild(stage(charSvg(s, state.dir)));
    const side = el("div", "compare-side");
    side.appendChild(stage(img(K.character(s, state.dir, { palette: state.palette, silhouette: "#0b0a10" }), 110), "fixed-light", "silhouette"));
    side.appendChild(stage(img(K.character(s, state.dir, { palette: state.palette }), boxFor(48)), "", "48 px"));
    main.appendChild(side);
    box.appendChild(main);
    const dirs = el("div", "dirs8");
    DIR_ORDER.forEach((d) => {
      const st = stage(charSvg(s, d, { grid: false }), d === state.dir ? "on" : "");
      st.title = K.DIRECTIONS[d].label;
      st.addEventListener("click", () => { state.dir = d; renderDirBar(); renderCompare(); });
      dirs.appendChild(st);
    });
    box.appendChild(dirs);
  }
  function renderCompare() {
    compareCol($("#colA"), state.a, "A");
    compareCol($("#colB"), state.b, "B");
    $("#wipeA").innerHTML = "";
    $("#wipeB").innerHTML = "";
    $("#wipeA").appendChild(stage(charSvg(style(state.a), state.dir)));
    $("#wipeB").appendChild(stage(charSvg(style(state.b), state.dir)));
  }
  function initWipe() {
    const r = $("#rngWipe");
    r.addEventListener("input", () => {
      $("#wipeB").style.clipPath = `inset(0 0 0 ${r.value}%)`;
      $("#wipeHandle").style.left = r.value + "%";
    });
  }

  // --- 02b Animation -------------------------------------------------------------------
  const ANIMS = { idle: ["Idle", 1.6], walk: ["Marche", 0.8], attack: ["Attaque", 0.7], hit: ["Coup reçu", 0.6], death: ["Mort", 1.4] };
  let animStart = performance.now();
  let animLast = 0;
  function initAnim() {
    const seg = $("#animKind");
    Object.entries(ANIMS).forEach(([k, v]) => {
      const b = el("button", k === state.animKind ? "on" : "", v[0]);
      b.type = "button";
      b.addEventListener("click", () => {
        state.animKind = k;
        seg.querySelectorAll("button").forEach((x) => x.classList.toggle("on", x === b));
        animStart = performance.now();
        renderAnim();
      });
      seg.appendChild(b);
    });
    const ds = $("#animDir");
    ds.innerHTML = DIR_ORDER.map((d) => `<option value="${d}">${K.DIRECTIONS[d].label}</option>`).join("");
    ds.value = state.animDir;
    ds.addEventListener("change", (e) => { state.animDir = e.target.value; renderAnim(); });
    $("#chkOnion").addEventListener("change", (e) => { state.onion = e.target.checked; renderAnim(); });
    requestAnimationFrame(tick);
  }
  function renderAnim() {
    const s = style(state.a);
    const strip = $("#animStrip");
    strip.innerHTML = "";
    for (let i = 0; i < 8; i++) {
      const ph = i / 8;
      strip.appendChild(stage(charSvg(s, state.animDir, { poseKind: state.animKind, phase: ph, grid: true }), "", "image " + (i + 1)));
    }
    const live = $("#animLive");
    live.className = "anim-live stage" + (state.onion ? " onion" : "");
    if (state.onion) {
      let h = "";
      for (let i = 0; i < 8; i++) {
        h += charSvg(s, state.animDir, { poseKind: state.animKind, phase: i / 8, grid: i === 0, showGround: i === 0 }).replace("<svg ", `<svg style="opacity:${i === 0 ? 0.9 : 0.28}" `);
      }
      live.innerHTML = h;
    }
  }
  function tick(now) {
    if (!state.onion && now - animLast > 1000 / 14) {
      animLast = now;
      const len = ANIMS[state.animKind][1] * 1000;
      const ph = ((now - animStart) % len) / len;
      const live = $("#animLive");
      if (live && isVisible(live)) live.innerHTML = charSvg(style(state.a), state.animDir, { poseKind: state.animKind, phase: ph });
    }
    requestAnimationFrame(tick);
  }
  function isVisible(node) {
    const r = node.getBoundingClientRect();
    return r.bottom > 0 && r.top < window.innerHeight;
  }

  // --- 03 Scale test -------------------------------------------------------------------
  function renderScale() {
    const t = $("#scaleTable");
    t.innerHTML = "";
    const sizes = [32, 48, 64, 96, 128, GAME_PX];
    t.appendChild(el("div", "head", "Style"));
    sizes.forEach((px, i) => t.appendChild(el("div", "head", i === sizes.length - 1 ? `Jeu (${px} px)` : px + " px")));
    K.STYLES.forEach((s) => {
      t.appendChild(el("div", "name", `${s.key} · ${s.name}<small>lisibilité ${s.scores.readability}/5</small>`));
      const svg = charSvg(s, "SE", { grid: false });
      sizes.forEach((px) => t.appendChild(stage(img(svg, boxFor(px), `${s.name} ${px}px`))));
    });
  }

  // --- 04 Silhouette test ---------------------------------------------------------------
  function renderSilhouettes() {
    const g = $("#silGrid");
    g.innerHTML = "";
    K.STYLES.forEach((s) => {
      const card = el("div", "sil-card");
      card.appendChild(el("h4", "", `${s.key} · ${s.name}`));
      const row = el("div", "sil-row");
      const col = K.character(s, "SE", { palette: state.palette });
      row.appendChild(stage(img(col, 108), "", "couleur"));
      row.appendChild(stage(img(K.character(s, "SE", { palette: state.palette, silhouette: "#000" }), 108), "fixed-light", "noir"));
      row.appendChild(stage(img(col, 108), "fixed-light", "clair"));
      row.appendChild(stage(img(col, 108), "fixed-dark", "sombre"));
      card.appendChild(row);
      g.appendChild(card);
    });
  }

  // --- 05 Color test ---------------------------------------------------------------------
  function renderColors() {
    const g = $("#colorGrid");
    g.innerHTML = "";
    const pals = Object.keys(K.PALETTES);
    const head = el("div", "color-row");
    head.appendChild(el("div", "color-head", ""));
    pals.forEach((p) => head.appendChild(el("div", "color-head", K.PALETTES[p].name)));
    g.appendChild(head);
    TOP3.forEach((id) => {
      const s = style(id);
      const row = el("div", "color-row");
      row.appendChild(el("div", "name", `${s.key} · ${s.name}`));
      pals.forEach((p) => row.appendChild(stage(img(K.character(s, "SE", { palette: p }), 138, K.PALETTES[p].name))));
      g.appendChild(row);
    });
  }

  // --- 05b Lab ------------------------------------------------------------------------------
  const LAB_FIELDS = [
    { k: "heads", label: "Proportions (têtes)", type: "range", min: 2.2, max: 5.5, step: 0.1 },
    { k: "build", label: "Carrure", type: "range", min: 0.8, max: 1.35, step: 0.05 },
    { k: "headShape", label: "Forme de tête", type: "select", opts: [["round", "Ronde"], ["square", "Carrée"], ["sharp", "Menton pointu"]] },
    { k: "hair", label: "Coiffure", type: "select", opts: [["ponytail", "Queue de cheval"], ["spiky", "Pointes"], ["short", "Courte"]] },
    { k: "eyes", label: "Yeux", type: "select", opts: [["glow", "Néon"], ["anime", "Anime"], ["dot", "Points"]] },
    { k: "mask", label: "Masque", type: "check" },
    { k: "scarf", label: "Pans d'écharpe", type: "range", min: 0, max: 1.6, step: 0.1 },
    { k: "cape", label: "Cape", type: "check" },
    { k: "armor", label: "Épaulière", type: "check" },
    { k: "detail", label: "Niveau de détail", type: "range", min: 0, max: 2, step: 1 },
    { k: "outer", label: "Contour extérieur", type: "range", min: 0, max: 9, step: 0.5, styleField: true },
    { k: "inner", label: "Traits intérieurs", type: "range", min: 0, max: 3, step: 0.2, styleField: true },
    { k: "contrast", label: "Contraste", type: "range", min: 0.8, max: 1.5, step: 0.05, styleField: true },
  ];
  function labStyle() {
    const base = style(state.a);
    const s = Object.assign({}, base, { outline: Object.assign({}, base.outline), look: Object.assign({}, base.look) });
    LAB_FIELDS.forEach((f) => {
      if (!(f.k in state.lab)) return;
      if (f.k === "outer" || f.k === "inner") s.outline[f.k] = state.lab[f.k];
      else if (f.k === "contrast") s.contrast = state.lab[f.k] === 1 ? undefined : state.lab[f.k];
      else s.look[f.k] = state.lab[f.k];
    });
    return s;
  }
  function labValue(f) {
    const s = style(state.a);
    if (f.k in state.lab) return state.lab[f.k];
    if (f.k === "outer" || f.k === "inner") return s.outline[f.k];
    if (f.k === "contrast") return s.contrast || 1;
    return f.k in s.look ? s.look[f.k] : K.DEFAULT_LOOK[f.k];
  }
  function renderLabForm() {
    const form = $("#labForm");
    form.innerHTML = "";
    LAB_FIELDS.forEach((f) => {
      const v = labValue(f);
      const lab = el("label", "", `<span>${f.label}</span>`);
      let input;
      if (f.type === "range") {
        const wrap = el("span");
        wrap.style.cssText = "display:flex;gap:8px;align-items:center";
        input = el("input");
        Object.assign(input, { type: "range", min: f.min, max: f.max, step: f.step, value: v });
        const out = el("output", "", String(v));
        input.addEventListener("input", () => { out.textContent = input.value; state.lab[f.k] = parseFloat(input.value); renderLab(); });
        wrap.append(input, out);
        lab.appendChild(wrap);
      } else if (f.type === "select") {
        input = el("select");
        input.innerHTML = f.opts.map(([k, n]) => `<option value="${k}">${n}</option>`).join("");
        input.value = v;
        input.addEventListener("change", () => { state.lab[f.k] = input.value; renderLab(); });
        lab.appendChild(input);
      } else {
        input = el("input");
        input.type = "checkbox";
        input.checked = !!v;
        input.addEventListener("change", () => { state.lab[f.k] = input.checked; renderLab(); });
        lab.appendChild(input);
      }
      form.appendChild(lab);
    });
    const actions = el("div", "actions");
    const reset = el("button", "", "Revenir au style A");
    reset.type = "button";
    reset.addEventListener("click", () => { state.lab = {}; renderLabForm(); renderLab(); });
    const copy = el("button", "", "Copier les réglages");
    copy.type = "button";
    copy.addEventListener("click", () => {
      const txt = JSON.stringify({ style: state.a, palette: state.palette, overrides: state.lab });
      if (navigator.clipboard) navigator.clipboard.writeText(txt).catch(() => {});
      copy.textContent = "Copié !";
      setTimeout(() => { copy.textContent = "Copier les réglages"; }, 1200);
    });
    actions.append(reset, copy);
    form.appendChild(actions);
  }
  function renderLab() {
    const s = labStyle();
    $("#labMain").className = "lab-main stage";
    $("#labMain").innerHTML = charSvg(s, "SE");
    const dirs = $("#labDirs");
    dirs.innerHTML = "";
    ["S", "E", "NE", "N"].forEach((d) => dirs.appendChild(stage(charSvg(s, d, { grid: false }), "", K.DIRECTIONS[d].label)));
    const small = $("#labSmall");
    small.className = "lab-small stage";
    small.innerHTML = "";
    const svg = K.character(s, "SE", { palette: state.palette });
    [32, 48, 64, GAME_PX].forEach((px) => small.appendChild(img(svg, boxFor(px))));
  }

  const VARIANTS = [
    { id: "style_07", name: "G1 — Premium Indie, référence", look: {}, note: "3 têtes, contour coloré 5 px, yeux néon. Équilibre lisibilité / charme." },
    { id: "style_07", name: "G2 — Premium Indie, chibi pointu", look: { heads: 2.6, hair: "spiky", armor: true }, outline: { outer: 6 }, note: "Tête plus grosse, cheveux en pointes, épaulière : plus lisible à 32-48 px, plus « mascotte »." },
    { id: "style_10", name: "J1 — Sumi-Neon, référence", look: {}, note: "Encre, halo papier, un seul néon. Identité la plus forte." },
    { id: "style_10", name: "J2 — Sumi-Neon, cape d'encre", look: { cape: true, detail: 2, heads: 3.8 }, note: "Cape et détails néon : plus dramatique, idéal pour boss et key art." },
    { id: "style_02", name: "B1 — Modern Cartoon, référence", look: {}, note: "Contour noir épais, couleurs franches : le plus « grand public »." },
    { id: "style_02", name: "B2 — Modern Cartoon, tête carrée", look: { headShape: "square", eyes: "glow", build: 1.15 }, note: "Tête carrée, yeux néon, carrure : plus héroïque, moins enfantin." },
  ];
  function renderVariants() {
    const box = $("#variants");
    box.innerHTML = "";
    VARIANTS.forEach((v) => {
      const base = style(v.id);
      const s = Object.assign({}, base, { look: Object.assign({}, base.look, v.look), outline: Object.assign({}, base.outline, v.outline || {}) });
      const card = el("div", "variant");
      card.appendChild(stage(charSvg(s, "SE", { grid: false })));
      card.appendChild(el("p", "", `<b>${v.name}</b><br>${v.note}`));
      box.appendChild(card);
    });
  }

  // --- 06 Mockup ------------------------------------------------------------------------------
  function rng(seed) {
    let a = seed >>> 0;
    return () => {
      a |= 0; a = (a + 0x6d2b79f5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  function initMock() {
    fillStyleSelect($("#mockStyle"), state.mockStyle);
    $("#mockStyle").addEventListener("change", (e) => { state.mockStyle = e.target.value; renderMock(); });
    const seg = $("#mockDensity");
    [["calm", "Calme"], ["chaos", "Chaos (vague 18)"]].forEach(([k, n]) => {
      const b = el("button", k === state.density ? "on" : "", n);
      b.type = "button";
      b.addEventListener("click", () => {
        state.density = k;
        seg.querySelectorAll("button").forEach((x) => x.classList.toggle("on", x === b));
        renderMock();
      });
      seg.appendChild(b);
    });
    $("#chkMockZoom").addEventListener("change", (e) => { state.mockZoom = e.target.checked; renderMock(); });
  }
  function renderMock() {
    const s = style(state.mockStyle);
    const pal = K.PALETTES[state.palette];
    const W = 1920;
    const H = 1080;
    const z = state.mockZoom ? 0.8 : 1;
    const vw = W / z;
    const vh = H / z;
    const vb = `${(W - vw) / 2} ${(H - vh) / 2} ${vw} ${vh}`;
    const r = rng(7);
    const chaos = state.density === "chaos";
    const cx = W / 2;
    const cy = H / 2 + 40;
    const playerH = boxFor(GAME_PX);
    const playerW = (playerH * K.VIEW_W) / K.VIEW_H;
    const impH = boxFor(70);
    const impW = (impH * K.VIEW_W) / K.VIEW_H;
    const playerUrl = svgUrl(K.character(s, "SE", { palette: state.palette, poseKind: "walk", phase: 0.2 }));
    const impUrls = [0, 1].map((v) => svgUrl(K.imp(s, { variant: v, palette: state.palette })));
    let out = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}"><defs>
      <pattern id="tiles" width="128" height="128" patternUnits="userSpaceOnUse">
        <rect width="128" height="128" fill="#4a4479"/><rect x="6" y="6" width="116" height="116" rx="10" fill="#554f8c"/>
        <path d="M20 40 l14 10 M90 96 l-12 8 M70 22 l6 14" stroke="#3e3970" stroke-width="3" stroke-linecap="round"/></pattern>
      <filter id="mglow" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
    </defs>`;
    out += `<rect x="-400" y="-300" width="2720" height="1680" fill="url(#tiles)"/>`;
    // ground decals (seals)
    [[380, 300], [1500, 820], [300, 860]].forEach(([x, y]) => {
      out += `<circle cx="${x}" cy="${y}" r="70" fill="none" stroke="#4fd5ff" stroke-opacity="0.35" stroke-width="5"/><circle cx="${x}" cy="${y}" r="52" fill="none" stroke="#4fd5ff" stroke-opacity="0.2" stroke-width="3" stroke-dasharray="10 8"/>`;
    });
    // gems
    for (let i = 0; i < (chaos ? 40 : 14); i++) {
      const x = r() * W;
      const y = r() * H;
      out += `<path d="M${x} ${y - 9}L${x + 6} ${y}L${x} ${y + 9}L${x - 6} ${y}Z" fill="#59ff9a" opacity="0.9"/>`;
    }
    // sprites sorted by y (player included)
    const sprites = [];
    const n = chaos ? 46 : 14;
    for (let i = 0; i < n; i++) {
      const ang = r() * Math.PI * 2;
      const d = (chaos ? 150 : 260) + r() * (chaos ? 700 : 600);
      const x = cx + Math.cos(ang) * d * 1.25;
      const y = cy + Math.sin(ang) * d * 0.7;
      if (x < -100 || x > W + 100 || y < -60 || y > H + 80) continue;
      sprites.push({ y, svg: `<image href="${impUrls[i % 2]}" x="${x - impW / 2}" y="${y - impH * (K.FEET / K.VIEW_H)}" width="${impW}" height="${impH}"/>` });
    }
    sprites.push({ y: cy, svg: `<image href="${playerUrl}" x="${cx - playerW / 2}" y="${cy - playerH * (K.FEET / K.VIEW_H)}" width="${playerW}" height="${playerH}"/>` });
    sprites.sort((a, b) => a.y - b.y);
    // player projectiles
    let fx = "";
    for (let i = 0; i < (chaos ? 34 : 10); i++) {
      const ang = r() * Math.PI * 2;
      const d = 90 + r() * 600;
      const x = cx + Math.cos(ang) * d;
      const y = cy - 50 + Math.sin(ang) * d * 0.7;
      fx += `<g filter="url(#mglow)"><ellipse cx="${x}" cy="${y}" rx="11" ry="5" transform="rotate(${(ang * 180) / Math.PI} ${x} ${y})" fill="${pal.accent}"/></g>`;
    }
    // shuriken
    for (let i = 0; i < (chaos ? 6 : 2); i++) {
      const x = cx + (r() - 0.5) * 700;
      const y = cy + (r() - 0.5) * 420;
      fx += `<path d="M${x} ${y - 14}L${x + 4} ${y - 4}L${x + 14} ${y}L${x + 4} ${y + 4}L${x} ${y + 14}L${x - 4} ${y + 4}L${x - 14} ${y}L${x - 4} ${y - 4}Z" fill="#dfe8f0" stroke="#0d0a14" stroke-width="2" transform="rotate(${r() * 90} ${x} ${y})"/>`;
    }
    // enemy shots
    for (let i = 0; i < (chaos ? 16 : 4); i++) {
      const x = r() * W;
      const y = r() * H;
      fx += `<circle cx="${x}" cy="${y}" r="9" fill="#ff3d78" filter="url(#mglow)"/>`;
    }
    // katana slash near the player
    fx += `<path d="M${cx + 40} ${cy - 150} A 150 150 0 0 1 ${cx + 150} ${cy + 10} L ${cx + 118} ${cy - 6} A 118 118 0 0 0 ${cx + 30} ${cy - 120} Z" fill="${pal.accent}" opacity="0.55" filter="url(#mglow)"/>`;
    // explosions
    if (chaos) {
      [[cx - 380, cy - 160], [cx + 420, cy + 180]].forEach(([x, y]) => {
        fx += `<circle cx="${x}" cy="${y}" r="70" fill="#ff9a3d" opacity="0.35" filter="url(#mglow)"/><circle cx="${x}" cy="${y}" r="38" fill="#ffe08a" opacity="0.7"/>`;
      });
    }
    // damage numbers
    let nums = "";
    for (let i = 0; i < (chaos ? 14 : 5); i++) {
      const x = cx + (r() - 0.5) * 900;
      const y = cy + (r() - 0.5) * 520;
      const crit = r() < 0.25;
      nums += `<text x="${x}" y="${y}" font-family="Segoe UI, sans-serif" font-weight="900" font-size="${crit ? 34 : 24}" fill="${crit ? "#ffd166" : "#fff"}" stroke="#14101e" stroke-width="5" paint-order="stroke">${Math.round(5 + r() * 40)}</text>`;
    }
    // light HUD
    const hud = `<g transform="translate(${(W - vw) / 2} ${(H - vh) / 2}) scale(${1 / z})">
      <rect x="32" y="40" width="380" height="38" rx="10" fill="#2a0f18" stroke="#000" stroke-width="3"/><rect x="34" y="42" width="290" height="34" rx="9" fill="#ff5a6a"/>
      <text x="222" y="67" text-anchor="middle" font-family="Segoe UI" font-weight="800" font-size="22" fill="#fff">78 / 100</text>
      <text x="960" y="64" text-anchor="middle" font-family="Segoe UI" font-weight="900" font-size="30" fill="#fff" stroke="#14101e" stroke-width="5" paint-order="stroke">Vague 18/20</text>
      <text x="960" y="112" text-anchor="middle" font-family="Segoe UI" font-weight="900" font-size="46" fill="#fff" stroke="#14101e" stroke-width="6" paint-order="stroke">00:31</text></g>`;
    out += sprites.map((sp) => sp.svg).join("") + fx + nums + hud + "</svg>";
    $("#mock").innerHTML = out;
  }

  // --- 07 Recommendation -------------------------------------------------------------------
  function renderReco() {
    const g = style("style_07");
    const j = style("style_10");
    const b = style("style_02");
    const mini = (s, look) => img(K.character(Object.assign({}, s, { look: Object.assign({}, s.look, look || {}) }), "SE", { palette: state.palette }), 150).outerHTML;
    $("#recoBody").innerHTML = `
      <div class="reco-grid">
        <div class="reco-item"><div class="k">1. Meilleur style</div><div class="v">G — Premium Indie</div>
          <p>Le meilleur rapport lisibilité / personnalité : silhouette en triangle, contour coloré qui la détache du sol violet, yeux néon qui deviennent la signature du jeu. Il reste propre de 32 px jusqu'à la carte de sélection.</p></div>
        <div class="reco-item"><div class="k">2. Deuxième</div><div class="v">J — Sumi-Neon</div>
          <p>L'identité la plus originale : encre noire, halo papier, un seul néon. Silhouette parfaite par construction. Risque de monotonie sur 25 persos : à garder pour une couche « signature » (boss, key art, écran titre).</p></div>
        <div class="reco-item"><div class="k">3. Meilleur compromis qualité / coût</div><div class="v">G — Premium Indie</div>
          <p>Même famille que le pipeline actuel du jeu (ADR 0016 : sprites vectoriels par code, contour + ombre franche). Évolution, pas révolution : pas de nouvel outil, pas d'illustrateur obligatoire.</p></div>
        <div class="reco-item"><div class="k">4. Meilleur pour un survivor-like</div><div class="v">G (et I pour la masse d'ennemis)</div>
          <p>Avec 650 ennemis, le joueur doit sauter aux yeux : contour + néon + écharpe rouge le garantissent. Les ennemis de base peuvent descendre vers le style I (moins de détails) dans la même famille pour que le joueur et les élites ressortent.</p></div>
        <div class="reco-item"><div class="k">5. Pour 5 persos + 15 ennemis + 5 boss</div><div class="v">G sur un squelette commun</div>
          <p>Un squelette paramétrique + des règles de style = 25 personnages cohérents sans dérive. Chaque perso change de forme signature (coiffure, arme, cape) et de couleur d'accent, jamais de style. Les boss peuvent passer en G « détail 2 » + touches J.</p></div>
        <div class="reco-item"><div class="k">Moins recommandés ici</div><div class="v">A, C, H</div>
          <p>Superbes en gros plan mais chers (peints / anime détaillé) et moins lisibles à 48 px. À réserver au marketing : capsule Steam, key art, trailer (style H).</p></div>
      </div>
      <h3>Risques de production</h3>
      <ul class="risks">
        <li><b>Plafond du dessin par code</b> : les formes restent simples. Pour la capsule Steam et le key art, prévoir un illustrateur (en style H ou C) qui part de ces planches.</li>
        <li><b>Discipline de palette</b> : 70 % sombre / 20 % neutre / 10 % accent, une couleur d'accent par perso. Sans cette règle, G devient générique.</li>
        <li><b>Confusion avec les VFX</b> : les tirs sont néon ; le perso doit garder son contour coloré et son écharpe (formes, pas seulement couleur). Le style K a ce défaut, à éviter.</li>
        <li><b>Animation</b> : pièces rigides (type Spine). Suffisant pour marche / attaque / coup ; une mort ou un dash spectaculaires demanderont des images dessinées en plus.</li>
        <li><b>Coop</b> : deux persos à l'écran → l'anneau de couleur au sol et l'accent par joueur doivent rester différents (cyan / rose).</li>
      </ul>
      <div class="reco-final">
        <h3>Recommandation finale</h3>
        <p><b>Adopter G — Premium Indie</b> comme style de jeu (variante G1 ou G2 selon la taille de tête préférée), avec la <b>signature néon</b> de J pour les boss, les écrans de titre et les VFX d'ultime, et un <b>style H</b> réservé au marketing. Étape suivante : valider G1 ou G2, puis appliquer le squelette au casting existant (4 persos, 7 ennemis, 2 boss) pour vérifier la cohérence avant d'en produire plus.</p>
        <div style="display:flex;gap:18px;align-items:flex-end;flex-wrap:wrap;margin-top:12px">${mini(g)}${mini(g, { heads: 2.6, hair: "spiky", armor: true })}${mini(j)}${mini(b)}</div>
      </div>`;
  }

  // --- Boot ------------------------------------------------------------------------------------
  function renderAll() {
    renderHero();
    renderCards();
    renderCompare();
    renderAnim();
    renderScale();
    renderSilhouettes();
    renderColors();
    renderLab();
    renderVariants();
    renderMock();
    renderReco();
  }
  document.body.dataset.bg = state.bg;
  initToolbar();
  renderRefs();
  renderDirBar();
  initWipe();
  initAnim();
  renderLabForm();
  initMock();
  renderAll();
})();
