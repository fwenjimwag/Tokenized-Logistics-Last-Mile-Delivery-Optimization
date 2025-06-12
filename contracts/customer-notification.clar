;; Customer Notification Contract
;; Manages customer notifications for delivery updates

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_NOTIFICATION_NOT_FOUND (err u401))
(define-constant ERR_INVALID_STATUS (err u402))

;; Notification types
(define-constant NOTIFICATION_ORDER_CONFIRMED u0)
(define-constant NOTIFICATION_OUT_FOR_DELIVERY u1)
(define-constant NOTIFICATION_DELIVERED u2)
(define-constant NOTIFICATION_DELAYED u3)
(define-constant NOTIFICATION_FAILED u4)

;; Notification status
(define-constant STATUS_PENDING u0)
(define-constant STATUS_SENT u1)
(define-constant STATUS_DELIVERED u2)
(define-constant STATUS_FAILED u3)

;; Data structures
(define-map notifications
  { notification-id: uint }
  {
    customer-id: principal,
    delivery-id: uint,
    notification-type: uint,
    message: (string-ascii 200),
    status: uint,
    created-block: uint,
    sent-block: (optional uint),
    delivery-method: (string-ascii 20) ;; "email", "sms", "push"
  }
)

(define-map customer-preferences
  { customer-id: principal }
  {
    email-notifications: bool,
    sms-notifications: bool,
    push-notifications: bool,
    notification-frequency: uint, ;; 0: all, 1: important only, 2: delivery only
    preferred-time-start: uint,
    preferred-time-end: uint
  }
)

(define-map delivery-tracking
  { delivery-id: uint }
  {
    customer-id: principal,
    provider-id: principal,
    current-status: uint,
    estimated-delivery: uint,
    actual-delivery: (optional uint),
    location-updates: (list 10 (string-ascii 100))
  }
)

(define-data-var next-notification-id uint u1)

;; Set customer notification preferences
(define-public (set-customer-preferences
  (email-enabled bool)
  (sms-enabled bool)
  (push-enabled bool)
  (frequency uint)
  (time-start uint)
  (time-end uint)
)
  (begin
    (map-set customer-preferences
      { customer-id: tx-sender }
      {
        email-notifications: email-enabled,
        sms-notifications: sms-enabled,
        push-notifications: push-enabled,
        notification-frequency: frequency,
        preferred-time-start: time-start,
        preferred-time-end: time-end
      }
    )
    (ok true)
  )
)

;; Create a new notification
(define-public (create-notification
  (customer-id principal)
  (delivery-id uint)
  (notification-type uint)
  (message (string-ascii 200))
  (delivery-method (string-ascii 20))
)
  (let ((notification-id (var-get next-notification-id)))
    (map-set notifications
      { notification-id: notification-id }
      {
        customer-id: customer-id,
        delivery-id: delivery-id,
        notification-type: notification-type,
        message: message,
        status: STATUS_PENDING,
        created-block: block-height,
        sent-block: none,
        delivery-method: delivery-method
      }
    )

    (var-set next-notification-id (+ notification-id u1))
    (ok notification-id)
  )
)

;; Update delivery tracking information
(define-public (update-delivery-tracking
  (delivery-id uint)
  (customer-id principal)
  (provider-id principal)
  (current-status uint)
  (estimated-delivery uint)
  (location (string-ascii 100))
)
  (let ((current-tracking (default-to
                            { customer-id: customer-id, provider-id: provider-id, current-status: u0,
                              estimated-delivery: u0, actual-delivery: none, location-updates: (list) }
                            (map-get? delivery-tracking { delivery-id: delivery-id })))
        (updated-locations (unwrap-panic (as-max-len?
                                          (append (get location-updates current-tracking) location)
                                          u10))))
    (map-set delivery-tracking
      { delivery-id: delivery-id }
      (merge current-tracking {
        current-status: current-status,
        estimated-delivery: estimated-delivery,
        location-updates: updated-locations,
        actual-delivery: (if (is-eq current-status NOTIFICATION_DELIVERED) (some block-height) (get actual-delivery current-tracking))
      })
    )

    ;; Auto-create notification for status change
    (create-notification customer-id delivery-id current-status
                        (get-status-message current-status) "push")
  )
)

;; Mark notification as sent
(define-public (mark-notification-sent (notification-id uint))
  (match (map-get? notifications { notification-id: notification-id })
    notification-data
    (begin
      (map-set notifications
        { notification-id: notification-id }
        (merge notification-data {
          status: STATUS_SENT,
          sent-block: (some block-height)
        })
      )
      (ok true)
    )
    ERR_NOTIFICATION_NOT_FOUND
  )
)

;; Get status message for notification type
(define-private (get-status-message (status-type uint))
  (if (is-eq status-type NOTIFICATION_ORDER_CONFIRMED)
    "Your order has been confirmed and is being prepared for delivery"
    (if (is-eq status-type NOTIFICATION_OUT_FOR_DELIVERY)
      "Your package is out for delivery and will arrive soon"
      (if (is-eq status-type NOTIFICATION_DELIVERED)
        "Your package has been successfully delivered"
        (if (is-eq status-type NOTIFICATION_DELAYED)
          "Your delivery has been delayed. We apologize for the inconvenience"
          "Delivery attempt failed. Please contact customer service"
        )
      )
    )
  )
)

;; Get notification details
(define-read-only (get-notification (notification-id uint))
  (map-get? notifications { notification-id: notification-id })
)

;; Get customer preferences
(define-read-only (get-customer-preferences (customer-id principal))
  (map-get? customer-preferences { customer-id: customer-id })
)

;; Get delivery tracking information
(define-read-only (get-delivery-tracking (delivery-id uint))
  (map-get? delivery-tracking { delivery-id: delivery-id })
)

;; Check if customer wants notifications for this type
(define-read-only (should-notify-customer (customer-id principal) (notification-type uint))
  (match (map-get? customer-preferences { customer-id: customer-id })
    prefs
    (let ((frequency (get notification-frequency prefs)))
      (or (is-eq frequency u0) ;; all notifications
          (and (is-eq frequency u1) ;; important only
               (or (is-eq notification-type NOTIFICATION_DELIVERED)
                   (is-eq notification-type NOTIFICATION_FAILED)))
          (and (is-eq frequency u2) ;; delivery only
               (is-eq notification-type NOTIFICATION_DELIVERED)))
    )
    true ;; default to true if no preferences set
  )
)
