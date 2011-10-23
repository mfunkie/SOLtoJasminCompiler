def generateCode(tree)
  if(tree.value == nil && tree.children[0] == nil)
    return
  end
  if(tree.children[0].value == "let")
    if(tree.children[0].typeName == "Function")
      generateFunctionCode(tree)
    else
      generateLetCode(tree)
    end
  else
    i = 1
    while(i < tree.children.size())
      if(tree.children[i].value == nil)
        generateCode(tree.children[i]) 
        if(tree.children[i].Code != nil)
          code = "\t" + tree.children[i].Code
          @@code << code
        end
      else
        code = "\t" + tree.children[i].Code
        @@code << code
      end
      i += 1
    end
    if(tree.children[0].value == "while")
      generateWhileCode(tree.children[1]) 
    end
    code = "\t" + tree.children[0].Code
    @@code << code
  end
end

def generateLetCode(tree)
  if(tree.children[2].value == nil)
    generateCode(tree.children[2]) 
  end
  if(tree.children[2].Code != nil)
    code = "\t" + tree.children[2].Code
    @@code << code
  end
  code = "\t" + tree.children[1].Code
  @@code << code
  if(tree.children.size == 4)
    generateCode(tree.children[3])
    if(tree.children[3].Code != nil)
      code = "\t" + tree.children[3].Code
      @@code << code
    end
  end
end

def generateFunctionCode(tree) #goes node 1 code, node 2 code, then node 0 code, then add it to @@codeAfter
  thisMethodCode = ["\n"+tree.children[1].Code]
  if(tree.children[2].value == nil)
    oldCode = Array.new(@@code)
    @@code = [""]
    generateCode(tree.children[2]) 
    @@code.each { |line|
      thisMethodCode << line
      thisMethodCode << "\n"
    }
    @@code = Array.new(oldCode)
  end
  if(tree.children[2].Code != nil)
    code = "\n\t" + tree.children[2].Code
    thisMethodCode << code
  end
  thisMethodCode << tree.children[0].Code
  if(tree.children.size == 4)
    generateCode(tree.children[3])
    if(tree.children[3].Code != nil)
      code = "\t" + tree.children[3].Code
      @@code << code
    end
  end
  @@prologue << thisMethodCode
end

def generateWhileCode(tree)
  if(tree.value == nil && tree.children[0] == nil)
    return
  end
  i = 1
  while(i < tree.children.size())
    if(tree.children[i].value == nil)
      generateCode(tree.children[i]) 
      if(tree.children[i].Code != nil)
        code = "\t" + tree.children[i].Code
        @@code << code
      end
    else
      code = "\t" + tree.children[i].Code
      @@code << code
    end
    i += 1
  end
  if(tree.children[0].value == "while")
    generateWhileCode(tree.children[1]) 
  end
  if(tree.children.size != 1)
    code = String.new("\t" + tree.children[0].Code)
    #Some crazy hacks goin on to get rid of the rest of the label code
    if(code.index("label") == nil) # We're working with an integer
      code = String.new(code + "\n\t" +  tree.Code)
    end
    newCode = code.slice(0..code.index("label")+4)
    restOfLabel = code.slice(code.index("label")+5..-1)
    restOfLabel.slice!(restOfLabel.index("\n")..-1)
    newCode += restOfLabel
    @@code << newCode
  else(tree.typeName == "Boolean")
    #More Crazy Hacks
    @@code << "\t" + tree.children[0].Code
    moreCode = String.new("\t" + tree.Code.lstrip)
    moreCode.slice!(tree.Code.lstrip.index("\n")+1..-1)
    @@code << moreCode
  end
end

def createJasminFile()
  jasminFile = File.open(@@fileName, "w")
  jasmineFile = ""
  @@code[0].gsub!(/['X']/, @@className)
  @@code[3].gsub!(/['Y']/, @@stackSize.to_s)
  @@localCounter += 3
  @@code[3].gsub!(/['Z']/, @@localCounter.to_s)
  @@code << @@codeAfter
  @@code.each{ |line|
    jasminFile << line
    jasminFile << "\n"
  }
  @@prologue.each{ |pline|
    jasminFile << pline
    jasminFile << "\n"
  }
  #jasminFile.gsub!("INTEGERSTORECONSTANT", @@localCounter.to_s)
  #jasminFile.gsub!("FLOATSTORECONSTANT", (@@localCounter-1).to_s)
  #jasminFile << jasmineFile
  
end