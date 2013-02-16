@@lineNumber = 1  
@@errorList = []
@@code = [".class public X",".super java/lang/Object",
  ".method public <init>()V\n\t.limit locals 1\n\t.limit stack 1

\taload_0
\tinvokenonvirtual java/lang/Object/<init>()V
\treturn
.end method",
".method public static main([Ljava/lang/String;)V
\t.limit stack Y
\t.limit locals Z"]
@@codeAfter = "\treturn\n.end method"
@@prologue = ["\n"]
@@stackSize = 0
@@localSize = 10
@@className = ""
@@labelCounter = 0
@@localCounter = 10


class Token
  @typeName = ""
  @stringValue = ""
  def initialize(type, value)
    @typeName = type
    @stringValue = value
    if(@typeName == "Integer")
      @stringValue = @stringValue.to_i
    end
    if(@typeName == "Float")
      @stringValue = @stringValue.to_f
    end
  end
  
  def typeName
    @typeName
  end
  
  def setTypeName(name)
    @typeName = name
  end
  
  def value
    @stringValue
  end
  
  def to_s
    "[ " + typeName.to_s + ", " + value.to_s + " ]"
  end
end

class Node < Token
  @children = []
  @thisToken = ''
  @returnType = ""
  @Code = ""
  
  def initialize(token)
    if(token != nil)
      super(token.typeName, token.value)
    else
      super(nil,nil)
    end
    @thisToken = token
    @children = []
  end
  
  def token
    @thisToken
  end
  
  def Code
    @Code
  end
  
  def setCode(list)
    @Code = String.new(list)
  end
  
  def returnType
    @returnType
  end
  
  def setReturnType(type)
    @returnType = type
  end
  
  def children
    @children
  end
  
  def addNode(node)
    @children.push(node)
  end
end


@@variableTable = [{}]

@@currentLevel = 0

@@symbolTable =
{
  "mod"=>{"type"=>"Operator"},
  "sin"=>{"type"=>"Operator"},"tan"=>{"type"=>"Operator"},
  "cos"=>{"type"=>"Operator"},"exp"=>{"type"=>"Operator"},
  "begin"=>{"type"=>"Keyword"}, "end"=>{"type"=>"Keyword"},
  "writeint"=>{"type"=>"Write","toPrint"=>"Integer"},
  "writebool"=>{"type"=>"Write","toPrint"=>"Boolean"},
  "writefloat"=>{"type"=>"Write","toPrint"=>"Float"},
  "writestring"=>{"type"=>"Write","toPrint"=>"String"},
  "stdout"=>{"type"=>"Keyword"},
  "insert"=>{"type"=>"Operator"},
  
  "int"=>{"type"=>"Type","typeName"=>"Integer"},
  "float"=>{"type"=>"Type", "typeName"=>"Float"},
  "bool"=>{"type"=>"Type", "typeName" =>"Boolean"},
  "string"=>{"type"=>"Type", "typeName"=>"String"},
  "void"=>{"type"=>"Type", "typeName"=>"Void"},
  
  "if"=>{"type"=>"Keyword"},"while"=>{"type"=>"Keyword"},
  "let"=>{"type"=>"Keyword"},
  "define"=>{"type"=>"Keyword"},
  "true"=>{"type"=>"Boolean"},"false"=>{"type"=>"Boolean"},
  
  "Boolean"=>{"true"=>"Boolean","false"=>"Boolean"},
  
  "loadCode"=>{
    "Integer"=>"iload ",
    "Boolean"=>"iload ",
    "Float"=>"fload ",
    "String"=>"aload ",
    
  },
  
  "storeCode"=>{
    "Integer"=>"istore ",
    "Boolean"=>"istore ",
    "Float"=>"fstore ",
    "String"=>"new java/lang/String\n\tastore ",
    
  },
  
  "Code"=>{
    "Integer"=>{"Value"=>"true","Code"=>"ldc X"},
    "Float"=>{"Value"=>"true","Code"=>"ldc X"},
    "String"=>{"Value"=>"true","Code"=>"ldc X"},
    "Boolean"=>{"Value"=>"true","Code"=>"ldc X"},
    "+Float"=>"fadd", "+Integer"=>"iadd",
    "*Float"=>"fmul", "*Integer"=>"imul",
    "/Float"=>"fdiv", "/Integer"=>"idiv",
    "-Integer"=>"isub","-Float"=>"fsub",
    "+String"=>"invokevirtual java/lang/String/concat(Ljava/lang/String;)Ljava/lang/String;",
    "modInteger"=>"irem",
    "modFloat"=>"frem",
    "sinFloat"=>"f2d\n\tinvokestatic java/lang/Math/sin(D)D\n\td2f",
    "cosFloat"=>"f2d\n\tinvokestatic java/lang/Math/cos(D)D\n\td2f",
    "tanFloat"=>"f2d\n\tinvokestatic java/lang/Math/tan(D)D\n\td2f",
    "expFloat"=>"f2d\n\tinvokestatic java/lang/Math/exp(D)D\n\td2f",
    "^Float"=>"invokestatic java/lang/Math/pow(DD)D\n\td2f",

  },
  
  "BooleanCode"=>{
    "<IntegerInteger"=>"isub\n\tiflt",
    "<FloatFloat"=>"fsub\n\tldc 0.0\n\tfcmpl\n\tiflt",
    "<FloatInteger"=>"fsub\n\tldc 0.0\n\tfcmpl\n\tiflt",
    "<IntegerFloat"=>"fsub\n\tldc 0.0\n\tfcmpl\n\tiflt",
    "<StringString"=>"invokevirtual java/lang/String.compareTo(Ljava/lang/String;)I\n\tiflt",

    "<=IntegerInteger"=>"isub\n\tifle",
    "<=FloatFloat"=>"fsub\n\tldc 0.0\n\tfcmpl\n\tifle",
    "<=FloatInteger"=>"fsub\n\tldc 0.0\n\tfcmpl\n\tifle",
    "<=IntegerFloat"=>"fsub\n\tldc 0.0\n\tfcmpl\n\tifle",
    "<=StringString"=>"invokevirtual java/lang/String.compareTo(Ljava/lang/String;)I\n\tifle",

    ">IntegerInteger"=>"isub\n\tifgt",
    ">FloatFloat"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifgt",
    ">FloatInteger"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifgt",
    ">IntegerFloat"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifgt",
    ">StringString"=>"invokevirtual java/lang/String.compareTo(Ljava/lang/String;)I\n\tifgt",
    
    ">=IntegerInteger"=>"isub\n\tifge",
    ">=FloatFloat"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifge",
    ">=FloatInteger"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifge",
    ">=IntegerFloat"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifge",
    ">=StringString"=>"invokevirtual java/lang/String.compareTo(Ljava/lang/String;)I\n\tifge",
    
    "=IntegerInteger"=>"isub\n\tifeq",
    "=FloatFloat"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifeq",
    "=FloatInteger"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifeq",
    "=IntegerFloat"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifeq",
    "=IntegerBoolean"=>"isub\n\tifeq",
    "=BooleanInteger"=>"isub\n\tifeq",
    "=FloatBoolean"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifeq",
    "=BooleanFloat"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifeq",
    "=StringString"=>"invokevirtual java/lang/String.compareTo(Ljava/lang/String;)I\n\tifeq",
    "=BooleanBoolean"=>"isub\n\tifeq",
    
    "!=IntegerInteger"=>"isub\n\tifne",
    "!=FloatFloat"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifne",
    "!=FloatInteger"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifne",
    "!=IntegerFloat"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifne",
    "!=IntegerBoolean"=>"isub\n\tifne",
    "!=BooleanInteger"=>"isub\n\tifne",
    "!=FloatBoolean"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifne",
    "!=BooleanFloat"=>"fsub\n\tldc 0.0\n\tfcmpg\n\tifne",
    "!=StringString"=>"invokevirtual java/lang/String.compareTo(Ljava/lang/String;)I\n\tifne",
    "!=BooleanBoolean"=>"isub\n\tifne",
    
    "!Integer"=>"ifeq",
    "!Float"=>"ldc 0.0\n\tfcmpg\n\tifeq",
    "!Boolean"=>"ifeq",
    
    "&IntegerBoolean"=>"isub\n\tifeq",
    "&BooleanInteger"=>"isub\n\tifeq",
    "&IntegerInteger"=>"isub\n\tifeq",
    "&BooleanBoolean"=>"isub\n\tifeq",
    
    "|IntegerInteger"=>"iadd\n\tifne",
    "|BooleanInteger"=>"iadd\n\tifne",
    "|IntegerBoolean"=>"iadd\n\tifne",
    "|BooleanBoolean"=>"iadd\n\tifne",
    
    "Default"=>" labelX\nlabelY:\n\tldc 0\n\tgoto labelZ\nlabelX:\n\tldc 1\nlabelZ:"
  },
  
  
  "ifCode"=>{
    "Bool"=>"ifeq labelX\n\tnop",
    "Bool2"=>"ifeq labelX\nlabelY:",
    ## AfterFirst contains dummy code to avoid stack inconsistency errors
    "AfterFirst1"=>"\nlabelX:","AfterFirst2"=>"goto labelZ\nlabelX:",
    "AfterSecond"=>"\nlabelZ:",
  },
  
  "whileCode"=>{
    "Bool"=>"ifne labelX\n\tgoto labelY\nlabelX:",
    "After"=>"labelY:"
  },
  
  "methodSig"=>{
    "Integer"=>"I",
    "Boolean"=>"I",
    "Float"=>"F",
    "String"=>"Ljava/lang/String;",
    "Void"=>"V"
  },
  
  "methodReturn"=>{
    "Integer"=>"\n\tireturn",
    "Boolean"=>"\n\tireturn",
    "Float"=>"\n\tfreturn",
    "String"=>"\n\tareturn",
    "Void"=>"\n\treturn"
  },
  
  "Print"=>{
    "Integer"=>{"Store"=>"","Load"=>"\tgetstatic\tjava/lang/System/out Ljava/io/PrintStream;\n\tswap\n\tinvokevirtual java/io/PrintStream/println(I)V"},
    "Float"=>{"Store"=>"","Load"=>"\tgetstatic\tjava/lang/System/out Ljava/io/PrintStream;\n\tswap\n\tinvokevirtual java/io/PrintStream/println(F)V"},
    "Boolean"=>{"Store"=>"","Load"=>"\tifne labelX\nlabelY:\n\tgetstatic\tjava/lang/System/out Ljava/io/PrintStream;\n\tldc \"False\"
\tinvokevirtual java/io/PrintStream.println(Ljava/lang/String;)V
\tgoto labelZ\nlabelX:
\tgetstatic\tjava/lang/System/out Ljava/io/PrintStream;
\tldc \"True\"
\tinvokevirtual java/io/PrintStream.println(Ljava/lang/String;)V
labelZ:\n"},
  "String"=>{"Store"=>"","Load"=>"\tgetstatic\tjava/lang/System/out Ljava/io/PrintStream;\n\tswap\n\tinvokevirtual java/io/PrintStream/println(Ljava/lang/String;)V"}
  },
  
  "Conversion"=>{
    "IntegerFloat"=>"i2f",
    "FloatInteger"=>"f2i",
    "IntegerDouble"=>"i2d",
    "FloatDouble"=>"f2d",
  },
  
  "BoolConversion"=>{
    "BooleanFloat"=>{"child1"=>"i2f"},
    "FloatBoolean"=>{"child2"=>"i2f"},
    "FloatInteger"=>{"child2"=>"i2f"},
    "IntegerFloat"=>{"child1"=>"i2f"},
    "IntegerBoolean"=>{"child1"=>"\n\tifne labelX\nlabelY:\n\tldc 0\n\tgoto labelZ\nlabelX:\n\tldc 1\nlabelZ:\n"},
    "BooleanInteger"=>{"child2"=>"\n\tifne labelX\nlabelY:\n\tldc 0\n\tgoto labelZ\nlabelX:\n\tldc 1\nlabelZ:\n"},
    "IntegerInteger"=>{"child1"=>"\n\tifne labelX\nlabelY:\n\tldc 0\n\tgoto labelZ\nlabelX:\n\tldc 1\nlabelZ:\n",
                       "child2"=>"\n\tifne labelX\nlabelY:\n\tldc 0\n\tgoto labelZ\nlabelX:\n\tldc 1\nlabelZ:\n"}
  },
  
  
  
  "Operator"=>{
    "+IntegerInteger"=>"Integer","+IntegerFloat"=>"Float","+FloatInteger"=>"Float","+FloatFloat"=>"Float",
    "+StringString"=>"String",
    
    "-IntegerInteger"=>"Integer", "-IntegerFloat"=>"Float", "-FloatInteger"=>"Float", "-FloatFloat"=>"Float",
    "*IntegerInteger"=>"Integer", "*IntegerFloat"=>"Float", "*FloatInteger"=>"Float", "*FloatFloat"=>"Float",
    "/IntegerInteger"=>"Integer", "/IntegerFloat"=>"Float", "/FloatInteger"=>"Float", "/FloatFloat"=>"Float", 
    
    "modIntegerInteger"=>"Integer","modFloatInteger"=>"Float","modIntegerFloat"=>"Float",
    "modFloatFloat"=>"Float",
    
    "-Integer"=>"Integer", "-Float"=>"Float",
    "+Integer"=>"Integer", "+Float"=>"Float",
    
    "sinFloat"=>"Float","cosFloat"=>"Float",
    "tanFloat"=>"Float","expFloat"=>"Float",
    
    "^FloatInteger"=>"Float","^FloatFloat"=>"Float",
    
    "!Integer"=>"Boolean","!Float"=>"Boolean", "!Boolean"=>"Boolean",
    
    "&IntegerBoolean"=>"Boolean","&BooleanInteger"=>"Boolean","&IntegerInteger"=>"Boolean","&BooleanBoolean"=>"Boolean",
    "|IntegerInteger"=>"Boolean","|BooleanInteger"=>"Boolean","|IntegerBoolean"=>"Boolean","|BooleanBoolean"=>"Boolean",
    
    "=IntegerInteger"=>"Boolean","=IntegerBoolean"=>"Boolean","=BooleanInteger"=>"Boolean","=FloatBoolean"=>"Boolean",
    "=BooleanFloat"=>"Boolean","=IntegerFloat"=>"Boolean","=FloatInteger"=>"Boolean","=FloatFloat"=>"Boolean",
    "=StringString"=>"Boolean","=BooleanBoolean"=>"Boolean",
    
    "<=IntegerInteger"=>"Boolean","<=FloatFloat"=>"Boolean","<=IntegerFloat"=>"Boolean","<=FloatInteger"=>"Boolean",
    "<=StringString"=>"Boolean",
    
    "<IntegerInteger"=>"Boolean","<FloatFloat"=>"Boolean","<IntegerFloat"=>"Boolean","<FloatInteger"=>"Boolean",
    "<StringString"=>"Boolean",
    
    ">=IntegerInteger"=>"Boolean",">=FloatFloat"=>"Boolean",">=IntegerFloat"=>"Boolean",">=FloatInteger"=>"Boolean",
    ">=StringString"=>"Boolean",
    
    ">IntegerInteger"=>"Boolean",">FloatFloat"=>"Boolean",">IntegerFloat"=>"Boolean",">FloatInteger"=>"Boolean",
    ">StringString"=>"Boolean",
    
    "!=IntegerInteger"=>"Boolean","!=IntegerBoolean"=>"Boolean","!=BooleanInteger"=>"Boolean","!=FloatBoolean"=>"Boolean",
    "!=BooleanFloat"=>"Boolean","!=IntegerFloat"=>"Boolean","!=FloatInteger"=>"Boolean","!=FloatFloat"=>"Boolean",
    "!=StringString"=>"Boolean","!=BooleanBoolean"=>"Boolean",
    
    ":=IntegerInteger"=>"Integer",":=FloatFloat"=>"Float",":=StringString"=>"String",
    ":=BooleanBoolean"=>"Boolean",
    
  }
}
example ="invokestatic problem10.convertint(I)D
dstore_1
getstatic java/lang/System/out Ljava/io/PrintStream;
dload_1
invokevirtual java/io/PrintStream.println(D)V
return
.end method

.method public static convertint(I)D
.limit locals 1
.limit stack 2

iload_0
i2d
dreturn
.end method"