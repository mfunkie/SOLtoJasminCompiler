#!/usr/bin/ruby
require 'parser'
require 'typecheck'
require 'codeGen'

def printPreTraversalTreeTypes(spaces, tree)
  if tree.value == nil
    tree.children.each { |child| printPreTraversalTreeTypes(spaces+2, child) }
  else
    numSpaces = "-"*spaces
    puts numSpaces + "> " + tree.to_s ##.value.to_s
  end
end

def printPreTraversalTree(spaces, tree)
  if tree.value == nil
    tree.children.each { |child| printPreTraversalTree(spaces+2, child) }
  else
    numSpaces = "-"*spaces
    puts numSpaces + "> " + tree.value.to_s
  end
end

def printStatement(tree)
  statement = ""
  if tree.value == nil
    statement += "["
    tree.children.each { |child| 
      statement += printStatement(child) 
    }
    statement += "]"
  else
    statement += tree.value.to_s.chomp + " " ##.value.to_s
  end
  return statement
end

def treeSize(tree)
  if tree.value == nil
    tree.children.each { |child| treeSize(child) }
  else
    @@stackSize += 1
  end
end


def driver()

  @@className = ARGV[0] 
  @@className = @@className[0..@@className.index('.')-1] #Removing stuff behind . so Jasmin doesnt get confused
  @@fileName = @@className + ".j"

  thisfile = File.open(ARGV[0])
  trees = parseA(thisfile)
  i = 1
  puts "\n"
  if(@@errorList.empty?)
    trees.each{ |tree|
      returnType = typeCheck(tree)
      if(@@errorList.empty?)
        generateCode(tree)
        treeSize(tree)
      else
        puts "There were some errors in statement " + printStatement(tree)
        @@errorList.each{ |error|
          puts error + "\n"
        }
        puts "\n"
      end
      @@errorList = []
    }
  else
    puts "Error, could not compile"
    @@errorList.each{ |error|
      puts error + "\n"
    }
    return
  end
  puts "\n"
  createJasminFile()
  
end

##Call driver
driver()