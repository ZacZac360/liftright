C:\Users\Zai>C:\xampp\htdocs\liftright
'C:\xampp\htdocs\liftright' is not recognized as an internal or external command,
operable program or batch file.

C:\Users\Zai>cd C:\xampp\htdocs\liftright

C:\xampp\htdocs\liftright>tree /f
Folder PATH listing for volume System
Volume serial number is 3E7B-6DED
C:.
│  .gitignore
│  decision_score_histogram.png
│  decision_score_histograms_clean.png
│  feature_distribution.png
│  feature_distribution_clean.png
│  liftright_db.sql
│  ocsvm_boundary.png
│  Pasted markdown.md
│  Thesis Proper.pdf
│  tree.md
│
├─ml
│  │  import pandas as pd.py
│  │  ocsvm_model_summary.csv
│  │
│  ├─api
│  ├─datasets
│  │  ├─frames
│  │  │      all_exercises_frames.csv
│  │  │
│  │  └─reps
│  │          bicep_curl_reps.csv
│  │          lateral_raise_reps.csv
│  │          shoulder_press_reps.csv
│  │
│  ├─models
│  │      bicep_curl_ocsvm.pkl
│  │      lateral_raise_ocsvm.pkl
│  │      shoulder_press_ocsvm.pkl
│  │
│  ├─outputs
│  │      bicep_curl_status.json
│  │      lateral_raise_status.json
│  │      shoulder_press_status.json
│  │
│  ├─scripts
│  │  │  01_extract_frames.py
│  │  │  02_build_reps_bicep_curl.py
│  │  │  02_build_reps_lateral_raise.py
│  │  │  02_build_reps_shoulder_press.py
│  │  │  03_train_bicep_curl_ocsvm.py
│  │  │  03_train_lateral_raise_ocsvm.py
│  │  │  03_train_shoulder_press_ocsvm.py
│  │  │  04_live_bicep_curl.py
│  │  │  04_live_lateral_raise.py
│  │  │  04_live_shoulder_press.py
│  │  │  generate_thesis_figures.py
│  │  │  import pandas as pd.py
│  │  │  realtime_server.py
│  │  │
│  │  ├─server
│  │  │      run_realtime_server.bat
│  │  │
│  │  └─__pycache__
│  │          realtime_server.cpython-310.pyc
│  │
│  ├─thesis captures
│  │  ├─RAW VIDS
│  │  │      IMG_0188.MOV
│  │  │      IMG_0189.MOV
│  │  │      IMG_0190.MOV
│  │  │      IMG_0219.MOV
│  │  │      IMG_0220.MOV
│  │  │      IMG_0221.MOV
│  │  │      IMG_0226.MOV
│  │  │      IMG_0227.MOV
│  │  │      IMG_0228.MOV
│  │  │      IMG_0229.MOV
│  │  │      IMG_0230.MOV
│  │  │      IMG_0231.MOV
│  │  │      IMG_0232.MOV
│  │  │      IMG_0233.MOV
│  │  │      IMG_0234.MOV
│  │  │      IMG_0235.MOV
│  │  │      IMG_0236.MOV
│  │  │      IMG_0237.MOV
│  │  │      IMG_0238.MOV
│  │  │
│  │  ├─Sir Benj
│  │  │      benj_bicep.MP4
│  │  │      benj_latraise.MP4
│  │  │      benj_shoulderpress.MP4
│  │  │      Sir Benj Gabriel De Jesus.m4a
│  │  │
│  │  ├─Sir Jack
│  │  │      Coach Jack.m4a
│  │  │      jack_bicep.MP4
│  │  │      jack_latraise.MP4
│  │  │      jack_shoulderpress.MP4
│  │  │
│  │  ├─Sir Jay
│  │  │      Coach Jay SouthGrind.m4a
│  │  │      jay_bicep.MP4
│  │  │      jay_latraise.MP4
│  │  │      jay_shoulderpress.MP4
│  │  │
│  │  ├─Sir Jeff
│  │  │      Coach Jeff.m4a
│  │  │      jeff_bicep.MP4
│  │  │      jeff_latraise.MP4
│  │  │      jeff_shoulderpress.MP4
│  │  │
│  │  └─Sir Renz
│  │          Coach Renz.m4a
│  │          renz_bicep.MP4
│  │          renz_latraise.MP4
│  │          renz_shoulderpress.MP4
│  │
│  ├─thesis_figures
│  │      mean_duration.png
│  │      mean_trunk_offset.png
│  │
│  └─videos
│      ├─bicep_curl
│      │      benj_bicep.MP4
│      │      jack_bicep.MP4
│      │      jay_bicep.MP4
│      │      jeff_bicep.MP4
│      │      renz_bicep.MP4
│      │
│      ├─lateral_raise
│      │      benj_latraise.MP4
│      │      jack_latraise.MP4
│      │      jay_latraise.MP4
│      │      jeff_latraise.MP4
│      │      renz_latraise.MP4
│      │
│      └─shoulder_press
│              benj_shoulderpress.MP4
│              jack_shoulderpress.MP4
│              jay_shoulderpress.MP4
│              jeff_shoulderpress.MP4
│              renz_shoulderpress.MP4
│
└─web
    │  cancel-profile-request.php
    │  compose-message.php
    │  dir dump.txt
    │  favicon.ico
    │  forgot-password.php
    │  hash.php
    │  index.php
    │  layout.txt
    │  list.txt
    │  login.php
    │  logout.php
    │  message-view.php
    │  messages.php
    │  notifications.php
    │  reset-password.php
    │  sql.txt
    │  tree_structure.txt
    │  verify-email.php
    │
    ├─admin
    │      audit-logs.php
    │      dashboard.php
    │      evaluation.php
    │      exports.php
    │      models.php
    │      open-proof.php
    │      profile-requests.php
    │      reviews.php
    │      thresholds.php
    │      trainer-applications.php
    │      users.php
    │
    ├─api
    │      dashboard_trend.php
    │      forgot-password.php
    │      resend-email-otp.php
    │      session_process.php
    │      set-theme.php
    │      verify-email-otp.php
    │
    ├─assets
    │  ├─css
    │  │      landing.css
    │  │      style.css
    │  │
    │  ├─data
    │  ├─gifs
    │  ├─guides
    │  ├─images
    │  │  ├─landing
    │  │  │      background.png
    │  │  │      hero-athlete.png
    │  │  │      liftright-logo.png
    │  │  │
    │  │  └─logo
    │  │          liftright-logo.png
    │  │
    │  ├─js
    │  │      charts.js
    │  │      start-session.js
    │  │
    │  └─sfx
    │          coach.mp3
    │          danger.mp3
    │          rep.mp3
    │          start.mp3
    │          stop.mp3
    │
    ├─coach
    │      dashboard.php
    │      edit-profile.php
    │      invitations.php
    │      profile.php
    │      review-history.php
    │      review-session.php
    │      reviews.php
    │
    ├─config
    │      audit.php
    │      auth.php
    │      config.php
    │
    ├─includes
    │      db_helpers.php
    │      footer.php
    │      head.php
    │      navbar.php
    │      profile_change_helpers.php
    │      text_helpers.php
    │
    ├─trainee
    │      assign-trainer.php
    │      dashboard.php
    │      edit-profile.php
    │      profile.php
    │      session-view.php
    │      sessions.php
    │      start-session.php
    │      sus.php
    │      trainer-info.php
    │
    └─uploads
        │  .htaccess
        │
        ├─pending_profiles
        ├─profile_photos
        │      user_2.jpg
        │      user_3.png
        │      user_9.jpg
        │
        ├─rep_snapshots
        │  ├─log_170
        │  │      rep_1.jpg
        │  │      rep_2.jpg
        │  │      rep_3.jpg
        │  │
        │  ├─log_172
        │  │      rep_1.jpg
        │  │      rep_2.jpg
        │  │      rep_3.jpg
        │  │      rep_4.jpg
        │  │      rep_5.jpg
        │  │      rep_6.jpg
        │  │
        │  ├─log_173
        │  │      rep_1.jpg
        │  │      rep_10.jpg
        │  │      rep_2.jpg
        │  │      rep_3.jpg
        │  │      rep_4.jpg
        │  │      rep_5.jpg
        │  │      rep_6.jpg
        │  │      rep_7.jpg
        │  │      rep_8.jpg
        │  │      rep_9.jpg
        │  │
        │  └─log_174
        │          rep_1.jpg
        │          rep_10.jpg
        │          rep_11.jpg
        │          rep_2.jpg
        │          rep_3.jpg
        │          rep_4.jpg
        │          rep_5.jpg
        │          rep_6.jpg
        │          rep_7.jpg
        │          rep_8.jpg
        │          rep_9.jpg
        │
        └─trainer_proofs
                .htaccess
                trainerproof_e3b807d38493dc67.png


C:\xampp\htdocs\liftright>