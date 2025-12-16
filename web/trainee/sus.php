<?php
// liftright/web/trainee/sus.php

session_start();
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/auth.php';

require_role(['user']);

$page_title = "SUS Evaluation (Trainee)";

$user_id   = (int)($_SESSION['user_id'] ?? 0);
$full_name = (string)($_SESSION['full_name'] ?? '');

$errors = [];
$success_msg = null;
$computed_score = null;

$items = [
  1 => "I think that I would like to use this system frequently.",
  2 => "I found the system unnecessarily complex.",
  3 => "I thought the system was easy to use.",
  4 => "I think that I would need the support of a technical person to be able to use this system.",
  5 => "I found the various functions in this system were well integrated.",
  6 => "I thought there was too much inconsistency in this system.",
  7 => "I would imagine that most people would learn to use this system very quickly.",
  8 => "I found the system very cumbersome to use.",
  9 => "I felt very confident using the system.",
  10 => "I needed to learn a lot of things before I could get going with this system."
];

function sus_compute_score(array $a): float {
  // Standard SUS scoring:
  // Odd items: score = (answer - 1)
  // Even items: score = (5 - answer)
  // SUS = (sum * 2.5)
  $sum = 0;
  for ($i = 1; $i <= 10; $i++) {
    $v = (int)($a[$i] ?? 0);
    if ($i % 2 === 1) $sum += ($v - 1);
    else $sum += (5 - $v);
  }
  return round($sum * 2.5, 2);
}

$answers = [];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  for ($i = 1; $i <= 10; $i++) {
    $key = "q{$i}";
    $val = isset($_POST[$key]) ? (int)$_POST[$key] : 0;
    if ($val < 1 || $val > 5) {
      $errors[] = "Please answer Question #{$i}.";
    } else {
      $answers[$i] = $val;
    }
  }

  if (!$errors) {
    $computed_score = sus_compute_score($answers);

    $stmt = $mysqli->prepare("
      INSERT INTO sus_responses
        (user_id, q1,q2,q3,q4,q5,q6,q7,q8,q9,q10, sus_score)
      VALUES
        (?, ?,?,?,?,?,?,?,?,?,?, ?)
    ");

    // bind_param types:
    // user_id (i), q1..q10 (i x10), sus_score (d)
    $stmt->bind_param(
      "iiiiiiiiiiid",
      $user_id,
      $answers[1], $answers[2], $answers[3], $answers[4], $answers[5],
      $answers[6], $answers[7], $answers[8], $answers[9], $answers[10],
      $computed_score
    );
    $stmt->execute();
    $stmt->close();

    $success_msg = "Thank you! Your SUS response was saved.";
  }
}

// Load recent SUS submissions (latest 5)
$recent = [];
$stmt = $mysqli->prepare("
  SELECT sus_id, sus_score, created_at
  FROM sus_responses
  WHERE user_id = ?
  ORDER BY created_at DESC
  LIMIT 5
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$res = $stmt->get_result();
while ($r = $res->fetch_assoc()) $recent[] = $r;
$stmt->close();

require __DIR__ . '/../includes/head.php';
?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
  <div class="container lr-main-container py-4">

    <div class="row mb-3 align-items-center">
      <div class="col-md-8">
        <h1 class="lr-section-heading mb-1">System Usability Scale (SUS)</h1>
        <p class="lr-stat-subtext mb-0">
          Rate the system based on your experience. This helps us evaluate usability.
        </p>
      </div>
      <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a class="btn btn-outline-light btn-sm" href="<?= $BASE_URL ?>/trainee/dashboard.php">
          Back to Dashboard
        </a>
      </div>
    </div>

    <?php if ($errors): ?>
      <div class="alert alert-danger">
        <div class="fw-semibold mb-1">Please fix the following:</div>
        <ul class="mb-0">
          <?php foreach ($errors as $e): ?>
            <li><?= h($e) ?></li>
          <?php endforeach; ?>
        </ul>
      </div>
    <?php endif; ?>

    <?php if ($success_msg): ?>
      <div class="alert alert-success d-flex justify-content-between align-items-center">
        <div>
          <div class="fw-semibold"><?= h($success_msg) ?></div>
          <?php if ($computed_score !== null): ?>
            <div class="small opacity-75">Your SUS score: <strong><?= h((string)$computed_score) ?></strong> / 100</div>
          <?php endif; ?>
        </div>
        <span class="badge text-bg-success">Saved</span>
      </div>
    <?php endif; ?>

    <div class="row g-4">

      <!-- SUS Form -->
      <div class="col-lg-8">
        <div class="lr-card">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">Questionnaire</div>
            <div class="lr-section-heading mb-0">Answer all 10 items (1–5)</div>
          </div>
          <div class="lr-card-body">

            <form method="POST" action="">
              <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 table-lr-dark">
                  <thead>
                    <tr>
                      <th style="width: 52%;">Statement</th>
                      <th class="text-center">1</th>
                      <th class="text-center">2</th>
                      <th class="text-center">3</th>
                      <th class="text-center">4</th>
                      <th class="text-center">5</th>
                    </tr>
                  </thead>
                  <tbody>
                    <?php foreach ($items as $i => $text): ?>
                      <tr>
                        <td>
                          <div class="fw-semibold">Q<?= (int)$i ?>.</div>
                          <div class="lr-stat-subtext"><?= h($text) ?></div>
                        </td>
                        <?php for ($v = 1; $v <= 5; $v++): ?>
                          <?php $name = "q{$i}"; ?>
                          <td class="text-center">
                            <input
                              class="form-check-input"
                              type="radio"
                              name="<?= h($name) ?>"
                              value="<?= (int)$v ?>"
                              <?= (isset($_POST[$name]) && (int)$_POST[$name] === $v) ? 'checked' : '' ?>
                              required
                            >
                          </td>
                        <?php endfor; ?>
                      </tr>
                    <?php endforeach; ?>
                  </tbody>
                </table>
              </div>

              <div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mt-3">
                <div class="lr-stat-subtext">
                  Scale: <strong>1</strong> = Strongly Disagree, <strong>5</strong> = Strongly Agree
                </div>
                <button type="submit" class="btn btn-primary">
                  Submit SUS
                </button>
              </div>
            </form>

          </div>
        </div>
      </div>

      <!-- Recent submissions -->
      <div class="col-lg-4">
        <div class="lr-card h-100">
          <div class="lr-card-header">
            <div class="lr-section-title mb-1">History</div>
            <div class="lr-section-heading mb-0">Your recent SUS submissions</div>
          </div>
          <div class="lr-card-body">
            <?php if (!$recent): ?>
              <div class="lr-stat-subtext">No SUS submissions yet.</div>
            <?php else: ?>
              <div class="list-group list-group-flush">
                <?php foreach ($recent as $r): ?>
                  <div class="list-group-item bg-transparent text-white border-secondary">
                    <div class="d-flex justify-content-between align-items-center">
                      <div class="fw-semibold">Score: <?= h((string)$r['sus_score']) ?></div>
                      <span class="lr-badge lr-badge-good">SUS</span>
                    </div>
                    <div class="lr-stat-subtext">
                      <?= h(date("M d, Y • g:i A", strtotime((string)$r['created_at']))) ?>
                    </div>
                  </div>
                <?php endforeach; ?>
              </div>
            <?php endif; ?>
          </div>
        </div>
      </div>

    </div>

  </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
