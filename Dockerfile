FROM public.ecr.aws/docker/library/alpine:latest

RUN apk add --no-cache git openssh-client jq && \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

ADD *.sh /
COPY whitelist.json /

ENTRYPOINT ["/entrypoint.sh"]
