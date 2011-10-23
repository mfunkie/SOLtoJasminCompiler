#!/usr/bin/ruby
require 'datastructures'
def getToken(file)
  nextChar = file.getc
  if(nextChar == nil)
    thisToken = Token.new("eof", "eof")
    return thisToken
  end
  nextChar = nextChar.chr  #converts char code into an actual char
  while(nextChar == ' ' || nextChar == "\n" || nextChar == "\t") 
    if( nextChar == "\n")
      @@lineNumber += 1
    end
    nextChar = file.getc
    if(nextChar == nil)
      thisToken = Token.new("eof", "eof")
      return thisToken
    end
    nextChar = nextChar.chr
  end
  ## LISP STYLE COMMENTS
  if(nextChar == ";")
    while(nextChar != "\n") #  || nextChar[0] == 10)
      nextChar = file.getc
      if(nextChar == nil)
        thisToken = Token.new("eof", "eof")
        return thisToken
      end
      nextChar = nextChar.chr
    end
    @@lineNumber += 1
    return getToken(file)
  end
  case nextChar
    when '"'
      thisToken = scanString(file)
      return thisToken
    when '+','-'
      peekChar = file.getc
      if(peekChar == nil)
        thisToken = Token.new("eof", "eof")
        return thisToken
      end
      peekChar = peekChar.chr
      if peekChar == '0' || peekChar.to_i > 0 && peekChar.to_i < 10
        prev = nextChar + peekChar
        token = scanNumber(file, prev)
        return token
      else ## HANDLE + - TOKEN
        file.ungetc(peekChar[0])
        return scanOperator(file,nextChar)
      end
    when '[',']'
      tokenType = nextChar == "[" ? "LeftBracket" : "RightBracket"
      thisToken = Token.new(tokenType,nextChar)
      return thisToken
    when '&','|','!','=','<','>','*','/','%','^',':','\\','+','-'
      return scanOperator(file,nextChar)
    else
      if nextChar == "0" || (nextChar.to_i > 0 && nextChar.to_i <= 9)
        prev = nextChar
        thisToken = scanNumber(file,prev)
        return thisToken
      elsif (nextChar[0] >= 97 && nextChar[0] <= 122) || (nextChar[0] >= 65 && nextChar[0] <= 90) #ALPHA CODES LC then UC
        prev = nextChar
        return scanName(file, prev)
      else
        @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + nextChar
        return getToken(file)
      end
  end
  
  return token
end

def scanOperator(file,prev)
  currentOperator = prev
  case currentOperator
    when '&','|','=','/','%','^','\\','+','-'
      pointer = file.getc
      if(pointer == nil)
        @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Operator " + currentOperator + " , Looking for [ ]"
        thisToken = Token.new("eof", "eof")
        return thisToken
      end
      pointer = pointer.chr
      if pointer == ' ' || pointer == '[' || pointer == ']' || pointer == "\n"
        if pointer == '[' || pointer == ']'
          file.ungetc(pointer[0])
        end
        if(pointer == "\n")
          @@lineNumber += 1
        end
        thisToken = Token.new("Operator",currentOperator)
        return thisToken
      else
        currentOperator += pointer
        @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentOperator
        return Token.new("Operator", currentOperator)
      end
    when '<','>','!',':'
      pointer = file.getc
      if(pointer == nil)
        @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Operator " + currentOperator + " , Looking for [ ]"
        thisToken = Token.new("eof", "eof")
        return thisToken
      end
      pointer = pointer.chr
      if pointer == ' ' || pointer == '[' || pointer == ']' || pointer == "\n"
        if pointer == '[' || pointer == ']'
          file.ungetc(pointer[0])
        end
        if(pointer == "\n")
          @@lineNumber += 1
        end
        thisToken = Token.new("Operator",currentOperator)
        return thisToken
      elsif(pointer == "=")
        currentOperator += pointer
        pointer = file.getc
        if(pointer == nil)
          @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Operator " + currentOperator + " , Looking for [ ]"
          thisToken = Token.new("eof", "eof")
          return thisToken
        end
        pointer = pointer.chr
        if pointer == ' ' || pointer == '[' || pointer == ']' || pointer == "\n"
          if pointer == '[' || pointer == ']'
            file.ungetc(pointer[0])
          end
          if(pointer == "\n")
            @@lineNumber += 1
          end
          thisToken = Token.new("Operator",currentOperator)
          return thisToken
        elsif(pointer == '>' && currentOperator == "<=")
          currentOperator += pointer
          pointer = file.getc
          if(pointer == nil)
            @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Operator " + currentOperator + " , Looking for [ ]"
            thisToken = Token.new("eof", "eof")
            return thisToken
          end
          pointer = pointer.chr
          if pointer == ' ' || pointer == '[' || pointer == ']' || pointer == "\n"
            if pointer == '[' || pointer == ']'
              file.ungetc(pointer[0])
            end
            if(pointer == "\n")
              @@lineNumber += 1
            end
            thisToken = Token.new("Operator",currentOperator)
            return thisToken
          else
            currentOperator += pointer
            @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentOperator
            return Token.new("Operator", currentOperator)
          end
        else
          currentOperator += pointer
          @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentOperator
          return Token.new("Operator", currentOperator)
        end
      else
        currentOperator += pointer
        @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentOperator
        return Token.new("Operator", currentOperator)
      end
    when '*'
      pointer = file.getc
      if(pointer == nil)
        @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Operator " + currentOperator + " , Looking for [ ]"
        thisToken = Token.new("eof", "eof")
        return thisToken
      end
      pointer = pointer.chr
      if pointer == ' ' || pointer == '[' || pointer == ']' || pointer == "\n"
        if pointer == '[' || pointer == ']'
          file.ungetc(pointer[0])
        end
        if(pointer == "\n")
          @@lineNumber += 1
        end
        thisToken = Token.new("Operator",currentOperator)
        return thisToken
      elsif pointer == "*"
        currentOperator += pointer
        pointer = file.getc
        if(pointer == nil)
          @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Operator " + currentOperator + " , Looking for [ ]"
          thisToken = Token.new("eof", "eof")
          return thisToken
        end
        pointer = pointer.chr
        if pointer == ' ' || pointer == '[' || pointer == ']' || pointer == "\n"
          if pointer == '[' || pointer == ']'
            file.ungetc(pointer[0])
          end
          if(pointer == "\n")
            @@lineNumber += 1
          end
          thisToken = Token.new("Operator",currentOperator)
          return thisToken
        else
          @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentOperator
          return Token.new("Operator", currentNumber)
        end
      else
        @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentOperator
        return Token.new("Operator", currentNumber)
      end
    end
end

def scanName(file,prev)
  currentName = prev
  pointer = file.getc
  if(pointer == nil)
    @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Variable/Name " + currentName + " , Looking for [ ]"
    thisToken = Token.new("eof", "eof")
    return thisToken
  end
  pointer = pointer.chr
  while((pointer[0] >= 97 && pointer[0] <= 122) || ## Lower Case
        (pointer[0] >= 65 && pointer[0] <= 90)  || ## Upper Case
        (pointer == "_") || (pointer == "0") || (pointer.to_i > 0 && pointer.to_i <= 9))
    currentName += pointer
    pointer = file.getc
    if(pointer == nil)
      @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Variable/Name " + currentName + " , Looking for [ ]"
      thisToken = Token.new("eof", "eof")
      return thisToken
    end
    pointer = pointer.chr
  end
  if(@@symbolTable[currentName] == nil)
    ## Add to Symbol Table as variable
    @@symbolTable[currentName] = {"type"=>"Variable"}
    returnToken = Token.new("Variable", currentName)
  else
    returnToken = Token.new(@@symbolTable[currentName]["type"], currentName)
  end
  if pointer == ' ' || pointer == '[' || pointer == ']'  || pointer == "\n"
    if pointer == '[' || pointer == ']'
      file.ungetc(pointer[0])
    end
  else 
    currentName += pointer
    @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentName
  end  
  return returnToken   
end

def scanNumber(file, prev)
  currentNumber = prev
  pointer = file.getc
  if(pointer == nil)
    @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Integer " + currentNumber + " , Looking for [ ]"
    thisToken = Token.new("eof", "eof")
    return thisToken
  end
  pointer = pointer.chr
  ##### INTEGER STATE #####
  while pointer == "0"  || (pointer.to_i > 0 && pointer.to_i <= 9)
    currentNumber += pointer
    pointer = file.getc
    if(pointer == nil)
      @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Integer " + currentNumber + " , Looking for [ ]"
      thisToken = Token.new("eof", "eof")
      return thisToken
    end
    pointer = pointer.chr
  end
  if pointer == ' ' || pointer == '[' || pointer == ']'  || pointer == "\n"
    if pointer == '[' || pointer == ']'
      file.ungetc(pointer[0])
    end
    if(pointer == "\n")
      @@lineNumber += 1
    end
    thisToken = Token.new("Integer",currentNumber)
    if(thisToken.value > 2147483647)  #Max Integer Size, we'll convert to Float
      thisToken = Token.new("Float",currentNumber + ".0")
    end
    return thisToken
  elsif pointer != '.' #&& pointer != 'e' && pointer != 'E'
    currentNumber += pointer
    @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentNumber
    return Token.new("Integer", currentNumber)
  ##### INTEGER STATE #####
  elsif pointer == '.'
  ##### FLOAT STATE #####
    currentNumber += pointer
    pointer = file.getc
    if(pointer == nil)
      @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Float " + currentNumber + " , Looking for [ ]"
      thisToken = Token.new("eof", "eof")
      return thisToken
    end
    pointer = pointer.chr
    if pointer == "0"  || (pointer.to_i > 0 && pointer.to_i <= 9)
      currentNumber += pointer
      pointer = file.getc
      if(pointer == nil)
        @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Float " + currentNumber + " , Looking for [ ]"
        thisToken = Token.new("eof", "eof")
        return thisToken
      end
      pointer = pointer.chr
    else
      currentNumber += pointer
      @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentNumber
      return Token.new("Float", currentNumber)
    end
    eFlag = false
    while pointer == "0"  || (pointer.to_i > 0 && pointer.to_i <= 9) || pointer == 'e' || pointer == 'E'
      currentNumber += pointer
      if pointer == 'e' || pointer == 'E'
        if eFlag == false
          eFlag = true
          pointer = file.getc
          if(pointer == nil)
            @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Float " + currentNumber + " , Looking for [ ]"
            thisToken = Token.new("eof", "eof")
            return thisToken
          end
          pointer = pointer.chr
          if pointer == '+' || pointer == '-'
            currentNumber += pointer
          else
            file.ungetc(pointer[0])
          end
        else
          @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentNumber
          return Token.new("Float", currentNumber)
        end
      end
      pointer = file.getc
      if(pointer == nil)
        @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in Float " + currentNumber + " , Looking for [ ]"
        thisToken = Token.new("eof", "eof")
        return thisToken
      end
      pointer = pointer.chr
    end
    if pointer == ' ' || pointer == '[' || pointer == ']' || pointer == "\n"
      if pointer == '[' || pointer == ']'
        file.ungetc(pointer[0])
      end
      if(pointer == "\n")
        @@lineNumber += 1
      end
      thisToken = Token.new("Float",currentNumber)
      return thisToken
    else
      currentNumber += pointer
      @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentNumber
      return Token.new("Float", currentNumber)
    end
  end
  ##### FLOAT STATE #####
end

def scanString(file)
  currentString = "\""
  pointer = file.getc
  if(pointer == nil)
    @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in String " + currentString + " , Looking for \" "
    thisToken = Token.new("eof", "eof")
    return thisToken
  end
  pointer = pointer.chr
  while pointer != '"'
    if pointer == '\\' 
      pointer = file.getc
      if(pointer == nil)
        @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in String " + currentString + " , Looking for \" "
        thisToken = Token.new("eof", "eof")
        return thisToken
      end
      pointer = pointer.chr
      backtypes = {"a"=>7,"b"=>8,"f"=>12,"n"=>10,"r"=>13,"t"=>9,"v"=>11,"\\"=>92,"0"=>0}
      if backtypes[pointer] != nil
        if backtypes[pointer] == 10
          @@lineNumber += 1
        end
        currentString += backtypes[pointer].chr
      else
        currentString += "\\" + pointer
      end
    else
      currentString += pointer
    end
    pointer = file.getc
    if(pointer == nil)
      @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in String " + currentString + " , Looking for \" "
      thisToken = Token.new("eof", "eof")
      return thisToken
    end
    pointer = pointer.chr
  end
  currentString += "\""
  pointer = file.getc
  if(pointer == nil)
    @@errorList << "Line " + @@lineNumber.to_s + ": " + "EOF Found in String " + currentString + " , Looking for [ ]"
    thisToken = Token.new("eof", "eof")
    return thisToken
  end
  pointer = pointer.chr
  if pointer != " " && pointer != "[" && pointer != "]" && pointer != "\n"
    currentString += pointer
    @@errorList << "Line " + @@lineNumber.to_s + ": " + "Syntax : Invalid String : " + currentString
    thisToken = Token.new("String", currentString)
    return thisToken
  else
    if pointer == "[" or pointer == "]"
      file.ungetc(pointer[0])
    end
    thisToken = Token.new("String",currentString)
    return thisToken
  end  
end