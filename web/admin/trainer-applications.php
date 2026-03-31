<?php
// liftright/web/admin/trainer-applications.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';
require_once __DIR__ . '/../config/audit.php';

require_role(['admin']);

$page_title = "Trainer Applications";

/* ---------- Helpers ---------- */
if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}
if (!function_exists('fmtDT')) {
  function fmtDT(?string $dt): string {
    if (!$dt) return "—";
    $ts = strtotime($dt);
    return $ts ? date("M d, Y • g:i A", $ts) : $dt;
  }
}
if (!function_exists('badgeAppClass')) {
  function badgeAppClass(string $status): string {
    return match ($status) {
      'approved' => 'lr-badge lr-badge-good',
      'pending'  => 'lr-badge lr-badge-warning',
      'rejected' => 'lr-badge lr-badge-danger',
      default    => 'lr-badge lr-badge-warning',
    };
  }
}
if (!function_exists('credLabel')) {
  function credLabel(string $t): string {
    return match ($t) {
      'cpt'     => 'Certified Personal Trainer',
      'scs'     => 'Strength & Conditioning Coach',
      'pt'      => 'Physical Therapist',
      'student' => 'Student / In training',
      'other'   => 'Other',
      default   => $t,
    };
  }
}

$flash = null;
$flash_kind = 'dark';

/* ---------- Handle actions ---------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $action = (string)($_POST['action'] ?? '');
  $app_id = (int)($_POST['app_id'] ?? 0);
  $notes  = trim((string)($_POST['admin_notes'] ?? ''));

  try {
    if ($app_id <= 0) throw new Exception("Invalid application.");

    $admin_id = (int)($_SESSION['user_id'] ?? 0);

    // Fetch app + user
    $stmt = $mysqli->prepare("
      SELECT ta.app_id, ta.user_id, ta.status, u.account_status, u.role
      FROM trainer_applications ta
      JOIN users u ON u.user_id = ta.user_id
      WHERE ta.app_id = ?
      LIMIT 1
    ");
    $stmt->bind_param("i", $app_id);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row) throw new Exception("Application not found.");

    $user_id = (int)$row['user_id'];

    if ($action === 'approve') {
      // Approve application + approve user account (role should already be trainer)
      $stmt = $mysqli->prepare("
        UPDATE trainer_applications
        SET status='approved', reviewed_by=?, reviewed_at=NOW(), admin_notes=?
        WHERE app_id=?
      ");
      $stmt->bind_param("isi", $admin_id, $notes, $app_id);
      $stmt->execute();
      $stmt->close();

      $stmt = $mysqli->prepare("
        UPDATE users
        SET account_status='approved'
        WHERE user_id=? AND role='trainer'
      ");
      $stmt->bind_param("i", $user_id);
      $stmt->execute();
      $stmt->close();

      audit_admin_action($mysqli, $admin_id, 'trainer_application_approved', $user_id, [
        'app_id' => $app_id,
        'admin_notes' => $notes
      ]);

      $flash = "Trainer application approved and account approved.";
      $flash_kind = "success";
    }
    elseif ($action === 'reject') {
      // Reject application + reject user account
      $stmt = $mysqli->prepare("
        UPDATE trainer_applications
        SET status='rejected', reviewed_by=?, reviewed_at=NOW(), admin_notes=?
        WHERE app_id=?
      ");
      $stmt->bind_param("isi", $admin_id, $notes, $app_id);
      $stmt->execute();
      $stmt->close();

      $stmt = $mysqli->prepare("
        UPDATE users
        SET account_status='rejected'
        WHERE user_id=? AND role='trainer'
      ");
      $stmt->bind_param("i", $user_id);
      $stmt->execute();
      $stmt->close();

      audit_admin_action($mysqli, $admin_id, 'trainer_application_rejected', $user_id, [
        'app_id' => $app_id,
        'admin_notes' => $notes
      ]);

      $flash = "Trainer application rejected and account set to rejected.";
      $flash_kind = "warning";
    }
    else {
      throw new Exception("Unknown action.");
    }

  } catch (Throwable $e) {
    $flash = "Error: " . $e->getMessage();
    $flash_kind = "danger";
  }
}

/* ---------- Filters ---------- */
$q = trim((string)($_GET['q'] ?? ''));
$statusFilter = trim((string)($_GET['status'] ?? 'pending'));
$credFilter   = trim((string)($_GET['cred'] ?? ''));

$allowedStatus = ['pending','approved','rejected',''];
$allowedCred   = ['cpt','scs','pt','student','other',''];

if (!in_array($statusFilter, $allowedStatus, true)) $statusFilter = 'pending';
if (!in_array($credFilter, $allowedCred, true)) $credFilter = '';

/* ---------- Query list ---------- */
$apps = [];

$sql = "
  SELECT
    ta.app_id,
    ta.user_id,
    u.full_name,
    u.email,
    u.account_status,
    ta.affiliation,
    ta.credential_type,
    ta.credential_ref,
    ta.statement,
    ta.proof_file,
    ta.status,
    ta.reviewed_by,
    ta.reviewed_at,
    ta.created_at
  FROM trainer_applications ta
  JOIN users u ON u.user_id = ta.user_id
  WHERE 1=1
";

$types = "";
$params = [];

if ($q !== '') {
  $sql .= " AND (u.full_name LIKE CONCAT('%', ?, '%') OR u.email LIKE CONCAT('%', ?, '%') OR CAST(u.user_id AS CHAR)=?)";
  $types .= "sss";
  $params[] = $q; $params[] = $q; $params[] = $q;
}
if ($statusFilter !== '') {
  $sql .= " AND ta.status = ?";
  $types .= "s";
  $params[] = $statusFilter;
}
if ($credFilter !== '') {
  $sql .= " AND ta.credential_type = ?";
  $types .= "s";
  $params[] = $credFilter;
}

$sql .= " ORDER BY ta.created_at DESC LIMIT 250";

$stmt = $mysqli->prepare($sql);
if ($types !== "") $stmt->bind_param($types, ...$params);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $apps[] = $r;
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
        <h1 class="lr-section-heading mb-1">Trainer Applications</h1>
        <p class="lr-stat-subtext mb-0">Review uploaded trainer proof, then approve or reject access.</p>
      </div>
    </div>

    <?php if ($flash): ?>
      <div class="alert alert-<?= h($flash_kind) ?> border border-secondary">
        <?= h($flash) ?>
      </div>
    <?php endif; ?>

    <!-- Filters -->
    <div class="lr-card mb-3">
      <div class="lr-card-body">
        <form class="row g-2 align-items-end" method="GET" action="">
          <div class="col-md-6">
            <label class="form-label lr-stat-label">Search</label>
            <input class="form-control" name="q" value="<?= h($q) ?>" placeholder="Name, email, or User ID...">
          </div>

          <div class="col-md-3">
            <label class="form-label lr-stat-label">Status</label>
            <select class="form-select" name="status">
              <option value="" <?= $statusFilter===''?'selected':'' ?>>All</option>
              <option value="pending" <?= $statusFilter==='pending'?'selected':'' ?>>pending</option>
              <option value="approved" <?= $statusFilter==='approved'?'selected':'' ?>>approved</option>
              <option value="rejected" <?= $statusFilter==='rejected'?'selected':'' ?>>rejected</option>
            </select>
          </div>

          <div class="col-md-3">
            <label class="form-label lr-stat-label">Credential</label>
            <select class="form-select" name="cred">
              <option value="" <?= $credFilter===''?'selected':'' ?>>All</option>
              <option value="cpt" <?= $credFilter==='cpt'?'selected':'' ?>>CPT</option>
              <option value="scs" <?= $credFilter==='scs'?'selected':'' ?>>S&amp;C</option>
              <option value="pt" <?= $credFilter==='pt'?'selected':'' ?>>PT</option>
              <option value="student" <?= $credFilter==='student'?'selected':'' ?>>Student</option>
              <option value="other" <?= $credFilter==='other'?'selected':'' ?>>Other</option>
            </select>
          </div>

          <div class="col-12 mt-2 d-flex gap-2">
            <button class="btn btn-primary btn-sm" type="submit">
              <i class="fa-solid fa-magnifying-glass me-2"></i>Apply
            </button>
            <a class="btn btn-sm btn-outline-light" href="<?= $BASE_URL ?>/admin/trainer-applications.php">Reset</a>
          </div>
        </form>
      </div>
    </div>

    <!-- Table -->
    <div class="lr-card">
      <div class="lr-card-header d-flex justify-content-between align-items-center">
        <div>
          <div class="lr-section-title mb-1">Applications</div>
          <div class="lr-section-heading mb-0">Trainer applications (max 250)</div>
        </div>
        <div class="lr-stat-subtext mb-0"><?= (int)count($apps) ?> shown</div>
      </div>

      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Applicant</th>
                <th>Credential</th>
                <th>Affiliation</th>
                <th>Status</th>
                <th>Submitted</th>
                <th>Uploaded Proof</th>
                <th class="text-end">Actions</th>
              </tr>
            </thead>
            <tbody>
            <?php if (!$apps): ?>
              <tr><td colspan="7" class="text-center py-4 lr-stat-subtext">No applications found.</td></tr>
            <?php else: ?>
              <?php foreach ($apps as $a): ?>
                <?php
                  $app_id = (int)$a['app_id'];
                  $uid = (int)$a['user_id'];
                  $status = (string)$a['status'];
                  $proof = (string)($a['proof_file'] ?? '');
                  $proofHref = $proof !== '' ? ($BASE_URL . "/admin/open-proof.php?app_id=" . (int)$app_id) : '';
                ?>
                <tr>
                  <td style="min-width:260px;">
                    <div class="fw-semibold"><?= h((string)$a['full_name']) ?></div>
                    <div class="lr-stat-subtext"><?= h((string)$a['email']) ?> • #<?= $uid ?></div>
                    <div class="lr-stat-subtext">user_status: <span class="text-capitalize"><?= h((string)$a['account_status']) ?></span></div>
                  </td>

                  <td style="min-width:200px;">
                    <div class="fw-semibold"><?= h(credLabel((string)$a['credential_type'])) ?></div>
                    <?php if ((string)$a['credential_ref'] !== ''): ?>
                      <div class="lr-stat-subtext"><?= h((string)$a['credential_ref']) ?></div>
                    <?php endif; ?>
                  </td>

                  <td style="min-width:220px;">
                    <div class="fw-semibold"><?= h((string)$a['affiliation']) ?></div>
                    <div class="lr-stat-subtext"><?= h((string)$a['statement']) ?></div>
                  </td>

                  <td>
                    <span class="<?= h(badgeAppClass($status)) ?> text-capitalize"><?= h($status) ?></span>
                    <?php if (!empty($a['reviewed_at'])): ?>
                      <div class="lr-stat-subtext">Reviewed: <?= h(fmtDT((string)$a['reviewed_at'])) ?></div>
                    <?php endif; ?>
                    <?php if (!empty($a['admin_notes'])): ?>
                      <div class="lr-stat-subtext">Notes: <?= h((string)$a['admin_notes']) ?></div>
                    <?php endif; ?>
                  </td>

                  <td><?= h(fmtDT((string)$a['created_at'])) ?></td>

                  <td>
                    <?php if ($proofHref): ?>
                      <div class="d-flex flex-column gap-2 align-items-start">
                        <a class="btn btn-sm btn-outline-light" href="<?= h($proofHref) ?>" target="_blank" rel="noopener">
                          <i class="fa-regular fa-file-lines me-2"></i>Open Proof
                        </a>
                        <span class="lr-stat-subtext">Accepted proof: PDF, JPG, PNG</span>
                      </div>
                    <?php else: ?>
                      <span class="lr-stat-subtext">No file uploaded</span>
                    <?php endif; ?>
                  </td>

                  <td class="text-end" style="min-width:280px;">
                    <?php if ($status === 'pending'): ?>
                      <form method="POST" class="d-inline-flex gap-2 align-items-center">
                        <input type="hidden" name="app_id" value="<?= $app_id ?>">
                        <input type="text" name="admin_notes" class="form-control form-control-sm"
                               placeholder="Optional notes…" style="width: 180px;">
                        <button class="btn btn-sm btn-outline-success" name="action" value="approve" type="submit"
                                onclick="return confirm('Approve this trainer application? This will approve the user account too.');">
                          Approve
                        </button>
                        <button class="btn btn-sm btn-outline-danger" name="action" value="reject" type="submit"
                                onclick="return confirm('Reject this trainer application? This will set the user account to rejected.');">
                          Reject
                        </button>
                      </form>
                    <?php else: ?>
                      <span class="lr-stat-subtext">—</span>
                    <?php endif; ?>
                  </td>

                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
            </tbody>
          </table>
        </div>
      </div>

      <div class="lr-card-body">
        <div class="lr-stat-subtext mb-0">
          Approve or reject here after reviewing the uploaded trainer proof.
        </div>
      </div>

    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
</body>
</html>