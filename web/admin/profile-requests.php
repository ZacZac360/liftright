<?php
// liftright/web/admin/profile-requests.php
session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';
require_once __DIR__ . '/../includes/profile_change_helpers.php';

require_role(['admin']);
$page_title = "Profile Requests";

$admin_id = (int)($_SESSION['user_id'] ?? 0);
$flash = null;

/* ---------- Actions ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $action = (string)($_POST['action'] ?? '');
  $request_id = (int)($_POST['request_id'] ?? 0);
  $admin_notes = trim((string)($_POST['admin_notes'] ?? ''));

  try {
    if ($request_id <= 0) throw new Exception("Invalid request.");

    // Load request (must still be pending)
    $stmt = $mysqli->prepare("
      SELECT r.*, u.full_name AS current_name, u.email AS current_email, u.age AS current_age
      FROM profile_change_requests r
      JOIN users u ON u.user_id = r.user_id
      WHERE r.request_id = ? AND r.status = 'pending'
      LIMIT 1
    ");
    $stmt->bind_param("i", $request_id);
    $stmt->execute();
    $req = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$req) throw new Exception("Request not found or already processed.");

    $target_user_id = (int)$req['user_id'];

    if ($action === 'approve') {

      // Validate new email uniqueness if email is changing
      $newEmail = (string)($req['requested_email'] ?? '');
      if ($newEmail !== '') {
        $stmt = $mysqli->prepare("SELECT 1 FROM users WHERE email = ? AND user_id <> ? LIMIT 1");
        $stmt->bind_param("si", $newEmail, $target_user_id);
        $stmt->execute();
        $exists = $stmt->get_result()->num_rows > 0;
        $stmt->close();
        if ($exists) throw new Exception("Requested email is already in use.");
      }

      // Apply changes to users table (only update fields that are non-null in request)
      $newName = $req['requested_full_name'];
      $newAge  = $req['requested_age']; // can be null

      $stmt = $mysqli->prepare("
        UPDATE users
        SET
          full_name = COALESCE(?, full_name),
          email     = COALESCE(?, email),
          age       = ?
        WHERE user_id = ?
      ");

      // For age: if request has NULL, keep existing by passing existing age
      $ageToSet = ($req['requested_age'] === null) ? $req['current_age'] : (int)$req['requested_age'];

      $stmt->bind_param(
        "ssii",
        $newName,
        $newEmail,
        $ageToSet,
        $target_user_id
      );
      $stmt->execute();
      $stmt->close();

      // Mark request approved
      $stmt = $mysqli->prepare("
        UPDATE profile_change_requests
        SET status='approved', reviewed_at=NOW(), reviewed_by=?, admin_notes=?
        WHERE request_id=?
      ");
      $stmt->bind_param("isi", $admin_id, $admin_notes, $request_id);
      $stmt->execute();
      $stmt->close();

      notify_user($mysqli, $target_user_id, 'system', "Your profile update was approved by an admin.", $admin_id);

      $flash = "Approved request #{$request_id}.";

    } elseif ($action === 'reject') {

      $stmt = $mysqli->prepare("
        UPDATE profile_change_requests
        SET status='rejected', reviewed_at=NOW(), reviewed_by=?, admin_notes=?
        WHERE request_id=?
      ");
      $stmt->bind_param("isi", $admin_id, $admin_notes, $request_id);
      $stmt->execute();
      $stmt->close();

      notify_user($mysqli, $target_user_id, 'system', "Your profile update was rejected by an admin.", $admin_id);

      $flash = "Rejected request #{$request_id}.";

    } else {
      throw new Exception("Unknown action.");
    }

  } catch (Throwable $e) {
    $flash = "Error: " . $e->getMessage();
  }
}

/* ---------- Filters ---------- */
$status = trim((string)($_GET['status'] ?? 'pending'));
$allowed = ['pending','approved','rejected','cancelled'];
if (!in_array($status, $allowed, true)) $status = 'pending';

$q = trim((string)($_GET['q'] ?? ''));

/* ---------- Fetch list ---------- */
$sql = "
  SELECT
    r.request_id, r.user_id,
    r.requested_full_name, r.requested_email, r.requested_age,
    r.status, r.created_at, r.reviewed_at, r.reviewed_by, r.admin_notes,
    u.full_name AS current_name, u.email AS current_email, u.age AS current_age, u.role
  FROM profile_change_requests r
  JOIN users u ON u.user_id = r.user_id
  WHERE r.status = ?
";
$types = "s";
$params = [$status];

if ($q !== '') {
  $sql .= " AND (u.full_name LIKE CONCAT('%', ?, '%') OR u.email LIKE CONCAT('%', ?, '%') OR CAST(r.request_id AS CHAR) = ?) ";
  $types .= "sss";
  $params[] = $q;
  $params[] = $q;
  $params[] = $q;
}

$sql .= " ORDER BY r.created_at DESC LIMIT 250";

$stmt = $mysqli->prepare($sql);
$stmt->bind_param($types, ...$params);
$stmt->execute();
$res = $stmt->get_result();
$rows = [];
while ($r = $res->fetch_assoc()) $rows[] = $r;
$stmt->close();

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-3 align-items-center">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Administration</div>
        <h1 class="lr-section-heading mb-1">Profile Change Requests</h1>
        <p class="lr-stat-subtext mb-0">Approve or reject pending profile changes for trainees and trainers.</p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/admin/users.php">Back to Users</a>
      </div>
    </div>

    <?php if ($flash): ?>
      <div class="alert alert-dark border border-secondary"><?= h($flash) ?></div>
    <?php endif; ?>

    <div class="lr-card mb-3">
      <div class="lr-card-body">
        <form method="get" class="row g-2 align-items-end">
          <div class="col-md-5">
            <label class="form-label lr-stat-label">Search</label>
            <input class="form-control" name="q" value="<?= h($q) ?>" placeholder="Name, email, or Request ID...">
          </div>
          <div class="col-md-3">
            <label class="form-label lr-stat-label">Status</label>
            <select class="form-select" name="status">
              <?php foreach (['pending','approved','rejected','cancelled'] as $s): ?>
                <option value="<?= h($s) ?>" <?= $status===$s?'selected':'' ?>><?= h($s) ?></option>
              <?php endforeach; ?>
            </select>
          </div>
          <div class="col-md-4 d-grid">
            <button class="btn btn-primary" type="submit">Apply</button>
          </div>
        </form>
      </div>
    </div>

    <div class="lr-card">
      <div class="lr-card-header d-flex justify-content-between align-items-center">
        <div>
          <div class="lr-section-title mb-1">Requests</div>
          <div class="lr-section-heading mb-0"><?= h(ucfirst($status)) ?> requests</div>
        </div>
        <div class="lr-stat-subtext mb-0"><?= count($rows) ?> shown</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>ID</th>
                <th>User</th>
                <th>Role</th>
                <th>Current</th>
                <th>Requested</th>
                <th>Submitted</th>
                <th class="text-end">Action</th>
              </tr>
            </thead>
            <tbody>
            <?php if (!$rows): ?>
              <tr><td colspan="7" class="text-center py-4 lr-stat-subtext">No requests found.</td></tr>
            <?php else: ?>
              <?php foreach ($rows as $r): ?>
                <tr>
                  <td class="fw-semibold">#<?= (int)$r['request_id'] ?></td>

                  <td>
                    <div class="fw-semibold"><?= h((string)$r['current_name']) ?></div>
                    <div class="lr-stat-subtext"><?= h((string)$r['current_email']) ?></div>
                  </td>

                  <td><span class="lr-chip-exercise"><?= h((string)$r['role']) ?></span></td>

                  <td style="max-width: 360px;">
                    <div class="lr-stat-subtext">
                      Name: <?= h((string)$r['current_name']) ?><br>
                      Email: <?= h((string)$r['current_email']) ?><br>
                      Age: <?= $r['current_age'] === null ? '—' : (int)$r['current_age'] ?>
                    </div>
                  </td>

                  <td style="max-width: 360px;">
                    <div class="lr-stat-subtext">
                      Name: <?= h((string)($r['requested_full_name'] ?? '—')) ?><br>
                      Email: <?= h((string)($r['requested_email'] ?? '—')) ?><br>
                      Age: <?= $r['requested_age'] === null ? '—' : (int)$r['requested_age'] ?>
                    </div>
                  </td>

                  <td><?= h(date("M d, Y • g:i A", strtotime((string)$r['created_at']))) ?></td>

                  <td class="text-end">
                    <?php if ((string)$r['status'] !== 'pending'): ?>
                      <span class="lr-stat-subtext">—</span>
                    <?php else: ?>
                      <form method="post" class="d-inline-flex gap-2 align-items-center">
                        <input type="hidden" name="request_id" value="<?= (int)$r['request_id'] ?>">
                        <input type="text" class="form-control form-control-sm"
                               name="admin_notes" placeholder="Admin notes (optional)" style="width: 220px;">
                        <button class="btn btn-sm btn-outline-light" name="action" value="approve"
                                onclick="return confirm('Approve this profile change request?');">
                          Approve
                        </button>
                        <button class="btn btn-sm btn-outline-danger" name="action" value="reject"
                                onclick="return confirm('Reject this profile change request?');">
                          Reject
                        </button>
                      </form>
                    <?php endif; ?>
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