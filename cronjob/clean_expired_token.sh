#!/bin/sh
source /opt/deploy/env/cms_rws/.envrc
ruby /opt/deploy/env/cms_rws/app_$1/current/cronjob/clean_expired_token.rb $1
