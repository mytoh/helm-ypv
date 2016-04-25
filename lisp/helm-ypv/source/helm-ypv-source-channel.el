;;; channel.el -*- lexical-binding: t -*-

;;;; Requires
(require 'cl-lib) ; don't use cl.el
(require 'seq)
(require 'helm)

(require 'colle)
(require 'glof)

;;;;; Local
(require 'ypv-class "helm-ypv/ypv-class")
(require 'helm-ypv-global "helm-ypv/helm-ypv-global")
(require 'helm-ypv-user-variable "helm-ypv/helm-ypv-user-variable")
(require 'helm-ypv-face "helm-ypv/helm-ypv-face")
(require 'helm-ypv-player "helm-ypv/helm-ypv-player")
(require 'helm-ypv-url "helm-ypv/helm-ypv-url")

(require 'helm-ypv-source-bookmark "helm-ypv/source/helm-ypv-source-bookmark")

;;;; Action
(cl-defun helm-ypv-action-channel-open (channel)
  (cl-letf ((url (helm-ypv-make-url `[:channel ,channel])))
    (thread-first channel
      helm-ypv-bookmark-channel->bookmark
      (helm-ypv-bookmark-data-update (helm-ypv-bookmark-data-file)))
    (helm-ypv-player helm-ypv-player-type url)))

(cl-defun helm-ypv-action-channel-copy-conctact-url (channel)
  (glof:let (((contact :contact))
             channel)
    (kill-new contact)
    (message "copy %s" contact)))

;;;; Canditate
(cl-defun helm-ypv-channel-create-candidates (channels)
  (colle:map
   (lambda (info)
     (cons
      ;; display candidate
      (helm-ypv-channel-create-display-candidate info)
      ;; real candidate
      info))
   channels))

(cl-defun helm-ypv-channel-create-display-candidate (channel)
  (glof:let (((genre :genre)
              (desc :desc)
              (contact :contact)
              (bitrate :bitrate)
              (uptime :uptime)
              (comment :comment)
              (listeners :listeners)
              (relays :relays)
              (yp :yp)
              (type :type))
             channel)
    ;; (genre desc contact type bitrate uptime
    ;;        comment listeners relays yp)
    (cl-letf ((name (helm-ypv-modify-channel-name channel))
              (genre (helm-ypv-add-face genre 'helm-ypv-genre))
              (desc (helm-ypv-add-face desc 'helm-ypv-desc))
              (contact (helm-ypv-add-face contact 'helm-ypv-contact))
              (type (helm-ypv-add-face type 'helm-ypv-type))
              (bitrate (helm-ypv-add-face bitrate 'helm-ypv-bitrate))
              (uptime (helm-ypv-add-face uptime 'helm-ypv-uptime))
              (comment (helm-ypv-add-face comment 'helm-ypv-comment))
              (lr (helm-ypv-add-face
                   (concat listeners "/" relays) 'helm-ypv-lr)))
      (format "%-16.16s %-8.8s %-40.40s %-40.40s %+4s %+4s %7s %s %s %s"
              name
              genre
              desc
              comment
              bitrate
              uptime
              lr
              type
              yp
              ;; (if (string-empty-p comment) "" comment)
              contact
              ))))

(cl-defun helm-ypv-modify-channel-name (channel)
  (helm-ypv-add-face (glof:get channel :name)
                     (pcase channel
                       ((pred helm-ypv-info-channel-p)
                        'font-lock-function-name-face)
                       ((pred helm-ypv-channel-playable-p)
                        'helm-ypv-name)
                       (_
                        'font-lock-variable-name-face))))

(cl-defun helm-ypv-info-channel-p (channel)
  ;; return self.listeners()<-1;
  (glof:let (((listeners :listeners))
             channel)
    (and (stringp listeners)
       (cl-letf* ((num (string-to-number listeners)))
         (< num -1)))))

(cl-defun helm-ypv-channel-playable-p (channel)
  ;; if (channel_id==null || channel_id==="" || channel_id===) return false;
  (glof:let (((id :id))
             channel)
    (not (or (string-equal
           id
           (make-string 32 ?0))
          (null id)
          (seq-empty-p id)))))

(defvar helm-ypv-channel-candidate-channels nil)

(cl-defun helm-ypv-channel-init ()
  (thread-last helm-ypv-yp-urls
    helm-ypv-get/parse-channels
    helm-ypv-channel-create-candidates
    (setq helm-ypv-channel-candidate-channels)))

;;;; Source

(defun helm-ypv-channel-add-source-mark (name)
  (cl-letf ((mark "📺")) ; "\U0001F4FA"
    (cond ((window-system)
           (seq-concatenate 'string " " mark " "  name))
          (t
           name))))

(defclass helm-ypv-channels-source (helm-source-sync)
  ((init :initform #'helm-ypv-channel-init)
   (candidates :initform 'helm-ypv-channel-candidate-channels)
   (action :initform
           (helm-make-actions
            "Open channel" #'helm-ypv-action-channel-open
            "Add to bookmarks" #'helm-ypv-action-bookmark-add
            "Copy contact url" #'helm-ypv-action-channel-copy-conctact-url))
   (migemo :initform t)))

(defvar helm-source-ypv-channels
  (helm-make-source (helm-ypv-channel-add-source-mark "Channel list")
      'helm-ypv-channels-source))

;;; Provide
(provide 'helm-ypv-source-channel)