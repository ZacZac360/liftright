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
      <div class="row g-3 align-items-center">
        <div class="col-lg-7">
          <div class="lr-section-title mb-1">Live Session</div>
          <h1 class="lr-section-heading mb-1">Webcam Posture Assessment</h1>
          <p class="lr-stat-subtext mb-0">Choose an exercise, then start.</p>
        </div>

        <div class="col-lg-5">
          <div class="lr-live-topbar-actions">
            <button type="button" id="btnPageGuide" class="btn btn-outline-light btn-lg">? Guide</button>
            <button id="btnStart" class="btn btn-primary btn-lg lr-btn-strong">Start Session</button>
            <button id="btnStop" class="btn btn-outline-light btn-lg" disabled>Stop</button>
          </div>
          <div class="lr-stat-subtext mt-2 text-lg-end">
            Keep shoulders to hips visible.
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
              <span class="lr-badge lr-badge-warning" id="uiFatigue">Fatigue: —</span>
            </div>

            <div class="lr-instruction-box">
              <div class="lr-section-title mb-1">Do this now</div>
              <div class="fw-bold lr-live-main-instruction" id="uiInstruction">
                Press Start to begin.
              </div>
              <div class="lr-stat-subtext mt-2 mb-0" id="uiInstructionSub">
                Use a safe, manageable load.
              </div>
              <div class="lr-live-debug mt-2" id="uiDebugLine">
                state: — | phase: — | conf: —
              </div>
            </div>
          </div>
        </div>

        <!-- Feedback (moved from bottom overlay) -->
        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Feedback</div>
            <div class="lr-section-heading mb-0">Current result</div>
          </div>
          <div class="lr-card-body">
            <div class="fw-bold lr-live-feedback-main" id="uiFeedback">—</div>
            <div class="mt-2 lr-live-feedback-sub" id="uiLastRep">—</div>

            <hr class="my-3">

            <div class="lr-stat-subtext">
              <div><strong>Log ID:</strong> <span id="uiLogIdMain">—</span></div>
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
                <div class="lr-section-title mb-1">Ready check</div>
                <div class="fw-bold lr-live-idle-title">
                  Keep shoulders to hips visible.
                </div>
                <div class="lr-stat-subtext mt-2 mb-0">
                  Press <strong>Start Session</strong> when ready.
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
            <div class="lr-section-heading mb-0">Exercise</div>
          </div>
          <div class="lr-card-body">
            <label class="lr-stat-subtext mb-2" for="exerciseSelect">
              Choose what you are about to perform.
            </label>

            <select id="exerciseSelect" class="form-select form-select-lg">
              <option value="bicep_curl" selected>Bicep Curl</option>
              <option value="shoulder_press">Shoulder Press</option>
              <option value="lateral_raise">Lateral Raise</option>
            </select>

            <div class="lr-stat-subtext mt-3 mb-0">
              Camera: chest height • Face camera • Good lighting
            </div>
          </div>
        </div>
          <div class="lr-card mb-3">
            <div class="lr-card-header">
              <div class="lr-section-title mb-1">Safety</div>
              <div class="lr-section-heading mb-0">Quick reminders</div>
            </div>
            <div class="lr-card-body">
              <ul class="lr-live-quick-list mb-0">
                <li>Warm up first.</li>
                <li>Use a weight you can control.</li>
                <li>Stop if you feel pain or dizziness.</li>
                <li>Rest if stop is recommended.</li>
              </ul>
            </div>
          </div>
          <div class="lr-card mb-3">
            <div class="lr-card-header">
              <div class="lr-section-title mb-1">Live Status</div>
              <div class="lr-section-heading mb-0">Session overview</div>
            </div>

            <div class="lr-card-body d-grid gap-3">

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

              <div>
                <div class="lr-stat-label">Fatigue Level</div>
                <div id="uiFatigueSide" class="fs-6 fw-semibold">—</div>
              </div>

              <div>
                <div class="lr-stat-label">Fatigue Trend</div>
                <div id="uiFatigueTrendSide" class="fs-6 fw-semibold">—</div>
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
            Use a safe load. Stop if something feels wrong.
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
            Keep your upper body clear and fully visible.
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- ---------- Page Guide Modal (Onboarding) ---------- -->
<div class="lr-modal-backdrop" id="pageGuideBackdrop" style="display:none;"></div>
<div class="lr-modal" id="pageGuideModal" style="display:none;" role="dialog" aria-modal="true" aria-labelledby="pageGuideTitle">
  <div class="lr-modal-card">
    <div class="lr-modal-head">
      <div>
        <div class="lr-section-title mb-1">Page Guide</div>
        <div class="lr-section-heading mb-0" id="pageGuideTitle">How to use Start Session</div>
      </div>
      <button class="btn btn-outline-light btn-sm" id="btnClosePageGuide" type="button">Close</button>
    </div>

    <div class="lr-modal-body">
      <div class="d-grid gap-3">
        <div class="lr-step-card">
          <div class="lr-step-kicker">1. Choose your exercise</div>
          <p class="lr-step-text mb-0">
            Select the exercise you are about to perform before starting the webcam session.
          </p>
        </div>

        <div class="lr-step-card">
          <div class="lr-step-kicker">2. Check your framing</div>
          <p class="lr-step-text mb-0">
            Keep your shoulders to hips visible, face the camera, and make sure the room is bright enough.
          </p>
        </div>

        <div class="lr-step-card">
          <div class="lr-step-kicker">3. Start and follow feedback</div>
          <p class="lr-step-text mb-0">
            Press <strong>Start Session</strong>, perform your reps, and watch the live coaching panel for instructions, warnings, and rep updates.
          </p>
        </div>

        <div class="lr-step-card">
          <div class="lr-step-kicker">4. End the session</div>
          <p class="lr-step-text mb-0">
            Press <strong>Stop</strong> when finished. Your results will be saved so you can review them later.
          </p>
        </div>

        <div class="d-flex justify-content-end gap-2 flex-wrap">
          <button type="button" class="btn btn-outline-light" id="btnLaterPageGuide">Got it</button>
          <button type="button" class="btn btn-primary" id="btnStartFromGuide">Go to Start Session</button>
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

<script>
(() => {
  const guideKey = 'lr_guide_start_session_seen';
  const modal = document.getElementById('pageGuideModal');
  const backdrop = document.getElementById('pageGuideBackdrop');
  const btnOpen = document.getElementById('btnPageGuide');
  const btnClose = document.getElementById('btnClosePageGuide');
  const btnLater = document.getElementById('btnLaterPageGuide');
  const btnStartFromGuide = document.getElementById('btnStartFromGuide');

  function openGuide() {
    modal.style.display = 'flex';
    backdrop.style.display = 'block';
    document.body.classList.add('lr-modal-open');
  }

  function closeGuide(markSeen = false) {
    modal.style.display = 'none';
    backdrop.style.display = 'none';
    document.body.classList.remove('lr-modal-open');
    if (markSeen) {
      localStorage.setItem(guideKey, '1');
    }
  }

  if (!localStorage.getItem(guideKey)) {
    openGuide();
  }

  btnOpen?.addEventListener('click', openGuide);
  btnClose?.addEventListener('click', () => closeGuide(true));
  btnLater?.addEventListener('click', () => closeGuide(true));
  btnStartFromGuide?.addEventListener('click', () => closeGuide(true));
  backdrop?.addEventListener('click', () => closeGuide(true));

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && modal.style.display === 'flex') {
      closeGuide(true);
    }
  });
})();
</script>

<?php require __DIR__ . '/../includes/footer.php'; ?>