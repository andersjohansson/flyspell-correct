;;; flyspell-correct-helm.el --- Correcting words with flyspell via helm interface -*- lexical-binding: t; -*-
;;
;; Copyright (c) 2016-2021 Boris Buliga
;;
;; Author: Boris Buliga <boris@d12frosted.io>
;; URL: https://github.com/d12frosted/flyspell-correct
;; Version: 0.6.1
;; Package-Requires: ((flyspell-correct "0.6.1") (helm "1.9.0") (emacs "24"))
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3
;;
;;; Commentary:
;; This package provides helm interface for flyspell-correct package.
;;
;; Points of interest are `flyspell-correct-wrapper',
;; `flyspell-correct-previous' and `flyspell-correct-next'.
;;
;; Example usage:
;;
;;   (require 'flyspell-correct-helm)
;;   (define-key flyspell-mode-map (kbd "C-;") 'flyspell-correct-wrapper)
;;
;; Or via use-package:
;;
;;   (use-package flyspell-correct-helm
;;     :bind ("C-M-;" . flyspell-correct-wrapper)
;;     :init
;;     (setq flyspell-correct-interface #'flyspell-correct-helm))
;;
;;; Code:
;;

;; Requires

(require 'flyspell-correct)
(require 'helm)

;; Interface implementation
(defvar flyspell-correct-helm-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "C-1") #'flyspell-correct-helm-save)
    (define-key map (kbd "C-2") #'flyspell-correct-helm-session)
    (define-key map (kbd "C-3") #'flyspell-correct-helm-buffer)
    (define-key map (kbd "C-4") #'flyspell-correct-helm-skip)
    (define-key map (kbd "C-5") #'flyspell-correct-helm-stop)
    map)
  "Keymap for ‘flyspell-correct-helm’.")

(defvar flyspell-correct-helm-mode-line-string "\
\\<flyspell-correct-helm-map>\
\\[flyspell-correct-helm-save]:Save \
\\[flyspell-correct-helm-session]:Accept (s) \
\\[flyspell-correct-helm-buffer]:Accept (b) \
\\[flyspell-correct-helm-skip]:Skip \
\\[flyspell-correct-helm-stop]:Stop"
  "Mode-line string for ‘flyspell-correct-helm’.")

(defvar flyspell-correct-helm-current-word nil
  "Current word to be corrected.")

(defun flyspell-correct-helm-save ()
  "Save current word."
  (interactive)
  (helm-run-after-exit #'cons 'save flyspell-correct-helm-current-word))
(defun flyspell-correct-helm-session ()
  "Accept (session) current word."
  (interactive)
  (helm-run-after-exit #'cons 'session flyspell-correct-helm-current-word))
(defun flyspell-correct-helm-buffer ()
  "Accept (buffer) current word."
  (interactive)
  (helm-run-after-exit #'cons 'buffer flyspell-correct-helm-current-word))
(defun flyspell-correct-helm-skip ()
  "Skip current word."
  (interactive)
  (helm-run-after-exit #'cons 'skip flyspell-correct-helm-current-word))
(defun flyspell-correct-helm-stop ()
  "Stop at current word."
  (interactive)
  (helm-run-after-exit #'cons 'stop flyspell-correct-helm-current-word))

(defun flyspell-correct-helm--always-match (_)
  "Return non-nil for any CANDIDATE."
  t)

(defun flyspell-correct-helm--option-candidates (word)
  "Return a set of options for the given WORD."
  (let ((opts (list (cons (format "Save \"%s\"" word)
                          (cons 'save word))
                    (cons (format "Accept (session) \"%s\"" word)
                          (cons 'session word))
                    (cons (format "Accept (buffer) \"%s\"" word)
                          (cons 'buffer word))
                    (cons (format "Skip \"%s\"" word)
                          (cons 'skip word))
                    (cons (format "Stop at \"%s\"" word)
                          (cons 'stop word)))))
    (unless (string= helm-pattern "")
      (setq opts
            (append opts
                    (list (cons (format "Save \"%s\"" helm-pattern)
                                (cons 'save helm-pattern))
                          (cons (format "Accept (session) \"%s\"" helm-pattern)
                                (cons 'session helm-pattern))
                          (cons (format "Accept (buffer) \"%s\"" helm-pattern)
                                (cons 'buffer helm-pattern))))))
    opts))

(defun flyspell-correct-helm (candidates word)
  "Run `helm' for the given CANDIDATES.

List of CANDIDATES is given by flyspell for the WORD.

Return a selected word to use as a replacement or a tuple
of (command, word) to be used by `flyspell-do-correct'."
  (let ((flyspell-correct-helm-current-word word))
    (helm :sources (list (helm-build-sync-source
                             (format "Suggestions for \"%s\" in dictionary \"%s\""
                                     word (or ispell-local-dictionary
                                              ispell-dictionary
                                              "Default"))
                           :candidates candidates
                           :action 'identity
                           :fuzzy-match t
                           :keymap 'flyspell-correct-helm-map
                           :mode-line 'flyspell-correct-helm-mode-line-string)
                         (helm-build-sync-source "Options"
                           :candidates (lambda ()
                                         (flyspell-correct-helm--option-candidates word))
                           :action 'identity
                           :match 'flyspell-correct-helm--always-match
                           :volatile t
                           :keymap 'flyspell-correct-helm-map
                           :mode-line 'flyspell-correct-helm-mode-line-string))
          :buffer "*Helm Flyspell*"
          :prompt "Correction: ")))

(setq flyspell-correct-interface #'flyspell-correct-helm)

(provide 'flyspell-correct-helm)

;;; flyspell-correct-helm.el ends here
