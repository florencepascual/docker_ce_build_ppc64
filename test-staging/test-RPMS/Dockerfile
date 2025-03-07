#docker build -t als_test_centos8 --build-arg DISTRO_NAME=centos --build-arg DISTRO_VER=8 .


ARG GOLANG_VERSION=1.15.2
ARG DISTRO_NAME
ARG DISTRO_VERS

FROM ppc64le/$DISTRO_NAME:$DISTRO_VERS

ARG GOLANG_VERSION
ARG DISTRO_NAME
ARG DISTRO_VERS

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace \
    TERM=xterm
ENV PATH /usr/local/go/bin:$PATH

RUN set -eux; yum -y install wget make gcc findutils procps-ng

#Install from Docekr-ce staging
RUN set -eux; yum install -y yum-utils &&\
yum-config-manager --add-repo https://download-stage.docker.com/linux/${DISTRO_NAME}/docker-ce-staging.repo &&\
yum -y install docker-ce docker-ce-cli containerd.io

##
#Docker in Docker inspired from
#  https://github.com/docker-library/docker/tree/master/20.10/dind
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
##
RUN set -eux; \
	groupadd --system dockremap; \
	adduser --system -g dockremap dockremap; \
	echo 'dockremap:165536:65536' >> /etc/subuid; \
	echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT ed89041433a031cafc0a0f19cfe573c31688d377

RUN set -eux; \
	wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
	chmod +x /usr/local/bin/dind;

RUN set -eux; \
	url="https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-ppc64le.tar.gz";\
    wget -O go.tgz "$url" --progress=dot:giga; \
    tar -C /usr/local -xzf go.tgz; \
    rm go.tgz; \
    go version;

COPY test_launch.sh /usr/local/bin

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["test_launch.sh"]
CMD []