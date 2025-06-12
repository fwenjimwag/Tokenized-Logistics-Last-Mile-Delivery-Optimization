;; Capacity Management Contract
;; Manages delivery capacity allocation and tracking

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_INSUFFICIENT_CAPACITY (err u301))
(define-constant ERR_PROVIDER_NOT_FOUND (err u302))
(define-constant ERR_INVALID_ALLOCATION (err u303))

;; Data structures
(define-map provider-capacity
  { provider-id: principal }
  {
    total-capacity: uint,
    allocated-capacity: uint,
    available-capacity: uint,
    capacity-type: (string-ascii 20), ;; "weight", "volume", "packages"
    last-updated: uint
  }
)

(define-map capacity-allocations
  { allocation-id: uint }
  {
    provider-id: principal,
    route-id: uint,
    allocated-amount: uint,
    allocation-time: uint,
    status: uint ;; 0: pending, 1: confirmed, 2: released
  }
)

(define-map daily-capacity-usage
  { provider-id: principal, date: uint }
  {
    used-capacity: uint,
    peak-usage: uint,
    efficiency-score: uint
  }
)

(define-data-var next-allocation-id uint u1)

;; Set provider capacity
(define-public (set-provider-capacity
  (provider-id principal)
  (total-capacity uint)
  (capacity-type (string-ascii 20))
)
  (begin
    (map-set provider-capacity
      { provider-id: provider-id }
      {
        total-capacity: total-capacity,
        allocated-capacity: u0,
        available-capacity: total-capacity,
        capacity-type: capacity-type,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

;; Allocate capacity for a route
(define-public (allocate-capacity (provider-id principal) (route-id uint) (amount uint))
  (match (map-get? provider-capacity { provider-id: provider-id })
    capacity-data
    (let ((available (get available-capacity capacity-data))
          (allocation-id (var-get next-allocation-id)))
      (asserts! (>= available amount) ERR_INSUFFICIENT_CAPACITY)

      ;; Update provider capacity
      (map-set provider-capacity
        { provider-id: provider-id }
        (merge capacity-data {
          allocated-capacity: (+ (get allocated-capacity capacity-data) amount),
          available-capacity: (- available amount),
          last-updated: block-height
        })
      )

      ;; Create allocation record
      (map-set capacity-allocations
        { allocation-id: allocation-id }
        {
          provider-id: provider-id,
          route-id: route-id,
          allocated-amount: amount,
          allocation-time: block-height,
          status: u1
        }
      )

      (var-set next-allocation-id (+ allocation-id u1))
      (ok allocation-id)
    )
    ERR_PROVIDER_NOT_FOUND
  )
)

;; Release allocated capacity
(define-public (release-capacity (allocation-id uint))
  (match (map-get? capacity-allocations { allocation-id: allocation-id })
    allocation-data
    (let ((provider-id (get provider-id allocation-data))
          (amount (get allocated-amount allocation-data)))
      (match (map-get? provider-capacity { provider-id: provider-id })
        capacity-data
        (begin
          ;; Update provider capacity
          (map-set provider-capacity
            { provider-id: provider-id }
            (merge capacity-data {
              allocated-capacity: (- (get allocated-capacity capacity-data) amount),
              available-capacity: (+ (get available-capacity capacity-data) amount),
              last-updated: block-height
            })
          )

          ;; Update allocation status
          (map-set capacity-allocations
            { allocation-id: allocation-id }
            (merge allocation-data { status: u2 })
          )

          (ok true)
        )
        ERR_PROVIDER_NOT_FOUND
      )
    )
    ERR_INVALID_ALLOCATION
  )
)

;; Update daily capacity usage
(define-public (update-daily-usage (provider-id principal) (date uint) (used-capacity uint))
  (let ((current-data (default-to
                        { used-capacity: u0, peak-usage: u0, efficiency-score: u0 }
                        (map-get? daily-capacity-usage { provider-id: provider-id, date: date }))))
    (map-set daily-capacity-usage
      { provider-id: provider-id, date: date }
      {
        used-capacity: used-capacity,
        peak-usage: (if (> used-capacity (get peak-usage current-data)) used-capacity (get peak-usage current-data)),
        efficiency-score: (calculate-efficiency-score provider-id used-capacity)
      }
    )
    (ok true)
  )
)

;; Calculate capacity efficiency score
(define-private (calculate-efficiency-score (provider-id principal) (used-capacity uint))
  (match (map-get? provider-capacity { provider-id: provider-id })
    capacity-data
    (let ((total (get total-capacity capacity-data)))
      (if (> total u0)
        (/ (* used-capacity u100) total)
        u0
      )
    )
    u0
  )
)

;; Get provider capacity information
(define-read-only (get-provider-capacity (provider-id principal))
  (map-get? provider-capacity { provider-id: provider-id })
)

;; Get capacity allocation
(define-read-only (get-capacity-allocation (allocation-id uint))
  (map-get? capacity-allocations { allocation-id: allocation-id })
)

;; Get daily usage statistics
(define-read-only (get-daily-usage (provider-id principal) (date uint))
  (map-get? daily-capacity-usage { provider-id: provider-id, date: date })
)

;; Calculate capacity utilization rate
(define-read-only (get-capacity-utilization (provider-id principal))
  (match (map-get? provider-capacity { provider-id: provider-id })
    capacity-data
    (let ((total (get total-capacity capacity-data))
          (allocated (get allocated-capacity capacity-data)))
      (if (> total u0)
        (some (/ (* allocated u100) total))
        none
      )
    )
    none
  )
)
