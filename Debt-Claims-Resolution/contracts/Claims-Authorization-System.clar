;; Decentralized Debt Resolution Protocol Smart Contract
;;
;; A comprehensive blockchain-based protocol for facilitating transparent debt resolution
;; and multi-party financial settlements on the Stacks network. This protocol enables:
;; - Transparent debt claim registration and verification
;; - Automated debtor-creditor relationship management
;; - Secure multi-party settlement orchestration with consent workflows
;; - Efficient batch processing for complex debt resolution scenarios
;; - Immutable audit trail for all financial settlement transactions
;; - Decentralized governance for dispute resolution and platform management
;; - Automated interest calculation and compounding
;; - Multi-party dispute resolution system with arbitration

;; ERROR CONSTANTS - Comprehensive Validation and Access Control

(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-DEBT-RECORD-NOT-FOUND (err u102))
(define-constant ERR-SETTLEMENT-ALREADY-APPROVED (err u103))
(define-constant ERR-CREDITOR-NOT-REGISTERED (err u104))
(define-constant ERR-PARAMETER-MISMATCH (err u105))
(define-constant ERR-APPROVAL-REQUIRED (err u106))
(define-constant ERR-INVALID-AMOUNT (err u107))
(define-constant ERR-SETTLEMENT-FAILED (err u108))
(define-constant ERR-INVALID-PRINCIPAL-ADDRESS (err u109))
(define-constant ERR-DEBTOR-NOT-REGISTERED (err u110))
(define-constant ERR-DISPUTE-NOT-FOUND (err u111))
(define-constant ERR-DISPUTE-ALREADY-RESOLVED (err u112))
(define-constant ERR-INVALID-DISPUTE-STATUS (err u113))
(define-constant ERR-ARBITRATOR-NOT-AUTHORIZED (err u114))
(define-constant ERR-INTEREST-CALCULATION-FAILED (err u115))
(define-constant ERR-INVALID-INTEREST-RATE (err u116))
(define-constant ERR-DEBT-CLAIM-NOT-FOUND (err u117))
(define-constant ERR-INVALID-INPUT (err u118))
(define-constant ERR-ARBITRATOR-POOL-FULL (err u119))

;; PROTOCOL CONFIGURATION AND GOVERNANCE

(define-data-var protocol-admin principal tx-sender)
(define-data-var total-settlement-volume uint u0)
(define-data-var dispute-counter uint u0)
(define-data-var arbitrator-pool (list 10 principal) (list))
(define-data-var default-interest-rate uint u500) ;; 5% annual rate (basis points)

;; CORE DATA STRUCTURES - Participant Registry and Settlement Tracking

;; Creditor registry: comprehensive tracking of all registered creditors and their claim portfolios
(define-map registered-creditor-claims principal uint)

;; Debtor registry: maintains comprehensive debt obligation tracking per registered debtor
(define-map registered-debtor-obligations principal uint)

;; Settlement consent matrix: tracks explicit creditor approvals for debt consolidation processes
(define-map settlement-consent-matrix {debtor-address: principal, creditor-address: principal} bool)

;; ENHANCED DATA STRUCTURES - Interest and Dispute Management

;; Individual debt claims with interest tracking
(define-map debt-claims 
  {debtor: principal, creditor: principal, claim-id: uint}
  {
    principal-amount: uint,
    interest-rate: uint,
    creation-block: uint,
    last-interest-update: uint,
    total-accrued-interest: uint,
    is-active: bool
  })

;; Dispute resolution system
(define-map dispute-records
  uint
  {
    disputer: principal,
    defendant: principal,
    dispute-type: (string-ascii 50),
    amount-disputed: uint,
    claim-id: uint,
    status: (string-ascii 20),
    arbitrator: (optional principal),
    resolution-block: (optional uint),
    resolution-details: (string-ascii 200)
  })

;; Arbitrator authorization and performance tracking
(define-map authorized-arbitrators
  principal
  {
    is-active: bool,
    cases-resolved: uint,
    reputation-score: uint
  })

;; Claim ID tracking for each debtor-creditor pair
(define-map claim-counter {debtor: principal, creditor: principal} uint)

;; INPUT VALIDATION HELPER FUNCTIONS

;; Validate principal address (not null/empty)
(define-private (is-valid-principal (address principal))
  (not (is-eq address 'SP000000000000000000002Q6VF78)))

;; Validate string input (50 chars)
(define-private (is-valid-string-50 (input (string-ascii 50)))
  (> (len input) u0))

;; Validate string input (200 chars)
(define-private (is-valid-string-200 (input (string-ascii 200)))
  (> (len input) u0))

;; Validate uint input (greater than 0)
(define-private (is-valid-uint (input uint))
  (> input u0))

;; Validate claim ID
(define-private (is-valid-claim-id (claim-id uint))
  (> claim-id u0))

;; PROTOCOL INITIALIZATION AND GOVERNANCE

;; Initialize the decentralized debt resolution protocol with administrative controls
(define-public (initialize-debt-resolution-protocol)
  (let ((current-transaction-sender tx-sender))
    (begin
      (asserts! (is-eq current-transaction-sender (var-get protocol-admin)) ERR-UNAUTHORIZED-ACCESS)
      (ok true))))

;; Add authorized arbitrator to the system
(define-public (add-arbitrator (arbitrator-address principal))
  (let ((current-pool (var-get arbitrator-pool)))
    (begin
      (asserts! (is-eq tx-sender (var-get protocol-admin)) ERR-UNAUTHORIZED-ACCESS)
      (asserts! (is-valid-principal arbitrator-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (< (len current-pool) u10) ERR-ARBITRATOR-POOL-FULL)
      
      (map-set authorized-arbitrators arbitrator-address 
        {is-active: true, cases-resolved: u0, reputation-score: u100})
      (var-set arbitrator-pool (unwrap-panic (as-max-len? (append current-pool arbitrator-address) u10)))
      (ok true))))

;; PARTICIPANT REGISTRATION AND ONBOARDING SYSTEM

;; Register a new creditor entity in the debt resolution protocol
(define-public (register-new-creditor)
  (begin
    (asserts! (is-valid-principal tx-sender) ERR-INVALID-PRINCIPAL-ADDRESS)
    (map-set registered-creditor-claims tx-sender u0)
    (ok true)))

;; Register a new debtor entity in the debt resolution protocol
(define-public (register-new-debtor)
  (begin
    (asserts! (is-valid-principal tx-sender) ERR-INVALID-PRINCIPAL-ADDRESS)
    (map-set registered-debtor-obligations tx-sender u0)
    (ok true)))

;; ENHANCED DEBT CLAIM CREATION WITH INTEREST TRACKING

;; Create and register a new debt claim with interest calculation
(define-public (register-debt-claim-with-interest 
                (target-debtor-address principal) 
                (claim-amount uint) 
                (interest-rate uint))
  (let (
    (current-creditor-total-claims (default-to u0 (map-get? registered-creditor-claims tx-sender)))
    (current-debtor-total-obligations (default-to u0 (map-get? registered-debtor-obligations target-debtor-address)))
    (current-claim-id (+ (default-to u0 (map-get? claim-counter {debtor: target-debtor-address, creditor: tx-sender})) u1))
    (current-block-height block-height)
  )
    (begin
      ;; Comprehensive input validation and business rule enforcement
      (asserts! (is-valid-principal target-debtor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-uint claim-amount) ERR-INVALID-AMOUNT)
      (asserts! (is-some (map-get? registered-creditor-claims tx-sender)) ERR-CREDITOR-NOT-REGISTERED)
      (asserts! (<= interest-rate u2000) ERR-INVALID-INTEREST-RATE) ;; Max 20% annual
      
      ;; Prevent integer overflow vulnerabilities in financial calculations
      (asserts! (< current-creditor-total-claims (- (pow u2 u128) claim-amount)) ERR-INVALID-AMOUNT)
      (asserts! (< current-debtor-total-obligations (- (pow u2 u128) claim-amount)) ERR-INVALID-AMOUNT)
      
      ;; Create detailed debt claim record with interest tracking
      (map-set debt-claims 
        {debtor: target-debtor-address, creditor: tx-sender, claim-id: current-claim-id}
        {
          principal-amount: claim-amount,
          interest-rate: interest-rate,
          creation-block: current-block-height,
          last-interest-update: current-block-height,
          total-accrued-interest: u0,
          is-active: true
        })
      
      ;; Update claim counter
      (map-set claim-counter {debtor: target-debtor-address, creditor: tx-sender} current-claim-id)
      
      ;; Update creditor's comprehensive claim portfolio
      (map-set registered-creditor-claims tx-sender (+ current-creditor-total-claims claim-amount))
      
      ;; Update debtor's consolidated financial obligation record
      (map-set registered-debtor-obligations target-debtor-address (+ current-debtor-total-obligations claim-amount))
      
      (ok current-claim-id))))

;; DEBT CLAIM CREATION AND MANAGEMENT SYSTEM (Original function maintained for compatibility)

;; Create and register a new debt claim against a specified debtor entity
(define-public (register-debt-claim (target-debtor-address principal) (claim-amount uint))
  (register-debt-claim-with-interest target-debtor-address claim-amount (var-get default-interest-rate)))

;; INTEREST CALCULATION AND MANAGEMENT SYSTEM

;; Calculate and update accrued interest for a specific debt claim
(define-public (update-debt-interest 
                (debtor-address principal) 
                (creditor-address principal) 
                (claim-id uint))
  (let (
    (claim-data (unwrap! (map-get? debt-claims {debtor: debtor-address, creditor: creditor-address, claim-id: claim-id}) 
                         ERR-DEBT-CLAIM-NOT-FOUND))
    (blocks-elapsed (- block-height (get last-interest-update claim-data)))
    (annual-blocks u52560) ;; Approximate blocks per year (assuming 10 min blocks)
    (interest-calculation (/ (* (* (get principal-amount claim-data) (get interest-rate claim-data)) blocks-elapsed) 
                           (* annual-blocks u10000))) ;; Convert from basis points
    (new-total-interest (+ (get total-accrued-interest claim-data) interest-calculation))
  )
    (begin
      ;; Input validation
      (asserts! (is-valid-principal debtor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-principal creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-claim-id claim-id) ERR-INVALID-INPUT)
      (asserts! (get is-active claim-data) ERR-DEBT-CLAIM-NOT-FOUND)
      (asserts! (> blocks-elapsed u0) ERR-INTEREST-CALCULATION-FAILED)
      
      ;; Update claim with new interest calculation
      (map-set debt-claims 
        {debtor: debtor-address, creditor: creditor-address, claim-id: claim-id}
        (merge claim-data {
          last-interest-update: block-height,
          total-accrued-interest: new-total-interest
        }))
      
      ;; Update creditor's total claims to include new interest
      (map-set registered-creditor-claims creditor-address 
        (+ (default-to u0 (map-get? registered-creditor-claims creditor-address)) interest-calculation))
      
      ;; Update debtor's total obligations to include new interest
      (map-set registered-debtor-obligations debtor-address 
        (+ (default-to u0 (map-get? registered-debtor-obligations debtor-address)) interest-calculation))
      
      (ok interest-calculation))))

;; DISPUTE RESOLUTION SYSTEM

;; File a dispute against a debt claim or settlement
(define-public (file-dispute 
                (defendant-address principal) 
                (dispute-type (string-ascii 50)) 
                (amount-disputed uint) 
                (claim-id uint))
  (let (
    (new-dispute-id (+ (var-get dispute-counter) u1))
  )
    (begin
      ;; Validate dispute parameters
      (asserts! (is-valid-principal defendant-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-string-50 dispute-type) ERR-INVALID-INPUT)
      (asserts! (is-valid-uint amount-disputed) ERR-INVALID-AMOUNT)
      (asserts! (is-valid-claim-id claim-id) ERR-INVALID-INPUT)
      (asserts! (not (is-eq tx-sender defendant-address)) ERR-PARAMETER-MISMATCH)
      
      ;; Create dispute record
      (map-set dispute-records new-dispute-id {
        disputer: tx-sender,
        defendant: defendant-address,
        dispute-type: dispute-type,
        amount-disputed: amount-disputed,
        claim-id: claim-id,
        status: "pending",
        arbitrator: none,
        resolution-block: none,
        resolution-details: ""
      })
      
      ;; Update dispute counter
      (var-set dispute-counter new-dispute-id)
      
      (ok new-dispute-id))))

;; Assign arbitrator to a dispute
(define-public (assign-arbitrator (dispute-id uint) (arbitrator-address principal))
  (let (
    (dispute-data (unwrap! (map-get? dispute-records dispute-id) ERR-DISPUTE-NOT-FOUND))
    (arbitrator-data (unwrap! (map-get? authorized-arbitrators arbitrator-address) ERR-ARBITRATOR-NOT-AUTHORIZED))
  )
    (begin
      ;; Validate inputs and arbitrator assignment
      (asserts! (is-eq tx-sender (var-get protocol-admin)) ERR-UNAUTHORIZED-ACCESS)
      (asserts! (is-valid-uint dispute-id) ERR-INVALID-INPUT)
      (asserts! (is-valid-principal arbitrator-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-eq (get status dispute-data) "pending") ERR-INVALID-DISPUTE-STATUS)
      (asserts! (get is-active arbitrator-data) ERR-ARBITRATOR-NOT-AUTHORIZED)
      
      ;; Update dispute with assigned arbitrator
      (map-set dispute-records dispute-id 
        (merge dispute-data {
          arbitrator: (some arbitrator-address),
          status: "in-review"
        }))
      
      (ok true))))

;; Resolve dispute with arbitrator decision
(define-public (resolve-dispute 
                (dispute-id uint) 
                (resolution-details (string-ascii 200)) 
                (award-amount uint))
  (let (
    (dispute-data (unwrap! (map-get? dispute-records dispute-id) ERR-DISPUTE-NOT-FOUND))
    (arbitrator-data (unwrap! (map-get? authorized-arbitrators tx-sender) ERR-ARBITRATOR-NOT-AUTHORIZED))
  )
    (begin
      ;; Validate inputs and arbitrator authority
      (asserts! (is-valid-uint dispute-id) ERR-INVALID-INPUT)
      (asserts! (is-valid-string-200 resolution-details) ERR-INVALID-INPUT)
      (asserts! (is-eq (some tx-sender) (get arbitrator dispute-data)) ERR-ARBITRATOR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status dispute-data) "in-review") ERR-DISPUTE-ALREADY-RESOLVED)
      (asserts! (get is-active arbitrator-data) ERR-ARBITRATOR-NOT-AUTHORIZED)
      
      ;; Update dispute with resolution
      (map-set dispute-records dispute-id 
        (merge dispute-data {
          status: "resolved",
          resolution-block: (some block-height),
          resolution-details: resolution-details
        }))
      
      ;; Update arbitrator performance metrics
      (map-set authorized-arbitrators tx-sender 
        (merge arbitrator-data {
          cases-resolved: (+ (get cases-resolved arbitrator-data) u1),
          reputation-score: (+ (get reputation-score arbitrator-data) u10)
        }))
      
      ;; Execute award transfer if applicable
      (if (> award-amount u0)
        (try! (stx-transfer? award-amount (get defendant dispute-data) (get disputer dispute-data)))
        true)
      
      (ok true))))

;; SETTLEMENT CONSENT AND AUTHORIZATION WORKFLOW

;; Grant explicit consent for debt settlement between debtor and creditor
(define-public (grant-settlement-consent (target-debtor-address principal))
  (let (
    (debtor-registration-exists (is-some (map-get? registered-debtor-obligations target-debtor-address)))
  )
    (begin
      ;; Input validation
      (asserts! (is-valid-principal target-debtor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      ;; Validate participant registration status and prevent duplicate approvals
      (asserts! (is-some (map-get? registered-creditor-claims tx-sender)) ERR-CREDITOR-NOT-REGISTERED)
      (asserts! debtor-registration-exists ERR-DEBTOR-NOT-REGISTERED)
      (asserts! (not (default-to false (map-get? settlement-consent-matrix 
                {debtor-address: target-debtor-address, creditor-address: tx-sender}))) 
                ERR-SETTLEMENT-ALREADY-APPROVED)
      
      ;; Record explicit settlement consent in the protocol
      (map-set settlement-consent-matrix {debtor-address: target-debtor-address, creditor-address: tx-sender} true)
      (ok true))))

;; INDIVIDUAL SETTLEMENT PROCESSING ENGINE

;; Execute individual settlement payment to a single creditor
(define-public (execute-individual-settlement (target-creditor-address principal) (settlement-amount uint))
  (let (
    (creditor-outstanding-claims (default-to u0 (map-get? registered-creditor-claims target-creditor-address)))
    (debtor-outstanding-obligations (default-to u0 (map-get? registered-debtor-obligations tx-sender)))
    (settlement-consent-granted (default-to false 
                                (map-get? settlement-consent-matrix 
                                {debtor-address: tx-sender, creditor-address: target-creditor-address})))
  )
    (begin
      ;; Input validation
      (asserts! (is-valid-principal target-creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-uint settlement-amount) ERR-INVALID-AMOUNT)
      ;; Comprehensive pre-settlement validation and authorization checks
      (asserts! (is-some (map-get? registered-creditor-claims target-creditor-address)) ERR-CREDITOR-NOT-REGISTERED)
      (asserts! (>= debtor-outstanding-obligations settlement-amount) ERR-INSUFFICIENT-BALANCE)
      (asserts! settlement-consent-granted ERR-APPROVAL-REQUIRED)
      (asserts! (<= settlement-amount creditor-outstanding-claims) ERR-INVALID-AMOUNT)
      
      ;; Execute secure STX transfer from debtor to creditor
      (try! (stx-transfer? settlement-amount tx-sender target-creditor-address))
      
      ;; Update post-settlement financial records
      (map-set registered-creditor-claims target-creditor-address (- creditor-outstanding-claims settlement-amount))
      (map-set registered-debtor-obligations tx-sender (- debtor-outstanding-obligations settlement-amount))
      
      ;; Track protocol-wide settlement volume metrics
      (var-set total-settlement-volume (+ (var-get total-settlement-volume) settlement-amount))
      
      (ok true))))

;; BATCH SETTLEMENT ORCHESTRATION SYSTEM

;; Execute batch settlement for exactly five creditors in a single transaction
(define-public (execute-five-party-batch-settlement 
                (first-creditor-address principal) (first-settlement-amount uint)
                (second-creditor-address principal) (second-settlement-amount uint)
                (third-creditor-address principal) (third-settlement-amount uint)
                (fourth-creditor-address principal) (fourth-settlement-amount uint)
                (fifth-creditor-address principal) (fifth-settlement-amount uint))
  (let (
    (debtor-initiating-settlement tx-sender)
    (total-batch-settlement-amount (+ (+ (+ (+ first-settlement-amount second-settlement-amount) third-settlement-amount) fourth-settlement-amount) fifth-settlement-amount))
    (available-debtor-balance (default-to u0 (map-get? registered-debtor-obligations debtor-initiating-settlement)))
  )
    (begin
      ;; Input validation for all creditor addresses
      (asserts! (is-valid-principal first-creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-principal second-creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-principal third-creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-principal fourth-creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-principal fifth-creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      ;; Validate all settlement amounts and debtor financial capacity
      (asserts! (is-valid-uint first-settlement-amount) ERR-INVALID-AMOUNT)
      (asserts! (is-valid-uint second-settlement-amount) ERR-INVALID-AMOUNT)
      (asserts! (is-valid-uint third-settlement-amount) ERR-INVALID-AMOUNT)
      (asserts! (is-valid-uint fourth-settlement-amount) ERR-INVALID-AMOUNT)
      (asserts! (is-valid-uint fifth-settlement-amount) ERR-INVALID-AMOUNT)
      (asserts! (>= available-debtor-balance total-batch-settlement-amount) ERR-INSUFFICIENT-BALANCE)
      
      ;; Execute sequential individual settlements within batch transaction
      (try! (execute-individual-settlement first-creditor-address first-settlement-amount))
      (try! (execute-individual-settlement second-creditor-address second-settlement-amount))
      (try! (execute-individual-settlement third-creditor-address third-settlement-amount))
      (try! (execute-individual-settlement fourth-creditor-address fourth-settlement-amount))
      (try! (execute-individual-settlement fifth-creditor-address fifth-settlement-amount))
      
      (ok true))))

;; Execute batch settlement for exactly three creditors in a single transaction
(define-public (execute-three-party-batch-settlement
                (first-creditor-address principal) (first-settlement-amount uint)
                (second-creditor-address principal) (second-settlement-amount uint)
                (third-creditor-address principal) (third-settlement-amount uint))
  (let (
    (debtor-initiating-settlement tx-sender)
    (total-batch-settlement-amount (+ (+ first-settlement-amount second-settlement-amount) third-settlement-amount))
    (available-debtor-balance (default-to u0 (map-get? registered-debtor-obligations debtor-initiating-settlement)))
  )
    (begin
      ;; Input validation for all creditor addresses
      (asserts! (is-valid-principal first-creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-principal second-creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-principal third-creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      ;; Validate all settlement amounts and debtor financial capacity
      (asserts! (is-valid-uint first-settlement-amount) ERR-INVALID-AMOUNT)
      (asserts! (is-valid-uint second-settlement-amount) ERR-INVALID-AMOUNT)
      (asserts! (is-valid-uint third-settlement-amount) ERR-INVALID-AMOUNT)
      (asserts! (>= available-debtor-balance total-batch-settlement-amount) ERR-INSUFFICIENT-BALANCE)
      
      ;; Execute sequential individual settlements within batch transaction
      (try! (execute-individual-settlement first-creditor-address first-settlement-amount))
      (try! (execute-individual-settlement second-creditor-address second-settlement-amount))
      (try! (execute-individual-settlement third-creditor-address third-settlement-amount))
      
      (ok true))))

;; Execute batch settlement for exactly two creditors in a single transaction
(define-public (execute-two-party-batch-settlement
                (first-creditor-address principal) (first-settlement-amount uint)
                (second-creditor-address principal) (second-settlement-amount uint))
  (let (
    (debtor-initiating-settlement tx-sender)
    (total-batch-settlement-amount (+ first-settlement-amount second-settlement-amount))
    (available-debtor-balance (default-to u0 (map-get? registered-debtor-obligations debtor-initiating-settlement)))
  )
    (begin
      ;; Input validation for all creditor addresses
      (asserts! (is-valid-principal first-creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-principal second-creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      ;; Validate all settlement amounts and debtor financial capacity
      (asserts! (is-valid-uint first-settlement-amount) ERR-INVALID-AMOUNT)
      (asserts! (is-valid-uint second-settlement-amount) ERR-INVALID-AMOUNT)
      (asserts! (>= available-debtor-balance total-batch-settlement-amount) ERR-INSUFFICIENT-BALANCE)
      
      ;; Execute sequential individual settlements within batch transaction
      (try! (execute-individual-settlement first-creditor-address first-settlement-amount))
      (try! (execute-individual-settlement second-creditor-address second-settlement-amount))
      
      (ok true))))

;; ENHANCED PROTOCOL ANALYTICS AND QUERY INTERFACE

;; Retrieve total settlement volume processed through the protocol
(define-read-only (get-total-protocol-settlement-volume)
  (ok (var-get total-settlement-volume)))

;; Query outstanding claims for a specific creditor entity
(define-read-only (get-creditor-outstanding-claims (creditor-address principal))
  (begin
    (asserts! (is-valid-principal creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
    (ok (default-to u0 (map-get? registered-creditor-claims creditor-address)))))

;; Query total financial obligations for a specific debtor entity
(define-read-only (get-debtor-total-obligations (debtor-address principal))
  (begin
    (asserts! (is-valid-principal debtor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
    (ok (default-to u0 (map-get? registered-debtor-obligations debtor-address)))))

;; Check settlement consent status between debtor and creditor entities
(define-read-only (check-settlement-consent-status (debtor-address principal) (creditor-address principal))
  (begin
    (asserts! (is-valid-principal debtor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
    (asserts! (is-valid-principal creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
    (ok (default-to false (map-get? settlement-consent-matrix {debtor-address: debtor-address, creditor-address: creditor-address})))))

;; Get current protocol administrator
(define-read-only (get-protocol-administrator)
  (ok (var-get protocol-admin)))

;; Get detailed debt claim information including interest
(define-read-only (get-debt-claim-details 
                  (debtor-address principal) 
                  (creditor-address principal) 
                  (claim-id uint))
  (begin
    (asserts! (is-valid-principal debtor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
    (asserts! (is-valid-principal creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
    (asserts! (is-valid-claim-id claim-id) ERR-INVALID-INPUT)
    (ok (map-get? debt-claims {debtor: debtor-address, creditor: creditor-address, claim-id: claim-id}))))

;; Get dispute information by ID
(define-read-only (get-dispute-details (dispute-id uint))
  (begin
    (asserts! (is-valid-uint dispute-id) ERR-INVALID-INPUT)
    (ok (map-get? dispute-records dispute-id))))

;; Get arbitrator information and performance metrics
(define-read-only (get-arbitrator-info (arbitrator-address principal))
  (begin
    (asserts! (is-valid-principal arbitrator-address) ERR-INVALID-PRINCIPAL-ADDRESS)
    (ok (map-get? authorized-arbitrators arbitrator-address))))

;; Calculate current total debt amount including accrued interest
(define-read-only (calculate-total-debt-with-interest 
                  (debtor-address principal) 
                  (creditor-address principal) 
                  (claim-id uint))
  (let (
    (claim-data (unwrap! (map-get? debt-claims {debtor: debtor-address, creditor: creditor-address, claim-id: claim-id}) 
                         ERR-DEBT-CLAIM-NOT-FOUND))
    (blocks-elapsed (- block-height (get last-interest-update claim-data)))
    (annual-blocks u52560)
    (additional-interest (/ (* (* (get principal-amount claim-data) (get interest-rate claim-data)) blocks-elapsed) 
                          (* annual-blocks u10000)))
    (total-amount (+ (get principal-amount claim-data) (get total-accrued-interest claim-data) additional-interest))
  )
    (begin
      (asserts! (is-valid-principal debtor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-principal creditor-address) ERR-INVALID-PRINCIPAL-ADDRESS)
      (asserts! (is-valid-claim-id claim-id) ERR-INVALID-INPUT)
      (ok total-amount))))

;; Get total number of active disputes
(define-read-only (get-active-disputes-count)
  (ok (var-get dispute-counter)))

;; Get list of authorized arbitrators
(define-read-only (get-arbitrator-pool)
  (ok (var-get arbitrator-pool)))