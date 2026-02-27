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
          <div class="lr-stat-subtext mt-2 text-lg-end">
            Tip: Make sure shoulders → hips are visible before starting.
          </div>
        </div>
      </div>
    </div>

  <div class="row g-4 lr-live-row lr-live-grid">

    <!-- LEFT: OVERLAYS / COACHING INFO -->
    <div class="col-12 col-lg-3 order-2 order-lg-1">
      <div class="lr-left-stack">

        <!-- Badges + phase -->
        <div class="lr-card mb-3">
          <div class="lr-card-header d-flex justify-content-between align-items-center">
            <div>
              <div class="lr-section-title mb-1">Live Coaching</div>
              <div class="lr-section-heading mb-0">Overlays</div>
            </div>
            <span class="lr-mini-pill" id="uiPhasePill">Phase: Idle</span>
          </div>

          <div class="lr-card-body">
            <div class="d-flex flex-wrap gap-2 mb-3">
              <span class="lr-badge lr-badge-good" id="uiReps">Reps: —</span>
              <span class="lr-badge lr-badge-warning" id="uiState">State: —</span>
              <span class="lr-badge lr-badge-warning" id="uiConf">Conf: —</span>
            </div>

            <div class="lr-instruction-box">
              <div class="lr-section-title mb-1">Instruction</div>
              <div class="fw-bold" style="font-size:1.1rem; line-height:1.2;" id="uiInstruction">
                Press Start to begin.
              </div>
              <div class="lr-stat-subtext mt-2 mb-0" id="uiInstructionSub">
                Warm-up assumed. Use a safe load you can control.
              </div>
              <div class="lr-stat-subtext mt-2 mb-0" id="uiDebugLine">
                state: — | phase: — | conf: —
              </div>
            </div>
          </div>
        </div>

        <!-- Feedback (moved from bottom overlay) -->
        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Feedback</div>
            <div class="lr-section-heading mb-0">What to do now</div>
          </div>
          <div class="lr-card-body">
            <div class="fw-bold" id="uiFeedback" style="font-size: 1.35rem; line-height: 1.2;">—</div>
            <div class="mt-2" id="uiLastRep" style="font-size: 1.05rem; opacity: .95;">—</div>

            <hr class="my-3">

            <div class="lr-stat-subtext">
              <div><strong>Exercise:</strong> <span id="uiExerciseMain">bicep_curl</span></div>
              <div><strong>Log:</strong> <span id="uiLogIdMain">—</span></div>
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- MIDDLE: CAMERA (CENTERED) -->
    <div class="col-12 col-lg-6 order-1 order-lg-2">
      <div class="lr-card" id="cameraCard">
        <div class="lr-card-header d-flex justify-content-between align-items-center">
          <div>
            <div class="lr-section-title mb-1">Camera</div>
            <div class="lr-section-heading mb-0">Live feed</div>
          </div>
          <span class="lr-mini-pill">Webcam mode</span>
        </div>

        <div class="lr-card-body">
          <div class="position-relative lr-camera-stage lr-camera-center">
            <!-- VIDEO ONLY -->
            <video id="video" autoplay playsinline class="w-100"
                style="transform: scaleX(-1);"></video>

            <!-- OVERLAY CANVAS ONLY -->
            <canvas id="overlayCanvas"
                    class="position-absolute top-0 start-0 w-100 h-100"
                    style="pointer-events:none;"></canvas>

            <!-- Big countdown overlay (3..2..1) -->
            <div id="countdownOverlay"
                class="position-absolute top-0 start-0 w-100 h-100 d-none"
                style="pointer-events:none; display:flex; align-items:center; justify-content:center;
                        background: rgba(0,0,0,.35); font-weight:800; font-size: clamp(64px, 10vw, 140px);
                        color:#fff; text-shadow: 0 8px 30px rgba(0,0,0,.55);">
            </div>

            <!-- Idle overlay stays on camera -->
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
          </div>

          <canvas id="captureCanvas" class="d-none"></canvas>
        </div>
      </div>
    </div>

    <!-- RIGHT: STATUS RAIL (UNCHANGED) -->
    <div class="col-12 col-lg-3 order-3 order-lg-3">
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

  const countdownOverlay = document.getElementById("countdownOverlay");
  
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
  {
    title: "Position & framing",
    text: "Stand back until your shoulders to hips are visible. Face the camera. Keep lighting bright and even.",
    hint: "Avoid strong backlight (window behind you)."
  },
  {
    title: "Quick guide (GIF placeholders)",
    text: "Soon: this step will show GIFs of proper vs improper form. For now, keep elbows/wrists visible and move smoothly.",
    hint: "Tip: keep wrists visible at all times."
  },
  {
    title: "Camera check (required)",
    text: "Next, we’ll run a framing check ON the live camera screen. Follow prompts to ensure your upper body is fully visible.",
    hint: "If tracking is low: step back, face camera, increase lighting."
  }
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
    stopGateLoop();
    resetGate();

    if (!running) {
      // We were only previewing
      stopCamera();
      if (idleOverlay) idleOverlay.style.display = "flex";
      ovCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);
    }

    if (countdownTimer) {
      clearInterval(countdownTimer);
      countdownTimer = null;
    }
    guideBackdrop.style.display = "none";
    guideModal.style.display = "none";
  }

  let gateTimer = null;
let gateOkStreak = 0;

// We confirm:
// 1) upper body landmarks are visible (frame_ok from server)
// 2) over a few seconds, wrists have reached:
let gateMemory = { minY: 1.0, minX: 1.0, maxX: 0.0 }; // normalized coords
let gateLastMsg = "";

function resetGate() {
  gateOkStreak = 0;
  gateMemory = { minY: 1.0, minX: 1.0, maxX: 0.0 };
  gateLastMsg = "";
}

function stopGateLoop() {
  if (gateTimer) {
    clearInterval(gateTimer);
    gateTimer = null;
  }
}

function updateGateMemory(gate) {
  const w = gate?.wrist;
  if (!w) return;
  if (typeof w.min_y === "number") gateMemory.minY = Math.min(gateMemory.minY, w.min_y);
  if (typeof w.min_x === "number") gateMemory.minX = Math.min(gateMemory.minX, w.min_x);
  if (typeof w.max_x === "number") gateMemory.maxX = Math.max(gateMemory.maxX, w.max_x);
}

// These are the “hands up” + “hands to side” targets (tweak if needed)
function gateHandsUpOk() {
  return gateMemory.minY <= 0.12;     // wrists reached near top
}
function gateHandsSideOk() {
  return gateMemory.minX <= 0.10 && gateMemory.maxX >= 0.90; // wrists reached near left/right edges
}

async function gateTick() {
  if (!video.videoWidth || !video.videoHeight) return;

  // Capture frame
  capCtx.drawImage(video, 0, 0, captureCanvas.width, captureCanvas.height);
  const frameDataUrl = await canvasToJpegBase64(captureCanvas, 0.5);

  // Ask backend to evaluate landmarks
  const resp = await api("gate", { frame_dataurl: frameDataUrl });
  const ok = !!resp.ok;
  const g = resp.gate || {};

  if (!ok) {
    gateOkStreak = 0;
    guideCountdown.textContent = "Framing check: Python gate error";
    uiInstruction.textContent = "Service error — check Python server.";
    uiInstructionSub.textContent = "Make sure realtime_server.py is running on port 5101.";
    return;
  }

  if (!g.pose_found) {
    gateOkStreak = 0;
    guideCountdown.textContent = "Framing check: No person detected (step into view)";
    uiInstruction.textContent = "Step into view and face the camera.";
    uiInstructionSub.textContent = "Better lighting helps. Avoid backlight.";
    return;
  }

  // Update memory for “hands up” and “hands to side”
  updateGateMemory(g);

  const frameOk = !!g.frame_ok;
  const handsUp = gateHandsUpOk();
  const handsSide = gateHandsSideOk();

  // Build a readable status line
  const parts = g.parts || {};
  const missing = [];
  if (!parts.shoulders) missing.push("shoulders");
  if (!parts.hips) missing.push("hips");
  if (!parts.elbows) missing.push("elbows");
  if (!parts.wrists) missing.push("wrists");

  if (!frameOk) {
    gateOkStreak = 0;
    guideCountdown.textContent = `Framing check: Adjust (${missing.length ? "missing " + missing.join(", ") : "reposition"})`;
    uiInstruction.textContent = "Please create distance from the camera.";
    uiInstructionSub.textContent = "Keep shoulders → hips visible. Face camera. Improve lighting if needed.";
    return;
  }

  // Frame is OK; now require the motion checks (up + sides)
  if (!handsUp || !handsSide) {
    gateOkStreak = 0;

    const todo = [];
    if (!handsUp) todo.push("raise both hands UP");
    if (!handsSide) todo.push("stretch arms to the SIDES");
    const msg = `Do this: ${todo.join(" + ")} (don’t leave frame)`;

    guideCountdown.textContent = `Framing check: OK • ${handsUp ? "UP✓" : "UP…"} • ${handsSide ? "SIDE✓" : "SIDE…"}`;
    uiInstruction.textContent = msg;
    uiInstructionSub.textContent = "We’re confirming you won’t get cropped during movement.";
    return;
  }

  // Everything OK — require a short streak to avoid false positives
  gateOkStreak += 1;
  guideCountdown.textContent = `Framing check: CONFIRMED ✓ (${gateOkStreak}/8)`;
  uiInstruction.textContent = "Perfect — hold for a moment…";
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
    gateTick().catch(() => {
      gateOkStreak = 0;
    });
  }, 250); // ~4 FPS
}

// Visible 3..2..1 overlay, then starts real session
async function start3sCountdownThenStart() {
  let n = 3;
  if (countdownOverlay) {
    countdownOverlay.classList.remove("d-none");
    countdownOverlay.textContent = String(n);
  }

  guideCountdown.textContent = "Countdown: 3";
  // Placeholder for audio cues later:
  // const beep = document.getElementById("audioBeep"); beep?.play();

  await new Promise((resolve) => {
    const t = setInterval(() => {
      n -= 1;
      if (n <= 0) {
        clearInterval(t);
        guideCountdown.textContent = "Countdown: GO!";
        if (countdownOverlay) countdownOverlay.classList.add("d-none");
        resolve();
        return;
      }
      guideCountdown.textContent = `Countdown: ${n}`;
      if (countdownOverlay) countdownOverlay.textContent = String(n);
    }, 1000);
  });

  closeGuide();
  await startSessionInternal(); // existing function (creates log + session + starts /frame loop)
}

  function renderGuideStep() {
    const s = GUIDE_STEPS[guideIndex];
    guideStepNum.textContent = String(guideIndex + 1);
    guideStepTitle.textContent = s.title;
    guideStepText.textContent = s.text;
    guideHintLine.textContent = s.hint;

    btnPrevGuide.disabled = (guideIndex === 0);

    const last = (guideIndex === GUIDE_STEPS.length - 1);

    // We no longer use the old "I'm ready → Start (5s)" button for last step.
    // The gate will auto-confirm then do a 3..2..1 overlay.
    btnNextGuide.style.display = last ? "none" : "";
    btnReadyGuide.style.display = "none";

    if (last) {
      btnReadyGuide.style.display = "";
      btnReadyGuide.textContent = "Start Camera Check";
    } else {
      btnReadyGuide.style.display = "none";
    }
  }

  async function enterGateMode() {
  if (running) return;

  // UI state
  uiPhasePill.textContent = "Phase: Setup";
  uiInstruction.textContent = "Framing check started.";
  uiInstructionSub.textContent = "Step back so shoulders → hips are visible.";
  uiFeedback.textContent = "Tracking...";

  btnStart.disabled = true;
  btnStop.disabled = false;
  exerciseSelect.disabled = true;

  if (idleOverlay) idleOverlay.style.display = "none";

  if (!stream) await startCamera();
  syncCanvasToVideo();

  await startGateLoop();
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
  btnReadyGuide.addEventListener("click", async () => {
    closeGuide();           // close modal
    await enterGateMode();  // start gate on main screen
  });
  btnCloseGuide.addEventListener("click", closeGuide);
  guideBackdrop.addEventListener("click", closeGuide);

  btnStart.addEventListener("click", () => {
    if (running) return;
    openGuide();
  });

  btnStop.addEventListener("click", () => {
  if (!running) {
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
    return;
  }

  stopSession(false);
});

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