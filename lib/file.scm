(library (Flax lib file)
  (export copy-file
		  cp-f
		  cp-rf)
  (import (scheme))

  ;; copy file
  ;; the mode is for the output port
  (define copy-file
    (case-lambda
      [(src-file target-file)
       (let ((input-port (open-file-input-port src-file))
             (output-port (open-file-output-port target-file)))
         (put-bytevector output-port (get-bytevector-all input-port))
         (close-port input-port)
         (close-port output-port))]
      [(src-file target-file mode)
       (let ((input-port (open-file-input-port src-file))
             (output-port (open-file-output-port target-file mode)))
         (put-bytevector output-port (get-bytevector-all input-port))
         (close-port input-port)
         (close-port output-port))]))


  ;; accept strings as arguments
  ;; if the target exsites, replace it.
  (define (cp-f src-file target-file)
    (if (not (file-exists? src-file)) (error src-file "File not exists!"))
    (mkdir-r (path-parent target-file))
    (copy-file src-file target-file (file-options no-fail)))

  ;; copy recursively and force
  (define (cp-rf src-file target-file)
    (if (file-exists? src-file)
        (cond
         [(file-regular? src-file)
          (cp-f src-file target-file)]
         [(file-directory? src-file)
          (mkdir-r target-file)
          (do ((file-list (directory-list src-file) (cdr file-list))
               (element (car (directory-list src-file)) (car file-list)))
              ((null? file-list)
               (cp-rf (string-append src-file (directory-separator-string) element)
                      (string-append target-file (directory-separator-string) element))
                     #t)
            (cp-rf (string-append src-file (directory-separator-string) element)
                   (string-append target-file (directory-separator-string) element)))])
        (error src-file "File not exists")))
  
  )
