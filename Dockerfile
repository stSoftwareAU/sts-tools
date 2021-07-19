# syntax=docker/dockerfile:1

FROM amazon/aws-cli:latest

RUN cat /etc/passwd

RUN yum install git jq -y && \
    amazon-linux-extras install docker && \
    useradd -u 1000 -d /home/tools tools && \
    usermod -aG docker tools

COPY docker/entrypoint.sh /entrypoint.sh 
RUN chmod u+x /entrypoint.sh

WORKDIR /home/tools

COPY init.sh .
COPY docker/bashrc.sh .bashrc
COPY release.sh .
COPY push.sh .
COPY common/IaC/ .

RUN chmod -R u+x /home/tools/*.sh

ENTRYPOINT ["/entrypoint.sh"]

USER tools
CMD ["--mode", "repl"]
