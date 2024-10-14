# Use an official Ubuntu base image
FROM ubuntu:20.04

# Set environment variable to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (BIND, dnsdist, dnsmasq)
RUN apt-get update && apt-get install -y \
    tzdata \
    bind9 bind9utils bind9-doc \
    dnsdist dnsmasq \
    && apt-get clean

# Set default timezone (e.g., Europe/London)
RUN ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

# Copy configuration files
COPY ./named.conf /etc/bind/named.conf
COPY ./dnsdist.conf /etc/dnsdist/dnsdist.conf
COPY ./allowed-ips.txt /etc/allowed-ips.txt
COPY ./sites-proxy-list.txt /etc/sites-proxy-list.txt

# Expose necessary ports (DNS: 53)
EXPOSE 53/udp
EXPOSE 53/tcp

# Start services
CMD ["bash", "/start.sh"]

