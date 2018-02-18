#lang typed/racket

(require "types.rkt"
         (prefix-in deps: "dependencies.rkt"))

(define IGNORE-FAILURE-SUFFIX "; echo 0")



;; Writes a list of strings as lines to a file.
(: display-to-file (-> Path-String (Listof String) Void))
(define (display-to-file path string-list)
  (call-with-output-file path #:mode 'text #:exists 'append
    (λ ([output-port : Output-Port])
      (printf "Output port: ~s~n" output-port)
      (for ([line string-list])
        (displayln line output-port)))))


(: add-docker-items (-> Path-String (Listof BasicDockerItem) Void))
(define (add-docker-items file-path items)
  (for ([item : BasicDockerItem items])
    (add-docker-item file-path item)))


(: add-docker-item (-> Path-String BasicDockerItem Void))
(define (add-docker-item file-path item)
  (display-to-file
   file-path
   (list
    (string-append (symbol->string (BasicDockerItem-type item)) " "
                   (if (BasicDockerItem-ignore-failure item)
                       (string-append (BasicDockerItem-command item) "; echo 0")
                       (BasicDockerItem-command item))))))

(: resolve-dependencies (-> MetaDockerItem (Listof BasicDockerItem)))
(define (resolve-dependencies meta-docker-item)
  (void))

(: main (->* () (String) Void))
(define (main [file-path "Dockerfile"])
  (add-docker-items
   "Dockerfile"
   (resolve-dependencies
    (MetaDockerItem 'debian:jessie
                    (list (deps:make-meta "testuser" "testuser@example.com")
                          (deps:make-unprivileged-debian-user "testuser"
                                                              "testgroup"
                                                              "testpass"))))))

(module* main #f
  (main))
