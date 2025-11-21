
(define-constant ADMIN tx-sender)
(define-constant ERR-UNAUTHORIZED u1)
(define-constant ERR-NOT-FOUND u2)
(define-constant ERR-INVALID-THRESHOLD u3)

(define-map bottleneck-analysis
  {analysis-id: uint}
  {department: (string-ascii 50), issue: (string-ascii 200), severity: uint})

(define-map process-redesigns
  {design-id: uint}
  {process-name: (string-ascii 100), improvement-target: (string-ascii 200), status: (string-ascii 20)})

(define-map capacity-records
  {record-id: uint}
  {resource-type: (string-ascii 50), current-load: uint, max-capacity: uint})

(define-map throughput-metrics
  {metric-id: uint}
  {period: uint, patients-processed: uint, average-wait-time: uint})

(define-data-var analysis-counter uint u0)
(define-data-var design-counter uint u0)
(define-data-var capacity-counter uint u0)
(define-data-var metric-counter uint u0)

(define-public (report-bottleneck (department (string-ascii 50)) (issue (string-ascii 200)) (severity uint))
  (if (is-eq tx-sender ADMIN)
    (if (<= severity u10)
      (let ((analysis-id (+ (var-get analysis-counter) u1)))
        (begin
          (map-set bottleneck-analysis
            {analysis-id: analysis-id}
            {department: department, issue: issue, severity: severity})
          (var-set analysis-counter analysis-id)
          (ok analysis-id)))
      (err ERR-INVALID-THRESHOLD))
    (err ERR-UNAUTHORIZED)))

(define-public (create-redesign-plan (process-name (string-ascii 100)) (improvement-target (string-ascii 200)))
  (if (is-eq tx-sender ADMIN)
    (let ((design-id (+ (var-get design-counter) u1)))
      (begin
        (map-set process-redesigns
          {design-id: design-id}
          {process-name: process-name, improvement-target: improvement-target, status: "planned"})
        (var-set design-counter design-id)
        (ok design-id)))
    (err ERR-UNAUTHORIZED)))

(define-public (record-capacity (resource-type (string-ascii 50)) (current-load uint) (max-capacity uint))
  (if (is-eq tx-sender ADMIN)
    (let ((record-id (+ (var-get capacity-counter) u1)))
      (begin
        (map-set capacity-records
          {record-id: record-id}
          {resource-type: resource-type, current-load: current-load, max-capacity: max-capacity})
        (var-set capacity-counter record-id)
        (ok record-id)))
    (err ERR-UNAUTHORIZED)))

(define-public (log-throughput-data (patients-processed uint) (average-wait-time uint))
  (if (is-eq tx-sender ADMIN)
    (let ((metric-id (+ (var-get metric-counter) u1)))
      (begin
        (map-set throughput-metrics
          {metric-id: metric-id}
          {period: u0, patients-processed: patients-processed, average-wait-time: average-wait-time})
        (var-set metric-counter metric-id)
        (ok metric-id)))
    (err ERR-UNAUTHORIZED)))

(define-public (update-design-status (design-id uint) (new-status (string-ascii 20)))
  (if (is-eq tx-sender ADMIN)
    (let ((design (map-get? process-redesigns {design-id: design-id})))
      (match design
        current-design
          (begin
            (map-set process-redesigns
              {design-id: design-id}
              {process-name: (get process-name current-design),
               improvement-target: (get improvement-target current-design),
               status: new-status})
            (ok true))
        (err ERR-NOT-FOUND)))
    (err ERR-UNAUTHORIZED)))

(define-read-only (get-bottleneck (analysis-id uint))
  (map-get? bottleneck-analysis {analysis-id: analysis-id}))

(define-read-only (get-redesign (design-id uint))
  (map-get? process-redesigns {design-id: design-id}))

(define-read-only (get-capacity (record-id uint))
  (map-get? capacity-records {record-id: record-id}))

(define-read-only (get-throughput (metric-id uint))
  (map-get? throughput-metrics {metric-id: metric-id}))

(define-read-only (get-analysis-count)
  (var-get analysis-counter))

(define-read-only (get-design-count)
  (var-get design-counter))

(define-read-only (get-capacity-count)
  (var-get capacity-counter))

(define-read-only (get-metric-count)
  (var-get metric-counter))

