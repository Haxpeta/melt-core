#!/usr/bin/env guile
-*- scheme -*-
!#

;; command option
;; --no-auto-compile


;; NOTE: for test
(add-to-load-path 
    "/home/eilliot/Lasga/Repository/Local_Repository/Guile/Dev")

;;Add modules here
(use-modules (Flax ui))

;; the main execution script
(apply flax (command-line))
