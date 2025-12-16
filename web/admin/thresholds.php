<?php
// liftright/web/admin/thresholds.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);

$page_title = "Error Thresholds";

$flash = null;

function formatExercise(string $ex): string {
  return match($ex) {
    'shoulder_press' => 'Shoulder Press',
    'bicep_curl'     => 'Bicep Curl',
    'lateral_raise'  => 'Lateral Raise',
    default          => ucwords(str_replace('_',' ', $ex)),
  };
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $action = (string)($_POST['action'] ?? '');

  try {
    if ($action === 'update') {
      $threshold_id = (int)($_POST['threshold_id'] ?? 0);
      $exercise_type = (string)($_POST['exercise_type'] ?? '');
      $metric_key = trim((string)($_POST['metric_key'] ?? ''));
      $compare_op = (string)($_POST['compare_op'] ?? '>');
      $metric_value = (float)($_POST['metric_value'] ?? 0);
      $severity = (string)($_POST['severity'] ?? 'warning');
      $enabled = isset($_POST['enabled']) ? 1 : 0;
      $notes = trim((string)($_POST['notes'] ?? ''));

      if (!in_array($exercise_type, ['bicep_curl','shoulder_press','lateral_raise'], true)) throw new Exception("Invalid exercise_type.");
      if ($metric_key === '') throw new Exception("metric_key required.");
      if (!in_array($compare_op, ['>','>=','<','<='], true)) throw new Exception("Invalid compare_op.");
      if (!in_array($severity, ['info','warning','danger'], true)) throw new Exception("Invalid severity.");

      $stmt = $mysqli->prepare("
        UPDATE error_thresholds
        SET exercise_type=?, metric_key=?, compare_op=?, metric_value=?, severity=?, enabled=?, notes=?
        WHERE threshold_id=?
      ");
      $stmt->bind_param("sssdsi si", $exercise_type, $metric_key, $compare_op, $metric_value, $severity, $enabled, $notes, $threshold_id);
      // ^ mysqli bind types must be continuous; build correctly:
      $stmt->close();
      // redo with correct bind types:
      $stmt = $mysqli->prepare("
        UPDATE error_thresholds
        SET exercise_type=?, metric_key=?, compare_op=?, metric_value=?, severity=?, enabled=?, notes=?
        WHERE threshold_id=?
      ");
      $stmt->bind_param("sssdsisi", $exercise_type, $metric_key, $compare_op, $metric_value, $severity, $enabled, $notes, $threshold_id);
      $stmt->execute();
      $stmt->close();

      $flash = "Updated threshold.";
    }

    if ($action === 'create') {
      $exercise_type = (string)($_POST['exercise_type'] ?? '');
      $metric_key = trim((string)($_POST['metric_key'] ?? ''));
      $compare_op = (string)($_POST['compare_op'] ?? '>');
      $metric_value = (float)($_POST['metric_value'] ?? 0);
      $severity = (string)($_POST['severity'] ?? 'warning');
      $enabled = isset($_POST['enabled']) ? 1 : 0;
      $notes = trim((string)($_POST['notes'] ?? ''));

      if (!in_array($exercise_type, ['bicep_curl','shoulder_press','lateral_raise'], true)) throw new Exception("Invalid exercise_type.");
      if ($metric_key === '') throw new Exception("metric_key required.");
      if (!in_array($compare_op, ['>','>=','<','<='], true)) throw new Exception("Invalid compare_op.");
      if (!in_array($severity, ['info','warning','danger'], true)) throw new Exception("Invalid severity.");

      $stmt = $mysqli->prepare("
        INSERT INTO error_thresholds (exercise_type, metric_key, compare_op, metric_value, severity, enabled, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ");
      $stmt->bind_param("sssdsis", $exercise_type, $metric_key, $compare_op, $metric_value, $severity, $enabled, $notes);
      $stmt->execute();
      $stmt->close();

      $flash = "Created threshold.";
    }

    if ($action === 'delete') {
      $threshold_id = (int)($_POST['threshold_id'] ?? 0);
      $stmt = $mysqli->prepare("DELETE FROM error_thresholds WHERE threshold_id=?");
      $stmt->bind_param("i", $threshold_id);
      $stmt->execute();
      $stmt->close();

      $flash = "Deleted threshold.";
    }
  } catch (Throwable $e) {
    $flash = "Error: " . $e->getMessage();
  }
}

// Filters
$exerciseFilter = trim((string)($_GET['exercise'] ?? ''));
$enabledFilter  = trim((string)($_GET['enabled'] ?? ''));

$rows = [];

$sql = "
  SELECT threshold_id, exercise_type, metric_key, compare_op, metric_value, severity, enabled, notes, updated_at
  FROM error_thresholds
  WHERE 1=1
";
$types = "";
$params = [];

if (in_array($exerciseFilter, ['bicep_curl','shoulder_press','lateral_raise'], true)) {
  $sql .= " AND exercise_type = ?";
  $types .= "s";
  $params[] = $exerciseFilter;
}
if ($enabledFilter === '1' || $enabledFilter === '0') {
  $sql .= " AND enabled = ?";
  $types .= "i";
  $params[] = (int)$enabledFilter;
}

$sql .= " ORDER BY exercise_type ASC, metric_key ASC, compare_op ASC";

$stmt = $mysqli->prepare($sql);
if ($types !== "") $stmt->bind_param($types, ...$params);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $rows[] = $r;
$stmt->close();

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-3">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">System Integrity</div>
        <h1 class="lr-section-heading mb-1">Error Thresholds</h1>
        <p class="lr-stat-subtext mb-0">Admin-controlled parameters for rule-based feedback (prototype).</p>
      </div>
    </div>

    <?php if ($flash): ?>
      <div class="alert alert-dark border border-secondary"><?= h($flash) ?></div>
    <?php endif; ?>

    <div class="lr-card mb-3">
      <div class="lr-card-body">
        <form class="row g-2" method="GET">
          <div class="col-md-5">
            <select class="form-select" name="exercise">
              <option value="">All exercises</option>
              <option value="bicep_curl" <?= $exerciseFilter==='bicep_curl'?'selected':'' ?>>Bicep Curl</option>
              <option value="shoulder_press" <?= $exerciseFilter==='shoulder_press'?'selected':'' ?>>Shoulder Press</option>
              <option value="lateral_raise" <?= $exerciseFilter==='lateral_raise'?'selected':'' ?>>Lateral Raise</option>
            </select>
          </div>
          <div class="col-md-4">
            <select class="form-select" name="enabled">
              <option value="">Enabled + Disabled</option>
              <option value="1" <?= $enabledFilter==='1'?'selected':'' ?>>Enabled only</option>
              <option value="0" <?= $enabledFilter==='0'?'selected':'' ?>>Disabled only</option>
            </select>
          </div>
          <div class="col-md-3 d-grid">
            <button class="btn btn-primary" type="submit">
              <i class="fa-solid fa-filter me-2"></i>Apply
            </button>
          </div>
        </form>
      </div>
    </div>

    <div class="lr-card mb-4">
      <div class="lr-card-header">
        <div class="lr-section-title mb-1">Create</div>
        <div class="lr-section-heading mb-0">Add New Threshold</div>
      </div>
      <div class="lr-card-body">
        <form method="POST" class="row g-2">
          <input type="hidden" name="action" value="create">

          <div class="col-md-3">
            <select class="form-select" name="exercise_type" required>
              <option value="bicep_curl">Bicep Curl</option>
              <option value="shoulder_press">Shoulder Press</option>
              <option value="lateral_raise">Lateral Raise</option>
            </select>
          </div>

          <div class="col-md-3">
            <input class="form-control" name="metric_key" placeholder="metric_key (e.g. trunk_sway)" required>
          </div>

          <div class="col-md-2">
            <select class="form-select" name="compare_op">
              <option value=">">></option>
              <option value=">=">>=</option>
              <option value="<"><</option>
              <option value="<="><=</option>
            </select>
          </div>

          <div class="col-md-2">
            <input class="form-control" name="metric_value" type="number" step="0.0001" placeholder="value" required>
          </div>

          <div class="col-md-2">
            <select class="form-select" name="severity">
              <option value="info">info</option>
              <option value="warning" selected>warning</option>
              <option value="danger">danger</option>
            </select>
          </div>

          <div class="col-md-8">
            <input class="form-control" name="notes" placeholder="notes (optional)">
          </div>

          <div class="col-md-2 d-flex align-items-center gap-2">
            <input class="form-check-input" type="checkbox" name="enabled" id="createEnabled" checked>
            <label class="form-check-label" for="createEnabled">Enabled</label>
          </div>

          <div class="col-md-2 d-grid">
            <button class="btn btn-outline-light" type="submit">
              <i class="fa-solid fa-plus me-2"></i>Add
            </button>
          </div>
        </form>
      </div>
    </div>

    <div class="lr-card">
      <div class="lr-card-header">
        <div class="lr-section-title mb-1">Library</div>
        <div class="lr-section-heading mb-0">Threshold Rules</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Exercise</th>
                <th>Metric</th>
                <th>Op</th>
                <th>Value</th>
                <th>Severity</th>
                <th>Enabled</th>
                <th>Updated</th>
                <th class="text-end">Actions</th>
              </tr>
            </thead>
            <tbody>
            <?php if (count($rows) === 0): ?>
              <tr><td colspan="8" class="text-center py-4 lr-stat-subtext">No thresholds found.</td></tr>
            <?php else: ?>
              <?php foreach ($rows as $t): ?>
                <tr>
                  <td><?= h(formatExercise((string)$t['exercise_type'])) ?></td>

                  <td>
                    <form method="POST" class="d-flex gap-2 align-items-center">
                      <input type="hidden" name="action" value="update">
                      <input type="hidden" name="threshold_id" value="<?= (int)$t['threshold_id'] ?>">

                      <input type="hidden" name="exercise_type" value="<?= h((string)$t['exercise_type']) ?>">
                      <input class="form-control form-control-sm" name="metric_key" value="<?= h((string)$t['metric_key']) ?>" style="min-width: 170px;">
                  </td>

                  <td>
                      <select class="form-select form-select-sm" name="compare_op" style="width: 90px;">
                        <?php foreach (['>','>=','<','<='] as $op): ?>
                          <option value="<?= h($op) ?>" <?= ((string)$t['compare_op']===$op)?'selected':'' ?>><?= h($op) ?></option>
                        <?php endforeach; ?>
                      </select>
                  </td>

                  <td>
                      <input class="form-control form-control-sm" name="metric_value" type="number" step="0.0001"
                             value="<?= h((string)$t['metric_value']) ?>" style="width: 120px;">
                  </td>

                  <td>
                      <select class="form-select form-select-sm" name="severity" style="width: 120px;">
                        <?php foreach (['info','warning','danger'] as $sev): ?>
                          <option value="<?= h($sev) ?>" <?= ((string)$t['severity']===$sev)?'selected':'' ?>><?= h($sev) ?></option>
                        <?php endforeach; ?>
                      </select>
                  </td>

                  <td class="text-center">
                      <input class="form-check-input" type="checkbox" name="enabled" <?= ((int)$t['enabled']===1)?'checked':'' ?>>
                  </td>

                  <td><?= h(date("M d, Y", strtotime((string)$t['updated_at']))) ?></td>

                  <td class="text-end">
                      <input class="form-control form-control-sm mb-2" name="notes" value="<?= h((string)$t['notes']) ?>" placeholder="notes" style="min-width: 220px;">
                      <div class="d-flex justify-content-end gap-2">
                        <button class="btn btn-sm btn-outline-light" type="submit">Save</button>
                      </div>
                    </form>

                    <form method="POST" class="d-inline" onsubmit="return confirm('Delete this threshold?');">
                      <input type="hidden" name="action" value="delete">
                      <input type="hidden" name="threshold_id" value="<?= (int)$t['threshold_id'] ?>">
                      <button class="btn btn-sm btn-outline-danger" type="submit">
                        <i class="fa-solid fa-trash"></i>
                      </button>
                    </form>
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
