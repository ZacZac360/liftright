<?php
// liftright/web/coach/review-history.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['trainer']);
$page_title = "Review History";

$trainer_id = (int)($_SESSION['user_id'] ?? 0);

require_once __DIR__ . '/../includes/text_helpers.php';

function formatExercise(string $ex): string {
  return match($ex) {
    'shoulder_press' => 'Shoulder Press',
    'bicep_curl'     => 'Bicep Curl',
    'lateral_raise'  => 'Lateral Raise',
    default          => ucwords(str_replace('_',' ', $ex)),
  };
}
function fmtDT(?string $dt): string {
  if (!$dt) return "—";
  $ts = strtotime($dt);
  return $ts ? date("M d, Y • g:i A", $ts) : $dt;
}

/* ---------- Filters ---------- */
$q        = trim((string)($_GET['q'] ?? ''));          // trainee/email/log_id
$exercise = trim((string)($_GET['exercise'] ?? ''));   // bicep_curl/...
$rating   = trim((string)($_GET['rating'] ?? ''));     // 1..5
$hasNotes = trim((string)($_GET['has_notes'] ?? ''));  // 0/1

$allowedExercises = ['bicep_curl','shoulder_press','lateral_raise'];
$exercise = in_array($exercise, $allowedExercises, true) ? $exercise : '';

$allowedRatings = ['1','2','3','4','5'];
$rating = in_array($rating, $allowedRatings, true) ? $rating : '';

$allowedHasNotes = ['0','1'];
$hasNotes = in_array($hasNotes, $allowedHasNotes, true) ? $hasNotes : '';

// Paging
$page = (int)($_GET['page'] ?? 1);
$per_page = (int)($_GET['per_page'] ?? 25);
if ($page < 1) $page = 1;

$allowedPP = [10, 25, 50, 100];
if (!in_array($per_page, $allowedPP, true)) $per_page = 25;

/* ---------- Query (WHERE builder) ---------- */
$where = " WHERE er.trainer_id = ? ";
$types = "i";
$params = [$trainer_id];

if ($exercise !== '') {
  $where .= " AND tl.exercise_type = ? ";
  $types .= "s";
  $params[] = $exercise;
}
if ($rating !== '') {
  $where .= " AND er.rating = ? ";
  $types .= "i";
  $params[] = (int)$rating;
}
if ($hasNotes !== '') {
  if ($hasNotes === '1') $where .= " AND er.notes IS NOT NULL AND TRIM(er.notes) <> '' ";
  else                  $where .= " AND (er.notes IS NULL OR TRIM(er.notes) = '') ";
}
if ($q !== '') {
  $where .= "
    AND (
      CAST(er.log_id AS CHAR) = ?
      OR u.full_name LIKE CONCAT('%', ?, '%')
      OR u.email LIKE CONCAT('%', ?, '%')
    )
  ";
  $types .= "sss";
  $params[] = $q; $params[] = $q; $params[] = $q;
}

/* ---------- Total count ---------- */
$countSql = "
  SELECT COUNT(*) AS cnt
  FROM expert_reviews er
  LEFT JOIN training_logs tl ON tl.log_id = er.log_id
  LEFT JOIN users u ON u.user_id = tl.user_id
  $where
";
$stmt = $mysqli->prepare($countSql);
$stmt->bind_param($types, ...$params);
$stmt->execute();
$total_rows = (int)($stmt->get_result()->fetch_assoc()['cnt'] ?? 0);
$stmt->close();

$total_pages = max(1, (int)ceil($total_rows / $per_page));
if ($page > $total_pages) $page = $total_pages;
$offset = ($page - 1) * $per_page;

/* ---------- Page rows ---------- */
$dataSql = "
  SELECT
    er.review_id,
    er.log_id,
    er.rating,
    er.notes,
    er.created_at AS reviewed_at,
    tl.exercise_type,
    tl.created_at AS session_date,
    u.full_name AS trainee_name,
    u.email AS trainee_email
  FROM expert_reviews er
  LEFT JOIN training_logs tl ON tl.log_id = er.log_id
  LEFT JOIN users u ON u.user_id = tl.user_id
  $where
  ORDER BY er.created_at DESC
  LIMIT ? OFFSET ?
";

$dataTypes = $types . "ii";
$dataParams = $params;
$dataParams[] = $per_page;
$dataParams[] = $offset;

$stmt = $mysqli->prepare($dataSql);
$stmt->bind_param($dataTypes, ...$dataParams);
$stmt->execute();
$res = $stmt->get_result();

$reviews = [];
while ($r = $res->fetch_assoc()) $reviews[] = $r;
$stmt->close();

/* ---------- URL builder ---------- */
function build_query(array $overrides = []): string {
  $q = $_GET;
  foreach ($overrides as $k => $v) {
    if ($v === null) unset($q[$k]);
    else $q[$k] = $v;
  }
  return http_build_query($q);
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
        <div class="lr-section-title mb-1">Coach</div>
        <h1 class="lr-section-heading mb-1">Review History</h1>
        <p class="lr-stat-subtext mb-0">Browse your submitted expert reviews. Use filters to find a session fast.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/coach/profile.php">Back to Profile</a>
      </div>
    </div>

    <!-- Filters -->
    <div class="lr-card mb-4">
      <div class="lr-card-body">
        <form method="get" class="row g-2 align-items-end">
          <div class="col-md-5">
            <label class="form-label lr-stat-label">Search</label>
            <input class="form-control" name="q"
                   placeholder="Trainee name, email, or Session ID..."
                   value="<?= h($q) ?>">
          </div>

          <div class="col-md-3">
            <label class="form-label lr-stat-label">Exercise</label>
            <select class="form-select" name="exercise">
              <option value="">All</option>
              <option value="bicep_curl" <?= $exercise==='bicep_curl'?'selected':'' ?>>Bicep Curl</option>
              <option value="shoulder_press" <?= $exercise==='shoulder_press'?'selected':'' ?>>Shoulder Press</option>
              <option value="lateral_raise" <?= $exercise==='lateral_raise'?'selected':'' ?>>Lateral Raise</option>
            </select>
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Rating</label>
            <select class="form-select" name="rating">
              <option value="">All</option>
              <option value="5" <?= $rating==='5'?'selected':'' ?>>5</option>
              <option value="4" <?= $rating==='4'?'selected':'' ?>>4</option>
              <option value="3" <?= $rating==='3'?'selected':'' ?>>3</option>
              <option value="2" <?= $rating==='2'?'selected':'' ?>>2</option>
              <option value="1" <?= $rating==='1'?'selected':'' ?>>1</option>
            </select>
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Notes</label>
            <select class="form-select" name="has_notes">
              <option value="">All</option>
              <option value="1" <?= $hasNotes==='1'?'selected':'' ?>>With notes</option>
              <option value="0" <?= $hasNotes==='0'?'selected':'' ?>>No notes</option>
            </select>
          </div>

          <div class="col-md-2">
            <label class="form-label lr-stat-label">Per page</label>
            <select class="form-select" name="per_page">
              <?php foreach ([10,25,50,100] as $pp): ?>
                <option value="<?= $pp ?>" <?= ($per_page===$pp)?'selected':'' ?>><?= $pp ?></option>
              <?php endforeach; ?>
            </select>
          </div>

          <input type="hidden" name="page" value="1">

          <div class="col-12 d-flex gap-2 mt-2">
            <button class="btn btn-outline-light" type="submit">Apply</button>
            <a class="btn btn-outline-light" href="<?= $BASE_URL ?>/coach/review-history.php">Reset</a>
          </div>
        </form>
      </div>
    </div>

    <!-- List -->
    <div class="lr-card">
      <div class="lr-card-header d-flex justify-content-between align-items-center">
        <div>
          <div class="lr-section-title mb-1">Results</div>
          <div class="lr-section-heading mb-0">Submitted reviews</div>
        </div>
        <div class="lr-stat-subtext mb-0"><?= count($reviews) ?> shown</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Reviewed</th>
                <th>Trainee</th>
                <th>Session</th>
                <th>Exercise</th>
                <th class="text-end">Rating</th>
                <th>Notes</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
            <?php if (!$reviews): ?>
              <tr>
                <td colspan="7" class="text-center py-4 lr-stat-subtext">No matching reviews found.</td>
              </tr>
            <?php else: ?>
              <?php foreach ($reviews as $r): ?>
                <?php
                  $notes = (string)($r['notes'] ?? '');
                  $has = (trim($notes) !== '');
                  $log_id = (int)($r['log_id'] ?? 0);
                ?>
                <tr>
                  <td><?= h(fmtDT((string)$r['reviewed_at'])) ?></td>

                  <td>
                    <div class="fw-semibold"><?= h((string)($r['trainee_name'] ?? 'Unknown Trainee')) ?></div>
                    <div class="lr-stat-subtext"><?= h((string)($r['trainee_email'] ?? '—')) ?></div>
                  </td>

                  <td>
                    <div class="fw-semibold">#<?= $log_id ?></div>
                    <div class="lr-stat-subtext"><?= h(fmtDT((string)$r['session_date'])) ?></div>
                  </td>

                  <td>
                    <span class="lr-chip-exercise">
                      <?= h(formatExercise((string)($r['exercise_type'] ?? 'unknown'))) ?>
                    </span>
                  </td>

                  <td class="text-end">
                    <span class="lr-badge lr-badge-good"><?= (int)$r['rating'] ?>/5</span>
                  </td>

                  <td style="max-width: 420px;">
                    <?php if (!$has): ?>
                      <span class="lr-stat-subtext">—</span>
                    <?php else: ?>
                      <span class="lr-stat-subtext"><?= h(lr_snippet($notes, 140)) ?></span>
                    <?php endif; ?>
                  </td>

                  <td class="text-end">
                    <a class="btn btn-sm btn-outline-light"
                       href="<?= $BASE_URL ?>/coach/review-session.php?log_id=<?= $log_id ?>">
                      Open
                    </a>
                  </td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
            </tbody>
          </table>
        </div>
      </div>

      <div class="d-flex justify-content-between align-items-center p-3">
  <div class="lr-stat-subtext mb-0">
    Showing <?= ($total_rows === 0) ? 0 : ($offset + 1) ?>–<?= min($offset + $per_page, $total_rows) ?> of <?= $total_rows ?>
  </div>

  <nav aria-label="Review history pagination">
    <ul class="pagination pagination-sm mb-0">
      <?php
        $prevDisabled = ($page <= 1) ? ' disabled' : '';
        $nextDisabled = ($page >= $total_pages) ? ' disabled' : '';

        $prevUrl = $BASE_URL . "/coach/review-history.php?" . build_query(['page' => max(1, $page - 1)]);
        $nextUrl = $BASE_URL . "/coach/review-history.php?" . build_query(['page' => min($total_pages, $page + 1)]);
      ?>
      <li class="page-item<?= $prevDisabled ?>">
        <a class="page-link" href="<?= $prevDisabled ? '#' : h($prevUrl) ?>">Prev</a>
      </li>

      <li class="page-item active">
        <span class="page-link"><?= (int)$page ?>/<?= (int)$total_pages ?></span>
      </li>

      <li class="page-item<?= $nextDisabled ?>">
        <a class="page-link" href="<?= $nextDisabled ? '#' : h($nextUrl) ?>">Next</a>
      </li>
    </ul>
  </nav>
</div>

      <?php if ($reviews): ?>
        <div class="lr-card-body">
          <div class="lr-stat-subtext mb-0">
            Tip: Use Search to jump to a specific session (#log_id) or find a trainee by name/email.
          </div>
        </div>
      <?php endif; ?>

    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>