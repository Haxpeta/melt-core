(define-module (Flax process)
  #:use-module (Flax post)

  #:use-module (srfi srfi-9)

  #:export (make-process
	    get-process-key
	    set-process-key
	    get-processor
	    set-processor

	    default-process-layer
	    process-ref
	    processor-ref))


;; defien the record of <process>
(define-record-type <process>
  (make-process key processor)
  is-process?
  (key get-process-key set-process-key)  ;; you'd better set the key as symbol
  (processor get-processor set-processor)) ;; the processor is a procedure which process the sxml tree


;; return the process from the process-layer otherwise
;; return '()
(define (process-ref process-layer key)
  (assq-ref process-layer key))

;; return the processor of one process in process-layer
(define (processor-ref process-layer key)
  (get-processor (process-ref process-layer key)))


;; read each post, genereate an alist of post path , not completed!!!!!!!!!!!!!!
(define (Hello)
  (format #t "This is not done!!~%"))

;; ---------------------------the default process layer------------------------------------------------
;; this template require these keywords in post
;; img    -- the preview image path, from the index file to that image, pure String
;; title  -- the title of the post, pure String
;; author -- Your name, pure String
;; date   -- the date the post posted, Pure String
;; tag    -- The type of the post, Pure String
;; this will show later in the end of the file
(define default-meta-process
  (make-process 'meta
		(lambda* (#:key process-layer process-object)
		  ((assq-ref process-layer 'index) (assq-ref process-layer 'post) process-object))))

(define default-index-process
  (make-process 'index
		(lambda (process post)
		  `(html (head)
			 (body ,((get-processor process) post))))))

(define default-post-process
  (make-process 'posts
		(lambda (post)
		  `(div (@ (style "display:block;"))
			,(if (eq? '() (post-ref post 'img))
			     '()
			     `(img (@ (src ,(post-ref post 'img)))))
			(hr)
			(h3 ,(if (eq? '() (post-ref post 'title))
				 "title"
				 (post-ref post 'title)))
			(span ,(if (eq? '() (post-ref post 'author))
				   "anonymous"
				   (post-ref post 'author))
			      ,(if (eq? '() (post-ref post 'date))
				   "today"
				   (post-ref post 'date)))
			(div ,(if (eq? '() (post-ref post 'tag))
				   "none"
				   (let ((span-tag (lambda (tag-list output-list)
						     (cons `(span ,(car tag-list))
							   output-list)))
					 (current-list '())
					 (tag-list (post-ref post 'tag)))
				     (while (not (eq? '() tag-list))
				       (set! current-list (span-tag tag-list current-list))
				       (set! tag-list (cdr tag-list)))
				     current-list))))
		  `(div ,(post-ref post 'content)))))

;; require each post has these metadatas
;; title if none output "title" -- title is a string
;; author if none output "anonymous" -- author is a string
;; date if none output "today" -- date is a string
;; img if none don't display the image -- img is a src string
;; tag if none output "none" -- tag is a !!string list!!
;; content -- must have! otherwise you will get one post without content 
(define default-process-layer
  `((meta . ,default-meta-process)
    (index . ,default-index-process)
    (post . ,default-post-process)))
