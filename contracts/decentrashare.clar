;; Define constants for error handling
(define-constant ERR_USER_NOT_REGISTERED (err u100))
(define-constant ERR_USER_ALREADY_REGISTERED (err u101))
(define-constant ERR_POST_NOT_FOUND (err u102))
(define-constant ERR_UNAUTHORIZED (err u103))
(define-constant ERR_LIST_FULL (err u104))

;; Define data structures for profiles, posts, and followers
(define-map profiles
  principal
  {
    username: (string-utf8 30),
    bio: (string-utf8 150),
    follower-count: uint,
    post-count: uint
  }
)

(define-map posts
  uint
  {
    author: principal,
    content: (string-utf8 280),
    timestamp: uint,
    like-count: uint
  }
)

(define-map followers
  { follower: principal, followed: principal }
  bool
)

(define-map user-posts
  principal
  (list 50 uint)  ;; Stores post IDs for each user
)

;; Global variable for post IDs
(define-data-var next-post-id uint u0)

;; Helper Functions

;; Check if user is registered
(define-private (is-registered (user principal))
  (is-some (map-get? profiles user))
)

;; Helper function to filter list items after first
(define-private (not-first-item (index uint))
  (> index u0)
)

;; Helper function to truncate list if at max length
(define-private (truncate-list (lst (list 50 uint)))
  (if (< (len lst) u50)
      (ok lst)
      ;; Create new list without first element using filter
      (ok (unwrap! (as-max-len? 
              (filter not-first-item lst)
              u50)
          ERR_LIST_FULL))
  )
)

;; Append to user's posts list safely, maintaining max length
(define-private (safe-append-post (user principal) (post-id uint))
  (let ((current-posts (default-to (list) (map-get? user-posts user))))
    (if (< (len current-posts) u50)
        ;; If list isn't full, just append
        (ok (append current-posts post-id))
        ;; If list is full, create new list with first element dropped
        (ok (unwrap! (as-max-len? 
                (concat (list post-id) 
                       (filter not-first-item current-posts))
                u50)
            ERR_LIST_FULL))
    )
  )
)

;; Public Functions

;; Register a profile
(define-public (register-user (username (string-utf8 30)) (bio (string-utf8 150)))
  (let ((user tx-sender))
    (if (is-registered user)
        ERR_USER_ALREADY_REGISTERED
        (begin
          (map-set profiles user { username: username, bio: bio, follower-count: u0, post-count: u0 })
          (ok true)
        )
    )
  )
)

;; Create a post
(define-public (create-post (content (string-utf8 280)))
  (let ((user tx-sender))
    (if (is-registered user)
        (let ((post-id (var-get next-post-id)))
          (map-set posts post-id { author: user, content: content, timestamp: block-height, like-count: u0 })
          (var-set next-post-id (+ post-id u1))
          ;; Update user's post list
          (map-set user-posts user (unwrap! (safe-append-post user post-id) ERR_LIST_FULL))
          ;; Update post count in profile
          (map-set profiles user (merge (unwrap! (map-get? profiles user) ERR_USER_NOT_REGISTERED) 
                                      { post-count: (+ (get post-count (unwrap! (map-get? profiles user) ERR_USER_NOT_REGISTERED)) u1) }))
          (ok post-id)
        )
        ERR_USER_NOT_REGISTERED
    )
  )
)

;; Like a post
(define-public (like-post (post-id uint))
  (let ((user tx-sender))
    (if (is-registered user)
        (let ((post (unwrap! (map-get? posts post-id) ERR_POST_NOT_FOUND)))
          (map-set posts post-id (merge post { like-count: (+ (get like-count post) u1) }))
          (ok true)
        )
        ERR_USER_NOT_REGISTERED
    )
  )
)

;; Follow/Unfollow a user
(define-public (toggle-follow (user-to-follow principal))
  (let ((user tx-sender))
    (if (is-registered user)
        (if (is-registered user-to-follow)
            (if (not (is-eq user user-to-follow))
                (let ((follow-status (default-to false (map-get? followers { follower: user, followed: user-to-follow }))))
                  ;; Toggle follow status
                  (map-set followers { follower: user, followed: user-to-follow } (not follow-status))
                  ;; Update follower count
                  (let ((followed-profile (unwrap! (map-get? profiles user-to-follow) ERR_USER_NOT_REGISTERED)))
                    (map-set profiles user-to-follow (merge followed-profile 
                      { follower-count: (if follow-status 
                                          (- (get follower-count followed-profile) u1) 
                                          (+ (get follower-count followed-profile) u1)) }))
                    (ok (not follow-status))
                  )
                )
                ERR_UNAUTHORIZED
            )
            ERR_USER_NOT_REGISTERED
        )
        ERR_USER_NOT_REGISTERED
    )
  )
)

;; Read-Only Functions

;; Get user profile
(define-read-only (get-profile (user principal))
  (map-get? profiles user)
)

;; Get post details
(define-read-only (get-post (post-id uint))
  (map-get? posts post-id)
)

;; Get user posts
(define-read-only (get-user-posts (user principal))
  (map-get? user-posts user)
)

;; Check follow status
(define-read-only (is-following (follower principal) (followed principal))
  (default-to false (map-get? followers { follower: follower, followed: followed }))
)