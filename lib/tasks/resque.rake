#PIDFILE=./tmp/pids/resque-worker.pid BACKGROUND=yes QUEUE=* rake environment resque:work
require 'resque/tasks'

task "resque:setup" => :environment do
  ENV['QUEUE'] = '*'
end
