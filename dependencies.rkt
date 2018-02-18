#lang typed/racket

(require "types.rkt")

(provide (all-defined-out))

(: make-meta
   (->* () (String String) BasicDockerItem))
(define (make-meta [name "example-maintainer"]
                   [email "<maintainer@example.com>"])
  (BasicDockerItem 'debian:jessie
                   'MAINTAINER
                   (string-append name " " email)
                   #f
                   '()))

(: make-unprivileged-debian-user
   (->* () (String String String) DockerItem))
(define (make-unprivileged-debian-user [username : String "app"]
                                       [usergroup : String "app"]
                                       [password : String "app"])
  (MetaDockerItem 'debian:jessie
                  (list
                   (BasicDockerItem 'debian:jessie
                                    'RUN
                                    (format "groupadd -r ~s -g 1000" usergroup)
                                    #f
                                    '())
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
                                    #f
                                    '())
                   (BasicDockerItem 'debian:jessie
                                    'RUN
                                    (format "chmod 755 /home/~s/" username)
                                    #f
                                    '())
                   (BasicDockerItem 'debian:jessie
                                    'RUN
                                    (format "echo \"~s:~s\" | chpasswd" username password)
                                    #f
                                    '()))))
