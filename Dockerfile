FROM alpine:3.7 as prep
      
RUN wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/archive/v4.25-9656-rtm.tar.gz \  
    && mkdir -p /usr/local/src \
    && tar -x -C /usr/local/src/ -f v4.25-9656-rtm.tar.gz \
    && rm v4.25-9656-rtm.tar.gz

FROM centos:7 as build

COPY --from=prep /usr/local/src /usr/local/src

RUN yum -y update \
    && yum -y groupinstall "Development Tools" \
    && yum -y install ncurses-devel openssl-devel readline-devel \
    && cd /usr/local/src/SoftEtherVPN_Stable-* \
    && ./configure \
    && make \
    && make install \
    && zip -r9 /artifacts.zip /usr/vpn* /usr/bin/vpn*

FROM centos:7

COPY --from=build /artifacts.zip /

COPY scripts /

RUN yum -y update \
    && yum -y install unzip iptables sysvinit-tools \
    && rm -rf /var/log/* /var/cache/yum/* /var/lib/yum/* \
    && chmod +x /entrypoint.sh /cert.sh \
    && unzip -o /artifacts.zip -d / \
    && rm /artifacts.zip \
    && rm -rf /opt \
    && ln -s /usr/vpnserver /opt \
    && find /usr/bin/vpn* -type f ! -name vpnserver \
       -exec sh -c 'ln -s {} /opt/$(basename {})' \;

WORKDIR /usr/vpnserver/

VOLUME ["/usr/vpnserver/server_log/"]

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 500/udp 4500/udp 1701/tcp 1194/udp 5555/tcp 443/tcp

CMD ["/usr/bin/vpnserver", "execsvc"]
