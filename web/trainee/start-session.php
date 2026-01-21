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
  <div class="container lr-main-container py-4">

    <div class="row mb-3 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Live Session</div>
        <h1 class="lr-section-heading mb-1">Webcam Posture Assessment</h1>
        <p class="lr-stat-subtext mb-0">
          Uses your real model pipeline via a local Python service.
        </p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0 d-flex gap-2 justify-content-md-end">
        <button id="btnStart" class="btn btn-primary">Start</button>
        <button id="btnStop" class="btn btn-outline-light" disabled>Stop</button>
      </div>
    </div>

    <div class="row g-4">
      <div class="col-lg-7">
        <div class="lr-card">
          <div class="lr-card-header d-flex justify-content-between align-items-center">
            <div>
              <div class="lr-section-title mb-1">Camera</div>
              <div class="lr-section-heading mb-0">Live feed</div>
            </div>

            <div style="min-width: 220px;">
              <select id="exerciseSelect" class="form-select">
                <option value="bicep_curl" selected>Bicep Curl</option>
                <option value="shoulder_press">Shoulder Press</option>
                <option value="lateral_raise">Lateral Raise</option>
              </select>
            </div>
          </div>

          <div class="lr-card-body">
            <div class="position-relative">
              <video id="video" autoplay playsinline class="w-100 rounded-3"
                     style="background:#000; transform: scaleX(-1);"></video>

              <!-- Overlay canvas (visible) -->
              <canvas id="overlayCanvas"
                  class="position-absolute top-0 start-0 w-100 h-100"
                  style="pointer-events:none; border-radius: .75rem;"></canvas>
  
              <div class="position-absolute top-0 start-0 p-3 w-100">
                <div class="d-flex flex-wrap gap-2">
                  <span class="lr-badge lr-badge-good" id="uiReps">Reps: —</span>
                  <span class="lr-badge lr-badge-warning" id="uiState">State: —</span>
                  <span class="lr-badge lr-badge-warning" id="uiConf">Conf: —</span>
                </div>
              </div>

              <div class="position-absolute bottom-0 start-0 p-3 w-100">
                <div class="p-3 rounded-3" style="border:1px solid var(--lr-border); background: rgba(15,23,42,0.65);">
                  <div class="lr-section-title mb-1">Feedback</div>
                  <div class="fs-5 fw-semibold" id="uiFeedback">—</div>
                  <div class="lr-stat-subtext mt-2 mb-0" id="uiLastRep">—</div>
                </div>
              </div>
            </div>

            <!-- Capture canvas (hidden) -->
            <canvas id="captureCanvas" class="d-none"></canvas>
          </div>
        </div>
      </div>

      <div class="col-lg-5">
        <div class="lr-card mb-3">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Status</div>
            <div class="lr-section-heading mb-0">Session info</div>
          </div>
          <div class="lr-card-body">
            <div class="lr-stat-subtext mb-2"><strong>Exercise:</strong> <span id="uiExercise">bicep_curl</span></div>
            <div class="lr-stat-subtext mb-2"><strong>Mode:</strong> webcam</div>
            <div class="lr-stat-subtext mb-0"><strong>DB Log ID:</strong> <span id="uiLogId">—</span></div>
          </div>
        </div>

        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Notes</div>
            <div class="lr-section-heading mb-0">Prototype behavior</div>
          </div>
          <div class="lr-card-body">
            <ul class="lr-stat-subtext mb-0">
              <li>Frames are sent to the local Python service (~6–10 FPS).</li>
              <li>Python runs MediaPipe + rep detection + OCSVM scoring.</li>
              <li>On stop, results are saved into your DB tables.</li>
            </ul>
          </div>
        </div>

      </div>
    </div>

  </div>
</div>

<script>
(() => {
  const API_URL = "../api/session_process.php";

  const btnStart = document.getElementById("btnStart");
  const btnStop  = document.getElementById("btnStop");
  const exerciseSelect = document.getElementById("exerciseSelect");

  const video = document.getElementById("video");
  const captureCanvas = document.getElementById("captureCanvas");
  const overlayCanvas = document.getElementById("overlayCanvas");

  const capCtx = captureCanvas.getContext("2d", { willReadFrequently: true });
  const ovCtx  = overlayCanvas.getContext("2d");

  const uiReps = document.getElementById("uiReps");
  const uiState = document.getElementById("uiState");
  const uiConf = document.getElementById("uiConf");
  const uiFeedback = document.getElementById("uiFeedback");
  const uiLastRep = document.getElementById("uiLastRep");
  const uiExercise = document.getElementById("uiExercise");
  const uiLogId = document.getElementById("uiLogId");

  let stream = null;
  let loopTimer = null;
  let inflight = false;

  let logId = 0;
  let sessionToken = "";
  let running = false;

  // ---- IMPORTANT: reuse ONE Image object (prevents flicker/GC) ----
  const annotatedImg = new Image();
  let annotatedBusy = false;

  function setBadge(el, text, kind) {
    el.textContent = text;
    el.classList.remove("lr-badge-good","lr-badge-warning","lr-badge-bad");
    if (kind === "good") el.classList.add("lr-badge-good");
    else if (kind === "bad") el.classList.add("lr-badge-bad");
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

  // ---- IMPORTANT: canvas sizing ONLY when video metadata is ready (NOT every frame) ----
  function syncCanvasToVideo() {
    const w = video.videoWidth || 1280;
    const h = video.videoHeight || 720;

    if (captureCanvas.width !== w || captureCanvas.height !== h) {
      captureCanvas.width = w;
      captureCanvas.height = h;
    }
    if (overlayCanvas.width !== w || overlayCanvas.height !== h) {
      overlayCanvas.width = w;
      overlayCanvas.height = h;
    }
  }

  async function startCamera() {
    stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: "user" },
      audio: false
    });
    video.srcObject = stream;

    await video.play();

    // once the browser knows the real camera size
    syncCanvasToVideo();
    video.onloadedmetadata = () => syncCanvasToVideo();

    // keep layout stable; we will show only the overlay drawing
    video.style.visibility = "hidden";
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

  async function tick() {
    if (!running || inflight) return;
    if (!video.videoWidth || !video.videoHeight) return;

    inflight = true;
    try {
      // capture frame WITHOUT resizing canvases here
      capCtx.drawImage(video, 0, 0, captureCanvas.width, captureCanvas.height);
      const frameDataUrl = captureCanvas.toDataURL("image/jpeg", 0.6);

      const resp = await api("frame", {
        log_id: logId,
        session_token: sessionToken,
        frame_dataurl: frameDataUrl
      });

      const annotated = resp.annotated_frame_dataurl;
      const status = resp.status || {};

      // One overlay only
      drawAnnotatedToOverlay(annotated);

      const repNow = (status.rep_now ?? "—");
      const state = (status.state ?? "—");
      const conf = (status.conf ?? "—");

      uiReps.textContent = `Reps: ${repNow}`;
      setBadge(uiState, `State: ${state}`, state === "stop" ? "bad" : "warning");
      uiConf.textContent = `Conf: ${typeof conf === "number" ? conf.toFixed(2) : conf}`;

      uiExercise.textContent = (status.exercise ?? exerciseSelect.value);

      // feedback text
      uiFeedback.textContent = state === "stop" ? "STOP RECOMMENDED (fatigue)" : "Tracking...";
      uiLastRep.textContent = status.last_rep_text ?? "—";

      // auto-stop if server says stop
      if (state === "stop") {
        await stopSession(true);
      }
    } catch (e) {
      uiFeedback.textContent = `Error: ${e.message}`;
    } finally {
      inflight = false;
    }
  }

  async function startSession() {
    if (running) return;
    const ex = exerciseSelect.value;

    // call your PHP bridge start()
    const res = await api("start", { exercise_type: ex });
    logId = res.log_id;
    sessionToken = res.session_token;

    uiLogId.textContent = String(logId);
    uiExercise.textContent = ex;

    await startCamera();

    running = true;
    btnStart.disabled = true;
    btnStop.disabled = false;
    exerciseSelect.disabled = true;

    // ~8 FPS
    loopTimer = setInterval(tick, 125);
  }

  async function stopSession(fromAutoStop=false) {
    if (!running) return;

    running = false;
    inflight = false;

    if (loopTimer) {
      clearInterval(loopTimer);
      loopTimer = null;
    }

    stopCamera();
    ovCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);

    btnStart.disabled = false;
    btnStop.disabled = true;
    exerciseSelect.disabled = false;

    // finalize + write to DB (your PHP bridge finish())
    try {
      await api("finish", { log_id: logId, session_token: sessionToken });
      setBadge(uiState, "State: finished", "good");
      if (!fromAutoStop) uiFeedback.textContent = "Session finished.";
    } catch (e) {
      uiFeedback.textContent = `Finish error: ${e.message}`;
    } finally {
      sessionToken = "";
      logId = 0;
    }
  }

  btnStart.addEventListener("click", startSession);
  btnStop.addEventListener("click", () => stopSession(false));

  // initial UI
  uiReps.textContent = "Reps: —";
  uiState.textContent = "State: —";
  uiConf.textContent = "Conf: —";
  uiFeedback.textContent = "—";
  uiLastRep.textContent = "—";

  // optional: if user resizes window, keep canvases in sync
  window.addEventListener("resize", () => {
    if (video.videoWidth && video.videoHeight) syncCanvasToVideo();
  });
})();
</script>


<?php require __DIR__ . '/../includes/footer.php'; ?>
