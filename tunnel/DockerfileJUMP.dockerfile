FROM alpine:latest

ENV user=jump
# pass in ENV for dev purposes - should use secret 
ENV password=jump
ENV UID=15000
ENV GID=15000
ENV user_dir=/home/${user}

RUN mkdir -m 0755 -p ${user_dir}

RUN addgroup -S "${GID}" && \
    adduser \
        -G "${GID}" \
        --disabled-password \
        --gecos "" \
        --home "${user_dir}" \
        --ingroup "${GID}" \
        --no-create-home \
        --uid "${UID}" \
        "${user}"

RUN apk update && apk upgrade && apk add openssh bash expect \
    && sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config \
    && sed -i s/AllowTcpForwarding.*/AllowTcpForwarding\ yes/ /etc/ssh/sshd_config \
    && echo "${user}:${password}" | chpasswd \	
    && rm -rf /var/cache/apk/*

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh
RUN chown -R ${UID}:${GID} ${user_dir}

EXPOSE 22 

CMD ["tcpdump", "-i", "eth0"]
ENTRYPOINT ["/docker-entrypoint.sh"]