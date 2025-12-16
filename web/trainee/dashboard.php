<?php
// trainee/dashboard.php - Trainee overview dashboard

session_start();
require_once __DIR__ . '/../config/config.php';

if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'trainee') {
    header("Location: {$BASE_URL}/login.php");
    exit;
}

$user_id   = $_SESSION['user_id'];
$full_name = $_SESSION['full_name'];

// 1) Aggregate stats
$total_sessions = 0;
$avg_form       = 0;
$latest_date    = null;

// Total sessions
$stmt = $mysqli->prepare("
    SELECT COUNT(*) AS c, AVG(avg_form_score) AS avg_score, MAX(session_date) AS latest
    FROM training_sessions
    WHERE user_id = ?
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
if ($row = $result->fetch_assoc()) {
    $total_sessions = (int)$row['c'];
    $avg_form       = $row['avg_score'] !== null ? round($row['avg_score']) : 0;
    $latest_date    = $row['latest'];
}
$stmt->close();

// 2) Recent sessions list (limit 5)
$recent_sessions = [];
$stmt = $mysqli->prepare("
    SELECT id, exercise, session_date, total_sets, total_reps, avg_form_score, fatigue_level
    FROM training_sessions
    WHERE user_id = ?
    ORDER BY session_date DESC
    LIMIT 5
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$res = $stmt->get_result();
while ($row = $res->fetch_assoc()) {
    $recent_sessions[] = $row;
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
                <div class="lr-section-title mb-1">Trainee Overview</div>
                <h1 class="lr-section-heading mb-1">Welcome back, <?php echo htmlspecialchars($full_name); ?> 👋</h1>
                <p class="lr-stat-subtext mb-0">
                    Here’s a snapshot of your recent training quality and fatigue patterns.
                </p>
            </div>
            <div class="col-md-4 text-md-end mt-3 mt-md-0">
                <button class="btn btn-primary px-3" disabled>
                    Start New Session (AI integration soon)
                </button>
            </div>
        </div>

        <!-- Stats -->
        <div class="row g-3 mb-4">
            <div class="col-md-4">
                <div class="lr-card h-100">
                    <div class="lr-card-body">
                        <div class="lr-stat-label">Total sessions</div>
                        <div class="lr-stat-value mt-1"><?php echo $total_sessions; ?></div>
                        <p class="lr-stat-subtext mb-0">
                            Based on recorded AI-assessed workouts.
                        </p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="lr-card h-100">
                    <div class="lr-card-body">
                        <div class="lr-stat-label">Average form score</div>
                        <div class="lr-stat-value mt-1"><?php echo $avg_form; ?>%</div>
                        <?php if ($avg_form >= 85): ?>
                            <span class="lr-badge lr-badge-good mt-2">Good overall form</span>
                        <?php elseif ($avg_form >= 70): ?>
                            <span class="lr-badge lr-badge-warning mt-2">Moderate &mdash; room to improve</span>
                        <?php else: ?>
                            <span class="lr-badge lr-badge-danger mt-2">Needs attention</span>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="lr-card h-100">
                    <div class="lr-card-body">
                        <div class="lr-stat-label">Last recorded session</div>
                        <div class="lr-stat-value mt-1">
                            <?php
                            if ($latest_date) {
                                echo date("M d, Y", strtotime($latest_date));
                            } else {
                                echo '—';
                            }
                            ?>
                        </div>
                        <p class="lr-stat-subtext mb-0">
                            Keep training consistently to see clearer fatigue patterns.
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Content -->
        <div class="row g-4">
            <!-- Recent sessions table -->
            <div class="col-lg-7">
                <div class="lr-card h-100">
                    <div class="lr-card-header d-flex justify-content-between align-items-center">
                        <div>
                            <div class="lr-section-title mb-1">History</div>
                            <div class="lr-section-heading mb-0">Recent Sessions</div>
                        </div>
                        <a href="<?php echo $BASE_URL; ?>/trainee/sessions.php" class="small text-decoration-none">
                            View all
                        </a>
                    </div>
                    <div class="lr-card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover table-striped align-middle mb-0 table-lr-dark">
                                <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Exercise</th>
                                    <th>Sets × Reps</th>
                                    <th>Form</th>
                                    <th>Fatigue</th>
                                    <th></th>
                                </tr>
                                </thead>
                                <tbody>
                                <?php if (count($recent_sessions) === 0): ?>
                                    <tr>
                                        <td colspan="6" class="text-center py-4 lr-stat-subtext">
                                            No recorded sessions yet.
                                        </td>
                                    </tr>
                                <?php else: ?>
                                    <?php foreach ($recent_sessions as $sess): ?>
                                        <tr>
                                            <td><?php echo date("M d, Y", strtotime($sess['session_date'])); ?></td>
                                            <td>
                                                <span class="lr-chip-exercise">
                                                    <?php echo htmlspecialchars(formatExercise($sess['exercise'])); ?>
                                                </span>
                                            </td>
                                            <td>
                                                <?php echo (int)$sess['total_sets']; ?> × <?php echo (int)$sess['total_reps'] / max((int)$sess['total_sets'], 1); ?>
                                            </td>
                                            <td><?php echo (int)$sess['avg_form_score']; ?>%</td>
                                            <td>
                                                <span class="<?php echo fatigueBadgeClass($sess['fatigue_level']); ?>">
                                                    <?php echo ucfirst($sess['fatigue_level']); ?>
                                                </span>
                                            </td>
                                            <td class="text-end">
                                                <a href="<?php echo $BASE_URL; ?>/trainee/session-view.php?id=<?php echo (int)$sess['id']; ?>"
                                                   class="btn btn-sm btn-outline-light">
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

            <!-- Chart + tips -->
            <div class="col-lg-5">
                <div class="lr-card mb-3">
                    <div class="lr-card-header">
                        <div class="lr-section-title mb-1">Trend</div>
                        <div class="lr-section-heading mb-0">
                            Form consistency (last 10 sessions)
                        </div>
                    </div>
                    <div class="lr-card-body">
                        <div id="formChartContainer"
                             class="border border-secondary rounded-3 p-3 text-center"
                             style="height: 220px; display:flex; align-items:center; justify-content:center;">
                            <span class="lr-stat-subtext">
                                [Chart placeholder] This will render a line chart using Chart.js and either
                                mock JSON data or real model outputs.
                            </span>
                        </div>
                    </div>
                </div>

                <div class="lr-card h-100">
                    <div class="lr-card-header">
                        <div class="lr-section-title mb-1">Guidance</div>
                        <div class="lr-section-heading mb-0">Key reminders for your next sessions</div>
                    </div>
                    <div class="lr-card-body">
                        <ul class="lr-stat-subtext mb-0">
                            <li>Stop the set once form score drops below 70% for two consecutive reps.</li>
                            <li>Prioritize controlled tempo over adding extra load when fatigue spikes.</li>
                            <li>Monitor shoulder position closely during lateral raises to avoid shrugging.</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>

    </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>
