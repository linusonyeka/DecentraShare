;; DecentraShare - Decentralized Social Media Platform
;; A smart contract for managing social media interactions on Stacks blockchain

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-POST-NOT-FOUND (err u2))
(define-constant ERR-INVALID-CONTENT (err u3))

;; Data Variables
(define-map posts 
    { post-id: uint }
    {
        author: principal,
        content: (string-utf8 500),
        timestamp: uint,
        likes: uint,
        tips: uint
    }
)

(define-map user-profiles
    { user: principal }
    {
        username: (string-utf8 50),
        bio: (string-utf8 200),
        followers: uint,
        following: uint
    }
)

(define-map follows
    { follower: principal, following: principal }
    { active: bool }
)

;; Post counter
(define-data-var post-counter uint u0)

;; Public functions

;; Create a new post
(define-public (create-post (content (string-utf8 500)))
    (let 
        (
            (post-id (+ (var-get post-counter) u1))
        )
        (try! (validate-content content))
        (map-set posts
            { post-id: post-id }
            {
                author: tx-sender,
                content: content,
                timestamp: block-height,
                likes: u0,
                tips: u0
            }
        )
        (var-set post-counter post-id)
        (ok post-id)
    )
)

;; Like a post
(define-public (like-post (post-id uint))
    (match (map-get? posts { post-id: post-id })
        post-data (begin
            (map-set posts
                { post-id: post-id }
                (merge post-data { likes: (+ (get likes post-data) u1) })
            )
            (ok true)
        )
        (err ERR-POST-NOT-FOUND)
    )
)

;; Tip a post with STX
(define-public (tip-post (post-id uint) (amount uint))
    (match (map-get? posts { post-id: post-id })
        post-data (begin
            (try! (stx-transfer? amount tx-sender (get author post-data)))
            (map-set posts
                { post-id: post-id }
                (merge post-data { tips: (+ (get tips post-data) amount) })
            )
            (ok true)
        )
        (err ERR-POST-NOT-FOUND)
    )
)

;; Create or update profile
(define-public (set-profile (username (string-utf8 50)) (bio (string-utf8 200)))
    (map-set user-profiles
        { user: tx-sender }
        {
            username: username,
            bio: bio,
            followers: u0,
            following: u0
        }
    )
    (ok true)
)

;; Follow a user
(define-public (follow-user (user principal))
    (begin
        (map-set follows
            { follower: tx-sender, following: user }
            { active: true }
        )
        (ok true)
    )
)

;; Private functions

;; Validate content
(define-private (validate-content (content (string-utf8 500)))
    (if (> (len content) u0)
        (ok true)
        (err ERR-INVALID-CONTENT)
    )
)

;; Read-only functions

;; Get post details
(define-read-only (get-post (post-id uint))
    (map-get? posts { post-id: post-id })
)

;; Get user profile
(define-read-only (get-profile (user principal))
    (map-get? user-profiles { user: user })
)

;; Check if user follows another user
(define-read-only (is-following (follower principal) (following principal))
    (default-to
        false
        (get active (map-get? follows { follower: follower, following: following }))
    )
)