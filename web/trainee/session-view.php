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

if (!$session) {
  header("Location: {$BASE_URL}/trainee/sessions.php");
  exit;
}

// Rep metrics
$reps = [];
$stmt = $mysqli->prepare("
  SELECT rep_index, duration_ms, rom_score, trunk_sway, confidence_avg, form_label, anomaly_score
  FROM rep_metrics
  WHERE log_id = ?
  ORDER BY rep_index ASC
");
$stmt->bind_param("i", $log_id);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $reps[] = $r;
$stmt->close();

// Feedback
$feedback = [];
$stmt = $mysqli->prepare("
  SELECT feedback_type, severity, feedback_text, created_at
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
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/trainee/sessions.php">
          ← Back to sessions
        </a>
      </div>
    </div>

    <!-- Summary cards -->
    <div class="row g-3 mb-4">
      <div class="col-md-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Reps</div>
            <div class="lr-stat-value mt-1"><?= (int)$session['reps_total'] ?></div>
            <p class="lr-stat-subtext mb-0"><?= (int)$session['reps_good'] ?> good / <?= (int)$session['reps_bad'] ?> bad</p>
          </div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Form score</div>
            <div class="lr-stat-value mt-1"><?= (int)$pct ?>%</div>
            <span class="<?= h(formBadge($pct)) ?> mt-2">
              <?= $pct >= 85 ? 'Good overall form' : ($pct >= 70 ? 'Moderate — improve' : 'Needs attention') ?>
            </span>
          </div>
        </div>
      </div>
      <div class="col-md-3">
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
      <div class="col-md-3">
        <div class="lr-card h-100">
          <div class="lr-card-body">
            <div class="lr-stat-label">Processing</div>
            <div class="lr-stat-value mt-1"><?= $session['processing_ms'] === null ? '—' : h((string)$session['processing_ms']) ?></div>
            <p class="lr-stat-subtext mb-0"><?= $session['processing_ms'] === null ? 'No timing data.' : 'ms latency (Objective 5)' ?></p>
          </div>
        </div>
      </div>
    </div>

    <!-- Details -->
    <div class="row g-4">
      <!-- Reps -->
      <div class="col-lg-7">
        <div class="lr-card h-100">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Rep Metrics</div>
            <div class="lr-section-heading mb-0">Per-rep breakdown</div>
          </div>

          <div class="lr-card-body p-0">
            <div class="table-responsive">
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
          </div>

        </div>
      </div>

      <!-- Feedback -->
      <div class="col-lg-5">
        <div class="lr-card mb-3">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Feedback</div>
            <div class="lr-section-heading mb-0">Messages generated</div>
          </div>
          <div class="lr-card-body">
            <?php if (count($feedback) === 0): ?>
              <div class="lr-stat-subtext">No feedback messages saved for this session yet.</div>
            <?php else: ?>
              <div class="d-grid gap-2">
                <?php foreach ($feedback as $f): ?>
                  <div class="p-3 rounded-3" style="border:1px solid var(--lr-border); background: rgba(15,23,42,0.65);">
                    <div class="d-flex justify-content-between align-items-center mb-1">
                      <div class="lr-section-title mb-0 text-capitalize"><?= h((string)$f['feedback_type']) ?></div>
                      <span class="<?= h(severityBadge((string)$f['severity'])) ?>"><?= h((string)$f['severity']) ?></span>
                    </div>
                    <div><?= h((string)$f['feedback_text']) ?></div>
                    <div class="lr-stat-subtext mt-2 mb-0">
                      <?= h(date("M d, Y • g:i A", strtotime((string)$f['created_at']))) ?>
                    </div>
                  </div>
                <?php endforeach; ?>
              </div>
            <?php endif; ?>
          </div>
        </div>

        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Files</div>
            <div class="lr-section-heading mb-0">Prototype paths</div>
          </div>
          <div class="lr-card-body">
            <div class="lr-stat-subtext mb-2"><strong>Video:</strong> <?= h((string)($session['video_path'] ?? '—')) ?></div>
            <div class="lr-stat-subtext mb-0"><strong>Result JSON:</strong> <?= h((string)($session['result_json_path'] ?? '—')) ?></div>
          </div>
        </div>

      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
