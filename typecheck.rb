def typeCheck(tree)
  if tree.value.nil? && tree.children[0].nil?
    return "NULL"
  end

  if(tree.value == nil && tree.children[0].typeName == nil) 
     if tree.children.length > 1
       @@errorList << "Found statement, expected Operator"
       return nil
     end
     # We have to go deeper
     return typeCheck(tree.children[0])
  end

  if(tree.children[0].typeName == "Keyword" || 
     tree.children[0].typeName == "Boolean" || 
     tree.children[0].typeName == "Write"   ||
     tree.children[0].typeName == "Variable")
    # Unless special case type for functions
    unless (tree.children[0].typeName == "Variable" && tree.children.size > 1)
      return specialTypeCheck(tree)
    end
  end

  if(@@symbolTable[tree.children[0].typeName].nil? && tree.children[0].typeName != "Variable")
    @@errorList << "Found " + tree.children[0].typeName + " Expected Operator"
    return nil
  end

  lookupName = tree.children[0].value
  i = 1

  while(i < tree.children.size())
    if tree.children[i].value.nil?
      type = typeCheck(tree.children[i])
      tree.children[i].setReturnType(type)
    else
      type = tree.children[i].typeName

      if(@@symbolTable["Code"][tree.children[i].typeName] != nil)

        value = @@symbolTable["Code"][tree.children[i].typeName]["Value"]
        code =  String.new(@@symbolTable["Code"][tree.children[i].typeName]["Code"])

        if(tree.children[i].typeName == "Boolean")
          # Translate true value to numeric for special boolean case
          thisValue = tree.children[i].value == "true" ? 1 : 0
          code.gsub!(/['X']/, thisValue.to_s)
        else
          code.gsub!(/['X']/, tree.children[i].value.to_s)
        end

        tree.children[i].setCode(code)
      else
        if (tree.children[i].typeName != "Variable")
          @@errorList << "Error: No code for " + tree.children[i].typeName
          return nil
        end

        codeAndType = varCheck(tree.children[i])

        if(codeAndType == nil)
          @@errorList << "Error: Variable or Function " + tree.children[i].value + " does not exist in this context."
          return nil
        end

        type = codeAndType["type"]

        if(codeAndType["loadCode"] == nil)
          if(tree.children[0].value == ":=")
            # Bide our time, no code needs to be made
            type = "Function"
          else
            @@errorList << "Error: Incorrect Use of Function"
            return nil
          end
        else
          code = String.new(codeAndType["loadCode"])
          tree.children[i].setTypeName(type)
          tree.children[i].setCode(code)
          if(i == 1 && tree.children[0].value == ":=")
            storageType = codeAndType["storeCode"]
            loadingType = codeAndType["loadCode"]
          end
        end
      end
    end

    if type.nil?
      @@errorList << "Error in Subtree: Returning Error"
      return nil
    end

    lookupName += type
    i += 1
  end

  if(lookupName == ":=FunctionFunction")
    functName = tree.children[1].value
    codeAndType1 = varCheck(tree.children[1])
    codeAndType2 = varCheck(tree.children[2])
    levelOfFunct = codeAndType1["currentLevel"].to_i
    if(codeAndType1["signature"] != codeAndType2["signature"])
      @@errorList << "Functions signatures do not match, cannot assign"
      return nil
    else
      oldArguments = String.new(codeAndType1["arguments"])
      @@variableTable[levelOfFunct][functName] = Hash.new(codeAndType2)

      #I hate ruby's quirks
      @@variableTable[levelOfFunct][functName] = @@variableTable[levelOfFunct][functName]["ANYTHINGCANGOHERE"]

      ## For calling function need new argument "signature"
      @@variableTable[levelOfFunct][functName]["arguments"]=String.new(oldArguments)
      tree.children[0].setCode("")
      tree.children[1].setCode("")
      tree.children[2].setCode("")
      return "Function"
    end
  end

  if(tree.children[0].typeName == "Variable")
    thisFunction = varCheck(tree.children[0])
    
    if thisFunction.nil?
      @@errorList << "Error: Function " + tree.children[0].value + " does not exist in this context."
      return nil
    end
    
    returnType = thisFunction["type"] #code is under call
    
    if thisFunction["call"].nil?
      @@errorList << "Found Variable, Expected Function"
      return nil
    end
    
    tree.children[0].setCode(thisFunction["call"])
    if(lookupName != thisFunction["arguments"])
      @@errorList << "Incorrect arguments for function"
      @@errorList << "Found: #{lookupName}"
      @@errorList << "Expected: #{thisFunction["arguments"]}"
      return nil
    end
  else
    returnType = @@symbolTable[tree.children[0].typeName][lookupName]
  end

  #Unary Minus
  if(lookupName == "+Integer" || lookupName == "-Integer" ||
     lookupName == "+Float"   || lookupName == "-Float")
     oldCode = tree.children[1].Code
     loadType = tree.children[1].typeName == "Integer" ? "ldc 0" : "ldc 0.0"
     newCode = "#{loadType}\n\t#{oldCode}"
     tree.children[1].setCode(newCode)
   end
  
  #Set conversion codes
  if returnType.nil?
    @@errorList << "Return Type is Nil, Returning Error"
    @@errorList << "No Rule for " + lookupName
    return returnType
  end

  tree.setTypeName(returnType)
  codeType = "" + tree.children[0].value + tree.typeName
  
  #### SPECIAL BOOLEAN CASE ####
  if(returnType == "Boolean")
    boolCode = @@symbolTable["BooleanCode"][lookupName]
    boolCode += @@symbolTable["BooleanCode"]["Default"]
    thisBoolCode = String.new(boolCode)

    ## Set Labels Unique
    thisBoolCode.gsub!(/['X']/, @@labelCounter.to_s)
    @@labelCounter += 1
    thisBoolCode.gsub!(/['Y']/, @@labelCounter.to_s)
    @@labelCounter += 1
    thisBoolCode.gsub!(/['Z']/, @@labelCounter.to_s)
    @@labelCounter += 1

    thisBoolCode = "#{tree.children[0].Code}\n\t#{thisBoolCode}" if tree.children[0].typeName == "Variable"
    
    tree.children[0].setCode(thisBoolCode)
  else
    if(storageType != nil)  # := case
      tree.children[1].setCode("")
      tree.children[0].setCode(storageType)
      tree.setCode(loadingType)
    else
      if(tree.children[0].typeName != "Variable")
        unless @@symbolTable["Code"][codeType].nil?
          tree.children[0].setCode(@@symbolTable["Code"][codeType])
        else
          @@errorList << "Error: No Code found for " + codeType
          @@errorList << "Attempted assignment without variable"
        end
      end
    end
  end
  i = 1
  
  ## Special rules for ^ because it only takes doubles but we want to return float
  if(returnType != "Boolean" and tree.children[0].typeName != "Variable")
    convertDouble = tree.children[0].value == "^"
    
    tree.children.each_index do |i|
      next if i == 0 # i starts at 1
      
      if convertDouble
        conversion = tree.children[i].typeName + "Double"
      elsif ( tree.children[i].typeName != tree.typeName && tree.typeName != "String")
        conversion = tree.children[i].typeName + tree.typeName
      else
        next
      end
        
      codeAdd = @@symbolTable["Conversion"][conversion]
      newCode = tree.children[i].Code.nil? ? codeAdd : "#{tree.children[i].Code}\n\t#{codeAdd}"

      tree.children[i].setCode(newCode)
      
    end

  elsif(tree.children.size == 3 and tree.children[0].typeName != "Variable")

    childLookup = tree.children[1].typeName + tree.children[2].typeName

    if(@@symbolTable["BoolConversion"][childLookup] != nil)
      if(lookupName == "&IntegerInteger" || lookupName == "|IntegerInteger" || childLookup != "IntegerInteger")
        
        tree.children.each_index do |i|
          next if i == 0 # i starts at 1

          childChange = @@symbolTable["BoolConversion"][childLookup]["child#{i}"]
          unless childChange.nil?
            newCode = tree.children[i].Code.nil? ? "#{childChange}" : "#{tree.children[i].Code}\n\t#{childChange}"
            newCode.gsub!(/['X']/, @@labelCounter.to_s)
            @@labelCounter += 1
            newCode.gsub!(/['Y']/, @@labelCounter.to_s)
            @@labelCounter += 1
            newCode.gsub!(/['Z']/, @@labelCounter.to_s)
            @@labelCounter += 1
            tree.children[i].setCode(newCode)
          end
        end
      end
    end
  end

  return returnType

end


def specialTypeCheck(tree)
  if(tree.children[0].typeName == "Keyword")
    return typeCheckKeyword(tree)
  end
  
  if(tree.children[0].typeName == "Write")
    return typeCheckWrite(tree)
  end
  
  if(tree.children[0].typeName == "Boolean")
    if(tree.children.size > 1)
      @@errorList << "Error: Too many arguments for Boolean"
      return nil
    end

    code = String.new(@@symbolTable["Code"]["Boolean"]["Code"])

    thisValue = tree.children[0].value == "true" ? 1 : 0

    code.gsub!(/['X']/, thisValue.to_s)

    tree.children[0].setCode(code)
    tree.setCode("")
    tree.setTypeName("Boolean")
    return "Boolean"
  end
  
  if tree.children[0].typeName == "Variable"

    codeAndType = varCheck(tree.children[0])
    if codeAndType.nil?
      @@errorList << "Error: Variable or Function " + tree.children[0].value + " does not exist in this context."
      return nil
    end

    type = codeAndType["type"]
    if(type != "Boolean" && codeAndType["call"].nil?)
      @@errorList << "Error: Variable cannot exist in location unless Boolean or function"
      return nil
    end

    tree.children[0].setTypeName(type)

    unless codeAndType["call"].nil?
      code = String.new(codeAndType["call"])
      tree.children[0].setCode(code)
      tree.setCode("")
      tree.setTypeName(type)
      return "Variable"

    else
      code = String.new(codeAndType["loadCode"])
      tree.children[0].setCode(code)
      tree.setCode("")
      tree.setTypeName("Boolean")
      return "Boolean"
    end
  end

end

def typeCheckKeyword(tree)
  case tree.children[0].value
    when "while"
      return typeCheckWhile(tree)
    when "if"
      return typeCheckIfStatement(tree)
    when "begin"
      return typeCheckBegin(tree)
    when "let"
      return typeCheckLet(tree)
  end
end

def typeCheckWhile(tree)
  if tree.children.size != 3
    @@errorList << "Error: In While Statement, incorrect number of arguments"
    @@errorList << "Correct Usage: while [bool or integer] [loop]"
    return nil
  end

  whileLabelX = @@labelCounter
  @@labelCounter += 1
  whileLabelY = @@labelCounter
  @@labelCounter += 1
  

  unless tree.children[1].value.nil?
    @@errorList << "Error: No Brackets around Boolean"
    @@errorList << "Correct Usage: while [bool or integer] [loop]"
    return nil
  end

  type = typeCheck(tree.children[1])
  if(type != "Boolean" && type != "Integer")
    @@errorList << "Error: In While Statement, didnt find boolean or integer where expected"
    return nil
  end
  
  codeAdd = @@symbolTable["whileCode"]["Bool"]
  
  thisCodeAdd = String.new(codeAdd)
  thisCodeAdd.gsub!(/['X']/, whileLabelX.to_s)
  thisCodeAdd.gsub!(/['Y']/, whileLabelY.to_s)

  newCode = tree.children[1].Code.nil? ? thisCodeAdd : "#{tree.children[1].Code}\n\t#{thisCodeAdd}"

  tree.children[1].setCode(newCode)

  unless tree.children[2].value.nil?
    @@errorList << "Error: No Brackets around loop"
    @@errorList << "Correct Usage: while [bool or integer] [loop]"
    return nil
  end
  
  ## We dont need type of while but we do need to type check it
  @@currentLevel += 1

  @@variableTable[@@currentLevel] = {} if @@variableTable[@@currentLevel].nil?

  type = typeCheck(tree.children[2])
  
  unless type.nil?
    code = tree.children[2].Code.nil? ? "pop" : "#{tree.children[2].Code}\n\tpop"
    tree.children[2].setCode(code)
  end
  
  @@variableTable.delete_at(@@currentLevel)
  @@currentLevel -= 1
  #We're going to need to put this code on the while due to the fact that
  #We will need to insert boolean code back in before the conditional in Code Generation
  codeAdd = @@symbolTable["whileCode"]["After"]
  thisCodeAdd = String.new(codeAdd)
  thisCodeAdd.gsub!(/['Y']/, whileLabelY.to_s)
  tree.children[0].setCode(thisCodeAdd)

  tree.setCode("")
  treeType = nil;
  tree.setTypeName(treeType)
  return treeType
end

def typeCheckIfStatement(tree)
  if(tree.children.size != 3 && tree.children.size != 4)
    @@errorList << "Error: Incorrect number of arguments"
    @@errorList << "Correct Usage: if [bool or integer] [ifclause] [elseclause] or if [bool] [ifclause]"
    return nil
  end

  labelX = @@labelCounter
  @@labelCounter += 1
  labelY = @@labelCounter
  @@labelCounter += 1
  labelZ = @@labelCounter
  @@labelCounter += 1
  
  unless tree.children[1].value.nil?
    @@errorList << "Error: No Brackets around If Clause"
    @@errorList << "Correct Usage: if [bool or integer] [ifclause] [elseclause] or if [bool] [ifclause]"
    return nil
  end

  type = typeCheck(tree.children[1]) 
  if(type != "Boolean" && type != "Integer")
    @@errorList << "Error: In If Statement, Didnt find boolean or integer where expected"
    return nil
  end
  
  codeAdd = tree.children.size == 3 ? @@symbolTable["ifCode"]["Bool"] : @@symbolTable["ifCode"]["Bool2"]
  thisCodeAdd = String.new(codeAdd)
  thisCodeAdd.gsub!(/['X']/, labelX.to_s)
  thisCodeAdd.gsub!(/['Y']/, labelY.to_s)

  newCode = tree.children[1].Code.nil? ? thisCodeAdd : "#{tree.children[1].Code}\n\t#{thisCodeAdd}"

  tree.children[1].setCode(newCode)

  unless tree.children[2].value.nil?
    @@errorList << "Error: No Brackets around If Clause"
    @@errorList << "Correct Usage: if [bool or integer] [ifclause] [elseclause] or if [bool] [ifclause]"
    return nil
  end

  @@currentLevel += 1

  @@variableTable[@@currentLevel] = {} if @@variableTable[@@currentLevel].nil?

  type = typeCheck(tree.children[2])
  @@variableTable.delete_at(@@currentLevel)
  @@currentLevel -= 1
  
  codeAdd = tree.children.size == 3 ? @@symbolTable["ifCode"]["AfterFirst1"] : @@symbolTable["ifCode"]["AfterFirst2"]
  thisCodeAdd = String.new(codeAdd)
  thisCodeAdd.gsub!(/['X']/, labelX.to_s)
  thisCodeAdd.gsub!(/['Z']/, labelZ.to_s)

  newCode = tree.children[2].Code.nil? ? thisCodeAdd : "#{tree.children[2].Code}\n#{thisCodeAdd}"
  newCode = "pop\n#{newCode}" if type != nil && type != "String" && tree.children.size == 3
  
  tree.children[2].setCode(newCode)
  typeOne = type

  if(tree.children.size == 4)
    unless tree.children[3].value.nil?
      @@errorList << "Error: No Brackets around Else Clause"
      @@errorList << "Correct Usage: if [bool or integer] [ifclause] [elseclause] or if [bool] [ifclause]"
      return nil
    end

    @@currentLevel += 1

    @@variableTable[@@currentLevel] = {} if @@variableTable[@@currentLevel].nil?

    type = typeCheck(tree.children[3])
    @@variableTable.delete_at(@@currentLevel)
    @@currentLevel -= 1
    codeAdd = @@symbolTable["ifCode"]["AfterSecond"]
    thisCodeAdd = String.new(codeAdd)
    thisCodeAdd.gsub!(/['Z']/, labelZ.to_s)

    newCode = tree.children[3].Code.nil? ? thisCodeAdd : "#{tree.children[3].Code}\n#{thisCodeAdd}"

    tree.children[3].setCode(newCode)
    typeTwo = tree.children[3].typeName
    if(typeOne != typeTwo)
      @@errorList << "Error: If Return Does not Match Else Return"
      return nil
    end
  end
  tree.children[0].setCode("")
  tree.setCode("")
  ## typeOne will be the type because we've already checked for match in ifElse
  treeType = tree.children.size == 4 ? typeOne : nil;
  tree.setTypeName(treeType)
  return treeType
end

def typeCheckBegin(tree)
  i = 1
  @@currentLevel += 1

  @@variableTable[@@currentLevel] = {} if @@variableTable[@@currentLevel].nil?

  while(i < tree.children.size-1)

    unless tree.children[i].value.nil?
      @@errorList << "Error in Begin End Statement, No Brackets around Statement " + printStatement(tree.children[i])
      @@variableTable.delete_at(@@currentLevel)
      @@currentLevel -= 1
      return nil
    end

    lastTyped = typeCheck(tree.children[i])
    
    if(lastTyped != nil && i != tree.children.size-2)
      childICode = tree.children[i].Code.nil? ? "pop" : "#{tree.children[i].Code}\n\tpop"
      tree.children[i].setCode(childICode)
    end
    i += 1
  end

  if(tree.children[i].value != "end" || tree.children[i].typeName != "Keyword")
    @@errorList << "Error: No End in Begin End Statement"
    @@variableTable.delete_at(@@currentLevel)
    @@currentLevel -= 1
    return nil
  end
  
  tree.children[0].setCode("")
  tree.children[tree.children.size-1].setCode("")
  @@variableTable.delete_at(@@currentLevel)
  @@currentLevel -= 1
  return lastTyped
end

def typeCheckLet(tree)
  isFunction = false
  if (tree.children.size != 3 && tree.children.size != 4) || (tree.children[1].value != nil)
    @@errorList << "Error: Incorrect number of arguments"
    @@errorList << "Correct Usage: let [: variable_name type] value or let [: variable_name type] value [action]"
    return nil
  end

  child1 = tree.children[1]
  if(child1.children == nil or child1.children.size != 3)
    @@errorList << "Error: Incorrect number of arguments for [: variable_name type]"
    return nil
  end

  if(child1.children[0].value != ":" || child1.children[1].typeName != "Variable" ||
    child1.children[2].typeName != "Type")
    if(child1.children[1].value == nil)
      isFunction = true
    else
      @@errorList << "Error: Incorrect arguments for [: variable_name type]"
      return nil
    end
  end

  child1.children[0].setCode("")
  child1.children[1].setCode("")
  child1.children[2].setCode("")

  unless isFunction

    if(@@variableTable[@@currentLevel][child1.children[1].value] != nil && tree.children.size == 3)
      @@errorList << "Error: " + child1.children[1].value + "cannot be redefined."
      return nil
    end
  
    unless tree.children[2].value.nil?
      typeAssign = tree.children[2].typeName
      unless @@symbolTable["Code"][typeAssign].nil?

        value = @@symbolTable["Code"][typeAssign]["Value"]
        code =  String.new(@@symbolTable["Code"][typeAssign]["Code"])

        # Translate true value to numeric for special boolean case
        if(typeAssign == "Boolean")
          thisValue = tree.children[2].value == "true" ? 1 : 0
          code.gsub!(/['X']/, thisValue.to_s)
        else
          code.gsub!(/['X']/, tree.children[2].value.to_s)
        end

        tree.children[2].setCode(code)

      else
        if(tree.children[2].typeName == "Variable")
          codeAndType = varCheck(tree.children[2])
          if(codeAndType == nil)
            @@errorList << "Error: Variable " + tree.children[2].value + " does not exist in this context."
            return nil
          end
          type = codeAndType["type"]
          if(codeAndType["loadCode"] == nil)
            ## WE HAVE A FUNCTION
            @@errorList << "Error: Incorrect Use of Function, cannot assign to Variable"
            return nil
          end
          code = String.new(codeAndType["loadCode"])
          tree.children[2].setTypeName(type)
          typeAssign = tree.children[2].typeName
          tree.children[2].setCode(code)
        else
          @@errorList << "Error: No code for " + tree.children[2].typeName
          return nil
        end
      end
    else
      typeAssign = typeCheck(tree.children[2])
    end

    if(typeAssign != @@symbolTable[child1.children[2].value]["typeName"])
      @@errorList << "Error: Value does not match type"
      return nil
    end

    ## So that we can delete this variable when done
    @@currentLevel = @@currentLevel + 1 if tree.children.size == 4

    @@variableTable[@@currentLevel] = {} if @@variableTable[@@currentLevel].nil?

    code = String.new(@@symbolTable["loadCode"][typeAssign] + @@localCounter.to_s)
    code = "#{code}\n\tswap" if typeAssign == "String"

    @@variableTable[@@currentLevel][child1.children[1].value] = {
        "type"=>String.new(typeAssign.to_s),
        "loadCode"=>String.new(code),
        "location"=>String.new(@@localCounter.to_s),
        "storeCode"=>String.new(@@symbolTable["storeCode"][typeAssign] + @@localCounter.to_s),
    }
    code = String.new(@@symbolTable["storeCode"][typeAssign] + @@localCounter.to_s)
    @@localCounter += 1
    tree.children[1].setCode(code)

    if(tree.children.size == 4)
      @@currentLevel += 1

      @@variableTable[@@currentLevel] = {} if @@variableTable[@@currentLevel].nil?

      returnType = typeCheck(tree.children[3])
      @@variableTable.delete_at(@@currentLevel)
      @@currentLevel -= 1
      @@variableTable[@@currentLevel].delete(child1.children[1].value)

      tree.children[3].setCode("pop") unless returnType.nil?

      @@currentLevel -= 1
    end

    return nil
  else
    ##################################
    ### HERE BE CODE FOR FUNCTIONS ###
    ##################################
    assigningFunction = false  # Variable to tell if we're setting one function to another
    
    if(child1.children[1].children[0] == nil)
      @@errorList << "Error: No name given for function"
      return nil
    end

    functionList = child1.children[1].children
    functionName = functionList[0].value
    if(@@variableTable[@@currentLevel][functionName] != nil && tree.children.size == 3)
      @@errorList << "Error: " + functionList[0].value + " cannot be redefined."
      return nil
    end

    i = 1
    argSize = 0
    typeList = ""
    argList = ""

    while(i < functionList.size) ## Parameters
      if(functionList[i].value != nil || functionList[i].children.size != 3)
        @@errorList << "Error: Expected [: name type] in parameters for function " + functionName
        return nil
      end

      if(functionList[i].children[0].value != ":" ||
          functionList[i].children[1].typeName != "Variable" ||
          functionList[i].children[2].typeName != "Type")
          @@errorList << "Error: Incorrect arguments for [: variable_name type]"
          return nil
      end

      @@variableTable[@@currentLevel+1] = {} if @@variableTable[@@currentLevel+1].nil?

      thisType = functionList[i].children[2].value
      thisType = @@symbolTable[thisType]["typeName"]

      code = String.new(@@symbolTable["loadCode"][thisType] + (i-1).to_s)
      if(thisType == "String")
        code = String.new(code + "\n\tswap")
      end

      @@variableTable[@@currentLevel+1][functionList[i].children[1].value] = {
          "type"=>String.new(thisType.to_s),
          "loadCode"=>String.new(code),
          "location"=>String.new((i-1).to_s),
          "storeCode"=>String.new(@@symbolTable["storeCode"][thisType] + (i-1).to_s),
      }

      typeList += @@symbolTable["methodSig"][thisType]
      argList += thisType
      argSize += 1
      i += 1
    end

    if(child1.children[2].typeName != "Type")
      @@errorList << "Error: No return type for function " + functionName
      return nil
    else
      treeReturn = @@symbolTable[child1.children[2].value]["typeName"]
    end
    
    functionSignature = "#{functionName}(#{typeList})#{@@symbolTable["methodSig"][treeReturn]}"
    callFunction = "invokestatic #{@@className}.#{functionSignature}"

    ## Need Current Level in there later on for :=
    @@variableTable[@@currentLevel][functionName] = {
        "currentLevel"=>String.new(@@currentLevel.to_s),
        "type"=>String.new(treeReturn.to_s),
        "call"=>callFunction,
        "returnCode"=>String.new(@@symbolTable["methodReturn"][treeReturn] +"\n"+".end method"),
        "arguments"=>String.new(functionName+argList),
        "signature"=>String.new(argList+treeReturn)
    }

    if(tree.children[2].value != nil)
      typeAssign = tree.children[2].typeName

      if(@@symbolTable["Code"][typeAssign] != nil)

        code = String.new(@@symbolTable["Code"][typeAssign]["Code"])

        if(typeAssign == "Boolean")
          # Translate true value to numeric for special boolean case
          codeValue = tree.children[2].value == "true" ? 1.to_s : 0.to_s
        else
          codeValue = tree.children[2].value.to_s
        end
        
        code.gsub!(/['X']/, codeValue)

        tree.children[2].setCode(code)
      else

        unless tree.children[2].typeName == "Variable"
          @@errorList << "Error: No code for " + tree.children[2].typeName
          @@variableTable[@@currentLevel].delete(functionName)
          return nil
        end

        codeAndType = varCheck(tree.children[2])
        if(codeAndType == nil)
          @@errorList << "Error: Variable " + tree.children[2].value + " does not exist in this context."
          @@variableTable[@@currentLevel].delete(functionName)
          return nil
        end

        type = codeAndType["type"]
        if(codeAndType["loadCode"] == nil)
          if(@@variableTable[@@currentLevel][functionName]["signature"] != codeAndType["signature"])
            @@errorList << "Functions signatures do not match, cannot assign"
            @@variableTable[@@currentLevel].delete(functionName)
            return nil
          else
            @@variableTable[@@currentLevel][functionName] = Hash.new(codeAndType)
            #I hate ruby's quirks
            # Really wished I had commented what I was trying to do here years ago...
            @@variableTable[@@currentLevel][functionName] = @@variableTable[@@currentLevel][functionName]["ANYTHINGCANGOHERE"]
            tree.children[2].setTypeName(treeReturn)
            ## For calling function need new argument "signature"
            @@variableTable[@@currentLevel][functionName]["arguments"]=String.new(functionName+argList)
            typeAssign = tree.children[2].typeName
            tree.children[2].setCode("")
            assigningFunction = true
          end
        else
          code = String.new(codeAndType["loadCode"])
          tree.children[2].setTypeName(type)
          typeAssign = tree.children[2].typeName
          tree.children[2].setCode(code)
        end
      end
      localsSize = 1
    else
      oldLocals = @@localCounter
      @@localCounter = argSize + 1
      @@currentLevel += 1

      @@variableTable[@@currentLevel] = {} if @@variableTable[@@currentLevel].nil?

      typeAssign = typeCheck(tree.children[2])
      @@variableTable.delete_at(@@currentLevel)
      @@currentLevel -= 1
      localsSize = @@localCounter #- oldLocals
      @@localCounter = oldLocals
    end

    if(typeAssign != treeReturn)
      if(treeReturn == "Void")
        if(typeAssign != nil)
          @@errorList << "Error: Function return does not match Type"
          @@variableTable[@@currentLevel].delete(functionName)
          return nil
        end
      else
        @@variableTable[@@currentLevel].delete(functionName)
        @@errorList << "Error: Function return does not match Type"
        return nil
      end
    end
    
    localsAndStack = "\n\t.limit locals #{(localsSize).to_s}\n\t.limit stack Y"
    treeSize(tree.children[2])
    localsAndStack.gsub!(/['Y']/, @@stackSize.to_s)

    @@stackSize = 0
    code = String.new(".method public static #{functionSignature}#{localsAndStack}")

    if(assigningFunction)
      tree.children[1].setCode("")
      tree.children[0].setCode("")
    else
      tree.children[1].setCode(code)
      tree.children[0].setCode("\t"+@@variableTable[@@currentLevel][functionName]["returnCode"])
    end

    tree.children[0].setTypeName("Function")
    
    if(tree.children.size == 4)
      @@currentLevel += 1

      @@variableTable[@@currentLevel] = {} if @@variableTable[@@currentLevel].nil?

      returnType = typeCheck(tree.children[3])
      @@variableTable.delete_at(@@currentLevel)
      @@currentLevel -= 1
      @@variableTable[@@currentLevel].delete(functionName)

      unless returnType.nil?
        tree.children[3].setCode("pop")
      end
    end
    return nil
  end
end


def typeCheckWrite(tree)
  if(tree.children.size != 3)
    @@errorList << "Error: Incorrect Number of Arguments for " + tree.children[0].value
    return nil
  end
  
  if(tree.children[1].value != "stdout")
    @@errorList << "Error: No rule to " + tree.children[0].value + " for " + tree.children[1].value
    return nil
  end
  
  if tree.children[2].value.nil?
    typeToPrint = typeCheck(tree.children[2])
    if typeToPrint.nil?
      @@errorList << "Error: Statement to Print Returned Incorrect Type"
      return nil
    end
  else
    typeToPrint = tree.children[2].typeName
    ## Code to Load
    unless @@symbolTable["Code"][typeToPrint].nil?
      value = @@symbolTable["Code"][typeToPrint]["Value"]
      code =  String.new(@@symbolTable["Code"][typeToPrint]["Code"])

      # Translate true value to numeric for special boolean case
      if(typeToPrint == "Boolean")
        thisValue = tree.children[2].value == "true" ? 1 : 0
        code.gsub!(/['X']/, thisValue.to_s)
      else
        code.gsub!(/['X']/, tree.children[2].value.to_s)
      end

      tree.children[2].setCode(code)
    else
      if(tree.children[2].typeName == "Variable")
        codeAndType = varCheck(tree.children[2])
        if codeAndType.nil?
          @@errorList << "Error: Variable " + tree.children[2].value + " does not exist in this context."
          return nil
        end
        type = codeAndType["type"]
        if(codeAndType["loadCode"] == nil)
          @@errorList << "Function can not be printed, must be in brackets"
          return nil
        end
        code = String.new(codeAndType["loadCode"])
        tree.children[2].setTypeName(type)
        typeToPrint = tree.children[2].typeName
        tree.children[2].setCode(code)
      else
        @@errorList << "Error: No code for " + tree.children[2].typeName
        return nil
      end
    end
  end

  if(@@symbolTable[tree.children[0].value]["toPrint"] != typeToPrint)
    @@errorList << "Error: Incorrect Type for " + tree.children[0].value
    return nil
  end

  code = @@symbolTable["Print"][typeToPrint]["Store"] + "\n"
  code += @@symbolTable["Print"][typeToPrint]["Load"]

  if(tree.children[2].typeName == "Boolean")
    boolCode = String.new(code)
    boolCode.gsub!(/['X']/, @@labelCounter.to_s)
    @@labelCounter += 1
    boolCode.gsub!(/['Y']/, @@labelCounter.to_s)
    @@labelCounter += 1
    boolCode.gsub!(/['Z']/, @@labelCounter.to_s)
    @@labelCounter += 1
    code = boolCode
  end

  newCode = tree.children[0].Code.nil? ? code : "#{tree.children[0].Code}\n#{code}"

  tree.children[0].setCode(newCode)
  tree.children[1].setCode("")
  return nil
end

# varCheck looks for the Variable on the current level on the tree
# and loops further up the tree until it can find the variable
# returning nil if the variable is not found.
def varCheck(node)
  newCount = @@currentLevel

  until newCount < 0
    unless @@variableTable[newCount].nil?
      unless @@variableTable[newCount][node.value].nil?
        return @@variableTable[newCount][node.value]
      end
    end
    newCount -= 1
  end

  return nil
end