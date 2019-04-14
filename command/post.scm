(library
  (melt command post)
  (export post)
  (import (scheme)
          (melt uutil)
          (melt lib console)
          (melt config)
          (melt data)
          (melt cell)
          (melt command))

  (define (post data)
    (create-command 'post "note post command."
                    (lambda args
                      (cond
                        [(null? args)
                         (gemd:help (gem:text "[38;5;15m" "this is the post command, contain 'new', 'list', and 'edit' subcommands."))
                         (gemd:help (gem:text "[38;5;15m" "use -h in each subcommand to get more info."))]
                        [(equal? (car args) "new")
                         (apply (action-new data) (cdr args))]
                        [(equal? (car args) "list")
                         (apply (action-list data) (cdr args))]
                        [(equal? (car args) "edit")
                         (apply (action-edit data) (cdr args))]
                        [(equal? (car args) "-h")
                         (gemd:help (gem:text "[38;5;15m" "this is the post command, contain 'new', 'list', and 'edit' subcommands."))
                         (gemd:help (gem:text "[38;5;15m" "use -h in each subcommand to get more info."))]
                        [else (gemd:error "unrecognized command, add -h to get info")]))))

  ;; ====================================================================
  ;; command new
  (define (action-new data)
    (lambda title
      (let* ((str-num-sequence (map car (get-md-post-title-list "post")))
             (numbers (sort > (map string->number str-num-sequence))))
        (if (not (null? title))
            (begin (write-template (car title)
                                   (string-append (data-value-query 'post data)
                                                  "/"
                                                  (number->string (+ 1 (car numbers))) ".md"))
                   (gemd:info (string-append "generate new post: " (car title))))
            (gemd:error "please provide a title.")))))

  (define (write-template title path)
    (call-with-output-file
      path
      (lambda (port)
        (display "~~~\n" port)
        (format port "title : ~a~%" title)
        (format port "date : ~a~%" (date-and-time))
        (display "~~~\n\n" port))))

  ;; ====================================================================
  ;; command list
  (define (action-list data)
    (lambda args
      (cond
        [(null? args)
         ((list-post data))
         (gemd:info "List complete :)")]
        [(and (eq? (length args) 1) (equal? (car args) "-h"))
         (gemd:help "A subcommand to list post sequence.")])))

  (define (list-post data)
    (lambda ()
      (do ((title-list (sort (lambda (pre aft) (string>? (car pre) (car aft))) (get-md-post-title-list (data-value-query 'post data)))
                       (cdr title-list)))
        ((null? title-list) (gemd:info "command complete."))
        (gemd:item (string-append
                     (gem:text "[38;5;15m" (car (car title-list)))
                     " ==> "
                     (gem:text "[38;5;15m" (cdr (car title-list))))))))


  ;; ====================================================================
  ;; command edit
  (define (action-edit data)
    (lambda number
      (let* ((str-num-sequence (map car (get-md-post-title-list "post")))
             (numbers (sort > (map string->number str-num-sequence))))
        (if (null? number)
            ((call-editor data) (number->string (car numbers)))
            ((call-editor data) (car number))))))


  ;; use external shell to call editor
  (define (call-editor data)
    (lambda (number)
      (define editor (make-cell (data-value-query 'editor data)
                                (lambda (value) (if value
                                                    (begin
                                                      (gemd:info (string-append "Got editor: " value))
                                                      (editor value (lambda (x) x))
                                                      value)
                                                    (begin
                                                      (gemd:warn "Editor not available")
                                                      #f)))))
      (gemd:info "invoking external editor ...")
      (if (editor)
          (begin
            (system (string-append (editor)
                                   " "
                                   (data-value-query 'post data)
                                   "/"
                                   number ".md"))
            (gemd:info "successfully quit."))
          (gemd:help "Please add editor config in your config file."))))
  )
