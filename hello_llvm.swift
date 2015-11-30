import LLVM_C

let module = LLVMModuleCreateWithName("Hello")

let int32 = LLVMInt32Type()

let paramTypes = [int32, int32]

// need to convert paramTypes into UnsafeMutablePointer because of API requirements
var paramTypesRef = UnsafeMutablePointer<LLVMTypeRef>.alloc(paramTypes.count)
paramTypesRef.initializeFrom(paramTypes)

let returnType = int32
let functionType = LLVMFunctionType(returnType, paramTypesRef, UInt32(paramTypes.count), 0)

let sumFunction = LLVMAddFunction(module, "sum", functionType)

let entryBlock = LLVMAppendBasicBlock(sumFunction, "entry")

let builder = LLVMCreateBuilder()
LLVMPositionBuilderAtEnd(builder, entryBlock)

let a = LLVMGetParam(sumFunction, 0)
let b = LLVMGetParam(sumFunction, 1)
let temp = LLVMBuildAdd(builder, a, b, "temp")
LLVMBuildRet(builder, temp)

LLVMDumpModule(module)

let engine = UnsafeMutablePointer<LLVMExecutionEngineRef>.alloc(alignof(LLVMExecutionEngineRef))
var error =  UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(alignof(UnsafeMutablePointer<Int8>))

LLVMLinkInInterpreter()

if LLVMCreateInterpreterForModule(engine, module, error) != 0 {
  print("can't initialize engine: \(String.fromCString(error.memory)!)")
	// TODO: cleanup all allocated memory ;)
  exit(1)
}

let x: UInt64 = 10
let y: UInt64 = 25

let args = [LLVMCreateGenericValueOfInt(int32, x, 0), 
            LLVMCreateGenericValueOfInt(int32, y, 1)]

var argsRef = UnsafeMutablePointer<LLVMTypeRef>.alloc(args.count)
argsRef.initializeFrom(args)

let result = LLVMRunFunction(engine.memory, sumFunction, UInt32(args.count), argsRef)

print("\(x) + \(y) = \(LLVMGenericValueToInt(result, 0))")

argsRef.dealloc(args.count)

paramTypesRef.dealloc(paramTypes.count)
LLVMDisposeModule(module)

