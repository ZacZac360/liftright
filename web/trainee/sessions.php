<?php
// liftright/web/trainee/sessions.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['user']);
$page_title = "My Sessions";

$user_id = (int)$_SESSION['user_id'];

// Filters
$exercise = trim((string)($_GET['exercise'] ?? ''));
$fatigue  = trim((string)($_GET['fatigue'] ?? ''));
$q        = trim((string)($_GET['q'] ?? ''));

$allowedExercises = ['bicep_curl','shoulder_press','lateral_raise'];
$exercise = in_array($exercise, $allowedExercises, true) ? $exercise : '';

$allowedFatigue = ['0','1'];
$fatigue = in_array($fatigue, $allowedFatigue, true) ? $fatigue : '';

// Build query
$sql = "
  SELECT log_id, exercise_type, source_type,
         reps_total, reps_good, reps_bad, form_error_count, fatigue_flag,
         processing_ms, created_at
  FROM training_logs
  WHERE user_id = ?
";
$types = "i";
$params = [$user_id];

if ($exercise !== '') {
  $sql .= " AND exercise_type = ? ";
  $types .= "s";
  $params[] = $exercise;
}
if ($fatigue !== '') {
  $sql .= " AND fatigue_flag = ? ";
  $types .= "i";
  $params[] = (int)$fatigue;
}
if ($q !== '') {
  // simple search: exercise or source
  $sql .= " AND (exercise_type LIKE CONCAT('%', ?, '%') OR source_type LIKE CONCAT('%', ?, '%')) ";
  $types .= "ss";
  $params[] = $q;
  $params[] = $q;
}

$sql .= " ORDER BY created_at DESC LIMIT 200";

$stmt = $mysqli->prepare($sql);
$stmt->bind_param($types, ...$params);
$stmt->execute();
$res = $stmt->get_result();

$sessions = [];
while ($row = $res->fetch_assoc()) $sessions[] = $row;
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

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <!-- Header -->
    <div class="row mb-4 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">History</div>
        <h1 class="lr-section-heading mb-1">My Sessions</h1>
        <p class="lr-stat-subtext mb-0">Browse your recorded sessions and open a detailed rep breakdown.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-primary px-3" href="<?= $BASE_URL ?>/trainee/start-session.php">
          Start New Session
        </a>
      </div>
    </div>

    <!-- Filters -->
    <div class="lr-card mb-4">
      <div class="lr-card-body">
        <form class="row g-2 align-items-end" method="get">
          <div class="col-md-4">
            <label class="form-label lr-stat-label">Exercise</label>
            <select class="form-select" name="exercise">
              <option value="">All</option>
              <option value="bicep_curl" <?= $exercise==='bicep_curl'?'selected':'' ?>>Bicep Curl</option>
              <option value="shoulder_press" <?= $exercise==='shoulder_press'?'selected':'' ?>>Shoulder Press</option>
              <option value="lateral_raise" <?= $exercise==='lateral_raise'?'selected':'' ?>>Lateral Raise</option>
            </select>
          </div>

          <div class="col-md-3">
            <label class="form-label lr-stat-label">Fatigue flag</label>
            <select class="form-select" name="fatigue">
              <option value="">All</option>
              <option value="0" <?= $fatigue==='0'?'selected':'' ?>>Normal</option>
              <option value="1" <?= $fatigue==='1'?'selected':'' ?>>Warning</option>
            </select>
          </div>

          <div class="col-md-3">
            <label class="form-label lr-stat-label">Search</label>
            <input class="form-control" name="q" placeholder="exercise / source..." value="<?= h($q) ?>">
          </div>

          <div class="col-md-2 d-grid">
            <button class="btn btn-outline-light">Apply</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Table -->
    <div class="lr-card">
      <div class="lr-card-header d-flex justify-content-between align-items-center">
        <div>
          <div class="lr-section-title mb-1">Sessions</div>
          <div class="lr-section-heading mb-0">Latest logs</div>
        </div>
        <div class="lr-stat-subtext mb-0"><?= count($sessions) ?> shown</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Date</th>
                <th>Exercise</th>
                <th>Source</th>
                <th>Reps</th>
                <th>Form</th>
                <th>Fatigue</th>
                <th class="text-end">Latency</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
            <?php if (count($sessions) === 0): ?>
              <tr>
                <td colspan="8" class="text-center py-4 lr-stat-subtext">No sessions found.</td>
              </tr>
            <?php else: ?>
              <?php foreach ($sessions as $s):
                $total = (int)$s['reps_total'];
                $good  = (int)$s['reps_good'];
                $pct   = formPct($good, $total);
              ?>
                <tr>
                  <td><?= h(date("M d, Y • g:i A", strtotime((string)$s['created_at']))) ?></td>
                  <td><span class="lr-chip-exercise"><?= h(formatExercise((string)$s['exercise_type'])) ?></span></td>
                  <td class="text-capitalize"><?= h((string)$s['source_type']) ?></td>
                  <td><?= (int)$s['reps_good'] ?> good / <?= (int)$s['reps_total'] ?> total</td>
                  <td><span class="<?= h(formBadge($pct)) ?>"><?= (int)$pct ?>%</span></td>
                  <td>
                    <span class="<?= h(fatigueBadge((int)$s['fatigue_flag'])) ?>">
                      <?= ((int)$s['fatigue_flag'] === 1) ? 'Warning' : 'Normal' ?>
                    </span>
                  </td>
                  <td class="text-end">
                    <?= $s['processing_ms'] === null ? '—' : h((string)$s['processing_ms'] . ' ms') ?>
                  </td>
                  <td class="text-end">
                    <a class="btn btn-sm btn-outline-light"
                       href="<?= $BASE_URL ?>/trainee/session-view.php?log_id=<?= (int)$s['log_id'] ?>">
                      View
                    </a>
                  </td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
            </tbody>
          </table>
        </div>
      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
