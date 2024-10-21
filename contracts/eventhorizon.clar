;; EventHorizon: Beyond Attendance
;; A Proof of Attendance Protocol (POAP) with Enhanced Features

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
(define-constant err-event-ended (err u108))
(define-constant err-insufficient-funds (err u109))
(define-constant err-transfer-failed (err u110))
(define-constant err-already-verified (err u111))
(define-constant err-invalid-role (err u112))
(define-constant err-event-cancelled (err u113))
(define-constant err-mint-failed (err u114))
(define-constant err-invalid-fee (err u115))
(define-constant err-invalid-description (err u116))
(define-constant err-invalid-event-type (err u117))
(define-constant err-invalid-location (err u118))
(define-constant err-invalid-verification-method (err u119))
(define-constant err-invalid-participant (err u120))
(define-constant err-invalid-organizer (err u121))
(define-constant err-invalid-is-private (err u122))

;; Data Variables
(define-data-var next-event-id uint u0)
(define-data-var total-events-created uint u0)
(define-data-var platform-fee uint u100)

;; Enhanced Data Maps
(define-map events 
  { event-id: uint }
  {
    name: (string-ascii 50),
    date: uint,
    max-participants: uint,
    current-participants: uint,
    creator: principal,
    entry-fee: uint,
    is-private: bool,
    is-cancelled: bool,
    description: (string-ascii 500),
    event-type: (string-ascii 20),
    location: (optional (string-ascii 100))
  }
)

(define-map participations
  { event-id: uint, participant: principal }
  {
    claimed: bool,
    timestamp: uint,
    verified: bool,
    verification-method: (string-ascii 20),
    attendance-duration: uint
  }
)

(define-map user-stats
  { user: principal }
  {
    total-events: uint,
    total-rewards: uint,
    reputation-score: uint,
    roles: (list 10 (string-ascii 20)),
    last-active: uint
  }
)

(define-map event-organizers
  { event-id: uint }
  { organizers: (list 5 principal) }
)

(define-map whitelisted-participants
  { event-id: uint }
  { participants: (list 100 principal) }
)

;; NFT Definitions
(define-non-fungible-token eventhorizon-nft uint)

;; Private Functions
(define-private (is-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (is-valid-name (name (string-ascii 50)))
  (and
    (> (len name) u0)
    (<= (len name) u50)
  )
)

(define-private (is-valid-description (description (string-ascii 500)))
  (and
    (> (len description) u0)
    (<= (len description) u500)
  )
)

(define-private (is-valid-event-type (event-type (string-ascii 20)))
  (and
    (> (len event-type) u0)
    (<= (len event-type) u20)
  )
)

(define-private (is-valid-location (location (optional (string-ascii 100))))
  (match location
    loc (and (> (len loc) u0) (<= (len loc) u100))
    true
  )
)

(define-private (is-valid-fee (fee uint))
  (<= fee u1000000000)
)

(define-private (is-future-date (date uint))
  (> date block-height)
)

(define-private (is-valid-max-participants (max-participants uint))
  (and
    (> max-participants u0)
    (<= max-participants u1000)
  )
)

(define-private (is-valid-verification-method (method (string-ascii 20)))
  (and
    (> (len method) u0)
    (<= (len method) u20)
  )
)

(define-private (increment-event-id)
  (let ((current (var-get next-event-id)))
    (var-set next-event-id (+ current u1))
    current
  )
)

(define-private (is-event-organizer (event-id uint) (user principal))
  (let ((organizers (default-to { organizers: (list) } (map-get? event-organizers { event-id: event-id }))))
    (is-some (index-of (get organizers organizers) user))
  )
)

(define-private (update-reputation (user principal) (points uint))
  (let ((stats (default-to 
                { total-events: u0, total-rewards: u0, reputation-score: u0, roles: (list), last-active: u0 }
                (map-get? user-stats { user: user }))))
    (map-set user-stats { user: user }
      (merge stats {
        reputation-score: (+ (get reputation-score stats) points)
      })
    )
    true
  )
)

(define-private (decrease-reputation (user principal) (points uint))
  (let ((stats (default-to 
                { total-events: u0, total-rewards: u0, reputation-score: u0, roles: (list), last-active: u0 }
                (map-get? user-stats { user: user }))))
    (map-set user-stats { user: user }
      (merge stats {
        reputation-score: (if (> (get reputation-score stats) points)
                            (- (get reputation-score stats) points)
                            u0)
      })
    )
    true
  )
)

(define-private (mint-event-nft (event-id uint) (recipient principal))
  (nft-mint? eventhorizon-nft event-id recipient)
)

(define-private (process-check-in (event-id uint) (event { name: (string-ascii 50),
    date: uint,
    max-participants: uint,
    current-participants: uint,
    creator: principal,
    entry-fee: uint,
    is-private: bool,
    is-cancelled: bool,
    description: (string-ascii 500),
    event-type: (string-ascii 20),
    location: (optional (string-ascii 100)) }))
  (begin
    (asserts! (is-valid-event-id event-id) err-invalid-event-id)
    (asserts! (is-valid-fee (get entry-fee event)) err-invalid-fee)
    
    (if (> (get entry-fee event) u0)
        (begin
          (try! (stx-transfer? (get entry-fee event) tx-sender (get creator event)))
          (try! (stx-transfer? (var-get platform-fee) tx-sender contract-owner)))
        true)
    
    (map-set events { event-id: event-id }
      (merge event { current-participants: (+ (get current-participants event) u1) }))
    
    (map-set participations { event-id: event-id, participant: tx-sender }
      {
        claimed: true,
        timestamp: block-height,
        verified: false,
        verification-method: "",
        attendance-duration: u0
      })
    
    (try! (mint-event-nft event-id tx-sender))
    (ok true)
  )
)

(define-private (is-valid-event-id (event-id uint))
  (< event-id (var-get next-event-id))
)

(define-private (is-valid-is-private (is-private bool))
  (or (is-eq is-private true) (is-eq is-private false))
)

;; Public Functions
(define-public (create-event (name (string-ascii 50)) 
                           (date uint) 
                           (max-participants uint)
                           (entry-fee uint)
                           (is-private bool)
                           (description (string-ascii 500))
                           (event-type (string-ascii 20))
                           (location (optional (string-ascii 100))))
  (begin
    (asserts! (is-owner) err-owner-only)
    (asserts! (is-valid-name name) err-invalid-name)
    (asserts! (is-future-date date) err-invalid-date)
    (asserts! (is-valid-max-participants max-participants) err-invalid-max-participants)
    (asserts! (is-valid-fee entry-fee) err-invalid-fee)
    (asserts! (is-valid-description description) err-invalid-description)
    (asserts! (is-valid-event-type event-type) err-invalid-event-type)
    (asserts! (is-valid-location location) err-invalid-location)
    (asserts! (is-valid-is-private is-private) err-invalid-is-private)
    
    (let ((event-id (increment-event-id)))
      (map-set events { event-id: event-id }
        {
          name: name,
          date: date,
          max-participants: max-participants,
          current-participants: u0,
          creator: tx-sender,
          entry-fee: entry-fee,
          is-private: is-private,
          is-cancelled: false,
          description: description,
          event-type: event-type,
          location: location
        })
      
      (var-set total-events-created (+ (var-get total-events-created) u1))
      (ok event-id))
  )
)

(define-public (check-in (event-id uint))
  (begin
    (asserts! (is-valid-event-id event-id) err-invalid-event-id)
    (let ((event (unwrap! (map-get? events { event-id: event-id }) err-event-not-found)))
      (begin
        (asserts! (not (get is-cancelled event)) err-event-cancelled)
        (asserts! (< (get current-participants event) (get max-participants event)) err-not-eligible)
        (asserts! (is-none (map-get? participations { event-id: event-id, participant: tx-sender })) err-already-claimed)
        (asserts! (or (not (get is-private event))
                     (is-some (index-of (get participants (default-to { participants: (list) }
                       (map-get? whitelisted-participants { event-id: event-id }))) tx-sender)))
                err-not-eligible)
        
        (process-check-in event-id event)))
  )
)

(define-public (verify-attendance (event-id uint) (participant principal) (verification-method (string-ascii 20)))
  (begin
    (asserts! (is-valid-event-id event-id) err-invalid-event-id)
    (asserts! (is-valid-verification-method verification-method) err-invalid-verification-method)
    (asserts! (not (is-eq participant tx-sender)) err-invalid-participant)
    (let ((participation (unwrap! (map-get? participations { event-id: event-id, participant: participant }) err-not-eligible)))
      (begin
        (asserts! (or (is-owner) (is-event-organizer event-id tx-sender)) err-owner-only)
        (asserts! (not (get verified participation)) err-already-verified)
        
        (map-set participations { event-id: event-id, participant: participant }
          (merge participation {
            verified: true,
            verification-method: verification-method
          }))
        
        (as-contract (update-reputation participant u10))
        (ok true)))
  )
)

(define-public (cancel-event (event-id uint))
  (begin
    (asserts! (is-valid-event-id event-id) err-invalid-event-id)
    (let ((event (unwrap! (map-get? events { event-id: event-id }) err-event-not-found)))
      (begin
        (asserts! (or (is-owner) (is-eq (get creator event) tx-sender)) err-owner-only)
        (asserts! (not (get is-cancelled event)) err-event-cancelled)
        
        (map-set events { event-id: event-id }
          (merge event { is-cancelled: true }))
        (ok true)))
  )
)

(define-public (add-organizer (event-id uint) (organizer principal))
  (begin
    (asserts! (is-valid-event-id event-id) err-invalid-event-id)
    (asserts! (not (is-eq organizer tx-sender)) err-invalid-organizer)
    (let ((event (unwrap! (map-get? events { event-id: event-id }) err-event-not-found))
          (current-organizers (default-to { organizers: (list) } (map-get? event-organizers { event-id: event-id }))))
      (begin
        (asserts! (or (is-owner) (is-eq (get creator event) tx-sender)) err-owner-only)
        (asserts! (< (len (get organizers current-organizers)) u5) err-not-eligible)
        (asserts! (is-none (index-of (get organizers current-organizers) organizer)) err-invalid-organizer)
        
        (let ((new-organizers (unwrap! (as-max-len? (append (get organizers current-organizers) organizer) u5)
                                       err-not-eligible)))
          (map-set event-organizers { event-id: event-id }
            { organizers: new-organizers })
          (ok true))))
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-owner) err-owner-only)
    (asserts! (is-valid-fee new-fee) err-invalid-fee)
    (var-set platform-fee new-fee)
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-event (event-id uint))
  (map-get? events { event-id: event-id })
)

(define-read-only (get-participation (event-id uint) (participant principal))
  (map-get? participations { event-id: event-id, participant: participant })
)

(define-read-only (get-user-stats (user principal))
  (default-to 
    { total-events: u0, total-rewards: u0, reputation-score: u0, roles: (list), last-active: u0 }
    (map-get? user-stats { user: user })
  )
)

(define-read-only (get-total-events)
  (var-get total-events-created)
)

(define-read-only (is-whitelisted (event-id uint) (participant principal))
  (let ((whitelist (default-to { participants: (list) } (map-get? whitelisted-participants { event-id: event-id }))))
    (is-some (index-of (get participants whitelist) participant))
  )
)