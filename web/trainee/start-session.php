<?php
// liftright/web/trainee/start-session.php
session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['user']);
$page_title = "Start Session (Live)";

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<style>
  /* =========================================================
     FINAL POLISH: responsive, no-scroll start, no fullscreen
     ========================================================= */

  /* Bigger max but still sane */
  .lr-main-wide { max-width: 1760px !important; }

  /* Make the whole screen feel “app-like” (camera is primary) */
  .lr-live-shell{
    min-height: calc(100vh - var(--lr-nav-h, 64px));
    display:flex;
    flex-direction:column;
  }

  /* Sticky top bar (title + Start/Stop) always visible */
  .lr-live-topbar{
    position: sticky;
    top: 0;
    z-index: 1200;
    backdrop-filter: blur(10px);
    background: rgba(2,6,23,.65);
    border: 1px solid rgba(55,65,81,.45);
    border-radius: 1.25rem;
    padding: 14px 14px;
    margin-bottom: 12px;
  }
  .lr-live-topbar h1{ margin:0; }

  /* Layout row stretches so camera can use remaining height */
  .lr-live-row{
    flex: 1 1 auto;
    min-height: 0; /* allows children to scroll properly */
  }

  /* Camera card consumes height, keeps video visible without page scroll */
  .lr-camera-stage{
    height: clamp(360px, 62vh, 760px);
    width: 100%;
  }

  /* On ultra-short screens, keep it usable */
  @media (max-height: 740px){
    .lr-camera-stage{ height: clamp(320px, 56vh, 680px); }
  }

  /* On large desktops, slightly taller camera */
  @media (min-width: 1200px){
    .lr-camera-stage{ height: clamp(420px, 68vh, 820px); }
  }

  /* Make video/canvas fill stage */
  #video{
    height: 100% !important;
    width: 100% !important;
    object-fit: cover;
    border-radius: .75rem;
  }
  #overlayCanvas{
    border-radius: .75rem;
  }

  /* Side rail should be scrollable, not the whole page */
  .lr-rail{
    max-height: calc(100vh - var(--lr-nav-h, 64px) - 120px);
    overflow:auto;
    padding-right: 4px;
  }
  .lr-rail::-webkit-scrollbar{ width: 8px; }
  .lr-rail::-webkit-scrollbar-thumb{
    background: rgba(148,163,184,.35);
    border-radius: 999px;
  }

  /* Mobile: keep Start always accessible */
  @media (max-width: 991.98px){
    .lr-live-topbar{
      border-radius: 1rem;
      padding: 12px;
    }
    .lr-camera-stage{ height: clamp(320px, 52vh, 560px); }
    .lr-rail{
      max-height: none;
      overflow: visible;
    }
  }

  /* ---------- Guide modal / overlays (keep) ---------- */
  .lr-modal-backdrop{
    position:fixed; inset:0; z-index: 2000;
    background: rgba(2,6,23,0.72);
    display:none;
  }
  .lr-modal{
    position:fixed; inset:0; z-index: 2010;
    display:none; align-items:center; justify-content:center;
    padding: 18px;
  }
  .lr-modal-card{
    width: min(980px, 100%);
    border: 1px solid var(--lr-border);
    border-radius: 1.25rem;
    background: linear-gradient(135deg, rgba(17,27,72,0.98), rgba(26,37,93,0.98) 40%, rgba(35,48,109,0.98) 100%);
    box-shadow: 0 18px 60px rgba(15, 23, 42, 0.9);
    overflow:hidden;
  }
  .lr-modal-head{
    padding: 14px 18px;
    border-bottom: 1px solid rgba(55, 65, 81, 0.7);
    display:flex; align-items:center; justify-content:space-between; gap:12px;
  }
  .lr-modal-body{ padding: 16px 18px 18px; }
  .lr-steps{
    display:grid;
    grid-template-columns: 1.25fr 0.9fr;
    gap: 14px;
  }
  @media (max-width: 992px){
    .lr-steps{ grid-template-columns: 1fr; }
  }
  .lr-step-card{
    border: 1px solid var(--lr-border);
    border-radius: 1rem;
    background: rgba(15,23,42,0.55);
    padding: 14px;
  }
  .lr-step-kicker{
    font-size: .75rem;
    letter-spacing: .16em;
    text-transform: uppercase;
    color: var(--lr-text-muted);
    font-weight: 600;
    margin-bottom: 8px;
  }
  .lr-step-title{ font-size: 1.15rem; font-weight: 800; margin: 0 0 8px; }
  .lr-step-text{ color: var(--lr-text-muted); margin: 0; line-height: 1.45; }
  .lr-mini-pill{
    display:inline-flex; align-items:center; gap:8px;
    border: 1px solid var(--lr-border);
    border-radius: 999px;
    padding: .25rem .6rem;
    font-size: .8rem;
    color: var(--lr-text);
    background: rgba(2,6,23,0.35);
  }
  .lr-countdown-wrap{
    display:flex; align-items:center; justify-content:space-between; gap:12px; flex-wrap:wrap;
    padding-top: 10px;
  }
  .lr-countdown{
    font-weight: 900;
    font-size: 1.25rem;
    letter-spacing: .08em;
  }

  /* ---------- In-camera instruction tag ---------- */
  .lr-instructions-bar{
    position:absolute;
    top: 56px;
    left: 12px;
    right: 12px;
    z-index: 10;
    pointer-events:none;
  }
  .lr-instructions-inner{
    display:flex; align-items:center; justify-content:space-between; gap:10px;
    padding: 10px 12px;
    border-radius: .85rem;
    border: 1px solid var(--lr-border);
    background: rgba(15,23,42,0.68);
    backdrop-filter: blur(6px);
  }
  .lr-instructions-text{
    font-weight: 900;
    font-size: 1.08rem;
    letter-spacing: .02em;
    line-height: 1.2;
    margin: 0;
    min-width:0;
    white-space:nowrap;
    overflow:hidden;
    text-overflow:ellipsis;
  }
  .lr-instructions-sub{
    font-size: .8rem;
    color: var(--lr-text-muted);
    margin: 0;
    white-space:nowrap;
    overflow:hidden;
    text-overflow:ellipsis;
  }

  /* ---------- Idle overlay ---------- */
  .lr-idle-overlay{
    position:absolute; inset:0;
    display:flex; align-items:center; justify-content:center;
    padding: 18px;
    z-index: 8;
    pointer-events:none;
  }
  .lr-idle-card{
    width:min(560px, 100%);
    border: 1px solid var(--lr-border);
    border-radius: 1.25rem;
    background: rgba(2,6,23,0.55);
    backdrop-filter: blur(6px);
    padding: 14px 16px;
    text-align:left;
  }

  /* Micro polish: make Start primary visually */
  .lr-btn-group .btn{ white-space:nowrap; }
</style>

<div class="lr-page-wrapper">
  <div class="container-fluid lr-main-container py-3 lr-main-wide lr-live-shell">

    <!-- Sticky topbar: Start/Stop always visible (no scroll needed) -->
    <div class="lr-live-topbar">
      <div class="row g-2 align-items-center">
        <div class="col-lg-8">
          <div class="lr-section-title mb-1">Live Session</div>
          <h1 class="lr-section-heading mb-1">Webcam Posture Assessment</h1>
          <p class="lr-stat-subtext mb-0">Uses your real model pipeline via a local Python service.</p>
        </div>

        <div class="col-lg-4">
          <div class="d-flex gap-2 justify-content-lg-end lr-btn-group">
            <button id="btnStart" class="btn btn-primary btn-lg">Start</button>
            <button id="btnStop" class="btn btn-outline-light btn-lg" disabled>Stop</button>
          </div>
          <div class="lr-stat-subtext mt-2 text-lg-end" style="opacity:.9;">
            Tip: Make sure shoulders → hips are visible before starting.
          </div>
        </div>
      </div>
    </div>

    <div class="row g-4 lr-live-row">

      <!-- LEFT: BIG CAMERA -->
      <div class="col-lg-9">
        <div class="lr-card" id="cameraCard">
          <div class="lr-card-header d-flex justify-content-between align-items-center">
            <div>
              <div class="lr-section-title mb-1">Camera</div>
              <div class="lr-section-heading mb-0">Live feed</div>
            </div>

            <!-- removed fullscreen -->
            <span class="lr-mini-pill">Webcam mode</span>
          </div>

          <div class="lr-card-body">
            <div class="position-relative lr-camera-stage">

              <video id="video" autoplay playsinline class="w-100"
                     style="background:#000; transform: scaleX(-1);"></video>

              <canvas id="overlayCanvas"
                      class="position-absolute top-0 start-0 w-100 h-100"
                      style="pointer-events:none;"></canvas>

              <div class="lr-idle-overlay" id="idleOverlay">
                <div class="lr-idle-card">
                  <div class="lr-section-title mb-1">Before you start</div>
                  <div class="fw-bold" style="font-size:1.1rem; line-height:1.2;">
                    Stand back so your shoulders to hips are visible.
                  </div>
                  <div class="lr-stat-subtext mt-2 mb-0">
                    Press <strong>Start</strong> to view a quick setup guide + a 5-second countdown.
                  </div>
                </div>
              </div>

              <!-- Badges -->
              <div class="position-absolute top-0 start-0 p-3 w-100" style="z-index: 12;">
                <div class="d-flex flex-wrap gap-2">
                  <span class="lr-badge lr-badge-good" id="uiReps">Reps: —</span>
                  <span class="lr-badge lr-badge-warning" id="uiState">State: —</span>
                  <span class="lr-badge lr-badge-warning" id="uiConf">Conf: —</span>
                </div>
              </div>

              <!-- Instruction bar -->
              <div class="lr-instructions-bar" aria-live="polite">
                <div class="lr-instructions-inner">
                  <div style="min-width:0;">
                    <p class="lr-instructions-text mb-0" id="uiInstruction">Press Start to begin.</p>
                    <p class="lr-instructions-sub mb-0" id="uiInstructionSub">Warm-up assumed. Use a safe load you can control.</p>
                    <p class="lr-instructions-sub mb-0" id="uiDebugLine" style="opacity:.75;">state: — | phase: — | conf: —</p>
                  </div>
                  <span class="lr-mini-pill" id="uiPhasePill">Phase: Idle</span>
                </div>
              </div>

              <!-- Feedback -->
              <div class="position-absolute bottom-0 start-0 p-3 w-100" style="z-index: 12;">
                <div class="p-3 rounded-3"
                     style="border:1px solid var(--lr-border);
                            background: rgba(15,23,42,0.78);
                            backdrop-filter: blur(6px);">
                  <div class="d-flex justify-content-between align-items-start gap-3">
                    <div style="min-width: 0;">
                      <div class="lr-section-title mb-1">Feedback</div>
                      <div class="fw-bold" id="uiFeedback" style="font-size: 1.35rem; line-height: 1.2;">—</div>
                      <div class="mt-2" id="uiLastRep" style="font-size: 1.05rem; opacity: .95;">—</div>
                    </div>
                    <div class="text-end lr-stat-subtext" style="min-width: 180px;">
                      <div><strong>Exercise:</strong> <span id="uiExerciseMain">bicep_curl</span></div>
                      <div><strong>Log:</strong> <span id="uiLogIdMain">—</span></div>
                    </div>
                  </div>
                </div>
              </div>

            </div>

            <canvas id="captureCanvas" class="d-none"></canvas>
          </div>
        </div>
      </div>

      <!-- RIGHT: STATUS RAIL (scrolls independently if needed) -->
      <div class="col-lg-3">
        <div class="lr-rail">

          <div class="lr-card mb-3">
            <div class="lr-card-header">
              <div class="lr-section-title mb-1">Session Setup</div>
              <div class="lr-section-heading mb-0">Choose exercise</div>
            </div>
            <div class="lr-card-body">
              <label class="lr-stat-subtext mb-2" for="exerciseSelect">
                Select an exercise before pressing <strong>Start</strong>.
              </label>

              <select id="exerciseSelect" class="form-select form-select-lg">
                <option value="bicep_curl" selected>Bicep Curl</option>
                <option value="shoulder_press">Shoulder Press</option>
                <option value="lateral_raise">Lateral Raise</option>
              </select>

              <details class="mt-3">
                <summary class="lr-stat-subtext" style="cursor:pointer;">Quick positioning guide (tap to expand)</summary>
                <div class="mt-2 lr-stat-subtext">
                  <ul class="mb-0" style="padding-left: 1.15rem;">
                    <li>Camera at chest height (laptop/webcam is fine).</li>
                    <li>Stand 1.5–2.5 meters back (see shoulders → hips).</li>
                    <li>Face the camera. Keep lighting bright and even.</li>
                    <li>Minimize background movement for best tracking.</li>
                  </ul>
                </div>
              </details>
            </div>
          </div>

          <div class="lr-card mb-3">
            <div class="lr-card-header">
              <div class="lr-section-title mb-1">Safety</div>
              <div class="lr-section-heading mb-0">Read before using</div>
            </div>
            <div class="lr-card-body">
              <div class="lr-stat-subtext mb-2">This tool provides posture feedback, but it is <strong>not</strong> medical advice.</div>
              <details>
                <summary class="lr-stat-subtext" style="cursor:pointer;">Warnings & assumptions (tap to expand)</summary>
                <div class="mt-2 lr-stat-subtext">
                  <ul class="mb-0" style="padding-left: 1.15rem;">
                    <li><strong>Warm-up assumed:</strong> you already warmed up properly.</li>
                    <li><strong>Use safe loads:</strong> choose a manageable weight you can control.</li>
                    <li><strong>Pain = stop:</strong> stop if you feel pain, dizziness, or numbness.</li>
                    <li><strong>Fatigue flag:</strong> if “STOP recommended” appears, rest or reduce weight.</li>
                    <li><strong>Environment:</strong> stable footing + enough space around you.</li>
                  </ul>
                </div>
              </details>
            </div>
          </div>

          <div class="lr-card mb-3">
            <div class="lr-card-header">
              <div class="lr-section-title mb-1">Live Status</div>
              <div class="lr-section-heading mb-0">Session overview</div>
            </div>

            <div class="lr-card-body d-grid gap-3">
              <div>
                <div class="lr-stat-label">Exercise</div>
                <div class="fs-5 fw-semibold text-capitalize" id="uiExerciseSide">bicep_curl</div>
              </div>

              <div class="row g-2">
                <div class="col-6">
                  <div class="lr-stat-label">Reps</div>
                  <div class="fs-4 fw-bold" id="uiRepsSide">—</div>
                </div>
                <div class="col-6">
                  <div class="lr-stat-label">Confidence</div>
                  <div class="fs-5 fw-semibold" id="uiConfSide">—</div>
                </div>
              </div>

              <div>
                <div class="lr-stat-label">State</div>
                <div id="uiStateSide" class="fs-6 fw-semibold">—</div>
              </div>

              <hr class="my-2">

              <div class="lr-stat-subtext"><strong>Mode:</strong> Webcam</div>
              <div class="lr-stat-subtext"><strong>Session Log ID:</strong> <span id="uiLogIdSide">—</span></div>
            </div>
          </div>

        </div><!-- /lr-rail -->
      </div>
    </div>

  </div>
</div>

<!-- ---------- Setup / Guide Modal ---------- -->
<div class="lr-modal-backdrop" id="guideBackdrop"></div>
<div class="lr-modal" id="guideModal" role="dialog" aria-modal="true" aria-labelledby="guideTitle">
  <div class="lr-modal-card">
    <div class="lr-modal-head">
      <div>
        <div class="lr-section-title mb-1">Pre-exercise setup</div>
        <div class="lr-section-heading mb-0" id="guideTitle">Quick guide + countdown</div>
      </div>
      <button class="btn btn-outline-light btn-sm" id="btnCloseGuide" type="button">Close</button>
    </div>

    <div class="lr-modal-body">
      <div class="lr-steps">
        <div class="lr-step-card">
          <div class="lr-step-kicker">Step <span id="guideStepNum">1</span> / 3</div>
          <h3 class="lr-step-title" id="guideStepTitle">Position & framing</h3>
          <p class="lr-step-text" id="guideStepText">
            Stand back until your shoulders to hips are visible. Face the camera and keep lighting bright.
          </p>
        </div>

        <div class="lr-step-card">
          <div class="lr-step-kicker">Selected exercise</div>
          <div class="d-flex align-items-center justify-content-between gap-2 flex-wrap">
            <div class="fw-bold" style="font-size:1.05rem;">
              <span id="guideExerciseText">bicep_curl</span>
            </div>
            <span class="lr-mini-pill" id="guideWarmupPill">Warm-up assumed</span>
          </div>

          <div class="mt-3 lr-stat-subtext">
            <strong>Reminder:</strong> stop if you feel pain. Use a safe load you can control.
          </div>

          <div class="lr-countdown-wrap">
            <div class="lr-countdown" id="guideCountdown">Countdown: —</div>
            <div class="d-flex gap-2">
              <button class="btn btn-outline-light" id="btnPrevGuide" type="button">Back</button>
              <button class="btn btn-primary" id="btnNextGuide" type="button">Next</button>
              <button class="btn btn-success" id="btnReadyGuide" type="button" style="display:none;">
                I'm ready → Start (5s)
              </button>
            </div>
          </div>

          <div class="mt-3 lr-stat-subtext" id="guideHintLine">
            Tip: keep elbows/wrists visible and avoid other people walking behind you.
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
(() => {
  const API_URL = "../api/session_process.php";
  const SESSION_VIEW_URL = "../trainee/session-view.php?log_id=";

  const btnStart = document.getElementById("btnStart");
  const btnStop  = document.getElementById("btnStop");
  const exerciseSelect = document.getElementById("exerciseSelect");

  const video = document.getElementById("video");
  const captureCanvas = document.getElementById("captureCanvas");
  const overlayCanvas = document.getElementById("overlayCanvas");

  const capCtx = captureCanvas.getContext("2d");
  const ovCtx  = overlayCanvas.getContext("2d");

  // Main overlay (camera)
  const uiReps = document.getElementById("uiReps");
  const uiState = document.getElementById("uiState");
  const uiConf = document.getElementById("uiConf");
  const uiFeedback = document.getElementById("uiFeedback");
  const uiLastRep = document.getElementById("uiLastRep");
  const uiExerciseMain = document.getElementById("uiExerciseMain");
  const uiLogIdMain = document.getElementById("uiLogIdMain");
  const idleOverlay = document.getElementById("idleOverlay");

  // Side panel
  const uiRepsSide = document.getElementById("uiRepsSide");
  const uiStateSide = document.getElementById("uiStateSide");
  const uiConfSide = document.getElementById("uiConfSide");
  const uiExerciseSide = document.getElementById("uiExerciseSide");
  const uiLogIdSide = document.getElementById("uiLogIdSide");

  // Instruction overlays
  const uiInstruction = document.getElementById("uiInstruction");
  const uiInstructionSub = document.getElementById("uiInstructionSub");
  const uiPhasePill = document.getElementById("uiPhasePill");
  const uiDebugLine = document.getElementById("uiDebugLine");

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

  let stream = null;
  let loopTimer = null;
  let inflight = false;

  let logId = 0;
  let sessionToken = "";
  let running = false;

  let loopRunning = false;

  async function loop() {
    if (!loopRunning) return;
    await tick();                 // tick already respects inflight
    setTimeout(loop, 16);          // backpressure; won’t stack calls
  }

  function startLoop() {
    if (loopRunning) return;
    loopRunning = true;
    loop();
  }

  function stopLoop() {
    loopRunning = false;
  }

  const annotatedImg = new Image();
  let annotatedBusy = false;

  const VARIANTS = {
    raise: ["RAISE the weight (up phase).", "Go UP — controlled lift.", "Bring it UP smoothly."],
    lower: ["LOWER the weight (down phase).", "Go DOWN — slow and controlled.", "Bring it DOWN steadily."],
    stop: ["STOP recommended — rest or reduce weight.", "High fatigue detected — stop and recover.", "Stop now — reset form and breathe."],
    lowconf: ["Tracking low — step back and face camera.", "Low confidence — improve lighting / distance.", "Reposition: keep shoulders→hips visible."]
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

  function setBadge(el, text, kind) {
    el.textContent = text;
    el.classList.remove("lr-badge-good","lr-badge-warning","lr-badge-bad","lr-badge-danger");
    if (kind === "good") el.classList.add("lr-badge-good");
    else if (kind === "bad" || kind === "danger") el.classList.add("lr-badge-danger");
    else el.classList.add("lr-badge-warning");
  }

  async function api(action, payload) {
    const res = await fetch(API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action, ...payload })
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.message || "API error");
    return data;
  }

  function syncCanvasToVideo() {
    const vw = video.videoWidth || 1280;
    const vh = video.videoHeight || 720;

    // Overlay matches real video resolution (for correct drawing)
    if (overlayCanvas.width !== vw || overlayCanvas.height !== vh) {
      overlayCanvas.width = vw;
      overlayCanvas.height = vh;
    }

    // Capture canvas = smaller inference resolution (BIG perf win)
    const TARGET_W = 640; // try 512 if you want even faster
    const scale = Math.min(1, TARGET_W / vw);
    const cw = Math.round(vw * scale);
    const ch = Math.round(vh * scale);

    if (captureCanvas.width !== cw || captureCanvas.height !== ch) {
      captureCanvas.width = cw;
      captureCanvas.height = ch;
    }
  }

  async function startCamera() {
    stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: "user" },
      audio: false
    });
    video.srcObject = stream;
    await video.play();

    syncCanvasToVideo();
    video.onloadedmetadata = () => syncCanvasToVideo();

    // annotated drawn on overlay
    video.style.visibility = "visible";
  }

  function stopCamera() {
    if (stream) {
      for (const t of stream.getTracks()) t.stop();
      stream = null;
    }
    video.srcObject = null;
    video.style.visibility = "visible";
  }

  function drawAnnotatedToOverlay(dataurl) {
    if (!dataurl || annotatedBusy) return;
    annotatedBusy = true;
    annotatedImg.onload = () => {
      ovCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);
      ovCtx.drawImage(annotatedImg, 0, 0, overlayCanvas.width, overlayCanvas.height);
      annotatedBusy = false;
    };
    annotatedImg.onerror = () => { annotatedBusy = false; };
    annotatedImg.src = dataurl;
  }

  let lastKnownPhase = "raise";
  let lastSeenRepNow = null;

  function normalizeState(raw) {
    const s = String(raw ?? "").toLowerCase().trim();
    if (["up","raise","raising","concentric","lift","lifting"].includes(s)) return "up";
    if (["down","lower","lowering","eccentric","drop","descending"].includes(s)) return "down";
    if (s.includes("up") || s.includes("raise")) return "up";
    if (s.includes("down") || s.includes("lower")) return "down";
    return "";
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

    if (typeof conf === "number" && conf < 0.55) {
      uiInstruction.textContent = pickVariantSticky("lowconf", repNow);
      uiInstructionSub.textContent = "Adjust lighting/distance. Keep shoulders→hips visible.";
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

    if (stateNorm === "down") {
      lastKnownPhase = "raise";
      uiInstruction.textContent = pickVariantSticky("raise", repNow);
      uiInstructionSub.textContent = "Lift smoothly (no jerking).";
      return;
    }
    if (stateNorm === "up") {
      lastKnownPhase = "lower";
      uiInstruction.textContent = pickVariantSticky("lower", repNow);
      uiInstructionSub.textContent = "Control the descent (don't drop).";
      return;
    }

    const repNum = toRepNum(repNow);
    if (repNum !== null) {
      if (lastSeenRepNow !== null && repNum > lastSeenRepNow) lastKnownPhase = "raise";
      lastSeenRepNow = repNum;
    }

    if (lastKnownPhase === "raise") {
      uiInstruction.textContent = pickVariantSticky("raise", repNow);
      uiInstructionSub.textContent = "Lift smoothly (no jerking).";
    } else {
      uiInstruction.textContent = pickVariantSticky("lower", repNow);
      uiInstructionSub.textContent = "Control the descent (don't drop).";
    }
  }

  function canvasToJpegBase64(canvas, quality = 0.5) {
    return new Promise((resolve, reject) => {
      canvas.toBlob((blob) => {
        if (!blob) return reject(new Error("toBlob failed"));
        const r = new FileReader();
        r.onloadend = () => resolve(r.result); // data:image/jpeg;base64,...
        r.onerror = () => reject(new Error("FileReader failed"));
        r.readAsDataURL(blob);
      }, "image/jpeg", quality);
    });
  }

  async function tick() {
    if (!running || inflight) return;
    if (!video.videoWidth || !video.videoHeight) return;

    inflight = true;
    try {
      // inside tick():
      capCtx.drawImage(video, 0, 0, captureCanvas.width, captureCanvas.height);
      const frameDataUrl = await canvasToJpegBase64(captureCanvas, 0.5);

      const resp = await api("frame", {
        log_id: logId,
        session_token: sessionToken,
        frame_dataurl: frameDataUrl
      });

      const annotated = resp.annotated_frame_dataurl;
      const status = resp.status || {};

      drawAnnotatedToOverlay(annotated);

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

      setInstructionsFromStatus(status);

      if (String(state).toLowerCase() === "stop") {
        await stopSession(true);
      }
    } catch (e) {
      uiFeedback.textContent = `Error: ${e.message}`;
      uiInstruction.textContent = "Service error — check Python server.";
      uiInstructionSub.textContent = "Restart the python service and refresh if needed.";
      setBadge(uiState, "State: error", "danger");
      uiStateSide.textContent = "error";
    } finally {
      inflight = false;
    }
  }

  async function startSessionInternal() {
    if (running) return;
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
    lastSeenRepNow = null;
    stickyPhrase = "";
    stickyKey = "";
    stickyRep = null;

    uiInstruction.textContent = pickVariantSticky("raise", null);
    uiInstructionSub.textContent = "Warm-up assumed. Use a safe load you can control.";
    uiPhasePill.textContent = "Phase: tracking";

    startLoop();
  }

  function goToSessionView(logIdToOpen) {
    if (!logIdToOpen || logIdToOpen <= 0) return;
    window.location.href = SESSION_VIEW_URL + encodeURIComponent(String(logIdToOpen));
  }

  async function stopSession(fromAutoStop=false) {
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
      uiInstructionSub.textContent = "Refresh the page and try again if needed.";
    } finally {
      sessionToken = "";
      logId = 0;

      uiLogIdMain.textContent = "—";
      uiLogIdSide.textContent = "—";

      if (idleOverlay) idleOverlay.style.display = "flex";
    }
  }

  /* ---------------- Guide modal logic ---------------- */
  const GUIDE_STEPS = [
    { title: "Position & framing", text: "Stand back until your shoulders to hips are visible. Face the camera. Keep lighting bright and even.", hint: "Avoid strong backlight (window behind you)." },
    { title: "Starting posture", text: "Begin in the exercise's neutral start position. Keep the weight controlled throughout the movement.", hint: "Keep elbows/wrists visible in frame." },
    { title: "Warm-up & safety", text: "Warm-up is assumed. Use a manageable load. Stop if you feel pain or if STOP is recommended.", hint: "If STOP appears, rest or reduce weight before continuing." }
  ];

  let guideIndex = 0;
  let countdownTimer = null;
  let countdownLeft = 0;

  function openGuide() {
    guideIndex = 0;
    guideExerciseText.textContent = exerciseSelect.value;

    guideCountdown.textContent = "Countdown: —";
    btnReadyGuide.style.display = "none";
    btnNextGuide.style.display = "";
    btnPrevGuide.disabled = true;

    renderGuideStep();

    guideBackdrop.style.display = "block";
    guideModal.style.display = "flex";
  }

  function closeGuide() {
    if (countdownTimer) {
      clearInterval(countdownTimer);
      countdownTimer = null;
    }
    guideBackdrop.style.display = "none";
    guideModal.style.display = "none";
  }

  function renderGuideStep() {
    const s = GUIDE_STEPS[guideIndex];
    guideStepNum.textContent = String(guideIndex + 1);
    guideStepTitle.textContent = s.title;
    guideStepText.textContent = s.text;
    guideHintLine.textContent = s.hint;

    btnPrevGuide.disabled = (guideIndex === 0);

    const last = (guideIndex === GUIDE_STEPS.length - 1);
    btnNextGuide.style.display = last ? "none" : "";
    btnReadyGuide.style.display = last ? "" : "none";
  }

  function startCountdownAndGo() {
    countdownLeft = 5;
    guideCountdown.textContent = `Countdown: ${countdownLeft}s`;
    btnReadyGuide.disabled = true;
    btnPrevGuide.disabled = true;
    btnCloseGuide.disabled = true;

    countdownTimer = setInterval(async () => {
      countdownLeft -= 1;
      if (countdownLeft <= 0) {
        clearInterval(countdownTimer);
        countdownTimer = null;
        guideCountdown.textContent = "Countdown: GO!";
        closeGuide();
        await startSessionInternal();
        btnReadyGuide.disabled = false;
        btnCloseGuide.disabled = false;
        return;
      }
      guideCountdown.textContent = `Countdown: ${countdownLeft}s`;
    }, 1000);
  }

  btnPrevGuide.addEventListener("click", () => {
    guideIndex = Math.max(0, guideIndex - 1);
    renderGuideStep();
  });
  btnNextGuide.addEventListener("click", () => {
    guideIndex = Math.min(GUIDE_STEPS.length - 1, guideIndex + 1);
    renderGuideStep();
  });
  btnReadyGuide.addEventListener("click", startCountdownAndGo);
  btnCloseGuide.addEventListener("click", closeGuide);
  guideBackdrop.addEventListener("click", closeGuide);

  btnStart.addEventListener("click", () => {
    if (running) return;
    openGuide();
  });

  btnStop.addEventListener("click", () => stopSession(false));

  // Initial UI
  uiReps.textContent = "Reps: —";
  uiState.textContent = "State: —";
  uiConf.textContent = "Conf: —";
  uiFeedback.textContent = "—";
  uiLastRep.textContent = "—";

  uiRepsSide.textContent = "—";
  uiStateSide.textContent = "—";
  uiConfSide.textContent = "—";
  uiLogIdMain.textContent = "—";
  uiLogIdSide.textContent = "—";

  uiInstruction.textContent = "Press Start to begin.";
  uiInstructionSub.textContent = "Warm-up assumed. Use a safe load you can control.";
  uiPhasePill.textContent = "Phase: Idle";

  window.addEventListener("resize", () => {
    if (video.videoWidth && video.videoHeight) syncCanvasToVideo();
  });
})();
</script>

<?php require __DIR__ . '/../includes/footer.php'; ?>