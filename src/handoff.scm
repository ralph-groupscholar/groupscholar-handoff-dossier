(define-module (handoff)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 ports)
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (init-db
            seed-db
            add-note
            list-notes
            show-note
            close-note
            stats
            build-insert
            build-select
            build-update))

(define (require-env key)
  (let ((val (getenv key)))
    (if (and val (not (string-null? val)))
        val
        (error (string-append "Missing required env var: " key)))))

(define (db-config)
  (list (cons 'host (require-env "GS_DB_HOST"))
        (cons 'port (require-env "GS_DB_PORT"))
        (cons 'user (require-env "GS_DB_USER"))
        (cons 'password (require-env "GS_DB_PASSWORD"))
        (cons 'name (or (getenv "GS_DB_NAME") "postgres"))))

(define (config-ref cfg key)
  (let ((pair (assoc key cfg)))
    (if pair (cdr pair) #f)))

(define (sql-escape s)
  (string-join (string-split s #\') "''"))

(define (sql-literal value)
  (cond
    ((not value) "NULL")
    ((number? value) (number->string value))
    ((string? value) (string-append "'" (sql-escape value) "'"))
    (else (error "Unsupported literal type" value))))

(define (build-insert table fields)
  (let ((columns (map car fields))
        (values (map (lambda (kv) (sql-literal (cdr kv))) fields)))
    (string-append
     "INSERT INTO " table " ("
     (string-join (map symbol->string columns) ", ")
     ") VALUES ("
     (string-join values ", ")
     ") RETURNING id;")))

(define (build-update table fields where-clause)
  (let ((assignments
         (map (lambda (kv)
                (string-append (symbol->string (car kv)) " = " (sql-literal (cdr kv))))
              fields)))
    (string-append
     "UPDATE " table " SET "
     (string-join assignments ", ")
     " WHERE " where-clause " RETURNING id;")))

(define (build-select table columns where-clause order-clause limit-clause)
  (string-append
   "SELECT " (string-join columns ", ")
   " FROM " table
   (if where-clause (string-append " WHERE " where-clause) "")
   (if order-clause (string-append " ORDER BY " order-clause) "")
   (if limit-clause (string-append " LIMIT " limit-clause) "")
   ";"))

(define (psql-base-args cfg)
  (list "psql"
        "-v" "ON_ERROR_STOP=1"
        "-q"
        "-h" (config-ref cfg 'host)
        "-p" (config-ref cfg 'port)
        "-U" (config-ref cfg 'user)
        "-d" (config-ref cfg 'name)
        "-A" "-t" "-F" "|"))

(define (run-psql cfg sql)
  (setenv "PGPASSWORD" (config-ref cfg 'password))
  (let* ((args (append (psql-base-args cfg) (list "-c" sql)))
         (port (apply open-pipe* OPEN_READ args))
         (output (get-string-all port))
         (status (close-pipe port)))
    (if (zero? (status:exit-val status))
        output
        (error "psql failed" output))))

(define (run-psql-file cfg path)
  (setenv "PGPASSWORD" (config-ref cfg 'password))
  (let* ((args (append (psql-base-args cfg) (list "-f" path)))
         (status (apply system* args)))
    (if (zero? status)
        #t
        (error "psql file failed" path))))

(define (parse-lines output)
  (let* ((trimmed (string-trim-right output))
         (lines (if (string-null? trimmed)
                    '()
                    (string-split trimmed #\newline))))
    (filter (lambda (line) (not (string-null? line))) lines)))

(define (parse-table output columns)
  (map (lambda (line)
         (let ((parts (string-split line #\|)))
           (map cons columns parts)))
       (parse-lines output)))

(define (project-root)
  (let* ((here (dirname (canonicalize-path (car (command-line)))))
         (root (dirname here)))
    root))

(define (init-db)
  (let* ((cfg (db-config))
         (schema-path (string-append (project-root) "/db/schema.sql")))
    (run-psql-file cfg schema-path)))

(define (seed-db)
  (let* ((cfg (db-config))
         (seed-path (string-append (project-root) "/db/seed.sql")))
    (run-psql-file cfg seed-path)))

(define (add-note data)
  (let* ((cfg (db-config))
         (fields (list (cons 'scholar_name (assoc-ref data 'scholar_name))
                       (cons 'cohort (assoc-ref data 'cohort))
                       (cons 'priority (assoc-ref data 'priority))
                       (cons 'summary (assoc-ref data 'summary))
                       (cons 'owner (assoc-ref data 'owner))
                       (cons 'due_date (assoc-ref data 'due_date))
                       (cons 'status (or (assoc-ref data 'status) "Open"))))
         (sql (build-insert "gs_handoff.handoff_notes" fields)))
    (parse-lines (run-psql cfg sql))))

(define (list-notes filters)
  (let* ((cfg (db-config))
         (status (assoc-ref filters 'status))
         (limit (or (assoc-ref filters 'limit) "20"))
         (where (if status
                    (string-append "status = " (sql-literal status))
                    #f))
         (sql (build-select
               "gs_handoff.handoff_notes"
               '("id" "scholar_name" "cohort" "priority" "status" "owner" "due_date" "created_at")
               where
               "created_at DESC"
               limit)))
    (parse-table (run-psql cfg sql)
                 '(id scholar_name cohort priority status owner due_date created_at))))

(define (show-note note-id)
  (let* ((cfg (db-config))
         (where (string-append "id = " (sql-literal note-id)))
         (sql (build-select
               "gs_handoff.handoff_notes"
               '("id" "scholar_name" "cohort" "priority" "summary" "status" "owner" "due_date" "tags" "created_at" "updated_at")
               where
               #f
               "1")))
    (parse-table (run-psql cfg sql)
                 '(id scholar_name cohort priority summary status owner due_date tags created_at updated_at))))

(define (close-note note-id)
  (let* ((cfg (db-config))
         (sql (build-update
               "gs_handoff.handoff_notes"
               (list (cons 'status "Closed"))
               (string-append "id = " (sql-literal note-id)))))
    (parse-lines (run-psql cfg sql))))

(define (stats)
  (let* ((cfg (db-config))
         (sql (string-append
               "SELECT status, COUNT(*) "
               "FROM gs_handoff.handoff_notes "
               "GROUP BY status ORDER BY status;"))
         (output (run-psql cfg sql)))
    (parse-table output '(status count))))
