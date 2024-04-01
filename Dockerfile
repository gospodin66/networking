FROM alpine:3.14

ENV user=tunneller
# pass in ENV for dev purposes - should use secret 
ENV password=tunneller
ENV UID=8922
ENV GID=8922
ENV user_dir=/home/${user}

RUN set -ex; \
    apk update && \
    apk add openssh \
            net-tools \
            iptables \
            tcpdump \
            openrc \
            bash

RUN rc-update add sshd
RUN set -ex; addgroup -S "${GID}" && \
    adduser \
    -G "${GID}" \
    --disabled-password \
    --gecos "" \
    --home "${user_dir}" \
    --ingroup "${GID}" \
    --uid "${UID}" \
    "${user}"

RUN mkdir -p /var/run/sshd \
 && mkdir -p -m 700 ${user_dir}/.ssh \
 && mkdir -p -m 700 /root/.ssh \
 && touch /root/.ssh/known_hosts \
 && touch /root/.ssh/authorized_keys \
 && touch ${user_dir}/.ssh/known_hosts \
 && touch ${user_dir}/.ssh/authorized_keys

COPY ./docker-entrypoint-ssh-keygen.sh /usr/local/bin/docker-entrypoint-ssh-keygen.sh
COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY ./configs/ssh_config /etc/ssh/ssh_config
COPY ./configs/sshd_config /etc/ssh/sshd_config

RUN chmod +x /usr/local/bin/docker-entrypoint-ssh-keygen.sh; \
    chmod +x /usr/local/bin/docker-entrypoint.sh; \
    chmod 600 /etc/ssh/ssh_config; \
    chmod 600 /etc/ssh/sshd_config; \
    chmod 600 /root/.ssh/known_hosts; \
    chmod 600 /root/.ssh/authorized_keys; \
    chmod 600 ${user_dir}/.ssh/known_hosts; \
    chmod 600 ${user_dir}/.ssh/authorized_keys; \
    chown -R ${UID}:${GID} ${user_dir}

RUN echo -n "${user}:${password}" | chpasswd \
 && echo -n "root:root" | chpasswd

EXPOSE 22

CMD ["tcpdump", "-i", "eth0"]

ENTRYPOINT ["docker-entrypoint.sh"]