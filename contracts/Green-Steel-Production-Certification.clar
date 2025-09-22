(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1001))
(define-constant ERR_NOT_FOUND (err u1002))
(define-constant ERR_ALREADY_EXISTS (err u1003))
(define-constant ERR_INVALID_CERTIFICATE (err u1004))
(define-constant ERR_INSUFFICIENT_BALANCE (err u1005))
(define-constant ERR_INVALID_ENERGY_SOURCE (err u1006))
(define-constant ERR_PRODUCTION_NOT_VERIFIED (err u1007))

(define-data-var next-certificate-id uint u1)
(define-data-var next-producer-id uint u1)
(define-data-var certification-fee uint u1000000)

(define-map producers
  { producer-id: uint }
  {
    name: (string-ascii 100),
    wallet: principal,
    location: (string-ascii 100),
    verified: bool,
    certification-count: uint,
    reputation-score: uint
  }
)

(define-map certificates
  { certificate-id: uint }
  {
    producer-id: uint,
    steel-batch-id: (string-ascii 50),
    production-date: uint,
    quantity: uint,
    energy-source: (string-ascii 50),
    carbon-footprint: uint,
    verified: bool,
    revoked: bool,
    premium-rate: uint,
    owner: principal
  }
)

(define-map energy-sources
  { source-id: (string-ascii 50) }
  {
    source-type: (string-ascii 50),
    carbon-intensity: uint,
    verified: bool,
    verifier: principal
  }
)

(define-map supply-chain
  { certificate-id: uint, step: uint }
  {
    entity: principal,
    location: (string-ascii 100),
    timestamp: uint,
    verified: bool
  }
)

(define-map premium-balances
  { owner: principal }
  { balance: uint }
)

(define-map iot-sensors
  { sensor-id: (string-ascii 50) }
  {
    producer-id: uint,
    sensor-type: (string-ascii 50),
    location: (string-ascii 100),
    last-reading: uint,
    verified: bool
  }
)

(define-public (register-producer (name (string-ascii 100)) (location (string-ascii 100)))
  (let ((producer-id (var-get next-producer-id)))
    (asserts! (is-none (map-get? producers { producer-id: producer-id })) ERR_ALREADY_EXISTS)
    (map-set producers
      { producer-id: producer-id }
      {
        name: name,
        wallet: tx-sender,
        location: location,
        verified: false,
        certification-count: u0,
        reputation-score: u100
      }
    )
    (var-set next-producer-id (+ producer-id u1))
    (ok producer-id)
  )
)

(define-public (verify-producer (producer-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? producers { producer-id: producer-id })
      producer-data
      (begin
        (map-set producers
          { producer-id: producer-id }
          (merge producer-data { verified: true })
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

(define-public (register-energy-source (source-id (string-ascii 50)) (source-type (string-ascii 50)) (carbon-intensity uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? energy-sources { source-id: source-id })) ERR_ALREADY_EXISTS)
    (map-set energy-sources
      { source-id: source-id }
      {
        source-type: source-type,
        carbon-intensity: carbon-intensity,
        verified: true,
        verifier: tx-sender
      }
    )
    (ok true)
  )
)

(define-public (register-iot-sensor (sensor-id (string-ascii 50)) (producer-id uint) (sensor-type (string-ascii 50)) (location (string-ascii 100)))
  (begin
    (match (map-get? producers { producer-id: producer-id })
      producer-data
      (begin
        (asserts! (is-eq (get wallet producer-data) tx-sender) ERR_UNAUTHORIZED)
        (map-set iot-sensors
          { sensor-id: sensor-id }
          {
            producer-id: producer-id,
            sensor-type: sensor-type,
            location: location,
            last-reading: burn-block-height,
            verified: false
          }
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

(define-public (update-iot-reading (sensor-id (string-ascii 50)) (reading uint))
  (match (map-get? iot-sensors { sensor-id: sensor-id })
    sensor-data
    (begin
      (match (map-get? producers { producer-id: (get producer-id sensor-data) })
        producer-data
        (begin
          (asserts! (is-eq (get wallet producer-data) tx-sender) ERR_UNAUTHORIZED)
          (map-set iot-sensors
            { sensor-id: sensor-id }
            (merge sensor-data { last-reading: reading })
          )
          (ok true)
        )
        ERR_NOT_FOUND
      )
    )
    ERR_NOT_FOUND
  )
)

(define-public (issue-certificate (producer-id uint) (steel-batch-id (string-ascii 50)) (quantity uint) (energy-source (string-ascii 50)) (carbon-footprint uint))
  (let ((certificate-id (var-get next-certificate-id)))
    (match (map-get? producers { producer-id: producer-id })
      producer-data
      (begin
        (asserts! (is-eq (get wallet producer-data) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get verified producer-data) ERR_UNAUTHORIZED)
        (match (map-get? energy-sources { source-id: energy-source })
          energy-data
          (begin
            (asserts! (get verified energy-data) ERR_INVALID_ENERGY_SOURCE)
            (let ((premium-rate (calculate-premium carbon-footprint (get carbon-intensity energy-data))))
              (map-set certificates
                { certificate-id: certificate-id }
                {
                  producer-id: producer-id,
                  steel-batch-id: steel-batch-id,
                  production-date: burn-block-height,
                  quantity: quantity,
                  energy-source: energy-source,
                  carbon-footprint: carbon-footprint,
                  verified: false,
                  revoked: false,
                  premium-rate: premium-rate,
                  owner: tx-sender
                }
              )
              (map-set producers
                { producer-id: producer-id }
                (merge producer-data { certification-count: (+ (get certification-count producer-data) u1) })
              )
              (var-set next-certificate-id (+ certificate-id u1))
              (ok certificate-id)
            )
          )
          ERR_INVALID_ENERGY_SOURCE
        )
      )
      ERR_NOT_FOUND
    )
  )
)

(define-public (verify-certificate (certificate-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? certificates { certificate-id: certificate-id })
      cert-data
      (begin
        (map-set certificates
          { certificate-id: certificate-id }
          (merge cert-data { verified: true })
        )
        (match (map-get? producers { producer-id: (get producer-id cert-data) })
          producer-data
          (begin
            (map-set producers
              { producer-id: (get producer-id cert-data) }
              (merge producer-data { reputation-score: (+ (get reputation-score producer-data) u10) })
            )
            (ok true)
          )
          ERR_NOT_FOUND
        )
      )
      ERR_NOT_FOUND
    )
  )
)

(define-public (revoke-certificate (certificate-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? certificates { certificate-id: certificate-id })
      cert-data
      (begin
        (map-set certificates
          { certificate-id: certificate-id }
          (merge cert-data { revoked: true })
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

(define-public (transfer-certificate (certificate-id uint) (new-owner principal))
  (match (map-get? certificates { certificate-id: certificate-id })
    cert-data
    (begin
      (asserts! (is-eq (get owner cert-data) tx-sender) ERR_UNAUTHORIZED)
      (asserts! (get verified cert-data) ERR_INVALID_CERTIFICATE)
      (map-set certificates
        { certificate-id: certificate-id }
        (merge cert-data { owner: new-owner })
      )
      (ok true)
    )
    ERR_NOT_FOUND
  )
)

(define-public (add-supply-chain-step (certificate-id uint) (step uint) (entity principal) (location (string-ascii 100)))
  (match (map-get? certificates { certificate-id: certificate-id })
    cert-data
    (begin
      (asserts! (is-eq (get owner cert-data) tx-sender) ERR_UNAUTHORIZED)
      (map-set supply-chain
        { certificate-id: certificate-id, step: step }
        {
          entity: entity,
          location: location,
          timestamp: burn-block-height,
          verified: false
        }
      )
      (ok true)
    )
    ERR_NOT_FOUND
  )
)

(define-public (verify-supply-chain-step (certificate-id uint) (step uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? supply-chain { certificate-id: certificate-id, step: step })
      step-data
      (begin
        (map-set supply-chain
          { certificate-id: certificate-id, step: step }
          (merge step-data { verified: true })
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

(define-public (claim-premium (certificate-id uint))
  (match (map-get? certificates { certificate-id: certificate-id })
    cert-data
    (begin
      (asserts! (is-eq (get owner cert-data) tx-sender) ERR_UNAUTHORIZED)
      (asserts! (get verified cert-data) ERR_INVALID_CERTIFICATE)
      (let ((premium-amount (* (get quantity cert-data) (get premium-rate cert-data))))
        (match (map-get? premium-balances { owner: tx-sender })
          current-balance
          (map-set premium-balances
            { owner: tx-sender }
            { balance: (+ (get balance current-balance) premium-amount) }
          )
          (map-set premium-balances
            { owner: tx-sender }
            { balance: premium-amount }
          )
        )
        (ok premium-amount)
      )
    )
    ERR_NOT_FOUND
  )
)

(define-public (withdraw-premium (amount uint))
  (match (map-get? premium-balances { owner: tx-sender })
    balance-data
    (begin
      (asserts! (>= (get balance balance-data) amount) ERR_INSUFFICIENT_BALANCE)
      (map-set premium-balances
        { owner: tx-sender }
        { balance: (- (get balance balance-data) amount) }
      )
      (ok amount)
    )
    ERR_INSUFFICIENT_BALANCE
  )
)

(define-public (set-certification-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set certification-fee new-fee)
    (ok true)
  )
)

(define-read-only (get-certificate (certificate-id uint))
  (map-get? certificates { certificate-id: certificate-id })
)

(define-read-only (get-producer (producer-id uint))
  (map-get? producers { producer-id: producer-id })
)

(define-read-only (get-energy-source (source-id (string-ascii 50)))
  (map-get? energy-sources { source-id: source-id })
)

(define-read-only (get-supply-chain-step (certificate-id uint) (step uint))
  (map-get? supply-chain { certificate-id: certificate-id, step: step })
)

(define-read-only (get-premium-balance (owner principal))
  (default-to { balance: u0 } (map-get? premium-balances { owner: owner }))
)

(define-read-only (get-iot-sensor (sensor-id (string-ascii 50)))
  (map-get? iot-sensors { sensor-id: sensor-id })
)

(define-read-only (get-certification-fee)
  (var-get certification-fee)
)

(define-read-only (calculate-premium (carbon-footprint uint) (energy-carbon-intensity uint))
  (if (<= carbon-footprint u100)
    (if (<= energy-carbon-intensity u50)
      u200
      u150
    )
    (if (<= carbon-footprint u200)
      (if (<= energy-carbon-intensity u50)
        u100
        u75
      )
      u25
    )
  )
)

(define-read-only (is-green-certified (certificate-id uint))
  (match (map-get? certificates { certificate-id: certificate-id })
    cert-data
    (and
      (get verified cert-data)
      (not (get revoked cert-data))
      (<= (get carbon-footprint cert-data) u150)
      (match (map-get? energy-sources { source-id: (get energy-source cert-data) })
        energy-data
        (<= (get carbon-intensity energy-data) u100)
        false
      )
    )
    false
  )
)

(define-read-only (get-certificate-chain (certificate-id uint))
  (let ((step1 (map-get? supply-chain { certificate-id: certificate-id, step: u1 }))
        (step2 (map-get? supply-chain { certificate-id: certificate-id, step: u2 }))
        (step3 (map-get? supply-chain { certificate-id: certificate-id, step: u3 })))
    {
      step1: step1,
      step2: step2,
      step3: step3
    }
  )
)

(define-public (validate-production (certificate-id uint) (iot-readings (list 10 uint)))
  (match (map-get? certificates { certificate-id: certificate-id })
    cert-data
    (begin
      (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
      (let ((avg-reading (/ (fold + iot-readings u0) (len iot-readings))))
        (if (and (<= avg-reading u100) (>= avg-reading u50))
          (begin
            (map-set certificates
              { certificate-id: certificate-id }
              (merge cert-data { verified: true })
            )
            (ok true)
          )
          ERR_PRODUCTION_NOT_VERIFIED
        )
      )
    )
    ERR_NOT_FOUND
  )
)
