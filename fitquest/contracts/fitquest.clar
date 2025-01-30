;; Fitness Challenge Smart Contract

;; Define trait for reward token
(define-trait sip-010-trait
    ((transfer (uint principal (optional (buff 34))) (response bool uint)))
)

;; Define data structures
(define-data-var total-challenges uint u0)
(define-data-var reward-token principal tx-sender) ;; Reward token contract address
(define-data-var reward-amount uint u100) ;; Reward amount in tokens

;; Constants for validation
(define-constant MIN_GOAL u1)
(define-constant MAX_GOAL u1000000) ;; 1 million steps/calories/etc
(define-constant MIN_DURATION u1440) ;; Minimum 1 day (in blocks)
(define-constant MAX_DURATION u525600) ;; Maximum 1 year (in blocks)
(define-constant MAX_PROGRESS u1000000) ;; Maximum progress value

(define-map challenges
  { challenge-id: uint }
  {
    creator: principal,
    goal: uint,
    start-time: uint,
    end-time: uint,
    participants: (list 50 principal),
    completed: (list 50 principal)
  }
)

(define-map user-progress
  { user: principal, challenge-id: uint }
  uint ;; Progress value (e.g., steps, calories burned)
)

;; Error codes
(define-constant ERR_NOT_STARTED (err u1))
(define-constant ERR_ENDED (err u2))
(define-constant ERR_ALREADY_JOINED (err u3))
(define-constant ERR_NOT_PARTICIPANT (err u4))
(define-constant ERR_GOAL_NOT_MET (err u5))
(define-constant ERR_TRANSFER_FAILED (err u6))
(define-constant ERR_INVALID_GOAL (err u7))
(define-constant ERR_INVALID_DURATION (err u8))
(define-constant ERR_INVALID_PROGRESS (err u9))
(define-constant ERR_INVALID_CHALLENGE (err u10))
(define-constant ERR_INVALID_TOKEN (err u11))

;; Create a new fitness challenge
(define-public (create-challenge (goal uint) (start-time uint) (end-time uint))
  (let 
    (
      (challenge-id (+ (var-get total-challenges) u1))
      (duration (- end-time start-time))
    )
    ;; Validate inputs
    (asserts! (and (>= goal MIN_GOAL) (<= goal MAX_GOAL)) ERR_INVALID_GOAL)
    (asserts! (>= start-time block-height) ERR_NOT_STARTED)
    (asserts! (and (>= duration MIN_DURATION) (<= duration MAX_DURATION)) ERR_INVALID_DURATION)
    
    (map-set challenges
      { challenge-id: challenge-id }
      {
        creator: tx-sender,
        goal: goal,
        start-time: start-time,
        end-time: end-time,
        participants: (list tx-sender),
        completed: (list)
      }
    )
    (var-set total-challenges challenge-id)
    (ok challenge-id)
  )
)

;; Join an existing fitness challenge
(define-public (join-challenge (challenge-id uint))
  (let 
    (
      (current-total (var-get total-challenges))
    )
    ;; Validate challenge-id
    (asserts! (<= challenge-id current-total) ERR_INVALID_CHALLENGE)
    (let ((challenge (unwrap! (map-get? challenges { challenge-id: challenge-id }) ERR_INVALID_CHALLENGE)))
      (asserts! (>= block-height (get start-time challenge)) ERR_NOT_STARTED)
      (asserts! (< block-height (get end-time challenge)) ERR_ENDED)
      (asserts! (not (contains? (get participants challenge) tx-sender)) ERR_ALREADY_JOINED)
      (map-set challenges
        { challenge-id: challenge-id }
        (merge challenge
          { participants: (unwrap-panic (as-max-len? (append (get participants challenge) tx-sender) u50)) }
        )
      )
      (ok true)
    )
  )
)

;; Submit progress for a challenge
(define-public (submit-progress (challenge-id uint) (progress uint))
  (let 
    (
      (current-total (var-get total-challenges))
    )
    ;; Validate inputs
    (asserts! (<= challenge-id current-total) ERR_INVALID_CHALLENGE)
    (asserts! (<= progress MAX_PROGRESS) ERR_INVALID_PROGRESS)
    
    (let ((challenge (unwrap! (map-get? challenges { challenge-id: challenge-id }) ERR_INVALID_CHALLENGE)))
      (asserts! (>= block-height (get start-time challenge)) ERR_NOT_STARTED)
      (asserts! (< block-height (get end-time challenge)) ERR_ENDED)
      (asserts! (contains? (get participants challenge) tx-sender) ERR_NOT_PARTICIPANT)
      (map-set user-progress { user: tx-sender, challenge-id: challenge-id } progress)
      (ok true)
    )
  )
)

;; Validate reward token contract
(define-private (validate-reward-token (reward-token-contract <sip-010-trait>))
  (is-eq (contract-of reward-token-contract) (var-get reward-token))
)

;; Claim reward for completing a challenge
(define-public (claim-reward (challenge-id uint) (reward-token-contract <sip-010-trait>))
  (let 
    (
      (current-total (var-get total-challenges))
    )
    ;; Validate challenge-id and reward token
    (asserts! (<= challenge-id current-total) ERR_INVALID_CHALLENGE)
    (asserts! (validate-reward-token reward-token-contract) ERR_INVALID_TOKEN)
    
    (let ((challenge (unwrap! (map-get? challenges { challenge-id: challenge-id }) ERR_INVALID_CHALLENGE)))
      (asserts! (>= block-height (get end-time challenge)) ERR_ENDED)
      (asserts! (contains? (get participants challenge) tx-sender) ERR_NOT_PARTICIPANT)
      (let ((progress (unwrap! (map-get? user-progress { user: tx-sender, challenge-id: challenge-id }) ERR_GOAL_NOT_MET)))
        (asserts! (>= progress (get goal challenge)) ERR_GOAL_NOT_MET)
        (map-set challenges
          { challenge-id: challenge-id }
          (merge challenge
            { completed: (unwrap-panic (as-max-len? (append (get completed challenge) tx-sender) u50)) }
          )
        )
        (match (contract-call? reward-token-contract transfer (var-get reward-amount) tx-sender none)
          success (ok true)
          error ERR_TRANSFER_FAILED)
      )
    )
  )
)

;; Helper function to check if a principal is in a list
(define-private (contains? (lst (list 50 principal)) (user principal))
  (is-some (index-of lst user))
)

;; Read-only function to get challenge details
(define-read-only (get-challenge-details (challenge-id uint))
  (let 
    (
      (current-total (var-get total-challenges))
    )
    (if (<= challenge-id current-total)
      (map-get? challenges { challenge-id: challenge-id })
      none
    )
  )
)

;; Read-only function to get user progress
(define-read-only (get-user-progress (user principal) (challenge-id uint))
  (let 
    (
      (current-total (var-get total-challenges))
    )
    (if (<= challenge-id current-total)
      (map-get? user-progress { user: user, challenge-id: challenge-id })
      none
    )
  )
)