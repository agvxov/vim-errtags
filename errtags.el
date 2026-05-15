;;; errtags.el --- Show compiler notices in source buffers -*- lexical-binding: t; -*-

;; Usage:
;; 
;; (load-file "~/vim-errtags/errtags.el")
;; (errtags_mode 1)
;; (add-hook 'find-file-hook #'errtags_do_notices)
;; (add-hook 'after-save-hook #'errtags_do_notices)

(defgroup errtags nil
  "Display compiler notices in source buffers."
  :group 'convenience)

(defface errtags_error_face
  '((t :inherit error))
  "Face used for the tiny highlight placed on the error position."
  :group 'errtags)

(defface errtags_message_face
  '((t :inherit font-lock-comment-face))
  "Face used for the appended inline error message."
  :group 'errtags)

;; ---------------------------------------------------------------------------
;; Configuration
;; ---------------------------------------------------------------------------

(defcustom errtags_cache_file
  (let ((explicit (getenv "ERRTAGS_CACHE_FILE")))
    (cond
     ((and explicit (not (string-empty-p explicit)))
      (expand-file-name explicit))

     ((let ((xdg (getenv "XDG_CACHE_HOME")))
        (and xdg (not (string-empty-p xdg))))
      (expand-file-name "errtags.tags" (getenv "XDG_CACHE_HOME")))

     (t
      (expand-file-name "errtags.tags" "~/.cache"))))
  "Path to the notice cache file."
  :type 'file
  :group 'errtags)

;; ---------------------------------------------------------------------------
;; Small internal helpers
;; ---------------------------------------------------------------------------

(defun errtags--current_buffer_basename ()
  "Return the basename of the current buffer's file, or nil if none exists.

This mirrors Vim's:
  expand('%:t')
which means \"just the tail component of the current file name\"."
  (when buffer-file-name
    (file-name-nondirectory buffer-file-name)))

(defun errtags--notice_basename (notice)
  "Return the basename of NOTICE's file name."
  (file-name-nondirectory (alist-get 'fname notice)))

(defun errtags--line_col_to_position (line column)
  "Convert LINE and COLUMN into a buffer position in the current buffer.

Vim uses 1-based line and column numbers in the notice cache.
Emacs positions are character positions, so we need to translate.

If LINE is outside the current buffer, return nil.

COLUMN handling here is intentionally simple:
we move to the requested column on that line, or as far as possible
if the line is shorter than the requested column."
  (when (and (integerp line) (>= line 1))
    (save-excursion
      (goto-char (point-min))

      ;; If the requested line is beyond the end of the buffer,
      ;; do not try to create overlays at nonsense positions.
      (let ((max-line (line-number-at-pos (point-max))))
        (when (<= line max-line)
          ;; Move to the requested line.
          ;; Because the file cache uses 1-based line numbers,
          ;; we subtract 1 before moving forward.
          (forward-line (1- line))

          ;; Convert the 1-based column to Emacs' zero-based notion
          ;; of "characters from beginning of line".
          ;;
          ;; The `t` means "go as far as possible even if the column
          ;; is beyond the end of the line".
          (move-to-column (max 0 (1- (or column 1))) t)

          (point))))))

(defun errtags--make-message_string (message)
  "Build the visible text that gets appended to the line."
  (concat " # E: " message))

(defun errtags--notice_parse (line)
  "Parse a single cache LINE into a notice alist.

This version intentionally uses simple colon splitting.

Reasoning:
If a user has colons in filenames or paths, the input format is already
fundamentally incompatible with the cache format. In that case, we do
not attempt to recover.

We therefore assume the format is strictly:
  filename:line:column:message

and split on every ':'.

Return nil if the line is malformed."
  (let ((fields (split-string line ":")))
    ;; We require at least 4 fields:
    ;;   0 = filename
    ;;   1 = line
    ;;   2 = column
    ;;   3..n = message (may itself contain ':')
    (when (>= (length fields) 4)
      (let* ((fname (nth 0 fields))
             (lnum  (string-to-number (nth 1 fields)))
             (col   (string-to-number (nth 2 fields)))
             ;; re-join the rest of the fields as the message
             ;; because only the first two colons are structurally important
             (text  (mapconcat #'identity (nthcdr 3 fields) ":")))
        (list (cons 'fname fname)
              (cons 'lnum lnum)
              (cons 'col col)
              (cons 'text text)
              (cons 'type "E"))))))

(defun errtags--read_cache_lines ()
  "Read the cache file and return its lines as a list of strings.

If the cache file does not exist, return nil rather than signaling
an error, which matches the Vim behavior of simply stopping early."
  (when (file-readable-p errtags_cache_file)
    (with-temp-buffer
      (insert-file-contents errtags_cache_file)
      (split-string (buffer-string) "\n" t))))

(defun errtags--make_overlay (beg end type)
  "Create a new overlay from BEG to END and tag it with TYPE.

We store TYPE in a custom overlay property so we can later delete
only the overlays created by this package."
  (let ((ov (make-overlay beg end)))
    (overlay-put ov 'errtags_type type)
    ov))

;; ---------------------------------------------------------------------------
;; Core overlay logic
;; ---------------------------------------------------------------------------

(defun errtags_add_notice (line_number column_number message)
  "Add one notice to the current buffer.

This corresponds to the Vim function ErrtagsAddNotice.

Two overlays are created:
  1. a tiny highlight at the error column
  2. a line-spanning overlay that appends the message at line end"
  (let ((pos (errtags--line_col_to_position line_number column_number)))
    (when pos
      ;; First overlay: the tiny red marker at the error position.
      ;; This is the equivalent of Vim's prop_add(... length 1).
      (let ((highlight-overlay (errtags--make_overlay pos (min (1+ pos) (point-max)) 'highlight)))
        (overlay-put highlight-overlay 'face 'errtags_error_face)
        ;; `priority` helps ensure the highlight stays visible even if
        ;; other overlays or text properties are also present.
        (overlay-put highlight-overlay 'priority 1000))

      ;; Second overlay: the inline message shown at the end of the line.
      ;; In Emacs, `after-string` is displayed after the overlay text.
      ;; So we span from beginning-of-line to end-of-line, then attach
      ;; the message through `after-string`.
      (save-excursion
        (goto-char pos)
        (let ((bol (line-beginning-position))
              (eol (line-end-position))
              (msg (errtags--make-message_string message)))
          (when (<= bol eol)
            (let ((message-overlay (errtags--make_overlay bol eol 'message)))
              (overlay-put message-overlay 'after-string
                           ;; The text is propertized so it looks like a comment.
                           (propertize msg 'face 'errtags_message_face))
              (overlay-put message-overlay 'priority 900))))))))

(defun errtags_add_notices (notices)
  "Add all NOTICES that belong to the current buffer.

The Vim code compares:
  fnamemodify(notice['fname'], ':t') == expand('%:t')

That means the notice is accepted only if the basename matches.
We do the same here."
  (let ((current-base (errtags--current_buffer_basename)))
    (when current-base
      (dolist (notice notices)
        (when (string= (errtags--notice_basename notice) current-base)
          (errtags_add_notice
           (alist-get 'lnum notice)
           (alist-get 'col notice)
           (alist-get 'text notice)))))))

(defun errtags_parse_notices (lines)
  "Parse all cache LINES and return a list of notice alists."
  (let (errors)
    ;; We keep malformed lines out, just like the Vim code silently skips
    ;; lines that do not look like the expected format.
    (dolist (line lines (nreverse errors))
      (let ((notice (errtags--notice_parse line)))
        (when notice
          (push notice errors))))))

(defun errtags_clear_notices ()
  "Remove all overlays created by this package in the current buffer.

This is the Emacs equivalent of the Vim prop_remove calls."
  (remove-overlays (point-min) (point-max) 'errtags_type 'highlight)
  (remove-overlays (point-min) (point-max) 'errtags_type 'message))

(defun errtags_clean_notices ()
  "Clear the current buffer and truncate the cache file.

This matches the Vim function that both removes visible notices
and empties the cache file itself."
  (interactive)
  (errtags_clear_notices)
  (with-temp-file errtags_cache_file
    ;; Writing nothing truncates the file.
    ;; That is all the original Vim code did as well.
    ))

(defun errtags_do_notices ()
  "Refresh the notices in the current buffer.

This is the main entry point:
  1. clear old overlays
  2. read the cache file
  3. parse the notices
  4. display only the ones matching this buffer"
  (interactive)
  (errtags_clear_notices)
  (let ((lines (errtags--read_cache_lines)))
    (when lines
      (let ((notices (errtags_parse_notices lines)))
        (errtags_add_notices notices)))))

(defun errtags_do_notices_hook (&rest _ignore)
  "Hook wrapper for `errtags_do_notices`.

Some Emacs hooks call functions with arguments, some do not.
This wrapper accepts anything and ignores it, which makes it easy
to place on ordinary hooks."
  (when (buffer-file-name)
    (errtags_do_notices)))

;; ---------------------------------------------------------------------------
;; Automatic hookup
;; ---------------------------------------------------------------------------

;;;###autoload
(define-minor-mode errtags_mode
  "Toggle Errtags mode."
  :global t
  :group 'errtags

  (if errtags_mode
      (progn
        (add-hook 'find-file-hook #'errtags_do_notices_hook)
        (add-hook 'after-save-hook #'errtags_do_notices_hook)
        (add-hook 'window-buffer-change-functions #'errtags_do_notices_hook)

        ;; initial pass
        (dolist (buf (buffer-list))
          (with-current-buffer buf
            (when (buffer-file-name)
              (errtags_do_notices)))))

    (remove-hook 'find-file-hook #'errtags_do_notices_hook)
    (remove-hook 'after-save-hook #'errtags_do_notices_hook)
    (remove-hook 'window-buffer-change-functions #'errtags_do_notices_hook)

    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (errtags_clear_notices)))))

(provide 'errtags)

;;; errtags.el ends here
