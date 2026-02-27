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
                    style="pointer-events:none; transform: scaleX(-1);"></canvas>

            <!-- Big countdown overlay (3..2..1) -->
            <div id="countdownOverlay"
                class="position-absolute top-0 start-0 w-100 h-100 d-none"
                style="pointer-events:none; display:flex; align-items:center; justify-content:center;
                        background: rgba(0,0,0,.35); font-weight:800; font-size: clamp(64px, 10vw, 140px);
                        color:#fff; text-shadow: 0 8px 30px rgba(0,0,0,.55);">
                        3
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
  // JS reads this so we don't hardcode paths inside the .js file
  window.LR_START_SESSION_CONFIG = {
    API_URL: "../api/session_process.php",
    SESSION_VIEW_URL: "../trainee/session-view.php?log_id="
  };
</script>

<script src="../assets/js/start-session.js?v=5"></script>

<?php require __DIR__ . '/../includes/footer.php'; ?>