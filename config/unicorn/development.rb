rails_root = '/var/www/stretcher_app'

ENV['BUNDLE_GEMFILE'] = "#{rails_root}/current/Gemfile"

worker_processes 2
working_directory "#{rails_root}/current"

timeout 30

stderr_path 'log/unicorn_stderr.log'
stdout_path 'log/unicorn_stderr.log'

listen 8080
pid "#{rails_root}/current/tmp/pids/unicorn.pid"
preload_app true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
      ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
