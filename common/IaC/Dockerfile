# syntax=docker/dockerfile:1
#
# WARNING: Automatically copied from sts-tools
#
FROM hashicorp/terraform:1.3.7

COPY --chown=nobody:nobody entrypoint.sh .
RUN chmod u+x entrypoint.sh

RUN mkdir /home/IaC

WORKDIR /home/IaC

COPY IaC/ .

RUN chown -R nobody:nobody /home/IaC

ENTRYPOINT ["/entrypoint.sh"]

USER nobody

CMD ["apply"]
