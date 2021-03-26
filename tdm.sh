#!/bin/sh

set -ex

exec gunicorn --bind 0.0.0.0:5000 tdm:app
