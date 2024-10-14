# DNS-Proxy
on-permise dns proxy seting on docker

this document created by GPT!


مراحل ساخت Docker Image برای سرویس DNS هوشمند

۱. تنظیمات پایه Dockerfile

ابتدا یک فایل Dockerfile بسازید که شامل نصب و راه‌اندازی ابزارهایی مثل BIND و dnsdist باشد. این فایل همچنین باید پیکربندی‌ها را بر اساس ورودی‌های محیطی (environment variables) انجام دهد.

Dockerfile
```
# Use an official Ubuntu base image
FROM ubuntu:20.04

# Install dependencies (BIND, dnsdist, dnsmasq)
RUN apt-get update && apt-get install -y \
    bind9 bind9utils bind9-doc \
    dnsdist dnsmasq \
    && apt-get clean

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
```
۲. پیکربندی DNS سرور (BIND)

پیکربندی BIND به گونه‌ای است که DNS سرور فقط درخواست‌های خاص (مثلاً سایت‌های فیلتر شده) را از طریق پراکسی عبور دهد. فایل named.conf را بر اساس نیاز خود تنظیم کنید.

named.conf:
```
options {
    directory "/var/cache/bind";

    forwarders {
        8.8.8.8;  // Google DNS
        1.1.1.1;  // Cloudflare DNS
    };

    // Allow queries only from specific IP addresses (from allowed-ips.txt)
    allow-query { 
        include "/etc/allowed-ips.txt";
    };

    dnssec-validation auto;
    listen-on-v6 { any; };
};

zone "example.com" {
    type forward;
    forwarders { your_proxy_ip; };
};

include "/etc/sites-proxy-list.txt";
```

۳. تنظیم dnsdist برای پراکسی DNS

فایل dnsdist به شما امکان می‌دهد درخواست‌های DNS خاص را به سرور پراکسی ارسال کنید. فایل dnsdist.conf را برای تعریف قوانین مسیریابی تنظیم کنید.

dnsdist.conf:

```
newServer("8.8.8.8")  -- Main DNS server (Google DNS)
newServer("1.1.1.1")  -- Backup DNS server (Cloudflare DNS)

-- Load the list of sites to proxy from sites-proxy-list.txt
local proxySites = {}
for line in io.lines("/etc/sites-proxy-list.txt") do
  table.insert(proxySites, line)
end

-- Forward specific domains to the proxy
for i, site in ipairs(proxySites) do
  addAction(RegexpRule(site), PoolAction("proxyPool"))
end

-- Define a pool for proxying requests
newServer({address="your_proxy_ip", pool="proxyPool"})
```

۴. پیکربندی ورودی‌های Docker برای سایت‌ها و IPهای مجاز

شما می‌توانید لیست سایت‌هایی که باید از پراکسی عبور کنند و IPهای مجاز را در فایل‌های جداگانه‌ای ذخیره کنید و هنگام ساخت ایمیج، این فایل‌ها را به کانتینر منتقل کنید.

allowed-ips.txt

لیست IPهایی که به سرویس DNS دسترسی دارند.

allowed-ips.txt:

```
10.0.0.0/8;
sites-proxy-list.txt: لیست دامنه‌هایی که باید از پراکسی عبور کنند.
```

sites-proxy-list.txt:
```
gitlab.com
github.com
docker.io
node.org
```

۵. اسکریپت شروع (start.sh)

برای شروع خودکار سرویس‌ها داخل کانتینر، یک اسکریپت start.sh بسازید که BIND و dnsdist را اجرا کند.

start.sh:

```
#!/bin/bash

# Start BIND DNS Server
service bind9 start

# Start dnsdist
dnsdist -C /etc/dnsdist/dnsdist.conf

# Keep the container running
tail -f /dev/null
```
۶. ساخت و اجرای Docker Image

حالا می‌توانید Docker Image خود را بسازید و اجرا کنید:

ساخت ایمیج:

```
docker build -t smart-dns-proxy .
```
اجرای کانتینر:

```
docker run -d --name smart-dns-container -p 53:53/udp -p 53:53/tcp smart-dns-proxy
```
۷. اضافه کردن امنیت (محدود کردن دسترسی)
در فایل named.conf، IPهایی که اجازه دسترسی به سرور DNS دارند از طریق فایل allowed-ips.txt تعریف می‌شوند. اگر ترافیک زیادی دارید یا می‌خواهید دسترسی محدودتری ایجاد کنید، می‌توانید از فایروال‌های سرور نیز برای محدود کردن دسترسی به پورت 53 استفاده کنید.

بهینه‌سازی‌ها:
کش DNS: می‌توانید کش کردن درخواست‌های DNS را فعال کنید تا درخواست‌های تکراری سرعت بالاتری داشته باشند.
ایجاد Rate Limiting: با استفاده از dnsdist، می‌توانید محدودیت نرخ برای درخواست‌های DNS تنظیم کنید تا از حملات DDoS جلوگیری شود.

TODO:

[-] rate limitation

[-] all domain proxy
