# OpenAPI Stub-Server (Mojolicious / Perl)

## Quick Start

```
sudo cpan YAML::Syck
sudo cpan Mojolicious
sudo cpan IO::Socket::SSL
sudo cpan LWP::UserAgent
sudo cpan LWP::Protocol::https
cd restful
vim lib/RESTful/Controller/Readme.pm

< modify outerUri >

hypnotoad script/restful
```

## nginx.conf

```
  upstream hypnotoad {
    server 127.0.0.1:6000;
  }
  location /ex {
    proxy_pass http://hypnotoad;
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
