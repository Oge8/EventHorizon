;; EventHorizon: Beyond Attendance
;; A Proof of Attendance Protocol (POAP) with Rewards

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-claimed (err u101))
(define-constant err-event-not-found (err u102))
(define-constant err-not-eligible (err u103))
(define-constant err-invalid-event-id (err u104))
(define-constant err-invalid-date (err u105))
(define-constant err-invalid-max-participants (err u106))
(define-constant err-invalid-name (err u107))

;; Data Maps
(define-map events 
  { event-id: uint }
  { name: (string-ascii 50), date: uint, max-participants: uint, current-participants: uint }
)

(define-map participations
  { event-id: uint, participant: principal }
  { claimed: bool, timestamp: uint }
)

(define-map user-stats
  { user: principal }
  { total-events: uint, total-rewards: uint }
)

;; NFT Definitions
(define-non-fungible-token eventhorizon-nft uint)

;; Private Functions
(define-private (is-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (is-valid-event-id (event-id uint))
  (< event-id u1000000)
)

(define-private (is-future-date (date uint))
  (> date block-height)
)

(define-private (is-valid-max-participants (max-participants uint))
  (and (> max-participants u0) (< max-participants u1000000))
)

(define-private (is-valid-name (name (string-ascii 50)))
  (and 
    (not (is-eq name ""))
    (<= (len name) u50)
  )
)

;; Public Functions
(define-public (create-event (event-id uint) (name (string-ascii 50)) (date uint) (max-participants uint))
  (begin
    (asserts! (is-owner) err-owner-only)
    (asserts! (is-valid-event-id event-id) err-invalid-event-id)
    (asserts! (is-valid-name name) err-invalid-name)
    (asserts! (is-future-date date) err-invalid-date)
    (asserts! (is-valid-max-participants max-participants) err-invalid-max-participants)
    (asserts! (is-none (map-get? events { event-id: event-id })) err-already-claimed)
    
    (map-set events { event-id: event-id }
      { 
        name: name, 
        date: date, 
        max-participants: max-participants, 
        current-participants: u0 
      })
    (ok true)
  )
)

(define-public (check-in (event-id uint))
  (let (
    (event (unwrap! (map-get? events { event-id: event-id }) err-event-not-found))
    (current-participants (get current-participants event))
    (max-participants (get max-participants event))
  )
    (asserts! (is-valid-event-id event-id) err-invalid-event-id)
    (asserts! (< current-participants max-participants) err-not-eligible)
    (asserts! (is-none (map-get? participations { event-id: event-id, participant: tx-sender })) err-already-claimed)
    
    (map-set events { event-id: event-id }
      (merge event { current-participants: (+ current-participants u1) })
    )
    
    (map-set participations { event-id: event-id, participant: tx-sender }
      { claimed: true, timestamp: block-height }
    )
    
    (mint-nft event-id tx-sender)
  )
)

(define-public (claim-reward (event-id uint))
  (let (
    (participation (unwrap! (map-get? participations { event-id: event-id, participant: tx-sender }) err-not-eligible))
    (user-stat (default-to { total-events: u0, total-rewards: u0 } (map-get? user-stats { user: tx-sender })))
  )
    (asserts! (is-valid-event-id event-id) err-invalid-event-id)
    (asserts! (get claimed participation) err-not-eligible)
    
    (map-set user-stats { user: tx-sender }
      { 
        total-events: (+ (get total-events user-stat) u1), 
        total-rewards: (+ (get total-rewards user-stat) u10) 
      })
    (ok true)
  )
)

(define-private (mint-nft (token-id uint) (recipient principal))
  (nft-mint? eventhorizon-nft token-id recipient)
)

;; Read-only Functions
(define-read-only (get-event (event-id uint))
  (map-get? events { event-id: event-id })
)

(define-read-only (get-participation (event-id uint) (participant principal))
  (map-get? participations { event-id: event-id, participant: participant })
)

(define-read-only (get-user-stats (user principal))
  (default-to { total-events: u0, total-rewards: u0 } (map-get? user-stats { user: user }))
)