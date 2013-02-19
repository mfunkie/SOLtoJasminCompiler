def generateCode(tree)

  if tree.value.nil? && tree.children[0].nil?
    return
  end
  
  if(tree.children[0].value == "let")
    if(tree.children[0].typeName == "Function")
      generateFunctionCode(tree)
    else
      generateLetCode(tree)
    end
    return
  end

  tree.children.each_index do |i|
    next if i == 0
    generateCode(tree.children[i]) if tree.children[i].value.nil?
    addTreeChildCode(tree, i) unless tree.children[i].Code.nil?
  end

  generateWhileCode(tree.children[1]) if tree.children[0].value == "while"
     
  addTreeChildCode(tree, 0)
end

def generateLetCode(tree)
  if tree.children[2].value.nil?
    generateCode(tree.children[2]) 
  end

  addTreeChildCode(tree, 2) unless tree.children[2].Code.nil?
  addTreeChildCode(tree, 1)

  if(tree.children.size == 4)
    generateCode(tree.children[3])
    addTreeChildCode(tree, 3) unless tree.children[3].Code.nil?
  end
end

def generateFunctionCode(tree) #goes node 1 code, node 2 code, then node 0 code, then add it to @@codeAfter

  thisMethodCode = "\n#{tree.children[1].Code}"

  if tree.children[2].value.nil?
    # Store old code so that we can reset it after we "generateCode"
    # on the third child, because that will add code to @@code
    # that we will want to add to the prologue instead of the current
    # place in code.

    oldCode = Array.new(@@code)
    @@code = [""]
    generateCode(tree.children[2]) 
    @@code.each { |line|
      thisMethodCode << line
      thisMethodCode << "\n"
    }
    @@code = Array.new(oldCode)
  end

  unless tree.children[2].Code.nil?
    thisMethodCode << "\n\t#{tree.children[2].Code}"
  end

  thisMethodCode << tree.children[0].Code
  if(tree.children.size == 4)
    generateCode(tree.children[3])
    addTreeChildCode(tree, 3) unless tree.children[3].Code.nil?
  end
  @@prologue << thisMethodCode
end

def generateWhileCode(tree)

  if tree.value.nil? && tree.children[0].nil?
    return
  end

  tree.children.each_index do |i|
    next if i == 0
    generateCode(tree.children[i]) if tree.children[i].value.nil?
    addTreeChildCode(tree, i) unless tree.children[i].Code.nil?
  end

  generateWhileCode(tree.children[1]) if tree.children[0].value == "while"

  if(tree.children.size != 1)
    code = "\t#{tree.children[0].Code}"
    #Some crazy hacks goin on to get rid of the rest of the label code
    code = "#{code}\n\t#{tree.Code}" if code.index("label").nil? # We're working with an integer

    newCode = code.slice(0..code.index("label")+4)
    restOfLabel = code.slice(code.index("label")+5..-1)
    restOfLabel.slice!(restOfLabel.index("\n")..-1)
    newCode += restOfLabel
    @@code << newCode
  else(tree.typeName == "Boolean")
    #More Crazy Hacks
    addTreeChildCode(tree, 0)
    moreCode = String.new("\t" + tree.Code.lstrip)
    moreCode.slice!(tree.Code.lstrip.index("\n")+1..-1)
    @@code << moreCode
  end
end

def addTreeChildCode(tree, child_index)
  @@code << "\t#{tree.children[child_index].Code}"
end

def createJasminFile()

  @@code[0].gsub!(/['X']/, @@className)
  @@code[3].gsub!(/['Y']/, @@stackSize.to_s)
  @@localCounter += 3
  @@code[3].gsub!(/['Z']/, @@localCounter.to_s)
  @@code << @@codeAfter

  File.open(@@fileName, "w") { |jasminFile|
    @@code.each{ |line|
      jasminFile << line
      jasminFile << "\n"
    }
    @@prologue.each{ |pline|
      jasminFile << pline
      jasminFile << "\n"
    }
  }
  
end