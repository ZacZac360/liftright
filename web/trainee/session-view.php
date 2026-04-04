<?php
// liftright/web/trainee/session-view.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['user']);
$page_title = "Session Details";

$user_id = (int)$_SESSION['user_id'];
$log_id  = isset($_GET['log_id']) ? (int)$_GET['log_id'] : 0;

if ($log_id <= 0) {
  header("Location: {$BASE_URL}/trainee/sessions.php");
  exit;
}

// Load session (must belong to current user)
$stmt = $mysqli->prepare("
  SELECT log_id, user_id, exercise_type, source_type,
         video_path, result_json_path,
         reps_total, reps_good, reps_bad, form_error_count, fatigue_flag,
         started_at, finished_at, processing_ms,
         created_at
  FROM training_logs
  WHERE log_id = ? AND user_id = ?
  LIMIT 1
");
$stmt->bind_param("ii", $log_id, $user_id);
$stmt->execute();
$session = $stmt->get_result()->fetch_assoc();
$stmt->close();

// Mark notifications for this session as read (when opened)
$stmt = $mysqli->prepare("
  UPDATE notifications
  SET is_read = 1
  WHERE user_id = ?
    AND log_id = ?
    AND notif_type = 'review_posted'
");
$stmt->bind_param("ii", $user_id, $log_id);
$stmt->execute();
$stmt->close();

if (!$session) {
  header("Location: {$BASE_URL}/trainee/sessions.php");
  exit;
}

// Latest trainer review (if any) for this session
$trainer_review = null;
$stmt = $mysqli->prepare("
  SELECT
    er.review_id,
    er.rating,
    er.notes,
    er.created_at,
    u.full_name AS trainer_name
  FROM expert_reviews er
  JOIN users u ON u.user_id = er.trainer_id
  WHERE er.log_id = ?
  ORDER BY er.created_at DESC
  LIMIT 1
");
$stmt->bind_param("i", $log_id);
$stmt->execute();
$trainer_review = $stmt->get_result()->fetch_assoc();
$stmt->close();

// Rep metrics
$reps = [];
$stmt = $mysqli->prepare("
  SELECT
    rm.rep_index,
    rm.duration_ms,
    rm.rom_score,
    rm.trunk_sway,
    rm.confidence_avg,
    rm.form_label,
    rm.anomaly_score,
    rs.image_path AS snapshot_path
  FROM rep_metrics rm
  LEFT JOIN rep_snapshots rs
    ON rs.log_id = rm.log_id
   AND rs.rep_index = rm.rep_index
  WHERE rm.log_id = ?
  ORDER BY rm.rep_index ASC
");
$stmt->bind_param("i", $log_id);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $reps[] = $r;
$stmt->close();

// Feedback
$feedback = [];
$stmt = $mysqli->prepare("
  SELECT feedback_type, severity, feedback_text, feedback_meta, created_at
  FROM feedback
  WHERE log_id = ?
  ORDER BY created_at ASC
");

$stmt->bind_param("i", $log_id);
$stmt->execute();
$res = $stmt->get_result();
while ($f = $res->fetch_assoc()) $feedback[] = $f;
$stmt->close();

function formatExercise(string $ex): string {
  return match($ex) {
    'shoulder_press' => 'Shoulder Press',
    'bicep_curl'     => 'Bicep Curl',
    'lateral_raise'  => 'Lateral Raise',
    default          => ucwords(str_replace('_',' ', $ex)),
  };
}
function formPct(int $good, int $total): int {
  return ($total > 0) ? (int)round(($good / $total) * 100) : 0;
}
function formBadge(int $pct): string {
  if ($pct >= 85) return 'lr-badge lr-badge-good';
  if ($pct >= 70) return 'lr-badge lr-badge-warning';
  return 'lr-badge lr-badge-danger';
}
function fatigueBadge(int $flag): string {
  return $flag ? 'lr-badge lr-badge-warning' : 'lr-badge lr-badge-good';
}
function severityBadge(string $sev): string {
  return match($sev) {
    'danger'  => 'lr-badge lr-badge-danger',
    'warning' => 'lr-badge lr-badge-warning',
    default   => 'lr-badge lr-badge-good',
  };
}

$good = (int)$session['reps_good'];
$total = (int)$session['reps_total'];
$pct = formPct($good, $total);

/* ---------------------------
   Key issues / highlights
----------------------------*/
$key_dangers = [];
$key_warnings = [];

foreach ($feedback as $f) {
  $text = trim((string)($f['feedback_text'] ?? ''));
  $sev  = (string)($f['severity'] ?? 'info');

  if ($text === '') continue;

  if ($sev === 'danger') {
    $key_dangers[] = $text;
  } elseif ($sev === 'warning') {
    $key_warnings[] = $text;
  }
}

$key_dangers = array_values(array_unique($key_dangers));
$key_warnings = array_values(array_unique($key_warnings));

$top_issues = array_slice(array_merge($key_dangers, $key_warnings), 0, 5);

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <!-- Header -->
    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Session</div>
        <h1 class="lr-section-heading mb-1">
          <?= h(formatExercise((string)$session['exercise_type'])) ?>
          <span class="ms-2 lr-chip-exercise"><?= h((string)$session['source_type']) ?></span>
        </h1>
        <p class="lr-stat-subtext mb-0">
          Recorded <?= h(date("M d, Y • g:i A", strtotime((string)$session['created_at']))) ?>
        </p>
      </div>
        <div class="col-md-4 text-md-end mt-3 mt-md-0 d-flex justify-content-md-end gap-2 flex-wrap">
          <button type="button" id="btnPageGuide" class="btn btn-outline-light">? Guide</button>
          <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/trainee/sessions.php">
            ← Back to sessions
          </a>
        </div>
    </div>

    <!-- Summary cards -->
    <div class="row g-3 mb-4 lr-summary-row">
      <div class="col-md-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Reps</div>
            <div class="lr-stat-value mt-1"><?= (int)$session['reps_total'] ?></div>
            <p class="lr-stat-subtext mb-0"><?= (int)$session['reps_good'] ?> good / <?= (int)$session['reps_bad'] ?> bad</p>
          </div>
        </div>
      </div>
      <div class="col-md-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Form quality</div>
            <div class="lr-stat-value mt-1"><?= (int)$pct ?>%</div>
            <span class="<?= h(formBadge($pct)) ?> mt-2">
              <?= $pct >= 85 ? 'Good overall form' : ($pct >= 70 ? 'Moderate — improve' : 'Needs attention') ?>
            </span>
          </div>
        </div>
      </div>
      <div class="col-md-4">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Fatigue flag</div>
            <div class="lr-stat-value mt-1"><?= ((int)$session['fatigue_flag'] === 1) ? 'Yes' : 'No' ?></div>
            <span class="<?= h(fatigueBadge((int)$session['fatigue_flag'])) ?> mt-2">
              <?= ((int)$session['fatigue_flag'] === 1) ? 'Warning' : 'Normal' ?>
            </span>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Trainer Review -->
    <div class="lr-card mb-4">
      <div class="lr-card-header">
        <div class="lr-section-title mb-1">Trainer Review</div>
        <div class="lr-section-heading mb-0">Expert evaluation</div>
      </div>

      <div class="lr-card-body">
        <?php if (!$trainer_review): ?>
          <div class="lr-stat-subtext mb-0">No trainer review yet.</div>
        <?php else: ?>
          <div class="d-flex justify-content-between align-items-start flex-wrap gap-2">
            <div>
              <div class="lr-stat-label">Trainer</div>
              <div class="fw-semibold"><?= h((string)$trainer_review['trainer_name']) ?></div>
              <div class="lr-stat-subtext">
                Reviewed <?= h(date("M d, Y • g:i A", strtotime((string)$trainer_review['created_at']))) ?>
              </div>
            </div>

            <div>
              <div class="lr-stat-label">Rating</div>
              <span class="lr-badge lr-badge-good"><?= (int)$trainer_review['rating'] ?>/5</span>
            </div>
          </div>

          <hr class="border-secondary my-3">

          <div class="lr-stat-label">Notes</div>
          <div class="lr-stat-subtext" style="white-space:pre-wrap;">
            <?= trim((string)$trainer_review['notes']) !== '' ? h((string)$trainer_review['notes']) : '—' ?>
          </div>
        <?php endif; ?>
      </div>
    </div>

    <!-- Main details -->
    <div class="row g-4">

      <!-- Left: feedback -->
      <div class="col-lg-5 order-1">
        <div class="lr-card mb-4">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Feedback</div>
            <div class="lr-section-heading mb-0">What to improve</div>
          </div>
          <div class="lr-card-body">
            <?php if (count($feedback) === 0): ?>
              <div class="lr-stat-subtext">No feedback messages saved for this session yet.</div>
            <?php else: ?>
              <div class="d-grid gap-2">
                <?php foreach ($feedback as $f): ?>
                  <?php
                    $repLabel = '';
                    if (!empty($f['feedback_meta'])) {
                      $meta = json_decode((string)$f['feedback_meta'], true);
                      if (is_array($meta)) {
                        if (isset($meta['rep'])) $repLabel = 'Rep ' . (int)$meta['rep'];
                        elseif (isset($meta['rep_index'])) $repLabel = 'Rep ' . (int)$meta['rep_index'];
                        elseif (isset($meta['since_rep'])) $repLabel = 'Since Rep ' . (int)$meta['since_rep'];
                      }
                    }

                    $typeLabel = (string)($f['feedback_type'] ?? 'posture');
                    $title = ($repLabel !== '' ? $repLabel . ' • ' : '') . $typeLabel;
                    $sevClass = 'lr-feedback-card';
                    if ((string)$f['severity'] === 'danger') $sevClass .= ' lr-feedback-card-danger';
                    elseif ((string)$f['severity'] === 'warning') $sevClass .= ' lr-feedback-card-warning';
                  ?>
                  <div class="<?= $sevClass ?>">
                    <div class="d-flex justify-content-between align-items-center mb-1 gap-2">
                      <div class="lr-section-title mb-0 text-capitalize"><?= h($title) ?></div>
                      <span class="<?= h(severityBadge((string)$f['severity'])) ?>"><?= h((string)$f['severity']) ?></span>
                    </div>
                    <div class="fw-semibold mb-1"><?= h((string)$f['feedback_text']) ?></div>
                    <div class="lr-stat-subtext mb-0">
                      <?= h(date("M d, Y • g:i A", strtotime((string)$f['created_at']))) ?>
                    </div>
                  </div>
                <?php endforeach; ?>
              </div>
            <?php endif; ?>
          </div>
        </div>
      </div>

      <!-- Right: simple snapshots -->
      <div class="col-lg-7 order-2">
        <div class="lr-card mb-4">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Snapshots</div>
            <div class="lr-section-heading mb-0">Per-rep images</div>
          </div>
          <div class="lr-card-body">
            <?php
              $snapshot_reps = array_values(array_filter($reps, function ($r) {
                return !empty($r['snapshot_path']);
              }));
            ?>

            <?php if (count($snapshot_reps) === 0): ?>
              <div class="lr-stat-subtext">No rep snapshots saved for this session yet.</div>
            <?php else: ?>
              <div class="lr-snapshot-grid">
                <?php foreach ($snapshot_reps as $r): ?>
                  <?php
                    $repIndex = (int)$r['rep_index'];
                    $label = strtolower((string)($r['form_label'] ?? 'good'));
                    $labelClass = ($label === 'bad') ? 'lr-badge lr-badge-danger' : 'lr-badge lr-badge-good';
                  ?>
                  <div class="lr-snapshot-card">
                    <button
                      type="button"
                      class="lr-snap-btn lr-snapshot-button"
                      data-snap-src="<?= h($BASE_URL . '/' . ltrim((string)$r['snapshot_path'], '/')) ?>"
                      data-snap-title="Rep <?= $repIndex ?> Snapshot">
                      <img
                        src="<?= $BASE_URL . '/' . ltrim((string)$r['snapshot_path'], '/') ?>"
                        alt="Rep <?= $repIndex ?> snapshot"
                        class="lr-snapshot-thumb">
                    </button>

                    <div class="d-flex justify-content-between align-items-center gap-2 mt-2">
                      <div class="fw-semibold">Rep <?= $repIndex ?></div>
                      <span class="<?= $labelClass ?> text-capitalize"><?= h($label) ?></span>
                    </div>
                  </div>
                <?php endforeach; ?>
              </div>
            <?php endif; ?>
          </div>
        </div>

        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Advanced</div>
            <div class="lr-section-heading mb-0">Detailed metrics</div>
          </div>
          <div class="lr-card-body">
            <details class="lr-advanced-filters">
              <summary class="lr-advanced-summary">Show technical details</summary>

              <div class="mt-3">
                <div class="row g-3 mb-3">
                  <div class="col-md-6">
                    <div class="lr-mini-stat">
                      <div class="lr-stat-label">Processing time</div>
                      <div class="fw-semibold">
                        <?= $session['processing_ms'] === null ? '—' : h((string)$session['processing_ms']) . ' ms' ?>
                      </div>
                    </div>
                  </div>
                  <div class="col-md-6">
                    <div class="lr-mini-stat">
                      <div class="lr-stat-label">Source</div>
                      <div class="fw-semibold text-capitalize"><?= h((string)$session['source_type']) ?></div>
                    </div>
                  </div>
                </div>

                <div class="table-responsive mt-3">
                  <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
                    <thead>
                      <tr>
                        <th>#</th>
                        <th>Duration</th>
                        <th>ROM</th>
                        <th>Trunk sway</th>
                        <th>Confidence</th>
                        <th>Label</th>
                        <th class="text-end">Anomaly</th>
                      </tr>
                    </thead>
                    <tbody>
                    <?php if (count($reps) === 0): ?>
                      <tr>
                        <td colspan="7" class="text-center py-4 lr-stat-subtext">No rep metrics saved for this session yet.</td>
                      </tr>
                    <?php else: ?>
                      <?php foreach ($reps as $r): ?>
                        <tr>
                          <td><?= (int)$r['rep_index'] ?></td>
                          <td><?= $r['duration_ms'] === null ? '—' : (int)$r['duration_ms'].' ms' ?></td>
                          <td><?= $r['rom_score'] === null ? '—' : number_format((float)$r['rom_score'], 2) ?></td>
                          <td><?= $r['trunk_sway'] === null ? '—' : number_format((float)$r['trunk_sway'], 2) ?></td>
                          <td><?= $r['confidence_avg'] === null ? '—' : number_format((float)$r['confidence_avg'], 2) ?></td>
                          <td class="text-capitalize"><?= h((string)$r['form_label']) ?></td>
                          <td class="text-end"><?= $r['anomaly_score'] === null ? '—' : number_format((float)$r['anomaly_score'], 2) ?></td>
                        </tr>
                      <?php endforeach; ?>
                    <?php endif; ?>
                    </tbody>
                  </table>
                </div>

                <details class="lr-advanced-filters mt-3">
                  <summary class="lr-advanced-summary">Show prototype file paths</summary>
                  <div class="mt-3">
                    <div class="lr-stat-subtext mb-2"><strong>Video:</strong> <?= h((string)($session['video_path'] ?? '—')) ?></div>
                    <div class="lr-stat-subtext mb-0"><strong>Result JSON:</strong> <?= h((string)($session['result_json_path'] ?? '—')) ?></div>
                  </div>
                </details>
              </div>
            </details>
          </div>
        </div>
      </div>

    </div>
</div>

<div class="lr-modal-backdrop" id="pageGuideBackdrop" style="display:none;"></div>
<div class="lr-modal" id="pageGuideModal" style="display:none;" role="dialog" aria-modal="true" aria-labelledby="pageGuideTitle">
  <div class="lr-modal-card">
    <div class="lr-modal-head">
      <div>
        <div class="lr-section-title mb-1">Page Guide</div>
        <div class="lr-section-heading mb-0" id="pageGuideTitle">How to use Session Details</div>
      </div>
      <button class="btn btn-outline-light btn-sm" id="btnClosePageGuide" type="button">Close</button>
    </div>

    <div class="lr-modal-body">
      <div class="d-grid gap-3">
        <div class="lr-step-card">
          <div class="lr-step-kicker">Session summary</div>
          <p class="lr-step-text mb-0">
            The top cards summarize your total reps, overall form quality, and whether fatigue was detected.
          </p>
        </div>

        <div class="lr-step-card">
          <div class="lr-step-kicker">Trainer review and feedback</div>
          <p class="lr-step-text mb-0">
            Use the trainer review and feedback section to understand the most important corrections for future sessions.
          </p>
        </div>

        <div class="lr-step-card">
          <div class="lr-step-kicker">Snapshots</div>
          <p class="lr-step-text mb-0">
            Open the rep snapshots to visually inspect what happened during each repetition.
          </p>
        </div>

        <div class="d-flex justify-content-end">
          <button type="button" class="btn btn-primary" id="btnDonePageGuide">Got it</button>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="lr-snap-modal-backdrop" id="lrSnapBackdrop" hidden></div>

<div class="lr-snap-modal" id="lrSnapModal" hidden>
  <div class="lr-snap-dialog">
    <button type="button" class="lr-snap-close" id="lrSnapClose" aria-label="Close image">×</button>
    <div class="lr-snap-title" id="lrSnapTitle">Snapshot</div>
    <img src="" alt="Session snapshot preview" id="lrSnapImage" class="lr-snap-image">
  </div>
</div>

<script>
(() => {
  const guideKey = 'lr_guide_session_view_seen';
  const modal = document.getElementById('pageGuideModal');
  const backdrop = document.getElementById('pageGuideBackdrop');
  const btnOpen = document.getElementById('btnPageGuide');
  const btnClose = document.getElementById('btnClosePageGuide');
  const btnDone = document.getElementById('btnDonePageGuide');

  function openGuide() {
    modal.style.display = 'flex';
    backdrop.style.display = 'block';
    document.body.classList.add('lr-modal-open');
  }

  function closeGuide(markSeen = false) {
    modal.style.display = 'none';
    backdrop.style.display = 'none';
    document.body.classList.remove('lr-modal-open');
    if (markSeen) localStorage.setItem(guideKey, '1');
  }

  if (!localStorage.getItem(guideKey)) openGuide();

  btnOpen?.addEventListener('click', openGuide);
  btnClose?.addEventListener('click', () => closeGuide(true));
  btnDone?.addEventListener('click', () => closeGuide(true));
  backdrop?.addEventListener('click', () => closeGuide(true));
})();
</script>

<script>
(() => {
  const modal = document.getElementById('lrSnapModal');
  const backdrop = document.getElementById('lrSnapBackdrop');
  const img = document.getElementById('lrSnapImage');
  const title = document.getElementById('lrSnapTitle');
  const closeBtn = document.getElementById('lrSnapClose');
  const triggers = document.querySelectorAll('.lr-snap-btn');

  function openSnap(src, label) {
    img.src = src;
    title.textContent = label || 'Snapshot';
    modal.hidden = false;
    backdrop.hidden = false;
    document.body.classList.add('lr-modal-open');
  }

  function closeSnap() {
    modal.hidden = true;
    backdrop.hidden = true;
    img.src = '';
    document.body.classList.remove('lr-modal-open');
  }

  triggers.forEach(btn => {
    btn.addEventListener('click', () => {
      openSnap(btn.dataset.snapSrc, btn.dataset.snapTitle);
    });
  });

  closeBtn.addEventListener('click', closeSnap);
  backdrop.addEventListener('click', closeSnap);

  modal.addEventListener('click', (e) => {
    if (e.target === modal) closeSnap();
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !modal.hidden) closeSnap();
  });
})();
</script>

<style>
.lr-issue-card{
  border: 1px solid var(--lr-border);
  border-radius: 14px;
  padding: 14px 16px;
  background: rgba(15,23,42,0.45);
}
.lr-issue-card-warning{
  border-color: color-mix(in srgb, var(--lr-warning) 35%, var(--lr-border));
  background: color-mix(in srgb, var(--lr-warning) 8%, rgba(15,23,42,0.55));
}
.lr-issue-card-danger{
  border-color: color-mix(in srgb, var(--lr-danger) 40%, var(--lr-border));
  background: color-mix(in srgb, var(--lr-danger) 8%, rgba(15,23,42,0.55));
}

.lr-feedback-card{
  border: 1px solid var(--lr-border);
  border-radius: 14px;
  padding: 14px 16px;
  background: rgba(15,23,42,0.65);
}
.lr-feedback-card-warning{
  border-color: color-mix(in srgb, var(--lr-warning) 35%, var(--lr-border));
}
.lr-feedback-card-danger{
  border-color: color-mix(in srgb, var(--lr-danger) 40%, var(--lr-border));
}

.lr-snapshot-grid{
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 14px;
}

.lr-snapshot-card{
  border: 1px solid var(--lr-border);
  border-radius: 14px;
  padding: 12px;
  background: rgba(15,23,42,0.42);
}

.lr-snapshot-button{
  display: block;
  width: 100%;
  padding: 0;
  border: 0;
  background: transparent;
}

.lr-snapshot-thumb{
  width: 100%;
  aspect-ratio: 1 / 1;
  object-fit: cover;
  border-radius: 12px;
  border: 1px solid var(--lr-border);
}

.lr-mini-stat{
  border: 1px solid var(--lr-border);
  border-radius: 12px;
  padding: 12px 14px;
  background: rgba(15,23,42,0.32);
}

.lr-advanced-filters{
  border: 1px solid var(--lr-border);
  border-radius: 14px;
  padding: 12px 14px 14px;
  background: rgba(15,23,42,0.28);
}
.lr-advanced-summary{
  cursor: pointer;
  list-style: none;
  font-weight: 700;
  color: var(--lr-text);
  margin: 0;
}
.lr-advanced-summary::-webkit-details-marker{
  display: none;
}
.lr-advanced-summary::after{
  content: " +";
  color: var(--lr-text-muted);
  font-weight: 700;
}
.lr-advanced-filters[open] .lr-advanced-summary::after{
  content: " −";
}
</style>

<?php require __DIR__ . '/../includes/footer.php'; ?>
