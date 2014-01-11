;;; player.el -*- lexical-binding: t -*-

(cl-defun helm-ypv-player (player url)
  (cl-case player
    (mplayer2
     (helm-ypv-player-mplayer2 url))))

(cl-defun helm-ypv-player-mplayer2 (url)
  (message url)
  (cl-letf ((command (cl-concatenate 'string
                                     "mplayer --playlist="
                                     "'" url "'"
                                     " --softvol --autosync=1 --nocache --framedrop --really-quiet --no-consolecontrols --use-filename-title"
                                     " &" )))
    (message command)
    (start-process-shell-command "ypv" nil command)))

(provide 'helm-ypv-player)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End: