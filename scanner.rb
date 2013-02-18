#!/usr/bin/ruby
require './datastructures'
def getToken(file)
  nextChar = file.getc

  return Token.new("eof", "eof") if nextChar.nil?

  nextChar = nextChar.chr  #converts char code into an actual char

  # Whitespace is whitespace is whitespace
  if(nextChar == ' ' || nextChar == "\n" || nextChar == "\t") 
    @@lineNumber += 1 if nextChar == "\n"

    return getToken(file)
  end

  ## LISP STYLE COMMENTS
  if(nextChar == ";")
    # Continue looping until next line.  Comments are ignored by compiler.
    until nextChar == "\n"
      nextChar = file.getc
      return Token.new("eof", "eof") if nextChar.nil?
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
      return Token.new("eof", "eof") if peekChar.nil?
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
      # Integers and Floats
      if nextChar == "0" || (nextChar.to_i > 0 && nextChar.to_i <= 9)
        prev = nextChar
        thisToken = scanNumber(file,prev)
        return thisToken

      # Names and Keywords
      elsif charIsUpperCaseLetter(nextChar[0]) || charIsLowerCaseLetter(nextChar[0]) #ALPHA CODES LC then UC
        prev = nextChar
        return scanName(file, prev)

      # Unrecognized tokens
      else
        @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + nextChar
        return getToken(file)
      end

  end
  
  return token
end

def charIsUpperCaseLetter(letter)
    (letter =~ /[A-Z]/) != nil
end

def charIsLowerCaseLetter(letter)
    (letter =~ /[a-z]/) != nil
end

def scanOperator(file,prev)

  currentOperator = prev

  case currentOperator
    when '&','|','=','/','%','^','\\','+','-'
      pointer = file.getc

      return endOfFileError("Operator", currentOperator) if pointer.nil?

      pointer = pointer.chr

      if isTokenBreak(pointer)
        if pointer == '[' || pointer == ']'
          file.ungetc(pointer[0])
        end

        @@lineNumber += 1 if pointer == "\n"
          
        return Token.new("Operator",currentOperator)
      else
        # If there are more tokens after this Operator not separated by a space
        currentOperator += pointer
        return unrecognizedTokenError(currentOperator)
      end

    when '<','>','!',':'
      pointer = file.getc

      return endOfFileError("Operator", currentOperator) if pointer.nil?

      pointer = pointer.chr

      if isTokenBreak(pointer)

        if pointer == '[' || pointer == ']'
          file.ungetc(pointer[0])
        end
        @@lineNumber += 1 if pointer == "\n"
        return Token.new("Operator",currentOperator)

      elsif(pointer == "=")

        currentOperator += pointer
        pointer = file.getc

        return endOfFileError("Operator", currentOperator) if pointer.nil?

        pointer = pointer.chr

        if isTokenBreak(pointer)

          if pointer == '[' || pointer == ']'
            file.ungetc(pointer[0])
          end

          @@lineNumber += 1 if pointer == "\n"
          return Token.new("Operator",currentOperator)

        elsif(pointer == '>' && currentOperator == "<=")
          currentOperator += pointer
          pointer = file.getc

          return endOfFileError("Operator", currentOperator) if pointer.nil?

          pointer = pointer.chr

          unless isTokenBreak(pointer)
            currentOperator += pointer
            return unrecognizedTokenError(currentOperator)
          end
          
          if pointer == '[' || pointer == ']'
            file.ungetc(pointer[0])
          end
          @@lineNumber += 1 if pointer == "\n"
          return Token.new("Operator",currentOperator)
          
        else
          currentOperator += pointer
          return unrecognizedTokenError(currentOperator)
        end
      else
        currentOperator += pointer
        return unrecognizedTokenError(currentOperator)
      end
    when '*'
      pointer = file.getc
      return endOfFileError("Operator", currentOperator) if pointer.nil?
      pointer = pointer.chr
      
      if isTokenBreak(pointer)
        if pointer == '[' || pointer == ']'
          file.ungetc(pointer[0])
        end
        @@lineNumber += 1 if pointer == "\n"
        return Token.new("Operator",currentOperator)
      elsif pointer == "*"
        currentOperator += pointer
        pointer = file.getc
        return endOfFileError("Operator", currentOperator) if pointer.nil?
        pointer = pointer.chr

        unless isTokenBreak(pointer)
          return unrecognizedTokenError(currentOperator)
        end

        if pointer == '[' || pointer == ']'
          file.ungetc(pointer[0])
        end
        @@lineNumber += 1 if pointer == "\n"
        return Token.new("Operator",currentOperator)
      else
          return unrecognizedTokenError(currentOperator)
      end
    end
end

def isTokenBreak(pointer)
  return pointer == ' ' || pointer == '[' || pointer == ']' || pointer == "\n"
end

def endOfFileError(inType, currentOperator)
  @@errorList << "Line #{@@lineNumber.to_s}: EOF Found in #{inType} #{currentOperator} , Looking for [ ]"
  return Token.new("eof", "eof")
end

def endOfFileErrorString(currentString)
  @@errorList << "Line #{@@lineNumber.to_s}: EOF Found in String #{currentString} , Looking for \" "
  return Token.new("eof", "eof")
end

def unrecognizedTokenError(currentOperator)
  @@errorList << "Line #{@@lineNumber.to_s}: Unrecognized Token : #{currentOperator}"
  return Token.new("Operator", currentOperator)
end

def unrecognizedTokenErrorByType(type, currentToken)
  @@errorList << "Line #{@@lineNumber.to_s}: Unrecognized Token : #{currentToken}"
  return Token.new(type, currentToken)
end

def scanName(file,prev)
  currentName = prev
  pointer = file.getc

  return endOfFileError("Variable/Name", currentName) if pointer.nil?

  pointer = pointer.chr
  while(charIsLowerCaseLetter(pointer[0]) || ## Lower Case
        charIsUpperCaseLetter(pointer[0]) || ## Upper Case
        (pointer == "_") || (pointer == "0") || (pointer.to_i > 0 && pointer.to_i <= 9))

    currentName += pointer
    pointer = file.getc
    return endOfFileError("Variable/Name", currentName) if pointer.nil?
    pointer = pointer.chr
  end

  if @@symbolTable[currentName].nil?
    ## Add to Symbol Table as variable
    @@symbolTable[currentName] = {"type"=>"Variable"}
    returnToken = Token.new("Variable", currentName)
  else
    returnToken = Token.new(@@symbolTable[currentName]["type"], currentName)
  end

  unless isTokenBreak(pointer)
    currentName += pointer
    @@errorList << "Line " + @@lineNumber.to_s + ": " + "Unrecognized Token : " + currentName
  end

  if pointer == '[' || pointer == ']'
    file.ungetc(pointer[0])
  end
  
  return returnToken
end

def scanNumber(file, prev)
  currentNumber = prev
  pointer = file.getc

  return endOfFileError("Integer", currentNumber) if pointer.nil?

  pointer = pointer.chr

  ##### INTEGER STATE #####
  while pointer == "0"  || (pointer.to_i > 0 && pointer.to_i <= 9)
    currentNumber += pointer
    pointer = file.getc
    return endOfFileError("Integer", currentNumber) if pointer.nil?
    pointer = pointer.chr
  end

  if isTokenBreak(pointer)

    if pointer == '[' || pointer == ']'
      file.ungetc(pointer[0])
    end

    @@lineNumber += 1 if pointer == "\n"

    thisToken = Token.new("Integer", currentNumber)
    if(thisToken.value > 2147483647)  #Max Integer Size, we'll convert to Float
      thisToken = Token.new("Float", currentNumber + ".0")
    end
    return thisToken

  elsif pointer != '.' #&& pointer != 'e' && pointer != 'E'

    currentNumber += pointer
    return unrecognizedTokenErrorByType("Integer", currentNumber)
  end

  ##### END INTEGER STATE #####

  ##### FLOAT STATE #####
  currentNumber += pointer
  pointer = file.getc

  return endOfFileError("Float", currentNumber) if pointer.nil?

  pointer = pointer.chr

  # We require at least one number after the decimal for a valid float
  if pointer == "0"  || (pointer.to_i > 0 && pointer.to_i <= 9)
    currentNumber += pointer
    pointer = file.getc
    return endOfFileError("Float", currentNumber) if pointer.nil?
    pointer = pointer.chr
  else
    currentNumber += pointer
    return unrecognizedTokenErrorByType("Float", currentNumber)
  end

  eFlag = false
  while pointer == "0"  || (pointer.to_i > 0 && pointer.to_i <= 9) || pointer == 'e' || pointer == 'E'
    currentNumber += pointer
    if pointer == 'e' || pointer == 'E'
      if eFlag
        # There was already an 'e' token in this float
        return unrecognizedTokenErrorByType("Float", currentNumber)
      end
      
      eFlag = true
      pointer = file.getc
      return endOfFileError("Float", currentNumber) if pointer.nil?
      pointer = pointer.chr

      if pointer == '+' || pointer == '-'
        currentNumber += pointer
      else
        file.ungetc(pointer[0])
      end
    end

    pointer = file.getc
    return endOfFileError("Float", currentNumber) if pointer.nil?
    pointer = pointer.chr
  end

  if isTokenBreak(pointer)
    if pointer == '[' || pointer == ']'
      file.ungetc(pointer[0])
    end

    @@lineNumber += 1 if pointer == "\n"
    return Token.new("Float", currentNumber)
  else
    currentNumber += pointer
    return unrecognizedTokenErrorByType("Float", currentNumber)
  end
  ##### END FLOAT STATE #####
end

def scanString(file)
  currentString = "\""
  pointer = file.getc

  return endOfFileErrorString(currentString) if pointer.nil?

  pointer = pointer.chr

  while pointer != '"'

    if pointer == '\\'
      # Detect escaped character codes

      pointer = file.getc

      return endOfFileErrorString(currentString) if pointer.nil?

      pointer = pointer.chr
      backtypes = {"a"=>7,"b"=>8,"f"=>12,"n"=>10,"r"=>13,"t"=>9,"v"=>11,"\\"=>92,"0"=>0}

      if backtypes[pointer] != nil
        @@lineNumber += 1 if backtypes[pointer] == 10
        currentString += backtypes[pointer].chr
      else
        currentString += "\\" + pointer
      end

    else
      currentString += pointer
    end

    pointer = file.getc
    return endOfFileErrorString(currentString) if pointer.nil?
    pointer = pointer.chr
  end

  currentString += "\""
  pointer = file.getc

  return endOfFileError("String", currentString) if pointer.nil?

  pointer = pointer.chr

  unless isTokenBreak(pointer)
    currentString += pointer
    @@errorList << "Line " + @@lineNumber.to_s + ": " + "Syntax : Invalid String : " + currentString
    return Token.new("String", currentString)
  else
    if pointer == "[" || pointer == "]"
      file.ungetc(pointer[0])
    end
    return Token.new("String",currentString)
  end  
end
