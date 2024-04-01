FROM alpine:latest


ENV user=tunnel
# pass in ENV for dev purposes - should use secret 
ENV password=tunnel
ENV UID=14000
ENV GID=14000
ENV user_dir=/home/${user}

RUN mkdir -m 0755 -p "${user_dir}/files"

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

RUN apk update && apk upgrade && apk add \
                                     openssh \
                                     bash \
                                     expect \
                                     gnupg \
    && sed -i s/#PermitRootLogin.*/PermitRootLogin\ yes/ /etc/ssh/sshd_config \
    && echo "${user}:${password}" | chpasswd \
    && rm -rf /var/cache/apk/*

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY scripts/tunnel.exp ${user_dir}/tunnel.exp
COPY scripts/handle_keys.exp ${user_dir}/handle_keys.exp
COPY scripts/tunnel.sh ${user_dir}/tunnel.sh
COPY scripts/connect-user-dest-net1_net2.exp ${user_dir}/connect-user-dest-net1_net2.exp
COPY encryption/gen-key-encrypt-file.sh ${user_dir}/gen-key-encrypt-file.sh
COPY configs/.tconfig ${user_dir}/.tconfig
COPY configs/.config ${user_dir}/.config
COPY configs/.pconfig ${user_dir}/.pconfig

RUN chmod +x /docker-entrypoint.sh && \
    chmod +x ${user_dir}/tunnel.exp && \
    chmod +x ${user_dir}/handle_keys.exp && \
    chmod +x ${user_dir}/tunnel.sh && \
    chmod +x ${user_dir}/connect-user-dest-net1_net2.exp && \
    chmod +x ${user_dir}/gen-key-encrypt-file.sh && \
    chmod 0600 ${user_dir}/.tconfig && \
    chmod 0600 ${user_dir}/.config && \
    chmod 0600 ${user_dir}/.pconfig

RUN echo -e "jump\ndest" > ${user_dir}/files/passwords && \
    chmod 0400 ${user_dir}/files/passwords && \
    chown -R ${UID}:${GID} ${user_dir}

EXPOSE 22 

ENTRYPOINT ["/docker-entrypoint.sh"]