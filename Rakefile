require 'rake'

task :clean do
    rm_f Dir.glob("*.j")
    rm_f Dir.glob("*.out")
    rm_f Dir.glob("*.class")
    rm_f Dir.glob("*~")
    sh "ls -G"
end

task :verifyJasmin do
    if !File.exist?("jasmin.jar")
        puts "Please download Jasmin from http://jasmin.sourceforge.net before continuing"
    end
end

task :run, :verbosity do |t, args|
    if args.verbosity == nil || args.verbosity != "low" 
        sh "cat stutestNoErrors.in"
    end

    if ENV["file"] != nil
        fileToBuild = ENV["file"]
    else
        fileToBuild = "stutestNoErrors.in"
    end

    ruby "driver.rb #{fileToBuild}"

    sh "java -jar jasmin.jar stutestNoErrors.j"
    sh "java stutestNoErrors > stutest.out"
    sh "cat stutest.out"
end

task :buildAndRun => :verifyJasmin do

    if ENV["file"] != nil
        fileToBuild = ENV["file"]
    else
        fileToBuild = "stutestNoErrors.in"
    end
    
    ruby "driver.rb #{fileToBuild}"

    sh "java -jar jasmin.jar stutestNoErrors.j"
    sh "java stutestNoErrors > stutest.out"
    puts "Results in stutest.out"

end

task :default => :buildAndRun
