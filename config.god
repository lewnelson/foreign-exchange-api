require "god"

base_dir = File.absolute_path(".")
processes_dir = "#{base_dir}/src/processes"
Dir.entries(processes_dir).each do |fname|
  next if fname.match(/^\.\.?$/)
  God.watch do |w|
    process_name = fname.gsub(/\.rb$/, "")
    w.env = {
      "REDIS_PATH" => ENV["REDIS_PATH"],
      "REDIS_URL" => ENV["REDIS_URL"],
      "DB_HOST" => ENV["DB_HOST"],
      "DB_UNAME" => ENV["DB_UNAME"],
      "DB_PASS" => ENV["DB_PASS"],
      "DB_PORT" => ENV["DB_PORT"],
      "RACK_ENV" => ENV["RACK_ENV"]
    }

    w.name = "process:#{process_name}"
    w.start = "ruby #{processes_dir}/#{fname}"
    w.log = "#{base_dir}/logs/#{process_name}.log"
    puts w.start
  end
end
