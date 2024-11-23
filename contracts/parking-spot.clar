;; Parking Spot Rental System Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-spot-occupied (err u103))
(define-constant err-not-renter (err u104))
(define-constant err-insufficient-funds (err u105))

;; Data Variables
(define-map parking-spots
    { spot-id: uint }
    {
        owner: principal,
        hourly-rate: uint,
        is-available: bool,
        current-renter: (optional principal),
        rental-start: (optional uint)
    }
)

;; Public Functions
(define-public (register-parking-spot (spot-id uint) (hourly-rate uint))
    (let (
        (spot-exists (get-parking-spot spot-id))
    )
    (if (is-some spot-exists)
        err-already-registered
        (begin
            (map-set parking-spots
                { spot-id: spot-id }
                {
                    owner: tx-sender,
                    hourly-rate: hourly-rate,
                    is-available: true,
                    current-renter: none,
                    rental-start: none
                }
            )
            (ok true)
        )
    ))
)

(define-public (rent-spot (spot-id uint))
    (let (
        (spot (unwrap! (get-parking-spot spot-id) err-not-found))
        (rate (get hourly-rate spot))
    )
    (if (get is-available spot)
        (begin
            (map-set parking-spots
                { spot-id: spot-id }
                {
                    owner: (get owner spot),
                    hourly-rate: rate,
                    is-available: false,
                    current-renter: (some tx-sender),
                    rental-start: (some block-height)
                }
            )
            (ok true)
        )
        err-spot-occupied
    ))
)

(define-public (end-rental (spot-id uint))
    (let (
        (spot (unwrap! (get-parking-spot spot-id) err-not-found))
        (renter (unwrap! (get current-renter spot) err-not-found))
        (start-time (unwrap! (get rental-start spot) err-not-found))
    )
    (if (is-eq tx-sender renter)
        (begin
            (map-set parking-spots
                { spot-id: spot-id }
                {
                    owner: (get owner spot),
                    hourly-rate: (get hourly-rate spot),
                    is-available: true,
                    current-renter: none,
                    rental-start: none
                }
            )
            (ok true)
        )
        err-not-renter
    ))
)

;; Read Only Functions
(define-read-only (get-parking-spot (spot-id uint))
    (map-get? parking-spots { spot-id: spot-id })
)

(define-read-only (get-rental-duration (spot-id uint))
    (let (
        (spot (unwrap! (get-parking-spot spot-id) err-not-found))
        (start-time (unwrap! (get rental-start spot) err-not-found))
    )
    (ok (- block-height start-time)))
)

(define-read-only (calculate-rental-fee (spot-id uint))
    (let (
        (spot (unwrap! (get-parking-spot spot-id) err-not-found))
        (duration (unwrap! (get-rental-duration spot-id) err-not-found))
        (rate (get hourly-rate spot))
    )
    (ok (* rate duration)))
)
