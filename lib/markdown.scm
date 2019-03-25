#!chezscheme
(library
  (melt lib markdown)
  (export markdown->sxml
          scone
          check-chars
          position-forward
          context-parse)
  (import (scheme))

  ;; this parser will append char, symbol,
  ;; `@ symbol, empty list to the sxml list

  ;; support form
  ;; [name](link)
  ;; ![name](link)
  ;; **hello** or __hello__
  ;; *hello* or _hello_
  ;; ```class ... codes ```
  ;; `code`
  ;; *** or --- equal (hr)

  ;; keywords in a line context
  (define %%inner-keyword '(#\* #\_ #\[ #\` #\!))
  ;; keywords starting a line
  (define %%line-keyword '(#\# #\! #\- #\* #\` #\>))
  ;; empty chars
  (define %%empty-chars '(#\newline #\space))


  ;; define append but contain one single element
  (define-syntax scone
    (syntax-rules ()
      ((_ ls new) (append ls (list new)))))

  ;; if n larger than position, do nothing
  (define (position-back port n)
    (let ((position (port-position port)))
      (set-port-position! port (if (and (> position 0) (> position n) (> n 0))
                                   (- position n)
                                   position))))

  ;; forward n position
  (define (position-forward port n)
    (set-port-position! port (+ n (port-position port))))

  ;; the pattern is a list. port is a text port.

  ;; pattern is a list of char and can include a nested char list.
  ;; normal pattern is (#\space #\a ...)
  ;; if the pattern is (#\space #a), it match " a", return #t.

  ;; and a nested pattern is (#\space (#\a #\b #\c) #\\)
  ;; this pattern match " a\" and " b\" and " c\".
  ;; the nested char match a single char.
  ;; if the nested list is '(), it will match any char, any!
  (define (check-chars pattern port)
    (define ($$check pattern position port)
      (if (null? pattern)
          (begin (set-port-position! port position) #t)
          (let ((pattern-char (car pattern)))
            (cond
              [(null? pattern-char)
               (read-char port) ;; accept it, if the pattern is '()
               ($$check (cdr pattern) position port)]
              [(list? pattern-char)
               (if (member (read-char port) pattern-char)
                   ($$check (cdr pattern) position port)
                   (begin (set-port-position! port position) #f))]
              [(char? pattern-char)
               (if (eq? (read-char port) pattern-char)
                   ($$check (cdr pattern) position port)
                   (begin (set-port-position! port position) #f))]
              [else
                (error 'pattern-chars "unproperly pattern char!")]))))
    ($$check pattern (port-position port) port))

  ;; define markdown->sxml
  (define (markdown->sxml port)
    (top-parse (list) %%line-keyword port))

  ;; the top field schedule 总调度器
  ;; top-parse will remain last readed char in port
  (define (top-parse sxml keywords port)
    (let ((next (peek-char port)))
      (cond
        [(eof-object? next)
         sxml]
        ;; drop blank char
        [(member next %%empty-chars)
         (position-forward port 1)
         (top-parse sxml keywords port)]
        ;; judge whether it is a line keyword
        [(member next keywords)
         (top-parse (scone sxml (context-switch 'line port))
                    keywords port)]
        ;; if not line keyword, treat it as a paragraph
        [else
          (let ((paragraph (compose-paragraph (list 'p) port)))
            (top-parse (scone sxml paragraph) keywords port))])))

  ;; Done
  ;; to generate a (p ...) element
  (define (compose-paragraph sxml port)
    (let ((next (peek-char port)))
      (if (eof-object? next)
          sxml
          (cond
            [(check-chars '(#\newline #\newline) port)
             (position-forward port 2)
             sxml]
            [(check-chars '(#\newline #\` #\` #\`) port)
             (position-forward port 1)
             sxml]
            [(check-chars '(#\newline #\#) port)
             (position-forward port 1)
             sxml]
            [(check-chars '(#\newline #\* #\space) port)
             (position-forward port 1)
             sxml]
            [(check-chars '(#\newline #\- #\space) port)
             (position-forward port 1)
             sxml]
            [(check-chars '(#\newline #\! #\[) port)
             sxml]
            [(check-chars '(#\newline #\> #\space) port)
             sxml]
            [(check-chars '(#\newline) port)
             (position-forward port 1)
             (let ((line (context-parse '(#\newline) %%inner-keyword (list) port)))
               (compose-paragraph (scone (scone sxml #\space) line) port))]
            [else
              (let ((line (context-parse '(#\newline) %%inner-keyword (list) port)))
                (compose-paragraph (scone sxml line) port))]))))

  ;; it's a context parser, could be invoked in any context
  ;; of course including itself
  ;; terminators and keywords are all char list

  ;; when return, the terminator in port will disappear
  (define (context-parse terminators keywords sxml port)
    ;; terminators is the end of parse
    ;; keywords for parsing
    ;; sxml is the returned sxml-tree
    (let ((next (peek-char port)))
      (cond
        [(or (eof-object? next)
             (member next terminators))
         (if (not (eq? next #\newline)) (read-char port))
         sxml]
        [(eq? next #\\)
         (position-forward port 1)
         (let ((escaped (read-char port)))
           (context-parse terminators keywords (scone sxml escaped) port))]
        ;; parse keywords
        [(member next keywords)
         (let ((special-block (context-switch 'inner port)))
           (context-parse terminators keywords
                          (scone sxml special-block) port))]
        ;; common chars, just append to the sxmls
        [else
          (context-parse terminators keywords
                         (scone sxml (read-char port)) port)])))


  ;; type is 'inner or 'line, an inner switcher
  ;; make sure the first char is the key char
  (define (context-switch type port)
    (cond
      [(eq? type 'line)
       (cond
         ;; to test ![] ()
         [(check-chars '(#\!) port)
          (list 'img (parse-img port))]
         [(check-chars '(#\>) port)
          (parse-blockquote port)]
         [(check-chars '(#\` #\` #\`) port)
          ;; use let* ensure first evalute attr
          (let* ((attr (parse-block-code-type (list) port))
                 (block (parse-block-code (list) port)))
            (if attr
                `(pre (code (@ ,attr) ,block))
                `(pre (code ,block))))]
         ;; change from line to paragraph
         [(check-chars '(#\`) port)
          (list 'p (compose-paragraph (list) port))]
         [(check-chars '(#\#) port) (parse-header port 0)]
         [(check-chars '(#\- #\- #\-) port)
          (parse-hr port)]
         [(check-chars '(#\* #\* #\*) port)
          (parse-hr port)]
         [(check-chars '(#\- #\space) port)
          (list 'p (compose-paragraph (list) port))]
         [(check-chars '(#\* #\space) port)
          (list 'p (compose-paragraph (list) port))]
         [else (error type (string-append "the char " (string (peek-char port)) " not match!!"))])]
      [(eq? type 'inner)
       (cond
         ;; judge the type, and switch context
         [(or (check-chars '(#\* #\*) port)
              (check-chars '(#\_ #\_) port))
          (list 'strong (parse-strong port))]
         [(or (check-chars '(#\_) port)
              (check-chars '(#\*) port))
          (list 'em (parse-em port))]
         [(check-chars '(#\[) port)
          (parse-link port)]
         [(check-chars '(#\`) port)
          (list 'code (parse-inline-code port))]
         [(check-chars '(#\! #\[) port)
          (parse-img port)]
         [(check-chars '(#\!) port)
          (context-parse '(#\space) '() '() port)]
         (else (display (string (peek-char port))) (display "\n")(error 'keychar (string-append "Not a special character"))))]))

  ;; generate hr
  (define (parse-hr port)
    (context-parse '(#\newline) '() (list) port)
    (read-char port)
    '(hr))

  ;; parse the image
  (define (parse-img port)
    (position-forward port 2) ;; consume ![
    (let ((title (list->string (context-parse '(#\]) '() '() port))))
      (position-forward port 1) ;; consume #\(
      (let ((link (list->string (context-parse '(#\)) '() '() port))))
        `((img (@ (src ,link) (title ,title)))))))

  ;; parse the blockquote
  (define (parse-blockquote port)
    (position-forward port 1)
    (list 'blockquote (list 'p (compose-paragraph (list) port))))

  ;; parse the link
  (define (parse-link port)
    (position-forward port 1) ;; consume [
    (let ((name (context-parse '(#\]) '() '() port)))
      (position-forward port 1)
      (let ((link (list->string (context-parse '(#\)) '() '() port))))
        (list 'a `(@ (href ,link)) name))))

  ;; parse the strong
  (define (parse-strong port)
    (position-forward port 1)
    (let ((text (context-parse (list (read-char port)) '() '() port)))
      (position-forward port 1)
      text))

  ;; parse em
  (define (parse-em port)
    (context-parse (list (read-char port)) '(#\`) '() port))

  ;; parse inline code
  (define (parse-inline-code port)
    (context-parse (list (read-char port)) '() '() port))

  ;; parse | ``` class name |
  (define (parse-block-code-type sxml port)
    (position-forward port 3)
    (let ((attr (context-parse '(#\newline) '() (list) port)))
      (position-forward port 1) ;; consume the \n, don't need it
      `(class ,(apply string attr))))

  ;; read the full context
  (define (parse-block-code sxml port)
    (if (check-chars '(#\` #\` #\`) port)
        (begin (context-parse '(#\newline) '() (list) port)
               (read-char port) ;; consume the newline
               sxml)
        (let* ((line (context-parse '(#\newline) '() (list) port))
               (newline (read-char port)))
          (parse-block-code (scone (scone sxml line)
                                   newline)
                            port))))

  (define (parse-header port count)
    (cond
      [(check-chars '(#\# #\# #\#) port)
       (position-forward port 3)
       (parse-header port (+ 3 count))]
      [(check-chars '(#\# #\#) port)
       (position-forward port 2)
       (parse-header port (+ 2 count))]
      [(check-chars '(#\# #\space) port)
       (position-forward port 2)
       (parse-header port (+ 1 count))]
      [(check-chars '(#\#) port)
       (position-forward port 1)
       (parse-header port (+ 1 count))]
      [else
        (let ((line (context-parse '(#\newline) '() (list) port)))
          (position-forward port 1)
          (list (string->symbol (string-append "h" (number->string (if (> count 6)
                                                                       6 count))))
                line))]))

  )
