require 'rake'

task :clean do
    rm_f Dir.glob("*.j")
    rm_f Dir.glob("*.out")
    rm_f Dir.glob("*.class")
    sh "ls"
end

task :verifyJasmin do
    #Will implement when I have a version higher than 1.8.7 to test with
    #if !File.Exists?("jasmin.jar")
    #    puts "Please download Jasmin from http://jasmin.sourceforge.net before continuing"
    #end
end

task :run, :verbosity do |t, args|
    if args.verbosity == nil || args.verbosity != "low" 
        sh "cat stutest.in"
    end

    if ENV["file"] != nil
        fileToBuild = ENV["file"]
    else
        fileToBuild = "stutest.in"
    end

    ruby "driver.rb #{fileToBuild}"

    sh "java -jar jasmin.jar stutest.j"
    sh "java stutest > stutest.out"
    sh "cat stutest.out"
end

task :buildAndRun => :verifyJasmin do

    if ENV["file"] != nil
        fileToBuild = ENV["file"]
    else
        fileToBuild = "stutest.in"
    end
    
    ruby "driver.rb #{fileToBuild}"

    sh "java -jar jasmin.jar stutest.j"
    sh "java stutest > stutest.out"
    puts "Results in stutest.out"

end

task :default => :buildAndRun
