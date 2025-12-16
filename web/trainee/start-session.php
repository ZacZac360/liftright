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
                      style="pointer-events:none; border-radius: .75rem; transform: scaleX(-1);"></canvas>

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
  const BASE_URL = "<?= $BASE_URL ?>";

  const video = document.getElementById("video");

  // overlay (visible)
  const overlayCanvas = document.getElementById("overlayCanvas");
  const octx = overlayCanvas.getContext("2d");

  // capture (hidden)
  const captureCanvas = document.getElementById("captureCanvas");
  const capCtx = captureCanvas.getContext("2d", { willReadFrequently: true });

  const btnStart = document.getElementById("btnStart");
  const btnStop  = document.getElementById("btnStop");

  const exerciseSelect = document.getElementById("exerciseSelect");
  const uiExercise = document.getElementById("uiExercise");

  const uiReps = document.getElementById("uiReps");
  const uiState = document.getElementById("uiState");
  const uiConf = document.getElementById("uiConf");
  const uiFeedback = document.getElementById("uiFeedback");
  const uiLastRep = document.getElementById("uiLastRep");
  const uiLogId = document.getElementById("uiLogId");

  let stream = null;
  let running = false;
  let tickTimer = null;

  let logId = null;
  let sessionToken = null;

  function currentExercise() {
    return exerciseSelect.value;
  }

  function lockExerciseSelect(lock) {
    exerciseSelect.disabled = lock;
    uiExercise.textContent = currentExercise();
  }

  async function postJSON(url, data) {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data)
    });
    return await res.json();
  }

  async function startCamera() {
    stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
    video.srcObject = stream;
    await video.play();
    resizeOverlayToVideo();
  }

  function stopCamera() {
    if (stream) {
      stream.getTracks().forEach(t => t.stop());
      stream = null;
    }
  }

  function captureJpegBase64(quality = 0.6) {
    const w = video.videoWidth || 640;
    const h = video.videoHeight || 480;
    captureCanvas.width = w;
    captureCanvas.height = h;
    capCtx.drawImage(video, 0, 0, w, h);
    return captureCanvas.toDataURL("image/jpeg", quality);
  }

  function setBadge(el, cls) {
    el.className = cls;
  }

  // ---------- Overlay helpers ----------
  function resizeOverlayToVideo() {
    // Ensure overlay canvas matches the rendered video box size
    const rect = video.getBoundingClientRect();
    const w = Math.max(1, Math.round(rect.width));
    const h = Math.max(1, Math.round(rect.height));
    if (overlayCanvas.width !== w || overlayCanvas.height !== h) {
      overlayCanvas.width = w;
      overlayCanvas.height = h;
    }
  }

  function clearOverlay() {
    octx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);
  }

  function severityColor(sev) {
    if (sev === "danger") return "rgba(255,122,122,0.95)";
    if (sev === "warning") return "rgba(247,210,62,0.95)";
    return "rgba(59,230,120,0.95)";
  }

  // Map python frame pixel coords -> overlay canvas coords
  function mapPoint(p, frameW, frameH) {
    const sx = overlayCanvas.width / frameW;
    const sy = overlayCanvas.height / frameH;
    return [p[0] * sx, p[1] * sy];
  }

  function drawLine(a, b, color, width = 3) {
    octx.strokeStyle = color;
    octx.lineWidth = width;
    octx.beginPath();
    octx.moveTo(a[0], a[1]);
    octx.lineTo(b[0], b[1]);
    octx.stroke();
  }

  function drawDot(p, color, r = 4) {
    octx.fillStyle = color;
    octx.beginPath();
    octx.arc(p[0], p[1], r, 0, Math.PI * 2);
    octx.fill();
  }

  function drawOverlay(out) {
    clearOverlay();
    if (!out || !out.skeleton || !out.guides || !out.frame_w || !out.frame_h) return;

    resizeOverlayToVideo();

    const fw = out.frame_w, fh = out.frame_h;
    const col = severityColor(out.feedback_severity || "warning");

    const sk = out.skeleton;

    const LS = mapPoint(sk.left_shoulder, fw, fh);
    const RS = mapPoint(sk.right_shoulder, fw, fh);
    const LE = mapPoint(sk.left_elbow, fw, fh);
    const RE = mapPoint(sk.right_elbow, fw, fh);
    const LW = mapPoint(sk.left_wrist, fw, fh);
    const RW = mapPoint(sk.right_wrist, fw, fh);
    const LH = mapPoint(sk.left_hip, fw, fh);
    const RH = mapPoint(sk.right_hip, fw, fh);

    // ---- NEW: threshold guide lines (SP/LR) ----
    // out.guides.threshold_lines = { down_y, up_y } where values are in python frame pixel Y
    if (out.guides && out.guides.threshold_lines) {
      const tl = out.guides.threshold_lines;

      const downY = mapPoint([0, tl.down_y], fw, fh)[1];
      const upY   = mapPoint([0, tl.up_y], fw, fh)[1];

      // rack/down line
      drawLine([0, downY], [overlayCanvas.width, downY], "rgba(79,157,252,0.55)", 3);
      // top/press line
      drawLine([0, upY],   [overlayCanvas.width, upY],   "rgba(79,157,252,0.85)", 3);
    }

    // arms (colored by severity)
    drawLine(LS, LE, col, 4);
    drawLine(LE, LW, col, 4);
    drawLine(RS, RE, col, 4);
    drawLine(RE, RW, col, 4);

    // shoulder + hip bars (blue)
    drawLine(LS, RS, "rgba(79,157,252,0.85)", 4);
    drawLine(LH, RH, "rgba(79,157,252,0.55)", 3);

    // trunk midline (white)
    const sm = mapPoint(out.guides.shoulder_mid, fw, fh);
    const hm = mapPoint(out.guides.hip_mid, fw, fh);
    drawLine(sm, hm, "rgba(255,255,255,0.35)", 3);

    // points
    [LS,RS,LE,RE,LW,RW,LH,RH].forEach(p => drawDot(p, col, 4));
    drawDot(sm, "rgba(255,255,255,0.55)", 5);
    drawDot(hm, "rgba(255,255,255,0.55)", 5);
  }
  // -------------------------------------

  window.addEventListener("resize", resizeOverlayToVideo);

  async function tick() {
    if (!running) return;

    try {
      const frame = captureJpegBase64(0.6);

      const out = await postJSON(`${BASE_URL}/api/session_process.php`, {
        action: "frame",
        exercise_type: currentExercise(),
        log_id: logId,
        session_token: sessionToken,
        frame_dataurl: frame
      });

      if (!out || out.success !== true) return;

      uiReps.textContent = `Reps: ${out.reps ?? "—"}`;
      uiState.textContent = `State: ${out.state ?? "—"}`;
      uiConf.textContent = `Conf: ${out.conf ?? "—"}`;

      uiFeedback.textContent = out.feedback ?? "—";
      uiLastRep.textContent = out.last_rep_text ?? "—";

      if (out.feedback_severity === "good") {
        setBadge(uiReps, "lr-badge lr-badge-good");
      } else if (out.feedback_severity === "warning") {
        setBadge(uiReps, "lr-badge lr-badge-warning");
      } else if (out.feedback_severity === "danger") {
        setBadge(uiReps, "lr-badge lr-badge-danger");
      }

      drawOverlay(out);

    } catch (e) {
      // silent (prototype)
    } finally {
      tickTimer = setTimeout(tick, 125); // ~8 fps
    }
  }

  btnStart.addEventListener("click", async () => {
    btnStart.disabled = true;

    try {
      lockExerciseSelect(true);
      await startCamera();

      const out = await postJSON(`${BASE_URL}/api/session_process.php`, {
        action: "start",
        exercise_type: currentExercise()
      });

      if (!out || out.success !== true) {
        alert(out?.message || "Could not start session.");
        btnStart.disabled = false;
        lockExerciseSelect(false);
        stopCamera();
        clearOverlay();
        return;
      }

      logId = out.log_id;
      sessionToken = out.session_token;
      uiLogId.textContent = String(logId);

      running = true;
      btnStop.disabled = false;
      tick();

    } catch (e) {
      alert("Camera start failed. Check browser permissions.");
      btnStart.disabled = false;
      lockExerciseSelect(false);
      stopCamera();
      clearOverlay();
    }
  });

  btnStop.addEventListener("click", async () => {
    btnStop.disabled = true;
    running = false;
    if (tickTimer) clearTimeout(tickTimer);

    try {
      const out = await postJSON(`${BASE_URL}/api/session_process.php`, {
        action: "finish",
        exercise_type: currentExercise(),
        log_id: logId,
        session_token: sessionToken
      });

      if (out && out.success === true && out.log_id) {
        window.location.href = `${BASE_URL}/trainee/session-view.php?log_id=${out.log_id}`;
        return;
      }
    } catch (e) {}

    stopCamera();
    clearOverlay();
    btnStart.disabled = false;
    lockExerciseSelect(false);
  });
})();
</script>

<?php require __DIR__ . '/../includes/footer.php'; ?>
