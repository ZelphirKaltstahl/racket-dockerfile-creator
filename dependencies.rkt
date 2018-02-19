#lang typed/racket

(require "types.rkt")

(provide (all-defined-out))

(: make-meta
   (->* () (String String) BasicDockerItem))

(: make-base-image (-> BaseImage BasicDockerItem))
(define (make-base-image image-name)
  (BasicDockerItem 'debian:jessie
                   'FROM
                   (format "~a" (symbol->string image-name))
                   #f))

(: make-comment (-> String BasicDockerItem))
(define (make-comment text)
  (let* ([left-padding 1]
         [right-padding 1]
         [border-width 1]
         [overline (list->string
                    (for/list ([ind (range (+ border-width
                                              left-padding
                                              (string-length text)
                                              right-padding
                                              border-width))])
                      #\#))]
         [underline overline])
    (BasicDockerItem 'debian:jessie
                     'COMMENT
                     (string-join (list overline (format "# ~a #" text) underline)
                                  "\n")
                     #t)))

(define (make-meta [name "example-maintainer"]
                   [email "<maintainer@example.com>"])
  (BasicDockerItem 'debian:jessie
                   'MAINTAINER
                   (string-append name " " email)
                   #f))

(: make-unprivileged-debian-user
   (->* () (String String String) MetaDockerItem))
(define (make-unprivileged-debian-user [username : String "app"]
                                       [usergroup : String "app"]
                                       [password : String "app"])
  (MetaDockerItem
   'debian:jessie
   (list
    (make-base-image 'debian:jessie)
    (make-comment "CREATING A NON-PRIVILEGED USER")
    (MetaDockerItem
     'debian:jessie
     (list
      (BasicDockerItem 'debian:jessie
                       'ARG
                       (format "NON_PRIVILEGED_USER_GROUP=~s" usergroup)
                       #f)
      (BasicDockerItem 'debian:jessie
                       'RUN
                       "groupadd -r $NON_PRIVILEGED_USER_GROUP -g 1000"
                       #f)))
    (MetaDockerItem
     'debian:jessie
     (list
      (BasicDockerItem 'debian:jessie
                       'ARG
                       (format "NON_PRIVILEGED_USER_GROUP=~s" usergroup)
                       #f)
      (BasicDockerItem 'debian:jessie
                       'ARG
                       (format "NON_PRIVILEGED_USER=~s" username)
                       #f)
      (BasicDockerItem 'debian:jessie
                       'RUN
                       (string-join (list "useradd"
                                          "--uid 1000"
                                          "--system"
                                          "--gid $NON_PRIVILEGED_USER_GROUP"
                                          "--create-home"
                                          "--home-dir /home/$NON_PRIVILEGED_USER/"
                                          "--shell /bin/bash"
                                          "--comment \"non-privileged user\""
                                          username)
                                    " \\\n    ")
                       #f)))
    (BasicDockerItem 'debian:jessie
                     'RUN
                     (format "chmod 755 /home/~a/" username)
                     #f)
    (BasicDockerItem 'debian:jessie
                     'RUN
                     (format "echo \"~a:~a\" | chpasswd" username password)
                     #f))))
