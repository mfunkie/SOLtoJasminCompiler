def typeCheck(tree)
  if(tree.value == nil && tree.children[0] == nil)
    return "NULL"
  end
  if(tree.value == nil && tree.children[0].typeName == nil) 
     if(tree.children.length > 1)
       @@errorList << "Found statement, expected Operator"
       return nil
     end
     return typeCheck(tree.children[0])
  else
    if(tree.children[0].typeName == "Keyword" || 
       tree.children[0].typeName == "Boolean" || 
       tree.children[0].typeName == "Write"   ||
       tree.children[0].typeName == "Variable")
      if(tree.children[0].typeName == "Variable" && tree.children.size > 1)
        ## DO NOTHING WE WILL HANDLE EVERYTHING HERE, IT IS A FUNCTION
      else
        return specialTypeCheck(tree)
      end
    end
    if(@@symbolTable[tree.children[0].typeName] == nil && tree.children[0].typeName != "Variable")
      @@errorList << "Found " + tree.children[0].typeName + " Expected Operator"
      return nil
    else
      lookupName = tree.children[0].value
      i = 1
      while(i < tree.children.size())
        if(tree.children[i].value == nil)
          type = typeCheck(tree.children[i]) 
          tree.children[i].setReturnType(type)
        else
          type = tree.children[i].typeName
          if(@@symbolTable["Code"][tree.children[i].typeName] != nil)
            value = @@symbolTable["Code"][tree.children[i].typeName]["Value"]
            code =  String.new(@@symbolTable["Code"][tree.children[i].typeName]["Code"])
            if(value != nil)
              ## SPECIAL BOOLEAN CASE
              if(tree.children[i].typeName == "Boolean")
                thisValue = tree.children[i].value == "true" ? 1 : 0
                code.gsub!(/['X']/, thisValue.to_s)
              else
                code.gsub!(/['X']/, tree.children[i].value.to_s)
              end
            end
            tree.children[i].setCode(code)
          else
            if(tree.children[i].typeName == "Variable")
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
            else
              @@errorList << "Error: No code for " + tree.children[i].typeName
              return nil
            end
          end
        end
        if(type == nil)
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
          oldArguments =String.new(codeAndType1["arguments"])
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
        if(thisFunction == nil)
          @@errorList << "Error: Function " + tree.children[0].value + " does not exist in this context."
          return nil
        end
        returnType = thisFunction["type"] #code is under call
        if(thisFunction["call"] == nil)
          @@errorList << "Found Variable, Expected Function"
          return nil
        end
        tree.children[0].setCode(thisFunction["call"])
        if(lookupName != thisFunction["arguments"])
          @@errorList << "Incorrect arguments for function"
          @@errorList << "Found: "+lookupName
          @@errorList << "Expected: "+thisFunction["arguments"]
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
         newCode = loadType + "\n\t" + oldCode
         tree.children[1].setCode(newCode)
       end
      
      #Set conversion codes
      if(returnType == nil)
        @@errorList << "Return Type is Nil, Returning Error"
        @@errorList << "No Rule for " + lookupName
        return returnType
      else
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
          if(tree.children[0].typeName == "Variable")
            thisBoolCode = tree.children[0].Code + "\n\t" + thisBoolCode
          end
          tree.children[0].setCode(thisBoolCode)
        else
          if(storageType != nil)  # := case
            tree.children[1].setCode("")
            tree.children[0].setCode(storageType)
            tree.setCode(loadingType)
          else
            if(tree.children[0].typeName != "Variable")
              if(@@symbolTable["Code"][codeType] != nil)
                tree.children[0].setCode(@@symbolTable["Code"][codeType])
              else
                @@errorList << "Error: No Code found for " + codeType
                @@errorList << "Attempted assignment without variable"
              end
            end
          end
        end
      end
      i = 1
      
      ## Special rules for ^ because it only takes doubles but we want to return float
      if(returnType != "Boolean" and tree.children[0].typeName != "Variable")
        while(i < tree.children.size())
          if( tree.children[0].value == "^")
            conversion = tree.children[i].typeName + "Double"
            codeAdd = @@symbolTable["Conversion"][conversion]
            if(tree.children[i].Code != nil)
              newCode = tree.children[i].Code + "\n" + "\t" + codeAdd
            else
              newCode = codeAdd
            end
            tree.children[i].setCode(newCode)
          elsif( tree.children[i].typeName != tree.typeName && tree.typeName != "String")
            conversion = tree.children[i].typeName + tree.typeName
            codeAdd = @@symbolTable["Conversion"][conversion]
            if(tree.children[i].Code != nil)
              newCode = tree.children[i].Code + "\n" + "\t" + codeAdd
            else
              newCode = codeAdd
            end
            tree.children[i].setCode(newCode)
          end
          i += 1
        end
      elsif(tree.children.size == 3 and tree.children[0].typeName != "Variable")
        child1 = tree.children[1]
        child2 = tree.children[2]
        childLookup = child1.typeName + child2.typeName
        if(@@symbolTable["BoolConversion"][childLookup] != nil)
          if(lookupName == "&IntegerInteger" || lookupName == "|IntegerInteger" || childLookup != "IntegerInteger")
            child1Change = @@symbolTable["BoolConversion"][childLookup]["child1"]
            if(child1Change != nil)
              if(child1.Code != nil)
                newCode = String.new(child1.Code + "\n" + "\t" + child1Change)
              else
                newCode = String.new(child1Change)
              end
              newCode.gsub!(/['X']/, @@labelCounter.to_s)
              @@labelCounter += 1
              newCode.gsub!(/['Y']/, @@labelCounter.to_s)
              @@labelCounter += 1
              newCode.gsub!(/['Z']/, @@labelCounter.to_s)
              @@labelCounter += 1
              child1.setCode(newCode)
            end
            child2Change = @@symbolTable["BoolConversion"][childLookup]["child2"]
            if(child2Change != nil)
              if(child2.Code != nil)
                newCode = String.new(child2.Code + "\n" + "\t" + child2Change)
              else
                newCode = String.new(child2Change)
              end
              newCode.gsub!(/['X']/, @@labelCounter.to_s)
              @@labelCounter += 1
              newCode.gsub!(/['Y']/, @@labelCounter.to_s)
              @@labelCounter += 1
              newCode.gsub!(/['Z']/, @@labelCounter.to_s)
              @@labelCounter += 1
              child2.setCode(newCode)
            end
          end
        end
      end
      return returnType
    end
  end
end


def specialTypeCheck(tree)
  if(tree.children[0].typeName == "Keyword")
    case tree.children[0].value
      when "while"
        if(tree.children.size != 3)
          @@errorList << "Error: In While Statement, incorrect number of arguments"
          @@errorList << "Correct Usage: while [bool or integer] [loop]"
          return nil
        end
        whileLabelX = @@labelCounter
        @@labelCounter += 1
        whileLabelY = @@labelCounter
        @@labelCounter += 1
        
        if(tree.children[1].value == nil)
          type = typeCheck(tree.children[1]) 
          if(type != "Boolean" && type != "Integer")
            @@errorList << "Error: In While Statement, didnt find boolean or integer where expected"
            return nil
          end
          
          codeAdd = @@symbolTable["whileCode"]["Bool"]
          
          thisCodeAdd = String.new(codeAdd)
          thisCodeAdd.gsub!(/['X']/, whileLabelX.to_s)
          thisCodeAdd.gsub!(/['Y']/, whileLabelY.to_s)
          if(tree.children[1].Code != nil)
            newCode = tree.children[1].Code + "\n" + "\t" + thisCodeAdd
          else
            newCode = thisCodeAdd
          end
          tree.children[1].setCode(newCode)
        else
          @@errorList << "Error: No Brackets around Boolean"
          @@errorList << "Correct Usage: while [bool or integer] [loop]"
          return nil
        end
        
        if(tree.children[2].value == nil)
          ## We dont need type of while but we do need to type check it
          @@currentLevel += 1
          if(@@variableTable[@@currentLevel] == nil)
            @@variableTable[@@currentLevel] = {}
          end
          type = typeCheck(tree.children[2])
          if(type != nil)
            if(tree.children[2].Code != nil)
              code = String.new(tree.children[2].Code + "\n\tpop")
            else
              code = String.new("pop")
            end
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
        else
          @@errorList << "Error: No Brackets around loop"
          @@errorList << "Correct Usage: while [bool or integer] [loop]"
          return nil
        end
        tree.setCode("")
        treeType = nil;
        tree.setTypeName(treeType)
        return treeType
      when "if"
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
        
        if(tree.children[1].value == nil)
          type = typeCheck(tree.children[1]) 
          if(type != "Boolean" && type != "Integer")
            @@errorList << "Error: In If Statement, Didnt find boolean or integer where expected"
            return nil
          end
          
          codeAdd = tree.children.size == 3 ? @@symbolTable["ifCode"]["Bool"] : @@symbolTable["ifCode"]["Bool2"]
          thisCodeAdd = String.new(codeAdd)
          thisCodeAdd.gsub!(/['X']/, labelX.to_s)
          thisCodeAdd.gsub!(/['Y']/, labelY.to_s)
          if(tree.children[1].Code != nil)
            newCode = tree.children[1].Code + "\n" + "\t" + thisCodeAdd
          else
            newCode = thisCodeAdd
          end
          tree.children[1].setCode(newCode)
        else
          @@errorList << "Error: No Brackets around Boolean"
          @@errorList << "Correct Usage: if [bool or integer] [ifclause] [elseclause] or if [bool] [ifclause]"
          return nil
        end
        if(tree.children[2].value == nil)
          @@currentLevel += 1
          if(@@variableTable[@@currentLevel] == nil)
            @@variableTable[@@currentLevel] = {}
          end
          type = typeCheck(tree.children[2])
          @@variableTable.delete_at(@@currentLevel)
          @@currentLevel -= 1
          
          codeAdd = tree.children.size == 3 ? @@symbolTable["ifCode"]["AfterFirst1"] : @@symbolTable["ifCode"]["AfterFirst2"]
          thisCodeAdd = String.new(codeAdd)
          thisCodeAdd.gsub!(/['X']/, labelX.to_s)
          thisCodeAdd.gsub!(/['Z']/, labelZ.to_s)
          if(tree.children[2].Code != nil)
            newCode = tree.children[2].Code + "\n" + thisCodeAdd
          else
            newCode = thisCodeAdd
          end
          if(type != nil && type != "String" && tree.children.size == 3)
            newCode = "pop\n" + newCode
          end
          tree.children[2].setCode(newCode)
          typeOne = type
        else
          @@errorList << "Error: No Brackets around If Clause"
          @@errorList << "Correct Usage: if [bool or integer] [ifclause] [elseclause] or if [bool] [ifclause]"
          return nil
        end
        if(tree.children.size == 4)
          if(tree.children[3].value == nil)
            @@currentLevel += 1
            if(@@variableTable[@@currentLevel] == nil)
              @@variableTable[@@currentLevel] = {}
            end
            type = typeCheck(tree.children[3])
            @@variableTable.delete_at(@@currentLevel)
            @@currentLevel -= 1
            codeAdd = @@symbolTable["ifCode"]["AfterSecond"]
            thisCodeAdd = String.new(codeAdd)
            thisCodeAdd.gsub!(/['Z']/, labelZ.to_s)
            if(tree.children[3].Code != nil)
              newCode = tree.children[3].Code + "\n" + thisCodeAdd
            else
              newCode = thisCodeAdd
            end
            tree.children[3].setCode(newCode)
            typeTwo = tree.children[3].typeName
            if(typeOne != typeTwo)
              @@errorList << "Error: If Return Does not Match Else Return"
              return nil
            end
          else
            @@errorList << "Error: No Brackets around Else Clause"
            @@errorList << "Correct Usage: if [bool or integer] [ifclause] [elseclause] or if [bool] [ifclause]"
            return nil
          end
        end
        tree.children[0].setCode("")
        tree.setCode("")
        ## typeOne will be the type because we've already checked for match in ifElse
        treeType = tree.children.size == 4 ? typeOne : nil;
        tree.setTypeName(treeType)
        return treeType
      when "begin"
        i = 1
        @@currentLevel += 1
        if(@@variableTable[@@currentLevel] == nil)
          @@variableTable[@@currentLevel] = {}
        end
        while(i < tree.children.size-1)
          if(tree.children[i].value != nil)
            @@errorList << "Error in Begin End Statement, No Brackets around Statement " + printStatement(tree.children[i])
            @@variableTable.delete_at(@@currentLevel)
            @@currentLevel -= 1
            return nil
          end
          lastTyped = typeCheck(tree.children[i])
          
          if(lastTyped != nil && i != tree.children.size-2) 
            if(tree.children[i].Code != nil)
              tree.children[i].setCode(String.new(tree.children[i].Code + "\n\tpop"))
            else
              tree.children[i].setCode(String.new("pop"))
            end
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
      when "let"
        isFunction = false
        if(tree.children.size != 3 && tree.children.size != 4)
          @@errorList << "Error: Incorrect number of arguments"
          @@errorList << "Correct Usage: let [: variable_name type] value or let [: variable_name type] value [action]"
          return nil
        end
        if(tree.children[1].value != nil)
          @@errorList << "Error: Incorrect number of arguments"
          @@errorList << "Correct Usage: let [: variable_name type] value or let [: variable_name type] value [action]"
          return nil
        end
        child1 = tree.children[1]
        if(child1.children == nil or child1.children.size != 3)
          @@errorList << "Error: Incorrect number of arguments for [: variable_name type]"
          return nil
        end
        if(child1.children[0].value != ":" or child1.children[1].typeName != "Variable" or
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
        if(!isFunction)
          if(@@variableTable[@@currentLevel][child1.children[1].value] != nil && tree.children.size == 3)
            @@errorList << "Error: " + child1.children[1].value + "cannot be redefined."
            return nil
          end
        
          if(tree.children[2].value != nil)
            typeAssign = tree.children[2].typeName
            if(@@symbolTable["Code"][typeAssign] != nil)
              value = @@symbolTable["Code"][typeAssign]["Value"]
              code =  String.new(@@symbolTable["Code"][typeAssign]["Code"])
              if(value != nil)
                ## SPECIAL BOOLEAN CASE
                if(typeAssign == "Boolean")
                  thisValue = tree.children[2].value == "true" ? 1 : 0
                  code.gsub!(/['X']/, thisValue.to_s)
                else
                  code.gsub!(/['X']/, tree.children[2].value.to_s)
                end
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
          if(tree.children.size == 4)  ## So that we can delete this variable when done
            @@currentLevel += 1
          end
          if(@@variableTable[@@currentLevel] == nil)
            @@variableTable[@@currentLevel] = {}
          end
          code = String.new(@@symbolTable["loadCode"][typeAssign] + @@localCounter.to_s)
          if(typeAssign == "String")
            code = String.new(code + "\n\tswap")
          end
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
            if(@@variableTable[@@currentLevel] == nil)
              @@variableTable[@@currentLevel] = {}
            end
            returnType = typeCheck(tree.children[3])
            @@variableTable.delete_at(@@currentLevel)
            @@currentLevel -= 1
            @@variableTable[@@currentLevel].delete(child1.children[1].value)
            if(returnType != nil)
              tree.children[3].setCode("pop")
            end
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
            if(functionList[i].children[0].value != ":" or functionList[i].children[1].typeName != "Variable" or
               functionList[i].children[2].typeName != "Type")
                @@errorList << "Error: Incorrect arguments for [: variable_name type]"
                return nil
            end
            if(@@variableTable[@@currentLevel+1] == nil)
              @@variableTable[@@currentLevel+1] = {}
            end
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
          
          
          functionSignature = functionName+"("+typeList+")"+@@symbolTable["methodSig"][treeReturn]
          callFunction ="invokestatic "+@@className+"."+functionSignature
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
              value = @@symbolTable["Code"][typeAssign]["Value"]
              code =  String.new(@@symbolTable["Code"][typeAssign]["Code"])
              if(value != nil)
                ## SPECIAL BOOLEAN CASE
                if(typeAssign == "Boolean")
                  thisValue = tree.children[2].value == "true" ? 1 : 0
                  code.gsub!(/['X']/, thisValue.to_s)
                else
                  code.gsub!(/['X']/, tree.children[2].value.to_s)
                end
              end
              tree.children[2].setCode(code)
            else
              if(tree.children[2].typeName == "Variable")
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
              else
                @@errorList << "Error: No code for " + tree.children[2].typeName
                @@variableTable[@@currentLevel].delete(functionName)
                return nil
              end
            end
            localsSize = 1
          else
            oldLocals = @@localCounter
            @@localCounter = argSize + 1
            @@currentLevel += 1
            if(@@variableTable[@@currentLevel] == nil)
              @@variableTable[@@currentLevel] = {}
            end
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
          
          localsAndStack = "\n\t.limit locals X\n\t.limit stack Y"
          localsAndStack.gsub!(/['X']/, (localsSize).to_s)
          treeSize(tree.children[2])
          localsAndStack.gsub!(/['Y']/, @@stackSize.to_s)
          @@stackSize = 0
          code = String.new(".method public static "+functionSignature+localsAndStack)
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
            if(@@variableTable[@@currentLevel] == nil)
              @@variableTable[@@currentLevel] = {}
            end
            returnType = typeCheck(tree.children[3])
            @@variableTable.delete_at(@@currentLevel)
            @@currentLevel -= 1
            @@variableTable[@@currentLevel].delete(functionName)
            if(returnType != nil)
              tree.children[3].setCode("pop")
            end
          end
          return nil
        end
    end
  end
  
  if(tree.children[0].typeName == "Write")
    if(tree.children.size != 3)
      @@errorList << "Error: Incorrect Number of Arguments for " + tree.children[0].value
      return nil
    end
    
    if(tree.children[1].value != "stdout")
      @@errorList << "Error: No rule to " + tree.children[0].value + " for " + tree.children[1].value
      return nil
    end
    
    if(tree.children[2].value == nil)
      typeToPrint = typeCheck(tree.children[2])
      if(typeToPrint == nil)
        @@errorList << "Error: Statement to Print Returned Incorrect Type"
        return nil
      end
    else
      typeToPrint = tree.children[2].typeName
      ## Code to Load
      if(@@symbolTable["Code"][typeToPrint] != nil)
        value = @@symbolTable["Code"][typeToPrint]["Value"]
        code =  String.new(@@symbolTable["Code"][typeToPrint]["Code"])
        if(value != nil)
          ## SPECIAL BOOLEAN CASE
          if(typeToPrint == "Boolean")
            thisValue = tree.children[2].value == "true" ? 1 : 0
            code.gsub!(/['X']/, thisValue.to_s)
          else
            code.gsub!(/['X']/, tree.children[2].value.to_s)
          end
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
    if(tree.children[0].Code != nil)
      newCode = tree.children[0].Code + "\n" + code
    else
      newCode = code
    end
    tree.children[0].setCode(newCode)
    tree.children[1].setCode("")
    return nil
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
  
  if(tree.children[0].typeName == "Variable")
    if(tree.children.size > 1)
      #it is a function
      
    end
    codeAndType = varCheck(tree.children[0])
    if(codeAndType == nil)
      @@errorList << "Error: Variable or Function " + tree.children[0].value + " does not exist in this context."
      return nil
    end
    type = codeAndType["type"]
    if(type != "Boolean" and codeAndType["call"] == nil)
      @@errorList << "Error: Variable cannot exist in location unless Boolean or function"
      return nil
    end
    if(codeAndType["call"] != nil)
      code = String.new(codeAndType["call"])
      tree.children[0].setTypeName(type)
      tree.children[0].setCode(code)
      tree.setCode("")
      tree.setTypeName(type)
      return "Variable"
    else
      code = String.new(codeAndType["loadCode"])
      tree.children[0].setTypeName(type)
      tree.children[0].setCode(code)
      tree.setCode("")
      tree.setTypeName("Boolean")
      return "Boolean"
    end
  end

end
          
def varCheck(node)
	newCount = @@currentLevel
	while(newCount >= 0)
		if(@@variableTable[newCount] != nil)
		  if(@@variableTable[newCount][node.value] != nil)
		    return @@variableTable[newCount][node.value]
	    end
		end
		newCount -= 1
	end
	return nil
end	

        