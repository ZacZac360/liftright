<?php
// liftright/web/admin/models.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['admin']);
$page_title = "Model Management";

if (!function_exists('h')) {
  function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
}

$models_dir = realpath(__DIR__ . '/../../ml/models');
if ($models_dir === false) {
  $models_dir = __DIR__ . '/../../ml/models'; // fallback display
}

$allowed = [
  'bicep_curl'     => 'bicep_curl_ocsvm.pkl',
  'shoulder_press' => 'shoulder_press_ocsvm.pkl',
  'lateral_raise'  => 'lateral_raise_ocsvm.pkl',
];

$flash = null;

function fileInfoSafe(string $path): array {
  if (!is_file($path)) return ['exists'=>false];
  return [
    'exists' => true,
    'size' => filesize($path),
    'mtime' => filemtime($path),
  ];
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  try {
    $exercise = (string)($_POST['exercise'] ?? '');
    if (!isset($allowed[$exercise])) throw new Exception("Invalid exercise.");

    if (!is_dir($models_dir) || !is_writable($models_dir)) {
      throw new Exception("Models directory not writable: " . $models_dir);
    }

    if (!isset($_FILES['model_file']) || $_FILES['model_file']['error'] !== UPLOAD_ERR_OK) {
      throw new Exception("Upload failed.");
    }

    $tmp = $_FILES['model_file']['tmp_name'];
    $orig = (string)($_FILES['model_file']['name'] ?? 'model.pkl');

    // basic file validation
    $ext = strtolower(pathinfo($orig, PATHINFO_EXTENSION));
    if ($ext !== 'pkl') throw new Exception("Only .pkl files are allowed.");

    $target_name = $allowed[$exercise];
    $target_path = $models_dir . DIRECTORY_SEPARATOR . $target_name;

    // backup existing (optional but safer)
    if (is_file($target_path)) {
      $stamp = date('Ymd_His');
      $backup_path = $models_dir . DIRECTORY_SEPARATOR . $target_name . ".bak_" . $stamp;
      @copy($target_path, $backup_path);
    }

    if (!move_uploaded_file($tmp, $target_path)) {
      throw new Exception("Failed to move uploaded file.");
    }

    $flash = "Uploaded and applied model for {$exercise} → {$target_name}. Restart realtime_server if it doesn't auto-reload.";
  } catch (Throwable $e) {
    $flash = "Error: " . $e->getMessage();
  }
}

// list current model files
$current = [];
foreach ($allowed as $k => $fname) {
  $path = (is_string($models_dir) ? $models_dir : '') . DIRECTORY_SEPARATOR . $fname;
  $current[$k] = [
    'filename' => $fname,
    'path' => $path,
    'info' => fileInfoSafe($path),
  ];
}

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-3">
      <div class="col-md-8">
        <div class="lr-section-title mb-1">Administration</div>
        <h1 class="lr-section-heading mb-1">Model Management</h1>
        <p class="lr-stat-subtext mb-0">
          Replace OCSVM model files used by the FastAPI realtime service.
          <strong>After updating, restart the Python server if needed.</strong>
        </p>
        <p class="lr-stat-subtext mb-0">Models directory: <code><?= h((string)$models_dir) ?></code></p>
      </div>
    </div>

    <?php if ($flash): ?>
      <div class="alert alert-dark border border-secondary"><?= h($flash) ?></div>
    <?php endif; ?>

    <div class="lr-card mb-3">
      <div class="lr-card-header">
        <div class="lr-section-title mb-1">Upload</div>
        <div class="lr-section-heading mb-0">Replace a model (.pkl)</div>
      </div>
      <div class="lr-card-body">
        <form method="POST" enctype="multipart/form-data" class="row g-2 align-items-end">
          <div class="col-md-4">
            <label class="form-label">Exercise</label>
            <select class="form-select" name="exercise" required>
              <option value="bicep_curl">Bicep Curl</option>
              <option value="shoulder_press">Shoulder Press</option>
              <option value="lateral_raise">Lateral Raise</option>
            </select>
          </div>

          <div class="col-md-6">
            <label class="form-label">Model file (.pkl)</label>
            <input class="form-control" type="file" name="model_file" accept=".pkl" required>
          </div>

          <div class="col-md-2 d-grid">
            <button class="btn btn-primary" type="submit">
              <i class="fa-solid fa-upload me-2"></i>Upload
            </button>
          </div>
        </form>
        <div class="lr-stat-subtext mt-2">
          Note: the page makes a timestamped <code>.bak_YYYYMMDD_HHMMSS</code> backup when replacing.
        </div>
      </div>
    </div>

    <div class="lr-card">
      <div class="lr-card-header">
        <div class="lr-section-title mb-1">Status</div>
        <div class="lr-section-heading mb-0">Current model files</div>
      </div>
      <div class="lr-card-body p-0">
        <div class="table-responsive">
          <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
            <thead>
              <tr>
                <th>Exercise</th>
                <th>Filename</th>
                <th>Exists</th>
                <th>Size</th>
                <th>Last Modified</th>
              </tr>
            </thead>
            <tbody>
              <?php foreach ($current as $ex => $meta):
                $info = $meta['info'];
              ?>
                <tr>
                  <td><?= h(ucwords(str_replace('_',' ', $ex))) ?></td>
                  <td><code><?= h($meta['filename']) ?></code></td>
                  <td>
                    <span class="<?= ($info['exists'] ?? false) ? 'lr-badge lr-badge-good' : 'lr-badge lr-badge-danger' ?>">
                      <?= ($info['exists'] ?? false) ? 'Yes' : 'No' ?>
                    </span>
                  </td>
                  <td>
                    <?= ($info['exists'] ?? false) ? number_format((int)$info['size']) . ' bytes' : '—' ?>
                  </td>
                  <td>
                    <?= ($info['exists'] ?? false) ? h(date("M d, Y • g:i A", (int)$info['mtime'])) : '—' ?>
                  </td>
                </tr>
              <?php endforeach; ?>
            </tbody>
          </table>
        </div>
      </div>
    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
