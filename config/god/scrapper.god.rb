app_path = '/srv/www/photo-scrapper/current'
num_workers = 1

God.pid_file_directory = '/home/ubuntu/god/pids'
 
num_workers.times do |num|
  God.watch do |w|
    w.name          = "scrapper-#{num}"
    w.group         = 'scrapper'
    w.interval      = 30.seconds
    w.env           = {}
    w.dir           = app_path
    w.start         = "bundle exec ruby #{app_path}/scrappers/run_scrapping.rb"
    w.start_grace   = 10.seconds
    w.log           = File.join(app_path, 'log', 'scrapper.log')
 
    # restart if memory gets too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.above = 220.megabytes
        c.times = 2
      end
    end
 
    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end
 
    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
      end
 
      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
      end
    end
 
    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end