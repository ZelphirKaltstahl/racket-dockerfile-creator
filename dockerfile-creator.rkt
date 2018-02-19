#lang racket

(require "types.rkt"
         (prefix-in deps: "dependencies.rkt"))

(define IGNORE-FAILURE-SUFFIX "; echo 0")



;; Writes a list of strings as lines to a file.
;;(: display-to-file (-> Path-String (Listof String) Void))
(define (display-to-file path string-list)
  (call-with-output-file path #:mode 'text #:exists 'append
    (λ (output-port)
      (printf "Output port: ~s~n" output-port)
      (for ([line string-list])
        #;(displayln line output-port)
        (fprintf output-port "~a~n" line)))))


;; (: add-docker-items (-> Path-String (Listof BasicDockerItem) Void))
(define (add-docker-items file-path items)
  (for ([item items])
    (add-docker-item file-path item)))


;; (: add-docker-item (-> Path-String BasicDockerItem Void))
(define (add-docker-item file-path item)
  (let ([item-type (BasicDockerItem-type item)])
    (display-to-file
     file-path
     (list
      (string-append (if (symbol=? item-type 'COMMENT)
                         ""
                         (string-append (symbol->string item-type) " "))
                     (if (BasicDockerItem-ignore-failure item)
                         (string-append (BasicDockerItem-command item) "; echo 0")
                         (BasicDockerItem-command item)))))))

;;(: resolve-dependencies (-> DockerItem (Listof BasicDockerItem)))
(define (resolve-dependencies docker-item)
  #;(ann (flatten
          (ann (cond [(MetaDockerItem? docker-item)
                      (let ([deps (MetaDockerItem-dependencies docker-item)])
                        (ann (for/list ([deps-item : DockerItem deps])
                               (ann (resolve-dependencies deps-item)
                                    (Listof BasicDockerItem)))
                             (Listof (Listof BasicDockerItem))))]
                     [else (ann (list (ann docker-item
                                           BasicDockerItem))
                                (List BasicDockerItem))])
               (U (Listof BasicDockerItem) (Listof (Listof BasicDockerItem)))))
         (Listof BasicDockerItem))
  (flatten
   (cond [(MetaDockerItem? docker-item)
          (let ([deps (MetaDockerItem-dependencies docker-item)])
            (for/list ([deps-item deps])
              (resolve-dependencies deps-item)))]
         [else (list docker-item)])))

;; (: main (->* () (String) Void))
(define (main [file-path "Dockerfile"])
  #;(display-to-file "Dockerfile" '("abc"))
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
