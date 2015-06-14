#!/bin/bash

source ~/.profile
ruby ~/voyagex/script/voyagex_on_vagrant.rb >>~/voyagex-synced/log/cron.log 2>&1

exit 0
