# OpenAPI Stub-Server (Mojolicious / Perl)

## Quick Start

```
sudo cpan YAML::Syck
sudo cpan Mojolicious
sudo cpan IO::Socket::SSL
sudo cpan LWP::UserAgent
sudo cpan LWP::Protocol::https
sudo cpan Mojolicious::Plugin::BasicAuthPlus
cd restful
cp r_e_s_tful.conf.base r_e_s_tful.conf
vim r_e_s_tful.conf
mkdir yamls  (default, copy your openapi-yaml-files in the directory)
hypnotoad script/restful
```

## HTTP Request

```
wget https://example.com/ex/stub{/PATH/OF/OPENAPI/YAML/FILE.yaml}{/STUB'S/REQUEST/PATH}
```

## nginx.conf

```
  upstream hypnotoad {
    server 127.0.0.1:6000;
  }
  location /ex {
    return 302 /ex/;
  }
  location /ex/ {
    proxy_pass http://hypnotoad/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    #
    # no-cache
    #
    #sendfile off;
    #etag off;
    #add_header Cache-Control no-cache;
    #if_modified_since off;
  }
```

