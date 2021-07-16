# syntax=docker/dockerfile:1
#
# WARNING: Automatically copied from dga-template
#
FROM amazon/aws-cli:latest

RUN yum install git jq -y && \
    amazon-linux-extras install docker

COPY entrypoint.sh /entrypoint.sh 
RUN chmod u+x /entrypoint.sh

RUN mkdir /home/tools

WORKDIR /home/tools

COPY init.sh .
COPY release.sh .
COPY push.sh .
COPY common/IaC/ .

RUN chmod -R u+x /home/tools/*.sh
# RUN chown -R nobody:nobody /home/tools

ENTRYPOINT ["/entrypoint.sh"]

CMD ["repl"]
