require './scanner'
## Grammar is 
## A' -> Aeof
## A  -> AA
## A  -> []
## A  -> [T]
def parseA(fileName)
  listOfTrees = []
  while( (thisToken = getToken(fileName)).typeName != "eof" )  ## HANDLES AA, ALSO EOF at END ##
    if(thisToken.typeName == "LeftBracket")
      listOfTrees << parseT(fileName)
    else  ## WE MUST START WITH A LEFTBRACKET
      error = "Line " + @@lineNumber.to_s + ": " + "Found " + thisToken.value.to_s
      error += " Expected: [ or eof"
      @@errorList << error
    end
  end
  return listOfTrees
end
## T  -> TT
## T  -> []
## T  -> [T]
## T  -> Atom
def parseT(fileName)
  addTree = Node.new(nil)
  thisToken = getToken(fileName)
  if(thisToken == "eof")
    @@errorList << "Line " + @@lineNumber.to_s + ": " + "Mid File EOF"
  end
  while( thisToken.typeName != "RightBracket" )
    if(thisToken.typeName == "LeftBracket")
      addTree.addNode(parseT(fileName)) 
    else
      thisNode = Node.new(thisToken)
      addTree.addNode(thisNode)
    end
    thisToken = getToken(fileName)
    if(thisToken.typeName == "eof")
      @@errorList << "Line " + @@lineNumber.to_s + ": " + "Expected ]"
      return addTree
    end
  end
  return addTree
end
