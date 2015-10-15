#!/bin/sh
source /opt/deploy/env/cms_rws/.envrc
cd /opt/deploy/env/cms_rws/app_$1/current
bundle exec ruby cronjob/clean_expired_token.rb $1
