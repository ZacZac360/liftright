<?php
// liftright/web/admin/audit-logs.php
session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);

$page_title = "Audit Logs";

if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

function badge_class(string $type): string {
  return match ($type) {
    'login_success', 'otp_verify_success', 'email_verify_success' => 'lr-badge lr-badge-good',
    'login_fail', 'otp_verify_fail', 'email_verify_fail' => 'lr-badge lr-badge-danger',
    'otp_sent', 'email_verify_sent' => 'lr-badge lr-badge-warning',

    'admin_approve_account', 'trainer_application_approved', 'profile_change_approved' => 'lr-badge lr-badge-good',
    'admin_reject_account', 'trainer_application_rejected', 'profile_change_rejected' => 'lr-badge lr-badge-danger',
    'admin_suspend_account' => 'lr-badge lr-badge-warning',
    'admin_unsuspend_account' => 'lr-badge lr-badge-good',

    default => 'lr-badge lr-badge-neutral',
  };
}

function safe_json_pretty($json): string {
  if ($json === null || $json === '') return '';
  $d = json_decode((string)$json, true);
  if (!is_array($d)) return '';
  return json_encode($d, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
}

/* ---------- Inputs ---------- */
$q         = trim((string)($_GET['q'] ?? ''));
$type      = trim((string)($_GET['type'] ?? ''));
$user      = trim((string)($_GET['user'] ?? '')); // email or name
$date_from = trim((string)($_GET['from'] ?? ''));
$date_to   = trim((string)($_GET['to'] ?? ''));

$page = (int)($_GET['page'] ?? 1);
$per_page = (int)($_GET['per_page'] ?? 100);
if ($page < 1) $page = 1;

$allowedPP = [50, 100, 200, 500];
if (!in_array($per_page, $allowedPP, true)) $per_page = 100;

/* ---------- WHERE builder ---------- */
$where = [];
$params = [];
$types  = "";

// type filter
if ($type !== '') {
  $where[] = "l.event_type = ?";
  $params[] = $type;
  $types .= "s";
}

// user filter (name/email)
if ($user !== '') {
  $where[] = "(u.email LIKE ? OR u.full_name LIKE ?)";
  $like = "%" . $user . "%";
  $params[] = $like;
  $params[] = $like;
  $types .= "ss";
}

// free-text search (ip, ua, meta)
if ($q !== '') {
  $where[] = "(l.ip_address LIKE ? OR l.user_agent LIKE ? OR CAST(l.meta AS CHAR) LIKE ?)";
  $like = "%" . $q . "%";
  $params[] = $like;
  $params[] = $like;
  $params[] = $like;
  $types .= "sss";
}

// date range
if ($date_from !== '') {
  $where[] = "l.created_at >= ?";
  $params[] = $date_from . " 00:00:00";
  $types .= "s";
}
if ($date_to !== '') {
  $where[] = "l.created_at <= ?";
  $params[] = $date_to . " 23:59:59";
  $types .= "s";
}

$whereSql = $where ? ("WHERE " . implode(" AND ", $where)) : "";

/* ---------- CSV export (exports ALL filtered rows) ---------- */
$is_csv = isset($_GET['export']) && $_GET['export'] === 'csv';
if ($is_csv) {
  header('Content-Type: text/csv; charset=utf-8');
  header('Content-Disposition: attachment; filename="audit_logs.csv"');

  $sql = "
    SELECT l.created_at, l.event_id, l.event_type, l.user_id, u.email, u.full_name,
           l.ip_address, l.user_agent, l.meta
    FROM auth_audit_logs l
    LEFT JOIN users u ON l.user_id = u.user_id
    $whereSql
    ORDER BY l.created_at DESC
  ";

  $stmt = $mysqli->prepare($sql);
  if ($types) $stmt->bind_param($types, ...$params);
  $stmt->execute();
  $res = $stmt->get_result();

  $out = fopen('php://output', 'w');
  fputcsv($out, ['created_at','event_id','event_type','user_id','email','full_name','ip_address','user_agent','meta']);
  while ($row = $res->fetch_assoc()) {
    fputcsv($out, [
      $row['created_at'],
      $row['event_id'],
      $row['event_type'],
      $row['user_id'],
      $row['email'],
      $row['full_name'],
      $row['ip_address'],
      $row['user_agent'],
      $row['meta'],
    ]);
  }
  fclose($out);
  $stmt->close();
  exit;
}

/* ---------- Fetch distinct event types for dropdown ---------- */
$eventTypes = [];
$r = $mysqli->query("SELECT DISTINCT event_type FROM auth_audit_logs ORDER BY event_type ASC");
if ($r) {
  while ($row = $r->fetch_assoc()) $eventTypes[] = (string)$row['event_type'];
  $r->free();
}

/* ---------- COUNT total rows ---------- */
$countSql = "
  SELECT COUNT(*) AS cnt
  FROM auth_audit_logs l
  LEFT JOIN users u ON l.user_id = u.user_id
  $whereSql
";
$stmt = $mysqli->prepare($countSql);
if ($types) $stmt->bind_param($types, ...$params);
$stmt->execute();
$total_rows = (int)($stmt->get_result()->fetch_assoc()['cnt'] ?? 0);
$stmt->close();

$total_pages = max(1, (int)ceil($total_rows / $per_page));
if ($page > $total_pages) $page = $total_pages;
$offset = ($page - 1) * $per_page;

/* ---------- Fetch logs (paged) ---------- */
$sql = "
  SELECT l.event_id, l.user_id, l.event_type, l.ip_address, l.user_agent, l.meta, l.created_at,
         u.full_name, u.email
  FROM auth_audit_logs l
  LEFT JOIN users u ON l.user_id = u.user_id
  $whereSql
  ORDER BY l.created_at DESC
  LIMIT ? OFFSET ?
";

$types2 = $types . "ii";
$params2 = $params;
$params2[] = $per_page;
$params2[] = $offset;

$stmt = $mysqli->prepare($sql);
$stmt->bind_param($types2, ...$params2);
$stmt->execute();
$logs = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="container-fluid py-4" style="max-width: 1400px;">

  <!-- Header row (CLOSED properly before the form) -->
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div>
      <div class="lr-section-title">Audit Logs</div>
      <div style="color: var(--lr-text-muted);">
        Showing <?= ($total_rows === 0) ? 0 : ($offset + 1) ?>–<?= min($offset + $per_page, $total_rows) ?> of <?= (int)$total_rows ?>
      </div>
    </div>

    <div class="d-flex gap-2">
      <a class="btn btn-success"
         href="<?= h($BASE_URL) ?>/admin/audit-logs.php?<?= h(http_build_query(array_merge($_GET, ['export'=>'csv']))) ?>">
        <i class="fa-solid fa-file-csv me-2"></i>Export CSV
      </a>
    </div>
  </div>

  <!-- Filters (NOT inside the header flex row) -->
  <form class="lr-card p-3 mb-3" method="get">
    <div class="row g-2 align-items-end">
      <div class="col-md-3">
        <label class="form-label">Event type</label>
        <select class="form-control" name="type">
          <option value="">All</option>
          <?php foreach ($eventTypes as $t): ?>
            <option value="<?= h($t) ?>" <?= $t === $type ? 'selected' : '' ?>><?= h($t) ?></option>
          <?php endforeach; ?>
        </select>
      </div>

      <div class="col-md-3">
        <label class="form-label">User (name/email)</label>
        <input class="form-control" name="user" value="<?= h($user) ?>" placeholder="admin@... or Juan">
      </div>

      <div class="col-md-3">
        <label class="form-label">Search (IP / UA / meta)</label>
        <input class="form-control" name="q" value="<?= h($q) ?>" placeholder="127.0.0.1 / Chrome / session_id">
      </div>

      <div class="col-md-3 d-flex gap-2">
        <div style="flex:1;">
          <label class="form-label">From</label>
          <input class="form-control" type="date" name="from" value="<?= h($date_from) ?>">
        </div>
        <div style="flex:1;">
          <label class="form-label">To</label>
          <input class="form-control" type="date" name="to" value="<?= h($date_to) ?>">
        </div>
      </div>

      <div class="col-md-3">
        <label class="form-label">Per page</label>
        <select class="form-control" name="per_page">
          <?php foreach ([50,100,200,500] as $n): ?>
            <option value="<?= $n ?>" <?= $per_page === $n ? 'selected' : '' ?>><?= $n ?></option>
          <?php endforeach; ?>
        </select>
      </div>

      <input type="hidden" name="page" value="1">

      <div class="col-md-9 d-flex gap-2 justify-content-end">
        <button class="btn btn-primary" type="submit">Apply</button>
        <a class="btn btn-outline-light" href="<?= h($BASE_URL) ?>/admin/audit-logs.php">Reset</a>
      </div>
    </div>
  </form>

  <div class="lr-card p-0">
    <div class="table-responsive">
      <table class="table table-dark table-striped table-bordered align-middle mb-0">
        <thead>
          <tr>
            <th style="width:170px;">Time</th>
            <th style="width:90px;">ID</th>
            <th style="width:180px;">Event</th>
            <th style="width:220px;">User</th>
            <th style="width:140px;">IP</th>
            <th>Details</th>
          </tr>
        </thead>
        <tbody>
          <?php if (!$logs): ?>
            <tr><td colspan="6" class="text-center" style="color:var(--lr-text-muted);">No logs found.</td></tr>
          <?php else: ?>
            <?php foreach ($logs as $log): ?>
              <?php
                $etype = (string)$log['event_type'];
                $badge = badge_class($etype);
                $metaPretty = safe_json_pretty($log['meta'] ?? null);
                $userLabel = ($log['full_name'] ? $log['full_name'] : 'System/Guest');
                $userEmail = ($log['email'] ? $log['email'] : '-');
              ?>
              <tr>
                <td><?= h($log['created_at']) ?></td>
                <td>#<?= (int)$log['event_id'] ?></td>
                <td><span class="<?= h($badge) ?>"><?= h($etype) ?></span></td>
                <td>
                  <div style="font-weight:700;"><?= h($userLabel) ?></div>
                  <div style="color:var(--lr-text-muted); font-size:12px;"><?= h($userEmail) ?></div>
                </td>
                <td><?= h($log['ip_address'] ?? '-') ?></td>
                <td>
                  <?php if ($metaPretty): ?>
                    <details>
                      <summary style="cursor:pointer; color: var(--lr-accent);">view meta</summary>
                      <pre style="margin:8px 0 0; font-size:12px; white-space:pre-wrap;"><?= h($metaPretty) ?></pre>
                    </details>
                  <?php else: ?>
                    <span style="color:var(--lr-text-muted);">-</span>
                  <?php endif; ?>

                  <?php if (!empty($log['user_agent'])): ?>
                    <div style="margin-top:6px; color:var(--lr-text-muted); font-size:12px;">
                      UA: <?= h($log['user_agent']) ?>
                    </div>
                  <?php endif; ?>
                </td>
              </tr>
            <?php endforeach; ?>
          <?php endif; ?>
        </tbody>
      </table>
    </div>

    <div class="d-flex justify-content-between align-items-center p-3 border-top">
      <div style="color:var(--lr-text-muted);">
        Page <?= (int)$page ?> of <?= (int)$total_pages ?>
      </div>

      <nav aria-label="Audit logs pagination">
        <ul class="pagination pagination-sm mb-0">
          <?php
            $prevDisabled = ($page <= 1) ? ' disabled' : '';
            $nextDisabled = ($page >= $total_pages) ? ' disabled' : '';

            $prevUrl = $BASE_URL . "/admin/audit-logs.php?" . http_build_query(array_merge($_GET, ['page' => max(1, $page - 1)]));
            $nextUrl = $BASE_URL . "/admin/audit-logs.php?" . http_build_query(array_merge($_GET, ['page' => min($total_pages, $page + 1)]));
          ?>
          <li class="page-item<?= $prevDisabled ?>">
            <a class="page-link" href="<?= $prevDisabled ? '#' : h($prevUrl) ?>">Prev</a>
          </li>
          <li class="page-item<?= $nextDisabled ?>">
            <a class="page-link" href="<?= $nextDisabled ? '#' : h($nextUrl) ?>">Next</a>
          </li>
        </ul>
      </nav>
    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>