#!/bin/sh


source /opt/deploy/env/ruby-1.9.3/.envrc
cd /home/laxino/code/cms_rws
bundle exec ruby cronjob/approve_transaction.rb development

#source /opt/deploy/env/cms_rws/.envrc
#cd /opt/deploy/env/cms_rws/app_$1/current
#bundle exec ruby cronjob/approve_transaction.rb $1
