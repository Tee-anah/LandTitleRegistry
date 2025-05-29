;; LandTitleRegistry: Property Ownership and Transfer System
;; Version: 1.0.0
(define-constant ERR-NOT-OWNER (err u1))
(define-constant ERR-PROPERTY-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-REGISTERED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-SIZE (err u5))
(define-constant ERR-INVALID-ZONE (err u6))
(define-constant ERR-INVALID-TYPE (err u7))
(define-constant ERR-INVALID-ADDRESS (err u8))
(define-constant ERR-INVALID-DESCRIPTION (err u9))
(define-constant MIN-SIZE u1)
(define-data-var next-property-id uint u1)
(define-map properties
    uint
    {
        owner: principal,
        property-address: (string-utf8 50),
        property-description: (string-utf8 200),
        zoning-type: (string-utf8 10),
        property-type: (string-utf8 20),
        status: (string-utf8 15),
        land-size: uint
    }
)
(define-private (validate-zone (zone (string-utf8 10)))
    (or 
        (is-eq zone u"Residential")
        (is-eq zone u"Commercial")
        (is-eq zone u"Industrial")
        (is-eq zone u"Agricultural")
        (is-eq zone u"Mixed-Use")
        (is-eq zone u"Special")
    )
)
(define-private (validate-type (type (string-utf8 20)))
    (or 
        (is-eq type u"Single-Family")
        (is-eq type u"Multi-Family")
        (is-eq type u"Vacant-Land")
        (is-eq type u"Commercial")
        (is-eq type u"Development")
    )
)
(define-private (validate-text-length (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)
(define-public (register-property 
    (property-address (string-utf8 50))
    (property-description (string-utf8 200))
    (zoning-type (string-utf8 10))
    (property-type (string-utf8 20))
    (land-size uint)
)
    (let
        (
            (property-id (var-get next-property-id))
        )
        (asserts! (validate-text-length property-address u3 u50) ERR-INVALID-ADDRESS)
        (asserts! (validate-text-length property-description u10 u200) ERR-INVALID-DESCRIPTION)
        (asserts! (>= land-size MIN-SIZE) ERR-INVALID-SIZE)
        (asserts! (validate-zone zoning-type) ERR-INVALID-ZONE)
        (asserts! (validate-type property-type) ERR-INVALID-TYPE)
        
        (map-set properties property-id {
            owner: tx-sender,
            property-address: property-address,
            property-description: property-description,
            zoning-type: zoning-type,
            property-type: property-type,
            status: u"registered",
            land-size: land-size
        })
        (var-set next-property-id (+ property-id u1))
        (ok property-id)
    )
)
(define-public (transfer-property (property-id uint) (new-owner principal))
    (let
        (
            (property (unwrap! (map-get? properties property-id) ERR-PROPERTY-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get owner property)) ERR-NOT-OWNER)
        (asserts! (is-eq (get status property) u"registered") ERR-INVALID-STATUS)
        (ok (map-set properties property-id (merge property { owner: new-owner, status: u"transferred" })))
    )
)
(define-read-only (get-property (property-id uint))
    (ok (map-get? properties property-id))
)
(define-read-only (get-owner (property-id uint))
    (ok (get owner (unwrap! (map-get? properties property-id) ERR-PROPERTY-NOT-FOUND)))
)
