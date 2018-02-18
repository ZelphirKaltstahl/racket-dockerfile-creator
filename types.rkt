#lang typed/racket

(provide (all-defined-out))

(define-type BaseImage
  ;; <image-name>@sha256:<checksum>
  ;; sha256:aa7a65b8796ea9e260c485f810b39929890d6ea630484dc75aa51a32c93af8ce
  (U 'debian:jessie
     'ubuntu:16.04))

(define-type DockerItemType
  (U 'FROM
     'MAINTAINER
     'CMD
     'RUN
     'ARG
     'ENV
     'ENTRYPOINT
     'WORKDIR
     'COPY
     'EXPOSE
     'USER))

(struct BasicDockerItem
  ([base-image : BaseImage]
   [type : DockerItemType]
   [command : String]
   [ignore-failure : Boolean]
   [dependencies : (Listof (U BasicDockerItem MetaDockerItem))]))

(struct MetaDockerItem
  ([base-image : BaseImage]
   [dependencies : (Listof (U BasicDockerItem MetaDockerItem))]))

(define-type DockerItem (U BasicDockerItem MetaDockerItem))
