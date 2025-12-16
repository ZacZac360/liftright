<?php
// admin/dashboard.php - System overview dashboard (Admin role)

session_start();
require_once __DIR__ . '/../config/config.php';

if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'admin') {
    header("Location: {$BASE_URL}/login.php");
    exit;
}

// --------- Aggregate stats ---------

// 1) User counts by role
$total_users     = 0;
$total_trainees  = 0;
$total_coaches   = 0;
$total_admins    = 0;

$sql_users = "
    SELECT role, COUNT(*) AS c
    FROM users
    GROUP BY role
";
$res_users = $mysqli->query($sql_users);

while ($row = $res_users->fetch_assoc()) {
    $count = (int)$row['c'];
    $role  = $row['role'];

    $total_users += $count;

    if ($role === 'trainee') {
        $total_trainees = $count;
    } elseif ($role === 'coach') {
        $total_coaches = $count;
    } elseif ($role === 'admin') {
        $total_admins = $count;
    }
}

// 2) Session stats
$total_sessions = 0;
$avg_form_global = 0;
$latest_session_date = null;

$sql_sessions = "
    SELECT COUNT(*) AS c,
           AVG(avg_form_score) AS avg_score,
           MAX(session_date) AS latest
    FROM training_sessions
";
$res_sessions = $mysqli->query($sql_sessions);
if ($row = $res_sessions->fetch_assoc()) {
    $total_sessions     = (int)$row['c'];
    $avg_form_global    = $row['avg_score'] !== null ? round($row['avg_score']) : 0;
    $latest_session_date = $row['latest'];
}

// 3) Latest 8 sessions (join users)
$latest_sessions = [];
$stmt = $mysqli->prepare("
    SELECT ts.id,
           ts.exercise,
           ts.session_date,
           ts.total_sets,
           ts.total_reps,
           ts.avg_form_score,
           ts.fatigue_level,
           u.full_name,
           u.role
    FROM training_sessions ts
    INNER JOIN users u ON ts.user_id = u.id
    ORDER BY ts.session_date DESC
    LIMIT 8
");
$stmt->execute();
$result = $stmt->get_result();
while ($row = $result->fetch_assoc()) {
    $latest_sessions[] = $row;
}
$stmt->close();

function formatExercise($ex) {
    switch ($ex) {
        case 'shoulder_press': return 'Shoulder Press';
        case 'bicep_curl':     return 'Bicep Curl';
        case 'lateral_raise':  return 'Lateral Raise';
        default:               return ucfirst(str_replace('_', ' ', $ex));
    }
}

function fatigueBadgeClass($level) {
    if ($level === 'low') return 'lr-badge lr-badge-good';
    if ($level === 'medium') return 'lr-badge lr-badge-warning';
    return 'lr-badge lr-badge-danger';
}

?>
<?php require __DIR__ . '/../includes/head.php'; ?>
<body>
<?php require __DIR__ . '/../includes/navbar.php'; ?>

<div class="lr-page-wrapper">
    <div class="container lr-main-container py-4">
        <!-- Header -->
        <div class="row mb-4 align-items-center">
            <div class="col-md-8">
                <div class="lr-section-title mb-1">Admin Overview</div>
                <h1 class="lr-section-heading mb-1">System Dashboard</h1>
                <p class="lr-stat-subtext mb-0">
                    High-level view of registered users and recorded AI-assessed training sessions.
                </p>
            </div>
        </div>

        <!-- Top stats row -->
        <div class="row g-3 mb-4">
            <div class="col-md-3">
                <div class="lr-card h-100">
                    <div class="lr-card-body">
                        <div class="lr-stat-label">Total users</div>
                        <div class="lr-stat-value mt-1"><?php echo $total_users; ?></div>
                        <p class="lr-stat-subtext mb-0">
                            <?php echo $total_trainees; ?> trainees ·
                            <?php echo $total_coaches; ?> coaches ·
                            <?php echo $total_admins; ?> admins
                        </p>
                    </div>
                </div>
            </div>

            <div class="col-md-3">
                <div class="lr-card h-100">
                    <div class="lr-card-body">
                        <div class="lr-stat-label">Total sessions</div>
                        <div class="lr-stat-value mt-1"><?php echo $total_sessions; ?></div>
                        <p class="lr-stat-subtext mb-0">
                            Across all trainees and exercises.
                        </p>
                    </div>
                </div>
            </div>

            <div class="col-md-3">
                <div class="lr-card h-100">
                    <div class="lr-card-body">
                        <div class="lr-stat-label">Global avg form</div>
                        <div class="lr-stat-value mt-1"><?php echo $avg_form_global; ?>%</div>
                        <?php if ($avg_form_global >= 85): ?>
                            <span class="lr-badge lr-badge-good mt-2">Generally good form</span>
                        <?php elseif ($avg_form_global >= 70): ?>
                            <span class="lr-badge lr-badge-warning mt-2">Mixed &mdash; moderate quality</span>
                        <?php else: ?>
                            <span class="lr-badge lr-badge-danger mt-2">Needs improvement</span>
                        <?php endif; ?>
                    </div>
                </div>
            </div>

            <div class="col-md-3">
                <div class="lr-card h-100">
                    <div class="lr-card-body">
                        <div class="lr-stat-label">Last recorded session</div>
                        <div class="lr-stat-value mt-1">
                            <?php
                            if ($latest_session_date) {
                                echo date("M d, Y", strtotime($latest_session_date));
                            } else {
                                echo '—';
                            }
                            ?>
                        </div>
                        <p class="lr-stat-subtext mb-0">
                            Latest AI log captured from client device.
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Lower content: latest sessions + small role breakdown -->
        <div class="row g-4">
            <!-- Latest sessions table -->
            <div class="col-lg-8">
                <div class="lr-card h-100">
                    <div class="lr-card-header d-flex justify-content-between align-items-center">
                        <div>
                            <div class="lr-section-title mb-1">Monitoring</div>
                            <div class="lr-section-heading mb-0">Latest recorded sessions</div>
                        </div>
                    </div>
                    <div class="lr-card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
                                <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Trainee</th>
                                    <th>Exercise</th>
                                    <th>Sets × Reps</th>
                                    <th>Form</th>
                                    <th>Fatigue</th>
                                </tr>
                                </thead>
                                <tbody>
                                <?php if (count($latest_sessions) === 0): ?>
                                    <tr>
                                        <td colspan="6" class="text-center py-4 lr-stat-subtext">
                                            No training sessions have been recorded in the system yet.
                                        </td>
                                    </tr>
                                <?php else: ?>
                                    <?php foreach ($latest_sessions as $sess): ?>
                                        <tr>
                                            <td><?php echo date("M d, Y H:i", strtotime($sess['session_date'])); ?></td>
                                            <td><?php echo htmlspecialchars($sess['full_name']); ?></td>
                                            <td>
                                                <span class="lr-chip-exercise">
                                                    <?php echo htmlspecialchars(formatExercise($sess['exercise'])); ?>
                                                </span>
                                            </td>
                                            <td>
                                                <?php echo (int)$sess['total_sets']; ?> × <?php
                                                    echo (int)$sess['total_reps'] / max((int)$sess['total_sets'], 1);
                                                ?>
                                            </td>
                                            <td><?php echo (int)$sess['avg_form_score']; ?>%</td>
                                            <td>
                                                <span class="<?php echo fatigueBadgeClass($sess['fatigue_level']); ?>">
                                                    <?php echo ucfirst($sess['fatigue_level']); ?>
                                                </span>
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

            <!-- Role breakdown card -->
            <div class="col-lg-4">
                <div class="lr-card h-100">
                    <div class="lr-card-header">
                        <div class="lr-section-title mb-1">Users</div>
                        <div class="lr-section-heading mb-0">Role distribution</div>
                    </div>
                    <div class="lr-card-body">
                        <ul class="lr-stat-subtext mb-3">
                            <li><strong><?php echo $total_trainees; ?></strong> trainees</li>
                            <li><strong><?php echo $total_coaches; ?></strong> coaches</li>
                            <li><strong><?php echo $total_admins; ?></strong> admins</li>
                        </ul>
                        <p class="lr-stat-subtext mb-0">
                            This page will later be extended with user management (add/edit/delete),
                            but for now it serves as a monitoring dashboard for the thesis prototype.
                        </p>
                    </div>
                </div>
            </div>
        </div>

    </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
