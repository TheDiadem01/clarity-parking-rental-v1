;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-not-available (err u103))
(define-constant err-not-authorized (err u104))

;; Define data variables
(define-data-var rental-fee uint u100)

;; Define data maps
(define-map parking-spaces
    principal
    {
        location: (string-ascii 50),
        price-per-hour: uint,
        available: bool,
        current-renter: (optional principal)
    }
)

(define-map rentals
    uint
    {
        space-owner: principal,
        renter: principal,
        start-time: uint,
        duration: uint,
        total-cost: uint
    }
)

(define-data-var rental-nonce uint u0)

;; Register a new parking space
(define-public (register-parking-space (location (string-ascii 50)) (price-per-hour uint))
    (let ((space (map-get? parking-spaces tx-sender)))
        (if (is-some space)
            err-already-registered
            (ok (map-set parking-spaces tx-sender {
                location: location,
                price-per-hour: price-per-hour,
                available: true,
                current-renter: none
            }))
        )
    )
)

;; Update parking space availability
(define-public (update-availability (available bool))
    (let ((space (map-get? parking-spaces tx-sender)))
        (match space
            space-data (ok (map-set parking-spaces tx-sender (merge space-data { available: available })))
            err-not-found
        )
    )
)

;; Rent a parking space
(define-public (rent-space (owner principal) (duration uint))
    (let (
        (space (map-get? parking-spaces owner))
        (rental-id (var-get rental-nonce))
    )
        (match space
            space-data
            (if (not (get available space-data))
                err-not-available
                (begin
                    (map-set parking-spaces owner 
                        (merge space-data { 
                            available: false,
                            current-renter: (some tx-sender)
                        })
                    )
                    (map-set rentals rental-id {
                        space-owner: owner,
                        renter: tx-sender,
                        start-time: block-height,
                        duration: duration,
                        total-cost: (* duration (get price-per-hour space-data))
                    })
                    (var-set rental-nonce (+ rental-id u1))
                    (ok rental-id)
                )
            )
            err-not-found
        )
    )
)

;; End rental
(define-public (end-rental (rental-id uint))
    (let ((rental (map-get? rentals rental-id)))
        (match rental
            rental-data
            (if (and
                (is-eq (get space-owner rental-data) tx-sender)
                (>= block-height (+ (get start-time rental-data) (get duration rental-data)))
            )
                (begin
                    (map-set parking-spaces (get space-owner rental-data)
                        (merge (unwrap-panic (map-get? parking-spaces (get space-owner rental-data)))
                            {
                                available: true,
                                current-renter: none
                            }
                        )
                    )
                    (ok true)
                )
                err-not-authorized
            )
            err-not-found
        )
    )
)

;; Read only functions
(define-read-only (get-parking-space (owner principal))
    (ok (map-get? parking-spaces owner))
)

(define-read-only (get-rental (rental-id uint))
    (ok (map-get? rentals rental-id))
)
