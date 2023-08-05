FROM amazoncorretto:11

ARG USER_ID
ARG GROUP_ID

# Java and Apache Tools
ENV ANT_HOME=/usr/local/ant
ENV MAVEN_HOME=/usr/local/maven
ENV PATH=${PATH}:${JAVA_HOME}/bin:${ANT_HOME}/bin:${MAVEN_HOME}/bin

# Version number for Apache Ant and Maven
ARG ANT_VERSION=1.10.13
ARG MAVEN_VERSION=3.9.4

RUN yum update -y
RUN yum install -y git jq tar rsync zip unzip awscli aspell gzip wget bzip2 which make gcc

RUN groupadd --force --gid ${GROUP_ID} hostGroup
RUN amazon-linux-extras install docker
RUN useradd -u ${USER_ID} -g ${GROUP_ID} -d /home/tools tools
RUN usermod -aG docker tools
RUN mkdir -p /usr/lib/jvm/
RUN curl -Lso /tmp/apache-ant.tar.gz https://downloads.apache.org/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz
RUN tar xzf /tmp/apache-ant.tar.gz -C /usr/local/
RUN mv /usr/local/apache-ant-${ANT_VERSION} ${ANT_HOME}
RUN curl -Lso /tmp/apache-maven.tar.gz https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
RUN tar xzf /tmp/apache-maven.tar.gz -C /usr/local/
RUN mv /usr/local/apache-maven-${MAVEN_VERSION} ${MAVEN_HOME}
# Download and install the English dictionary for Aspell
RUN wget http://ftp.gnu.org/gnu/aspell/dict/en/aspell6-en-2020.12.07-0.tar.bz2 \
    && tar xjf aspell6-en-2020.12.07-0.tar.bz2 \
    && cd aspell6-en-2020.12.07-0 \
    && ./configure \
    && make \
    && make install
# Cleanup
RUN yum remove -y wget bzip2 which make gcc 
RUN yum clean all
RUN rm -rf /tmp/*.tar.gz aspell6-en-2020.12.07-0 aspell6-en-2020.12.07-0.tar.bz2 /var/cache/yum

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod u+x /entrypoint.sh

WORKDIR /home/tools

COPY init.sh .
COPY clean-up.sh .
COPY docker/bashrc.sh .bashrc
COPY release.sh .
COPY create-bucket.sh .
COPY push.sh .
COPY secrets_scan.sh .
COPY common/IaC/ .

RUN chown -R tools /home/tools && \
    chmod -R u+x /home/tools/*.sh

RUN echo "$PATH" 
RUN echo $JAVA_HOME
RUN ls -la /usr/lib/jvm/
RUN type java && \
    type javac && \
    java --version && \
    mvn --version && \
    ant -version

ENTRYPOINT ["/entrypoint.sh"]

# USER tools
CMD ["--mode", "repl"]
