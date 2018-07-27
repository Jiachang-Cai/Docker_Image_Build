#! /bin/bash

set -e

cd /home/app

gunicorn wsgi:application -c deploy/gunicorn.conf


