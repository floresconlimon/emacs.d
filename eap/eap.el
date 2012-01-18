;;; eap.el --- Emacs' AlsaPlayer - "Music Without Jolts"
;;; Copyright (C) 2007, 2008, 2009 Sebastian Tennant
;;;
;;; Author:     Sebastian Tennant <sebyte@gmail.com>
;;; Maintainer: Sebastian Tennant <sebyte@gmail.com>
;;; Version:    0.12
;;; Keywords:   audio, player, mp3, ogg
;;;
;;; This file is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3, or (at your option)
;;; any later version.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;;; Boston, MA 02110-1301, USA.
;;;
;;; eap.el is not (yet) part of GNU Emacs.

;;; Detailed installation and usage intructions are to be found in the
;;; manual (available in HTML, Info, and plain text formats) or, if
;;; you didn't receive the manual, at EAP's online home:
;;;
;;;  http://home.gna.org/eap/

;;; requires
(require 'eap-dired-keybindings)
(require 'comint)

;;; =========================================== defvars/defcustoms
(defgroup EAP nil "Emacs' AlsaPlayer - Music Without Jolts" :group 'multimedia :version "22.2.1")
;;; volumes
(defvar eap-volume-mute 0.01)
(defvar eap-volume-soft 0.2)
(defvar eap-volume-full 1.0)

;;; volume knob
(defvar eap-volume-knob 1.0)
(defvar eap-volume-step 0.01)

;;; fades
(defvar eap-volume-restore 1.0)
(defcustom eap-volume-fade-in-flag nil
  "Occasionally you will come across a song that starts abruptly,
causing an unpleasant jolt to your idyllic happiness.  Always use
volume-fade-in to eliminate jolts entirely.  Toggle this value
with 'i' from within Emacs' AlsaPlayer buffers, or 'M-x api' from anywhere
within Emacs."
  :group 'EAP
  :version "22.2.1"
  :type '(choice (const :tag "Always use volume fade in - Music Without Jolts" t)
		 (const :tag "Never use volume fade in - music with jolts" nil)))
(defcustom eap-volume-fade-out-flag t
  "If you ever tire of songs  before they are finished,
skipping to the next song will cause an unpleasant jolt to your
idyllic happiness.  Eliminate this jolt by always using
volume-fade-out.  Toggle this value 'o' from within Emacs' AlsaPlayer buffers,
or 'M-x apo' from anywhere within Emacs."
  :group 'EAP
  :version "22.2.1"
  :type '(choice (const :tag "Always use volume fade out - Music Without Jolts" t)
		 (const :tag "Never use volume fade out - music with jolts" nil)))
(defvar eap-volume-fade-step 0.05)

;;; songs
(defvar eap-playlist '())
(defcustom eap-music-library "~/Music"
  "The directory containing your music library.  Emacs' AlsaPlayer will create
this directory for you if it doesn't exist."
  :group 'EAP
  :version "22.2.1"
  :type '(directory))
(defcustom eap-playlist-library "~/eap-playlist-library"
  "The directory where your Emacs' AlsaPlayer playlists are stored.
This directory MUST NOT be a sub-directory of `eap-music-library'.
Emacs' AlsaPlayer will create this directory for you if it doesn't exist."
  :group 'EAP
  :version "22.2.1"
  :type '(directory))

;;; misc
(defcustom eap-alsa-device nil
  "Support for multiple soundcards.  Issue the command:

  $ cat /proc/asound/cards

in order to determine the integer values of your available
cards."
  :group 'EAP
  :version "22.2.1"
  :type '(integer))
(defcustom eap-startup-hook nil
  "Hook run at startup.  Useful for mounting external media for
instance."
  :group 'EAP
  :version "22.2.1"
  :type '(hook))
(defcustom eap-playlist-font-lock-keywords '((".*\\* ?$" . font-lock-keyword-face)
					     (".*Pos ?$" . font-lock-builtin-face))
  "Alter the appearance of the Emacs' AlsaPlayer playlist buffer. Each cons in
this alist must be of the form (REGEXP . FACE)."
  :group 'EAP
  :version "22.2.1"
  :type '(alist :key-type regexp :value-type face))
(defvar eap-header-line-format
  (mapconcat
   (lambda (k)
     (format "%s %s" (propertize (car k) 'face 'bold) (cdr k)))
   '((">" . "next,") ("<" . "previous,") ("SPC" . "pause,") ("j" . "jump,") ("p" . "playlist,") ("m" . "music,")
     ("l" . "lists,") ("s" . "symlink,") ("0" . "mute,") ("-" . "soft,") ("=" . "full,") ("q" . "bury,") ("Q" . "quit"))
   " "))
(defcustom eap-buffer-name "*EAP*"
  "Name of the AlsaPlayer process output buffer.  Choose a name
  beginning with a SPC character to hide the buffer from buffer
  listings."
  :group 'EAP
  :version "22.2.1"
  :type '(string))
(defcustom eap-playlist-buffer-name "*EAP Playlist*"
  "Name of the Emacs' AlsaPlayer playlist buffer.  Choose a name beginning with
  a SPC character to hide the buffer from buffer listings."
  :group 'EAP
  :version "22.2.1"
  :type '(string))


;;; =========================================== modes
;;; mode map
(defvar eap-mode-map (make-keymap))
(suppress-keymap eap-mode-map)
(mapc (lambda (k) (define-key eap-mode-map (car k) (cdr k)))
      '(;; state change keys (not volume)
	([right] . ap>) (">" . ap>) ;next track
	([left]  . ap<) ("<" . ap<) ;previous track
	(" "     . ap.) ("j" . apj) ("Q" . apq) ;pause, jump & quit
	;; fixed volume keys
	("0"     . ap0) ("-" . ap-) ("=" . ap=) ;mute, soft & full volume
	;; eap-to-dired keys
	("m"     . apm) ("l" . apl) ("v" . apv) ("s" . aps) ;music lib, playlist lib, view track & symlink track
	;; other keys
	("p"     . app) ("i" . api) ("o" . apo) ;playlist, toggle fade-in, toggle fade-out
	;; functions only acccessible from within an EAP buffer
	("b"     . (lambda ()
		     (interactive)
		     (eap-call-alsaplayer "relative" '("-2"))))
	("f"     . (lambda ()
		     (interactive)
		     (eap-call-alsaplayer "relative" '("2"))))
	([up]    . (lambda () ; volume up
		     (interactive)
		     (unless (eap-volume-at-full-p)
		       (eap-volume-change '+)
		       (setq eap-volume-restore eap-volume-knob))))
	([down]  . (lambda () (interactive) ; volume down
		     (unless (eap-volume-at-mute-p)
		       (eap-volume-change '-)
		       (setq eap-volume-restore eap-volume-knob))))
	("c"     . (lambda (dir) (interactive "sChange value of eap-music-library to: ")
		     (if (file-accessible-directory-p dir)
			 (setq eap-music-library dir)
		       (message "%s not accessible. eap-music-libraryectory unchanged." dir))))
	("k"     . eap-shrink-window) ;used in code (below)
	("q"     . (lambda () (interactive) ; bury EAP buffers
		     (delete-windows-on eap-buffer-name) (bury-buffer eap-buffer-name)
		     (when (get-buffer eap-playlist-buffer-name)
		       (bury-buffer eap-buffer-name)
		       (kill-buffer eap-playlist-buffer-name))))
	))

;;; EAP mode
(define-derived-mode eap-mode comint-mode "EAP"
  "Major mode for the control of Emacs' AlsaPlayer.

Emacs' AlsaPlayer - \"Music Without Jolts\"
\\<eap-mode-map>
\\{eap-mode-map}"
  (set-face-attribute 'header-line nil :underline nil)
  (setq header-line-format eap-header-line-format)
  (setq comint-scroll-to-bottom-on-output t))

;;; EAP Playlist mode
(defun eap-playlist-mode ()
  "Major mode for the control of Emacs' AlsaPlayer and the
display of the current Emacs' AlsaPlayer playlist.

Emacs' AlsaPlayer - \"Music Without Jolts\"
\\<eap-mode-map>
\\{eap-mode-map}"
  (kill-all-local-variables)
  (use-local-map eap-mode-map)
  (setq major-mode 'eap-playlist-mode)
  (setq mode-name "EAP Playlist")
  (setq font-lock-defaults '(eap-playlist-font-lock-keywords t))
  (font-lock-mode 1)
  (set-face-attribute 'header-line nil :underline nil)
  (setq header-line-format eap-header-line-format))

;;; =========================================== state control
(setq eap-paused-flag nil)

;;; call alsaplayer
(defun eap-call-alsaplayer (action &optional args msg)
  (setq action (concat "--" action))
  (if args (apply 'call-process "alsaplayer" nil nil nil action args)
    (call-process "alsaplayer" nil nil nil action))
  (when msg (message msg)))

;;; change song stae
(defun eap-state-change (change)
  (if (eap-running-p)
      (progn
	(unless (equal change 'togg)
	  (unless (not eap-volume-fade-out-flag)
	    (eap-volume-fade-out)))
	(cond ((equal change 'next) (eap-call-alsaplayer "next"))
	      ((equal change 'prev) (eap-call-alsaplayer "prev"))
	      ((equal change 'togg)	;toggle (pause or resume)
	       (if eap-paused-flag
		   (progn (eap-call-alsaplayer "start")
			  (setq eap-paused-flag nil)
			  (if eap-volume-fade-in-flag
			      (eap-volume-fade-in)
			    (eap-volume-change eap-volume-restore)))
		 (progn (unless (not eap-volume-fade-out-flag)
			  (eap-volume-fade-out))
			(eap-call-alsaplayer "pause")
			(setq eap-paused-flag t))))
	      ((equal change 'quit) (eap-call-alsaplayer "quit") (setq eap-playlist '() eap-paused-flag nil))
	      (t             (eap-call-alsaplayer "jump" (list change))))
	(unless (equal change 'togg)
	  (if eap-volume-fade-in-flag
	      (eap-volume-fade-in)
	    (eap-volume-change eap-volume-restore))))
    (message "Emacs' AlsaPlayer not running.")))


;;; =========================================== volume control
(defun eap-volume-at-full-p ()
  (if (>= eap-volume-knob eap-volume-full)
      (progn (setq eap-volume-knob eap-volume-full) t)
    nil))

(defun eap-volume-at-mute-p ()
  (if (<= eap-volume-knob eap-volume-mute)
      (progn (setq eap-volume-knob eap-volume-mute) t)
    nil))

(defun eap-volume-at-restore-p ()
  (if (>= eap-volume-knob eap-volume-restore)
      (progn (setq eap-volume-knob eap-volume-restore) t)
    nil))

(defun eap-volume-change (n)
  (cond ((equal n '+) (setq eap-volume-knob (+ eap-volume-knob eap-volume-step)))
	((equal n '-) (setq eap-volume-knob (- eap-volume-knob eap-volume-step)))
	((numberp n) (setq eap-volume-knob n)))
  (call-process "alsaplayer" nil nil nil "--volume" (number-to-string eap-volume-knob)))

(defun eap-volume-fade-out ()
  (setq eap-volume-restore eap-volume-knob)
  (while (not (eap-volume-at-mute-p))
    (eap-volume-change '-)
    (sleep-for eap-volume-fade-step)))

(defun eap-volume-fade-in ()
  (while (not (eap-volume-at-restore-p))
    (eap-volume-change '+)
    (sleep-for eap-volume-fade-step)))


;;; =========================================== file management
(defun eap-check-file-suffix (str)
  (or (string= (substring str -4) ".mp3")
      (string= (substring str -4) ".MP3")
      (string= (substring str -4) ".ogg")
      (string= (substring str -4) ".OGG")
      (string= (substring str -4) ".wav")
      (string= (substring str -4) ".WAV")
      ))

(defun eap-marked-check (files)
  (apply 'nconc
	 (mapcar '(lambda (f)
		    (if (eap-check-file-suffix f)
			(list f)
		      (when (file-accessible-directory-p f)
			;; cddr removes '.' and '..' from the list
			(eap-marked-check (cddr (directory-files f t))))))
		 files)))

(defun eap-marked-randomise (files)
  (let (f l)
    (while files
      (setq f (elt files (random (length files)))
	    files (remove f files)
	    l (cons f l))) l))

(defun eap-running-p ()
  (equal (process-status "EAP") 'run))


;;; =========================================== do what I mean
;;; start a new alsaplayer process, add to an existing playlist or start a new playlist
(defun eap-dwim (files enqueue-flag)
  (set-buffer (get-buffer-create eap-buffer-name))
  (unless (equal major-mode "eap-mode") (eap-mode))
  ;; go alsaplayer go
  (if (not (eap-running-p))
      (progn
	(erase-buffer)
	(if (not eap-alsa-device)
	    (display-buffer (apply 'make-comint-in-buffer "EAP" eap-buffer-name
				   "alsaplayer" nil "-i" "text" files))
	  (display-buffer (apply 'make-comint-in-buffer "EAP" eap-buffer-name
				 "alsaplayer" nil "-i" "text"
				 "-d" (concat "hw:" (number-to-string eap-alsa-device)) files)))
	(eap-shrink-window)
	;;; set up a simple sentinel
	(set-process-sentinel
	 (get-buffer-process eap-buffer-name)
	 (lambda (proc ev)
	   (setq ev (substring ev 0 6)) ;remove the newline
	   (and (equal ev "finish")
		(message "AlsaPlayer process ended cleanly, current playlist saved."))
	   (and (member ev '("killed" "exited"))
		(message "AlsaPlayer process ended abruptly, current playlist not saved.")))))
    (progn
      (if enqueue-flag
	  (eap-call-alsaplayer "enqueue" files "Added to play queue.")
	(progn
	  (when eap-volume-fade-out-flag (eap-volume-fade-out))
	  (eap-call-alsaplayer "replace" files "Started new play queue.")
	  (eap-volume-change eap-volume-restore))))))

;;; top level entry to eap
;;;###autoload
(defun eap ()
  "Emacs' AlsaPlayer - Music Without Jolts"
  (interactive)
  (if (eap-running-p)
      ;; just pop to EAP buffer if already running
      (progn (pop-to-buffer eap-buffer-name) (eap-shrink-window))
    ;; else...
    (progn
      (if (and (file-readable-p "~/.alsaplayer/alsaplayer.m3u")
	       (not (equal (elt (file-attributes "~/.alsaplayer/alsaplayer.m3u") 7) 0))
	       (y-or-n-p "Continue where you left off? "))
	  (progn
	    ;; set eap-playlist variable to file contents, and go...
	    (with-temp-buffer
	      (insert-file-contents "~/.alsaplayer/alsaplayer.m3u")
	      (setq eap-playlist (remove "" (split-string (buffer-string) "\n"))))
	    (eap-dwim nil nil))
	;; just bring up music directory in Dired
	(if (file-accessible-directory-p eap-music-library)
	    (dired eap-music-library)
	  (message "Music directory (%s) not found or inaccessible." eap-music-library)
	)))))

(defun eap-shrink-window ()
  (interactive)
  (let ((w (get-buffer-window eap-buffer-name)))
    (when (and w (not (= (window-height w) 3)))
      (fit-window-to-buffer w 3 3))))


;;; =========================================== status
(defun eap-alsaplayer-status-alist ()
  (mapcar '(lambda (s) (split-string s ": "))
    (remove "---------------- Session ----------------"
      (remove "-------------- Current Track ------------"
	(remove "-----------------------------------------"
	  (remove ""
	    (split-string (call-process-to-string "alsaplayer --status") "\n")))))))

(defun eap-alsaplayer-this-status (s)
  (cadr (assoc s (eap-alsaplayer-status-alist))))

(defun eap-alsaplayer-current-song ()
  (car (last (split-string (eap-alsaplayer-this-status "path") "/"))))


;;; =========================================== eap to dired
;;; no need to auto-load this as well as the alias 'apm'
(defun eap-dired-music-lib ()
  (interactive)
  (dired-other-window eap-music-library))

;;; no need to auto-load this as well as the alias 'apl'
(defun eap-dired-playlist-lib ()
  (interactive)
  (dired-other-window eap-playlist-library))

(defun eap-dired-current-track ()
  (interactive)
  (when (eap-running-p)
    (let ((track (eap-alsaplayer-this-status "path")))
      (dired-other-window (file-name-directory track))
      (goto-char (point-max))
      (re-search-backward (file-name-nondirectory track)))))

(defun eap-symlink-current-track ()
  (interactive)
  (eap-dired-current-track)
  (dired-eap-symlink-to-playlist-library))


;;; =========================================== dired to eap
;;;###autoload
(defun dired-eap-replace-marked (rand-flag)
  (interactive "p")
  (let ((files (eap-marked-check (dired-get-marked-files))))
    (if (equal rand-flag 4)
	(setq eap-playlist (eap-marked-randomise files))
      (setq eap-playlist files))
    (eap-dwim eap-playlist nil))) ;start new playlist

;;;###autoload
(defun dired-eap-enqueue-marked (rand-flag)
  (interactive "p")
  (let ((files (eap-marked-check (dired-get-marked-files))))
    (if (equal rand-flag 4)
	(setq eap-playlist (nconc eap-playlist (eap-marked-randomise files)))
      (setq eap-playlist (nconc eap-playlist files)))
    (eap-dwim files t))) ;add files to current playlist

;;;###autoload
(defun dired-eap-symlink-to-playlist-library ()
  (interactive)
  (let ((dired-dwim-target t))
    ;; create the playlist-library directory if necessary
    (or (file-accessible-directory-p eap-playlist-library)
	(make-directory eap-playlist-library t))
    ;; create a playlist-library if necessary
    (or (split-string
	 (shell-command-to-string
	  (format "find %s -mindepth 1 -type d -print"
		  (shell-quote-argument eap-playlist-library))))
	(make-directory (concat eap-playlist-library "/Favourite songs")))
    ;; go
    (dired-other-window eap-playlist-library)
    (other-window 1)
    (let ((default-directory eap-playlist-library))
      (dired-do-symlink))))


;;; =========================================== other
(defun eap-display-playlist ()
  (interactive)
  (if (eap-running-p)
      (progn
	(switch-to-buffer eap-playlist-buffer-name)
	(unless (equal major-mode "eap-playlist-mode") (eap-playlist-mode))
	(delete-other-windows)		;this is needed for some reason
	(when buffer-read-only (toggle-read-only))
	(erase-buffer)
	(insert (format "\n%28s | %28s | %52s | %3s\n" "Artist" "Album" "Track file name" "Pos"))
	(let ((qpos 1))
	  (mapc '(lambda (s)
		   (let* ((aas-list (last (split-string s "/") 3))
			  (artist (car aas-list))
			  (album (car (cdr aas-list)))
			  (song (car (cdr (cdr aas-list)))))
		     (insert (format "%28s | %28s | %52s | %3d\n"
				     (truncate-string-to-width artist 28 nil nil t)
				     (truncate-string-to-width album 28 nil nil t)
				     (truncate-string-to-width song 52 nil nil t)
				     qpos)))
		   (setq qpos (1+ qpos)))
		eap-playlist))
	(goto-char (point-min))
	;; now place '*' next to current song, remembering that
	;; file names longer than approx. 48 chars are truncated
	(let ((search-substring-length
	       (if (>= (length (eap-alsaplayer-current-song)) 49)
		   48
		 (1- (length (eap-alsaplayer-current-song))))))
	  (re-search-forward (substring (eap-alsaplayer-current-song) 0 search-substring-length) nil nil))
	(end-of-line) (insert "*")
	(toggle-read-only)
	(pop-to-buffer eap-buffer-name)		;return to *EAP*
	(eap-shrink-window))
    (message "Emacs' AlsaPlayer isn't running")))

(defun eap-toggle-fade-in ()
  (interactive)
  (setq eap-volume-fade-in-flag (not eap-volume-fade-in-flag))
  (message "Volume fade-in now %s." (if eap-volume-fade-in-flag "active" "inactive")))

(defun eap-toggle-fade-out ()
  (interactive)
  (setq eap-volume-fade-out-flag (not eap-volume-fade-out-flag))
  (message "Volume fade-out now %s." (if eap-volume-fade-out-flag "active" "inactive")))

;;; =========================================== hooks
;;; add to kill-buffer-hook to ensure AlsaPlayer quits cleanly
(defun eap-always-kill-buffer-cleanly ()
  (and (equal (buffer-name) eap-buffer-name)
       (eap-state-change 'quit)))

;;; add to kill-emacs-query-functions to ensure AlsaPlayer quits cleanly
(defun eap-always-kill-emacs-cleanly ()
  (if (fboundp 'eap-running-p)
      (if (eap-running-p) (progn (eap-state-change 'quit) t) t)
    t))


;;; =========================================== global to eap
;;; non-volume state change functions
(defun ap> () (interactive) (eap-state-change 'next))
(defun ap< () (interactive) (eap-state-change 'prev))
(defun ap. () (interactive) (eap-state-change 'togg))
(defun apj () (interactive) (eap-display-playlist)
  (let ((n (string-to-number (read-from-minibuffer  "Jump to track: "))))
    (if (or (<= n 0) (> n (length eap-playlist)))
	(message "That number does not correspond to a queued track.")
      (eap-state-change (number-to-string n)))))
(defun apq () (interactive) (eap-state-change 'quit))

;;; volume functions
(defun ap0 () (interactive) (eap-volume-change eap-volume-mute))
(defun ap- () (interactive) (eap-volume-change eap-volume-soft))
(defun ap= () (interactive) (eap-volume-change eap-volume-full))

(defalias 'api 'eap-toggle-fade-in)
(defalias 'apo 'eap-toggle-fade-out)

;;; dired function aliae
;;;###autoload
(defalias 'apm 'eap-dired-music-lib)
;;;###autoload
(defalias 'apl 'eap-dired-playlist-lib)
(defalias 'apv 'eap-dired-current-track)
(defalias 'aps 'eap-symlink-current-track)

;;; playlist function alias
(defalias 'app 'eap-display-playlist)

;;; =========================================== helper function
;;; send synchronous process output to a string
(defun call-process-to-string (process &optional sep)
  "Start the synchronous process PROCESS (via `call-process') and
return the results in a string.  PROCESS may be a list or a
string.  If PROCESS is a string, any SEP argument (which must
also be a string) will be used as the separator when converting
the string to a list (via `split-string') instead of the default
whitespace value."
  (let (process-list)
    (cond ((stringp process)
	   (setq process-list (if sep (split-string process sep) (split-string process))))
	  ((listp process)
	   (setq process-list process))
	  (t
	   (setq process-list nil)))
    (when process-list
      (with-output-to-string
	(with-current-buffer standard-output
	  (apply 'call-process (car process-list) nil t nil (cdr process-list)))))))

(provide 'eap)

;;; Local Variables:
;;; fill-column:70
;;; End: