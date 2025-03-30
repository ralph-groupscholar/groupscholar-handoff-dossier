(use-modules (ice-9 ftw)
             (srfi srfi-64))

(eval-when (compile load eval)
  (define (add-src-path)
    (let ((test-dir (dirname (canonicalize-path (current-filename)))))
      (add-to-load-path (string-append test-dir "/../src"))))
  (add-src-path))

(use-modules (handoff))

(test-begin "query-builder")

(test-equal "insert builder"
  "INSERT INTO gs_handoff.handoff_notes (scholar_name, cohort) VALUES ('Amina Noor', '2026 Spring') RETURNING id;"
  (build-insert "gs_handoff.handoff_notes"
                (list (cons 'scholar_name "Amina Noor")
                      (cons 'cohort "2026 Spring"))))

(test-equal "update builder"
  "UPDATE gs_handoff.handoff_notes SET status = 'Closed' WHERE id = 12 RETURNING id;"
  (build-update "gs_handoff.handoff_notes"
                (list (cons 'status "Closed"))
                "id = 12"))

(test-equal "select builder"
  "SELECT id, scholar_name FROM gs_handoff.handoff_notes WHERE status = 'Open' ORDER BY created_at DESC LIMIT 10;"
  (build-select "gs_handoff.handoff_notes"
                '("id" "scholar_name")
                "status = 'Open'"
                "created_at DESC"
                "10"))

(test-end "query-builder")
