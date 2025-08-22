;; ArtChain: Decentralized Digital Art Marketplace Platform
;; Version: 1.0.0

(define-data-var gallery-curator principal tx-sender)
(define-data-var artwork-collection uint u0)
(define-data-var creativity-token-rate uint u90) ;; creativity tokens per artistic cycle
(define-data-var last-token-mint uint u0) ;; last block when tokens were minted

(define-map artist-portfolios principal uint)

;; Helper function to ensure only the gallery curator can perform certain actions
(define-private (is-curator (caller principal))
  (begin
    (asserts! (is-eq caller (var-get gallery-curator)) (err u300))
    (ok true)))

;; Initialize the digital art marketplace
(define-public (open-gallery (curator principal))
  (begin
    (asserts! (is-none (map-get? artist-portfolios curator)) (err u301))
    (var-set gallery-curator curator)
    (ok "ArtChain gallery opened")))

;; Submit digital artwork
(define-public (submit-artwork (pieces uint))
  (begin
    (asserts! (> pieces u0) (err u302))
    (let ((current-portfolio (default-to u0 (map-get? artist-portfolios tx-sender))))
      (map-set artist-portfolios tx-sender (+ current-portfolio pieces))
      (var-set artwork-collection (+ (var-get artwork-collection) pieces))
      (ok (+ current-portfolio pieces)))))

;; Mint creativity tokens for all artists
(define-public (mint-creativity-tokens)
  (begin
    (try! (is-curator tx-sender))
    (let ((current-block stacks-block-height)
          (previous-mint (var-get last-token-mint)))
      (asserts! (> current-block previous-mint) (err u303))
      ;; Calculate tokens based on blocks elapsed
      (let ((elapsed (- current-block previous-mint))
            (total-tokens (* elapsed (var-get creativity-token-rate))))
        (var-set last-token-mint current-block)
        (var-set artwork-collection (+ (var-get artwork-collection) total-tokens))
        (ok total-tokens)))))

;; Sell artwork and claim creativity rewards
(define-public (monetize-art-collection)
  (begin
    (let ((artist-works (default-to u0 (map-get? artist-portfolios tx-sender))))
      (asserts! (> artist-works u0) (err u304))
      (let ((total-collection (var-get artwork-collection))
            (new-tokens (* (var-get creativity-token-rate) (- stacks-block-height (var-get last-token-mint))))
            (portfolio-ratio (/ (* artist-works u100000) total-collection)))
        ;; Calculate rewards based on portfolio ratio
        (let ((reward-amount (/ (* portfolio-ratio new-tokens) u100000)))
          (map-delete artist-portfolios tx-sender)
          (var-set artwork-collection (- (var-get artwork-collection) artist-works))
          (ok (+ artist-works reward-amount)))))))

;; Read-only functions
(define-read-only (get-artist-portfolio (artist principal))
  (default-to u0 (map-get? artist-portfolios artist)))

(define-read-only (get-gallery-stats)
  {
    curator: (var-get gallery-curator),
    total-collection: (var-get artwork-collection),
    token-rate: (var-get creativity-token-rate),
    last-mint: (var-get last-token-mint)
  })

(define-read-only (get-artwork-collection)
  (var-get artwork-collection))