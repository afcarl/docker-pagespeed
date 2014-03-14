docker-pagespeed
================

Sample Dockerfile and Nginx configuration to run nginx + ngx_pagespeed.

Build an image with::

    % sudo docker build -t="nginx-pagespeed" -no-cache .

And start it with::

    % sudo docker run -p 80:80 -i -t \
    -v ~/sites-enabled:/etc/nginx/sites-enabled \
    -v ~/logs:/var/log/nginx \
    -v ~/media:/var/www/media \
    -v ~/static:/var/www/static \
    -v ~/run/gunicorn:/var/run/gunicorn \
    nginx-pagespeed

For debugging & playing with nginx config on the image, do the above command but add ``/bin/bash`` at the end (and possibly host port mapping).
