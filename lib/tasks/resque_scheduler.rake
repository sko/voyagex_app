#PIDFILE=./tmp/pids/resque-scheduler.pid BACKGROUND=yes rake resque:scheduler
#RAILS_ENV=stage PIDFILE=./tmp/pids/resque-scheduler.pid BACKGROUND=yes rake resque:scheduler
#require 'resque/tasks'
require 'resque/scheduler/tasks'

task "resque:setup" => :environment
task "resque:scheduler_setup" => :environment

task "jobs:work" => "resque:scheduler"
