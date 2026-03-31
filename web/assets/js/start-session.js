(() => {
  const CFG = window.LR_START_SESSION_CONFIG || {};
  const API_URL = CFG.API_URL || "../api/session_process.php";
  const SESSION_VIEW_URL = CFG.SESSION_VIEW_URL || "../trainee/session-view.php?log_id=";

  /* =========================
     DOM
  ========================= */
  const btnStart = document.getElementById("btnStart");
  const btnStop  = document.getElementById("btnStop");
  const exerciseSelect = document.getElementById("exerciseSelect");

  const video = document.getElementById("video");
  const captureCanvas = document.getElementById("captureCanvas");
  const overlayCanvas = document.getElementById("overlayCanvas");
  const countdownOverlay = document.getElementById("countdownOverlay");
  const idleOverlay = document.getElementById("idleOverlay");

  const capCtx = captureCanvas.getContext("2d");
  const ovCtx  = overlayCanvas.getContext("2d");

  // Left panel
  const uiReps = document.getElementById("uiReps");
  const uiState = document.getElementById("uiState");
  const uiConf = document.getElementById("uiConf");
  const uiFeedback = document.getElementById("uiFeedback");
  const uiLastRep = document.getElementById("uiLastRep");
  const uiExerciseMain = document.getElementById("uiExerciseMain");
  const uiLogIdMain = document.getElementById("uiLogIdMain");
  const uiInstruction = document.getElementById("uiInstruction");
  const uiInstructionSub = document.getElementById("uiInstructionSub");
  const uiPhasePill = document.getElementById("uiPhasePill");
  const uiDebugLine = document.getElementById("uiDebugLine");

  // Right rail
  const uiRepsSide = document.getElementById("uiRepsSide");
  const uiStateSide = document.getElementById("uiStateSide");
  const uiConfSide = document.getElementById("uiConfSide");
  const uiExerciseSide = document.getElementById("uiExerciseSide");
  const uiLogIdSide = document.getElementById("uiLogIdSide");

  // Guide modal
  const guideBackdrop = document.getElementById("guideBackdrop");
  const guideModal = document.getElementById("guideModal");
  const btnCloseGuide = document.getElementById("btnCloseGuide");
  const btnPrevGuide = document.getElementById("btnPrevGuide");
  const btnNextGuide = document.getElementById("btnNextGuide");
  const btnReadyGuide = document.getElementById("btnReadyGuide");
  const guideStepNum = document.getElementById("guideStepNum");
  const guideStepTitle = document.getElementById("guideStepTitle");
  const guideStepText = document.getElementById("guideStepText");
  const guideCountdown = document.getElementById("guideCountdown");
  const guideExerciseText = document.getElementById("guideExerciseText");
  const guideHintLine = document.getElementById("guideHintLine");

  /* =========================
     STATE
  ========================= */
  let stream = null;

  let running = false;     // true only when /frame loop is active
  let loopRunning = false;
  let inflight = false;

  let logId = 0;
  let sessionToken = "";

  // Gate mode state (setup)
  let gateTimer = null;
  let gateOkStreak = 0;
  let gateMemory = { minY: 1.0, minX: 1.0, maxX: 0.0 };

  // Overlay image from python
  const annotatedImg = new Image();
  let lastAnnotatedDataUrl = "";
  let lastStatusForOverlay = null;

  // “What arrow should I show right now?”
  // We keep this aligned with your instruction state.
  let lastKnownPhase = "raise"; // "raise" or "lower"

/* =========================
   SFX SYSTEM
========================= */

const SFX = {
  start:  new Audio("../assets/sfx/start.mp3"),
  rep:    new Audio("../assets/sfx/rep.mp3"),
  coach:  new Audio("../assets/sfx/coach.mp3"),
  danger: new Audio("../assets/sfx/danger.mp3"),
  stop:   new Audio("../assets/sfx/stop.mp3"),
};

Object.values(SFX).forEach(a => {
  a.preload = "auto";
  a.volume = 0.6;
});

function playSfx(name) {
  const a = SFX[name];
  if (!a) return;

  try {
    a.currentTime = 0;
    a.play().catch(() => {});
  } catch {}
}

function sfx(name) { playSfx(name); }

// For “play only on change” logic
let prevStateLower = "";
let prevRepNum = 0;

// Cooldowns to reduce spam
let lastCoachSfxAt = 0;
let lastDangerSfxAt = 0;
const COACH_COOLDOWN_MS = 1200;
const DANGER_COOLDOWN_MS = 1200;

  /* =========================
     VISUAL CONFIG (EDIT HERE)
     Everything scales with canvas size.
  ========================= */
  const VIS = {
    safeZone: {
      marginX: 0.14,
      marginY: 0.08,
      dash: [12, 10],
      lineW: 0.004,
      corner: 0.06,
      alpha: 0.65,
    },

    arrow: {
      lineW: 0.010,
      head: 0.028,
      alpha: 0.70,
      color: "rgb(38, 56, 41)"
    },

    tint: {
      lowConfAlpha: 0.08,
      badFrameAlpha: 0.12,
      stopAlpha: 0.16,
    },

    conf: {
      warn: 0.55,
      bad:  0.45,
    },

    pulseMs: 750,

    // ✅ MAIN THING YOU ASKED:
    // This is the HUD arrow position (upper right).
    // Change these to move the up/down arrow.
    hud: {
      x: 0.92,        // 0..1 (closer to 1 = more right)
      yTop: 0.16,     // arrow top Y
      yBot: 0.32,     // arrow bottom Y (controls length)
      inset: 0.02,    // keeps it away from edges
    },

    // Exercise-specific arrows (non-HUD, like lateral raise side arrows)
    exArrows: {
      lateralRaise: {
        y: 0.46,
        leftFrom: 0.40,
        leftTo:   0.15,
        rightFrom: 0.60,
        rightTo:   0.85,
      }
    }
  };

  /* =========================
     HELPERS
  ========================= */
  const clamp01 = (x) => Math.max(0, Math.min(1, x));

  function lw(frac) {
    const m = Math.min(overlayCanvas.width, overlayCanvas.height);
    return Math.max(2, Math.round(m * frac));
  }

  function pulseAlpha(base = 0.45, amp = 0.25) {
    const t = Date.now() / VIS.pulseMs;
    const s = 0.5 + 0.5 * Math.sin(t * Math.PI * 2);
    return clamp01(base + amp * s);
  }

  async function api(action, payload) {
    const res = await fetch(API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action, ...payload }),
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.message || "API error");
    return data;
  }

  function syncCanvasToVideo() {
    const vw = video.videoWidth || 1280;
    const vh = video.videoHeight || 720;

    if (overlayCanvas.width !== vw || overlayCanvas.height !== vh) {
      overlayCanvas.width = vw;
      overlayCanvas.height = vh;
    }

    const TARGET_W = 640;
    const scale = Math.min(1, TARGET_W / vw);
    captureCanvas.width = Math.round(vw * scale);
    captureCanvas.height = Math.round(vh * scale);
  }

  async function startCamera() {
    if (stream) return;
    stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: "user" },
      audio: false,
    });
    video.srcObject = stream;
    await video.play();
    syncCanvasToVideo();
    video.onloadedmetadata = () => syncCanvasToVideo();
  }

  function stopCamera() {
    if (!stream) return;
    for (const t of stream.getTracks()) t.stop();
    stream = null;
    video.srcObject = null;
  }

  function canvasToJpegBase64(canvas, quality = 0.5) {
    return new Promise((resolve, reject) => {
      canvas.toBlob(
        (blob) => {
          if (!blob) return reject(new Error("toBlob failed"));
          const r = new FileReader();
          r.onloadend = () => resolve(r.result);
          r.onerror = () => reject(new Error("FileReader failed"));
          r.readAsDataURL(blob);
        },
        "image/jpeg",
        quality
      );
    });
  }

  function normalizeState(raw) {
    const s = String(raw ?? "").toLowerCase().trim();
    if (["up","raise","raising","concentric","lift","lifting"].includes(s)) return "up";
    if (["down","lower","lowering","eccentric","drop","descending"].includes(s)) return "down";
    if (s.includes("up") || s.includes("raise")) return "up";
    if (s.includes("down") || s.includes("lower")) return "down";
    return "";
  }

  /* =========================
     DRAWING PRIMITIVES
  ========================= */
  function drawSafeZone(colorRGBA) {
    const w = overlayCanvas.width, h = overlayCanvas.height;
    const mx = w * VIS.safeZone.marginX;
    const my = h * VIS.safeZone.marginY;

    ovCtx.save();
    ovCtx.strokeStyle = colorRGBA;
    ovCtx.lineWidth = lw(VIS.safeZone.lineW);
    ovCtx.setLineDash(VIS.safeZone.dash);
    ovCtx.globalAlpha = VIS.safeZone.alpha;
    ovCtx.strokeRect(mx, my, w - mx * 2, h - my * 2);
    ovCtx.restore();
  }

  function drawCornerBrackets(colorRGBA) {
    const w = overlayCanvas.width, h = overlayCanvas.height;
    const mx = w * VIS.safeZone.marginX;
    const my = h * VIS.safeZone.marginY;
    const bw = w - mx * 2;
    const bh = h - my * 2;
    const L = Math.min(w, h) * VIS.safeZone.corner;

    ovCtx.save();
    ovCtx.strokeStyle = colorRGBA;
    ovCtx.lineWidth = lw(VIS.safeZone.lineW);
    ovCtx.globalAlpha = 0.85;

    ovCtx.beginPath();
    // TL
    ovCtx.moveTo(mx, my + L); ovCtx.lineTo(mx, my); ovCtx.lineTo(mx + L, my);
    // TR
    ovCtx.moveTo(mx + bw - L, my); ovCtx.lineTo(mx + bw, my); ovCtx.lineTo(mx + bw, my + L);
    // BR
    ovCtx.moveTo(mx + bw, my + bh - L); ovCtx.lineTo(mx + bw, my + bh); ovCtx.lineTo(mx + bw - L, my + bh);
    // BL
    ovCtx.moveTo(mx + L, my + bh); ovCtx.lineTo(mx, my + bh); ovCtx.lineTo(mx, my + bh - L);
    ovCtx.stroke();

    ovCtx.restore();
  }

  function drawTint(colorRGBA, alpha) {
    const w = overlayCanvas.width, h = overlayCanvas.height;
    ovCtx.save();
    ovCtx.globalAlpha = alpha;
    ovCtx.fillStyle = colorRGBA;
    ovCtx.fillRect(0, 0, w, h);
    ovCtx.restore();
  }

  function drawArrow(x1, y1, x2, y2, colorRGBA) {
    const m = Math.min(overlayCanvas.width, overlayCanvas.height);
    const head = m * VIS.arrow.head;

    const dx = x2 - x1, dy = y2 - y1;
    const len = Math.hypot(dx, dy) || 1;
    const ux = dx / len, uy = dy / len;

    const px = -uy, py = ux;

    const hx = x2 - ux * head;
    const hy = y2 - uy * head;

    ovCtx.save();
    ovCtx.strokeStyle = colorRGBA;
    ovCtx.lineWidth = lw(VIS.arrow.lineW);
    ovCtx.globalAlpha = VIS.arrow.alpha;

    ovCtx.beginPath();
    ovCtx.moveTo(x1, y1);
    ovCtx.lineTo(x2, y2);
    ovCtx.stroke();

    ovCtx.beginPath();
    ovCtx.moveTo(x2, y2);
    ovCtx.lineTo(hx + px * (head * 0.55), hy + py * (head * 0.55));
    ovCtx.moveTo(x2, y2);
    ovCtx.lineTo(hx - px * (head * 0.55), hy - py * (head * 0.55));
    ovCtx.stroke();

    ovCtx.restore();
  }

  // ✅ HUD arrow (upper right) — for UP/DOWN only
  function drawHudUpDown(dir, color = "rgb(103, 243, 98)") {
    const w = overlayCanvas.width, h = overlayCanvas.height;
    const inset = Math.min(w, h) * VIS.hud.inset;

    const x = w * VIS.hud.x - inset;
    const yTop = h * VIS.hud.yTop;
    const yBot = h * VIS.hud.yBot;

    if (dir === "up")   drawArrow(x, yBot, x, yTop, color);
    if (dir === "down") drawArrow(x, yTop, x, yBot, color);
  }

  /* =========================
     OVERLAY RENDER PIPELINE
     (annotated frame first, then cues on top)
  ========================= */
  function renderOverlay() {
    ovCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);

    if (annotatedImg.complete && annotatedImg.naturalWidth) {
      ovCtx.drawImage(annotatedImg, 0, 0, overlayCanvas.width, overlayCanvas.height);
    }

    if (lastStatusForOverlay) drawLiveCues(lastStatusForOverlay);
  }

  function drawAnnotatedToOverlay(dataurl, statusObj) {
    if (!dataurl) {
      lastStatusForOverlay = statusObj || lastStatusForOverlay;
      renderOverlay();
      return;
    }

    lastStatusForOverlay = statusObj || lastStatusForOverlay;

    if (dataurl === lastAnnotatedDataUrl) {
      renderOverlay();
      return;
    }
    lastAnnotatedDataUrl = dataurl;

    annotatedImg.onload = () => renderOverlay();
    annotatedImg.onerror = () => renderOverlay();
    annotatedImg.src = dataurl;
  }

  /* =========================
     LIVE CUES (during exercise)
  ========================= */
  function drawLiveCues(status) {
    const w = overlayCanvas.width, h = overlayCanvas.height;
    if (!w || !h) return;

    const ex = String(status.exercise ?? exerciseSelect.value ?? "");
    const state = String(status.state ?? "").toLowerCase();
    const conf = (typeof status.conf === "number") ? status.conf : null;

    // Safe zone always
    let boxColor = "rgba(0,255,0,1)";
    if (state === "stop") boxColor = "rgba(255,70,70,1)";
    else if (conf !== null && conf < VIS.conf.warn) boxColor = "rgba(255,215,0,1)";
    drawSafeZone(boxColor);

    // Only when needed
    if (state === "stop") {
      drawTint("rgba(120,0,0,1)", VIS.tint.stopAlpha);
    } else if (conf !== null && conf < VIS.conf.warn) {
      drawCornerBrackets("rgba(255,215,0,1)");
      const a = (conf < VIS.conf.bad) ? (VIS.tint.lowConfAlpha + 0.06) : VIS.tint.lowConfAlpha;
      drawTint("rgba(255,215,0,1)", a);
    }

    // ✅ UP/DOWN cue in upper-right HUD for bicep + shoulder press
    if (ex === "bicep_curl" || ex === "shoulder_press") {
      drawHudUpDown(lastKnownPhase === "raise" ? "up" : "down");
    }

    // Lateral raise gets side arrows (not in HUD)
    if (ex === "lateral_raise") {
      const y = h * VIS.exArrows.lateralRaise.y;
      const L1 = w * VIS.exArrows.lateralRaise.leftFrom;
      const L2 = w * VIS.exArrows.lateralRaise.leftTo;
      const R1 = w * VIS.exArrows.lateralRaise.rightFrom;
      const R2 = w * VIS.exArrows.lateralRaise.rightTo;

      if (lastKnownPhase === "raise") {
        drawArrow(L1, y, L2, y, "rgba(255,255,255,1)");
        drawArrow(R1, y, R2, y, "rgba(255,255,255,1)");
      } else {
        drawArrow(L2, y, L1, y, "rgba(255,255,255,1)");
        drawArrow(R2, y, R1, y, "rgba(255,255,255,1)");
      }
    }
  }

  /* =========================
     INSTRUCTIONS (text) + keeps lastKnownPhase in sync
  ========================= */
  const VARIANTS = {
    raise: ["RAISE the weight.", "Go UP — controlled lift.", "Bring it UP smoothly."],
    lower: ["LOWER the weight.", "Go DOWN — slow and controlled.", "Bring it DOWN steadily."],
    stop:  ["STOP recommended — rest.", "High fatigue detected — stop.", "Stop now — reset form."],
    lowconf: [
      "Tracking low — step back.",
      "Low confidence — improve lighting/distance.",
      "Reposition: keep shoulders→hips visible."
    ]
  };

  function toRepNum(repNow) {
    if (repNow === undefined || repNow === null) return null;
    if (typeof repNow === "number") return repNow;
    const n = parseInt(repNow, 10);
    return Number.isNaN(n) ? null : n;
  }

  let stickyPhrase = "";
  let stickyKey = "";
  let stickyRep = null;

  function pickVariantSticky(key, repNow) {
    const repNum = toRepNum(repNow);
    const repChanged = (repNum !== null && stickyRep !== null && repNum > stickyRep);
    if (stickyPhrase && stickyKey === key && !repChanged) return stickyPhrase;

    const list = VARIANTS[key] || ["—"];
    stickyPhrase = list[Math.floor(Math.random() * list.length)];
    stickyKey = key;
    if (repNum !== null) stickyRep = repNum;
    return stickyPhrase;
  }

  function setInstructionsFromStatus(status) {
    const rawState = status?.phase ?? status?.state;
    const stateNorm = normalizeState(rawState);
    const conf = status?.conf;
    const repNow = status?.rep_now;

    uiPhasePill.textContent = `Phase: ${running ? (stateNorm || String(rawState || "tracking")) : "Idle"}`;

    if (uiDebugLine) {
      const confTxt = (typeof conf === "number") ? conf.toFixed(2) : String(conf ?? "—");
      uiDebugLine.textContent = `state: ${String(status?.state ?? "—")} | phase: ${String(status?.phase ?? "—")} | conf: ${confTxt}`;
    }

    if (typeof conf === "number" && conf < VIS.conf.warn) {
      uiInstruction.textContent = pickVariantSticky("lowconf", repNow);
      uiInstructionSub.textContent = "Step back, face camera, improve lighting.";
      return;
    }

    if (!running) {
      uiInstruction.textContent = "Press Start to begin.";
      uiInstructionSub.textContent = "Warm-up assumed. Use a safe load you can control.";
      return;
    }

    if (String(rawState).toLowerCase() === "stop") {
      uiInstruction.textContent = pickVariantSticky("stop", repNow);
      uiInstructionSub.textContent = "Rest 1–3 minutes. Reduce load if needed.";
      return;
    }

    // Keep lastKnownPhase aligned with what you want the user to do NOW
    if (stateNorm === "down") {
      lastKnownPhase = "raise";
      uiInstruction.textContent = pickVariantSticky("raise", repNow);
      uiInstructionSub.textContent = "Lift smoothly (no jerking).";
      return;
    }
    if (stateNorm === "up") {
      lastKnownPhase = "lower";
      uiInstruction.textContent = pickVariantSticky("lower", repNow);
      uiInstructionSub.textContent = "Control the descent (don’t drop).";
      return;
    }

    // fallback
    uiInstruction.textContent = (lastKnownPhase === "raise")
      ? pickVariantSticky("raise", repNow)
      : pickVariantSticky("lower", repNow);

    uiInstructionSub.textContent = (lastKnownPhase === "raise")
      ? "Lift smoothly (no jerking)."
      : "Control the descent (don’t drop).";
  }

  function setBadge(el, text, kind) {
    el.textContent = text;
    el.classList.remove("lr-badge-good","lr-badge-warning","lr-badge-bad","lr-badge-danger");
    if (kind === "good") el.classList.add("lr-badge-good");
    else if (kind === "bad" || kind === "danger") el.classList.add("lr-badge-danger");
    else el.classList.add("lr-badge-warning");
  }

  /* =========================
     MAIN SESSION LOOP (/frame)
  ========================= */
  async function tick() {
    if (!running || inflight) return;
    if (!video.videoWidth || !video.videoHeight) return;

    inflight = true;
    try {
      capCtx.drawImage(video, 0, 0, captureCanvas.width, captureCanvas.height);
      const frameDataUrl = await canvasToJpegBase64(captureCanvas, 0.5);

      const resp = await api("frame", {
        log_id: logId,
        session_token: sessionToken,
        frame_dataurl: frameDataUrl,
      });

      const annotated = resp.annotated_frame_dataurl;
      const status = resp.status || {};
      
      const lastRepText = String(status.last_rep_text ?? "");
      const lastRepTextUpper = lastRepText.toUpperCase();

      const repNum = toRepNum(status.rep_now) ?? 0;
      const repJustIncremented = repNum > prevRepNum;

      if (repJustIncremented) {
        const now = Date.now();

        if (lastRepTextUpper.includes("UNSAFE")) {
          if ((now - lastDangerSfxAt) >= DANGER_COOLDOWN_MS) {
            sfx("danger");
            lastDangerSfxAt = now;
          }
        } else if (lastRepTextUpper.includes("COACHING")) {
          if ((now - lastCoachSfxAt) >= COACH_COOLDOWN_MS) {
            sfx("coach");
            lastCoachSfxAt = now;
          }
        } else {
          sfx("rep");
        }

        prevRepNum = repNum;
      }

      drawAnnotatedToOverlay(annotated, status);

      const repNow = (status.rep_now ?? "—");
      const state = (status.state ?? "—");
      const conf = (status.conf ?? "—");

      uiReps.textContent = `Reps: ${repNow}`;
      setBadge(uiState, `State: ${state}`, String(state).toLowerCase() === "stop" ? "danger" : "warning");
      uiConf.textContent = `Conf: ${typeof conf === "number" ? conf.toFixed(2) : conf}`;

      uiRepsSide.textContent = String(repNow);
      uiStateSide.textContent = String(state);
      uiConfSide.textContent = (typeof conf === "number" ? conf.toFixed(2) : String(conf));

      const ex = (status.exercise ?? exerciseSelect.value);
      uiExerciseMain.textContent = ex;
      uiExerciseSide.textContent = ex;

      uiFeedback.textContent = String(state).toLowerCase() === "stop"
        ? "STOP RECOMMENDED (fatigue)"
        : "Tracking...";
      uiLastRep.textContent = status.last_rep_text ?? "—";

      const now = Date.now();

      setInstructionsFromStatus(status);

      const stateLower = String(status.state ?? "").toLowerCase();

      // ✅ HOOK: play stop sound ONLY once on transition into stop
      if (stateLower === "stop" && prevStateLower !== "stop") {
        sfx("stop"); // short double-beep
      }
      prevStateLower = stateLower;

      if (stateLower === "stop") {
        await stopSession(true);
      }

    } catch (e) {
      uiFeedback.textContent = `Error: ${e.message}`;
      uiInstruction.textContent = "Service error — check Python server.";
      uiInstructionSub.textContent = "Restart realtime_server.py and refresh if needed.";
      setBadge(uiState, "State: error", "danger");
      uiStateSide.textContent = "error";
    } finally {
      inflight = false;
    }
  }

  async function loop() {
    if (!loopRunning) return;
    await tick();
    setTimeout(loop, 16);
  }

  function startLoop() {
    if (loopRunning) return;
    loopRunning = true;
    loop();
  }

  function stopLoop() {
    loopRunning = false;
  }

  async function startSessionInternal() {
    const ex = exerciseSelect.value;
    const res = await api("start", { exercise_type: ex });
    logId = res.log_id;
    sessionToken = res.session_token;

    uiLogIdMain.textContent = String(logId);
    uiLogIdSide.textContent = String(logId);
    uiExerciseMain.textContent = ex;
    uiExerciseSide.textContent = ex;

    if (idleOverlay) idleOverlay.style.display = "none";
    await startCamera();

    running = true;
    btnStart.disabled = true;
    btnStop.disabled = false;
    exerciseSelect.disabled = true;

    lastKnownPhase = "raise";
    stickyPhrase = "";
    stickyKey = "";
    stickyRep = null;

    uiPhasePill.textContent = "Phase: tracking";
    startLoop();
  }

  function goToSessionView(id) {
    if (!id || id <= 0) return;
    window.location.href = SESSION_VIEW_URL + encodeURIComponent(String(id));
  }

  async function stopSession(fromAutoStop = false) {
    if (!running) return;

    const finishedLogId = logId;

    running = false;
    inflight = false;
    stopLoop();

    stopCamera();
    ovCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);

    btnStart.disabled = false;
    btnStop.disabled = true;
    exerciseSelect.disabled = false;

    try {
      await api("finish", { log_id: finishedLogId, session_token: sessionToken });
      setBadge(uiState, "State: finished", "good");
      uiStateSide.textContent = "finished";
      uiFeedback.textContent = fromAutoStop ? "Session finished (auto-stop)." : "Session finished.";
      goToSessionView(finishedLogId);
    } catch (e) {
      uiFeedback.textContent = `Finish error: ${e.message}`;
      uiInstruction.textContent = "Finish error — check connection.";
      uiInstructionSub.textContent = "Refresh and try again.";
    } finally {
      sessionToken = "";
      logId = 0;
      uiLogIdMain.textContent = "—";
      uiLogIdSide.textContent = "—";
      if (idleOverlay) idleOverlay.style.display = "flex";
    }
  }

  /* =========================
     GUIDE MODAL + GATE MODE
     (still uses your working logic)
  ========================= */
  const GUIDE_STEPS = [
    {
      title: "Position & framing",
      text: "Stand back until your shoulders to hips are visible. Face the camera and keep lighting bright.",
      hint: "Avoid strong backlight (window behind you).",
    },
        {
    title: "Quick guide",
    text: "",   // will be injected dynamically
    hint: "Compare your form to the demo below.",
    render: function() {
        const ex = exerciseSelect.value;
        const gifPath = `../assets/guides/${ex}.gif`;

        return `
        <div style="text-align:center;">
            <div style="font-weight:600; margin-bottom:10px;">
            Proper form demo
            </div>

            <img src="${gifPath}"
                onerror="this.style.display='none'; this.nextElementSibling.style.display='block';"
                style="max-width:100%; border-radius:12px;" />

            <div style="display:none; opacity:.8; margin-top:10px;">
            No ${ex}.gif detected.
            </div>
        </div>
        `;
    }
    },
    {
      title: "Camera check (required)",
      text: "Next, we’ll run a framing check ON the live camera screen. Follow prompts to ensure your upper body is fully visible.",
      hint: "If tracking is low: step back, face camera, increase lighting.",
    },
  ];

  let guideIndex = 0;

  function openGuide() {
    guideIndex = 0;
    guideExerciseText.textContent = exerciseSelect.value;

    guideCountdown.textContent = "Countdown: —";
    btnNextGuide.style.display = "";
    btnPrevGuide.disabled = true;
    btnReadyGuide.style.display = "none";

    renderGuideStep();

    guideBackdrop.style.display = "block";
    guideModal.style.display = "flex";
  }

  function closeGuide() {
    guideBackdrop.style.display = "none";
    guideModal.style.display = "none";
  }

  function renderGuideStep() {
    const s = GUIDE_STEPS[guideIndex];
    guideStepNum.textContent = String(guideIndex + 1);
    guideStepTitle.textContent = s.title;
    if (typeof s.render === "function") {
        guideStepText.innerHTML = s.render();
        } else {
        guideStepText.textContent = s.text;
    }
    guideHintLine.textContent = s.hint;

    btnPrevGuide.disabled = (guideIndex === 0);

    const last = (guideIndex === GUIDE_STEPS.length - 1);
    btnNextGuide.style.display = last ? "none" : "";
    btnReadyGuide.style.display = last ? "" : "none";
    if (last) btnReadyGuide.textContent = "Start Camera Check";
  }

  function resetGate() {
    gateOkStreak = 0;
    gateMemory = { minY: 1.0, minX: 1.0, maxX: 0.0 };
  }

  function stopGateLoop() {
    if (!gateTimer) return;
    clearInterval(gateTimer);
    gateTimer = null;
  }

  function updateGateMemory(gate) {
    const w = gate?.wrist;
    if (!w) return;
    if (typeof w.min_y === "number") gateMemory.minY = Math.min(gateMemory.minY, w.min_y);
    if (typeof w.min_x === "number") gateMemory.minX = Math.min(gateMemory.minX, w.min_x);
    if (typeof w.max_x === "number") gateMemory.maxX = Math.max(gateMemory.maxX, w.max_x);
  }

  function gateHandsUpOk() { return gateMemory.minY <= 0.12; }
  function gateHandsSideOk() { return gateMemory.minX <= 0.10 && gateMemory.maxX >= 0.90; }

  async function gateTick() {
    if (!video.videoWidth || !video.videoHeight) return;
    ovCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);

    capCtx.drawImage(video, 0, 0, captureCanvas.width, captureCanvas.height);
    const frameDataUrl = await canvasToJpegBase64(captureCanvas, 0.5);

    const resp = await api("gate", { frame_dataurl: frameDataUrl });
    const ok = !!resp.ok;
    const g = resp.gate || {};

    if (!ok) {
      gateOkStreak = 0;
      drawSafeZone(`rgba(255,70,70,${pulseAlpha(0.5,0.25)})`);
      drawTint("rgba(120,0,0,1)", VIS.tint.badFrameAlpha);
      uiInstruction.textContent = "Service error — check Python server.";
      uiInstructionSub.textContent = "Make sure realtime_server.py is running on port 5101.";
      return;
    }

    if (!g.pose_found) {
      gateOkStreak = 0;
      drawSafeZone(`rgba(255,70,70,${pulseAlpha(0.5,0.25)})`);
      drawTint("rgba(120,0,0,1)", VIS.tint.badFrameAlpha);
      uiInstruction.textContent = "Step into view and face the camera.";
      uiInstructionSub.textContent = "Better lighting helps. Avoid backlight.";
      return;
    }

    updateGateMemory(g);

    const frameOk = !!g.frame_ok;
    const handsUp = gateHandsUpOk();
    const handsSide = gateHandsSideOk();

    if (!frameOk) {
      gateOkStreak = 0;
      drawSafeZone(`rgba(255,70,70,${pulseAlpha(0.5,0.25)})`);
      drawTint("rgba(120,0,0,1)", VIS.tint.badFrameAlpha);

      uiInstruction.textContent = "Step back (create distance).";
      uiInstructionSub.textContent = "Keep shoulders → hips visible. Face camera.";
      return;
    }

    drawSafeZone("rgba(0,255,0,1)");

    if (!handsUp || !handsSide) {
      gateOkStreak = 0;

      const w = overlayCanvas.width;
      const h = overlayCanvas.height;

      if (!handsUp) {
        drawArrow(w * 0.5, h * 0.60, w * 0.5, h * 0.30, "rgba(255,255,255,1)");
      }
      if (!handsSide) {
        const y = h * 0.45;
        drawArrow(w * 0.40, y, w * 0.15, y, "rgba(255,255,255,1)");
        drawArrow(w * 0.60, y, w * 0.85, y, "rgba(255,255,255,1)");
      }

      uiInstruction.textContent = !handsUp && !handsSide
        ? "Raise hands UP, then stretch arms to the SIDES."
        : (!handsUp ? "Raise both hands UP." : "Stretch arms to the SIDES.");
      uiInstructionSub.textContent = "We’re confirming you won’t get cropped mid-movement.";
      return;
    }

    gateOkStreak += 1;
    uiInstruction.textContent = `Perfect — hold... (${gateOkStreak}/8)`;
    uiInstructionSub.textContent = "Starting in 3 seconds.";

    if (gateOkStreak >= 8) {
      stopGateLoop();
      await start3sCountdownThenStart();
    }
  }

  async function startGateLoop() {
    stopGateLoop();
    resetGate();
    gateTimer = setInterval(() => {
      gateTick().catch(() => { gateOkStreak = 0; });
    }, 250);
  }

  async function start3sCountdownThenStart() {
    let n = 3;
    countdownOverlay.classList.remove("d-none");
    countdownOverlay.textContent = String(n);

    sfx("start"); // ✅ HOOK: start sound (short “ready” chirp)

    await new Promise((resolve) => {
      const t = setInterval(() => {
        n -= 1;
        if (n <= 0) {
          clearInterval(t);
          countdownOverlay.classList.add("d-none");
          resolve();
          return;
        }
        countdownOverlay.textContent = String(n);
      }, 1000);
    });

    await startSessionInternal();
  }

  async function enterGateMode() {
    uiPhasePill.textContent = "Phase: Setup";
    uiInstruction.textContent = "Framing check started.";
    uiInstructionSub.textContent = "Step back so shoulders → hips are visible.";
    uiFeedback.textContent = "Tracking...";

    btnStart.disabled = true;
    btnStop.disabled = false;
    exerciseSelect.disabled = true;

    if (idleOverlay) idleOverlay.style.display = "none";

    await startCamera();
    syncCanvasToVideo();

    await startGateLoop();
  }

  /* =========================
     EVENTS
  ========================= */
  let audioUnlocked = false;

  btnStart.addEventListener("click", () => {
    if (running) return;

    // Unlock audio on first interaction (needed for autoplay restrictions)
    if (!audioUnlocked) {
      audioUnlocked = true;
      Object.values(SFX).forEach(a => {
        try {
          a.play().then(() => {
            a.pause();
            a.currentTime = 0;
          }).catch(() => {});
        } catch {}
      });
    }

    openGuide();
  });

  btnStop.addEventListener("click", async () => {
    if (running) return stopSession(false);

    // Cancel gate mode
    stopGateLoop();
    stopCamera();
    btnStart.disabled = false;
    btnStop.disabled = true;
    exerciseSelect.disabled = false;

    uiPhasePill.textContent = "Phase: Idle";
    uiInstruction.textContent = "Press Start to begin.";
    uiInstructionSub.textContent = "Warm-up assumed. Use a safe load you can control.";
    if (idleOverlay) idleOverlay.style.display = "flex";
    ovCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);
  });

  btnPrevGuide.addEventListener("click", () => {
    guideIndex = Math.max(0, guideIndex - 1);
    renderGuideStep();
  });

  btnNextGuide.addEventListener("click", () => {
    guideIndex = Math.min(GUIDE_STEPS.length - 1, guideIndex + 1);
    renderGuideStep();
  });

  btnReadyGuide.addEventListener("click", async () => {
    closeGuide();
    await enterGateMode();
  });

  btnCloseGuide.addEventListener("click", closeGuide);
  guideBackdrop.addEventListener("click", closeGuide);

  window.addEventListener("resize", () => {
    if (video.videoWidth && video.videoHeight) syncCanvasToVideo();
  });

  /* =========================
     INIT UI
  ========================= */
  uiReps.textContent = "Reps: —";
  uiState.textContent = "State: —";
  uiConf.textContent = "Conf: —";
  uiFeedback.textContent = "—";
  uiLastRep.textContent = "—";
  uiLogIdMain.textContent = "—";
  uiLogIdSide.textContent = "—";

  uiRepsSide.textContent = "—";
  uiStateSide.textContent = "—";
  uiConfSide.textContent = "—";

  uiInstruction.textContent = "Press Start to begin.";
  uiInstructionSub.textContent = "Warm-up assumed. Use a safe load you can control.";
  uiPhasePill.textContent = "Phase: Idle";
})();