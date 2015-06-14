class InitSyncedEnv

  attr_reader :script_dir
  
  def initialize
    @script_dir = File.dirname(__FILE__)
  end
  
end

class InitWebapp

  def initialize env
    #puts "ENV['USER'] = #{ENV['USER']}, ENV['HOME'] = #{ENV['HOME']}, PATH=#{ENV['PATH']}"
    @env = env
deploy_cmd = <<EOC
cd ~/ &&
rm -fR tmp/* &&
ln -s ~/voyagex-synced tmp/voyagex &&
tar cfz tmp/voyagex.tgz voyagex/ &&
cd tmp/ &&
tar --keep-directory-symlink -x -z -f voyagex.tgz && 
cd ~/
EOC
    synced_readme = "#{ENV['HOME']}/voyagex-synced/README.md"
    #puts "synced_readme = #{synced_readme}"
    unless File.exist? synced_readme
      puts "deploying webapp to synced directory ..."
      system deploy_cmd
    end
    Dir.chdir "#{ENV['HOME']}/voyagex-synced"
  end

  def start_resque_worker
    resque_worker_pid = -`cat tmp/pids/resque-worker.pid`.to_i
    #puts "resque_worker_pid = #{resque_worker_pid}"
    ps = `ps aux | grep resque | grep #{-resque_worker_pid}`.split("\n")
    ps.each do |p|
      p_name = p.match(/[0-9]:[0-9]{2}\s([^\s]+)\s[^:]+$/)
      next if p_name[1] == 'grep' # resque-...
      #puts "p_name[1] = #{p_name[1]}, p = #{p}"
      resque_worker_pid = resque_worker_pid.abs unless p_name[1].match(/resque-/).nil?
    end
    if resque_worker_pid <= 0
      puts "starting resque-worker ..."
      system("RAILS_ENV=staging PIDFILE=./tmp/pids/resque-worker.pid BACKGROUND=yes TERM_CHILD=1 QUEUE=* rake environment resque:work")
    else
      puts "resque-worker up with pid #{resque_worker_pid} ..."
    end
    resque_scheduler_pid = -`cat tmp/pids/resque-scheduler.pid`.to_i
    #puts "resque_scheduler_pid = #{resque_scheduler_pid}"
    ps = `ps aux | grep resque | grep #{-resque_scheduler_pid}`.split("\n")
    ps.each do |p|
      p_name = p.match(/[0-9]:[0-9]{2}\s([^\s]+)\s[^:]+$/)
      next if p_name[1] == 'grep' # resque-scheduler-...
      #puts "p_name[1] = #{p_name[1]}, p = #{p}"
      resque_scheduler_pid = resque_scheduler_pid.abs unless p_name[1].match(/resque-scheduler-/).nil?
    end
    if resque_scheduler_pid <= 0
      puts "starting resque-scheduler ..."
      system("RAILS_ENV=staging PIDFILE=./tmp/pids/resque-scheduler.pid BACKGROUND=yes rake resque:scheduler")
    else
      puts "resque-scheduler up with pid #{resque_scheduler_pid} ..."
    end
  end

  def start_faye
    work_dir = `pwd`.strip
    #puts "work_dir = #{work_dir}, env.script_dir[#{@env.script_dir.class}] = #{@env.script_dir}"
    Dir.chdir @env.script_dir
    res = `./checkServer.sh`
    Dir.chdir work_dir
  end
  
end

#FileUtils.touch 'timestamp'
env = InitSyncedEnv.new
iw = InitWebapp.new env
iw.start_resque_worker
iw.start_faye
