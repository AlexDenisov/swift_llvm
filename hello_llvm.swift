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

LLVMLinkInMCJIT()
LLVMInitializeNativeTarget()
LLVMInitializeNativeAsmPrinter()

func runSumFunction(a: Int, _ b: Int) -> Int {
  let functionType = LLVMFunctionType(returnType, nil, 0, 0)
  let wrapperFunction = LLVMAddFunction(module, "", functionType)
  defer {
    LLVMDeleteFunction(wrapperFunction)
  }

  let entryBlock = LLVMAppendBasicBlock(wrapperFunction, "entry")

  let builder = LLVMCreateBuilder()
  LLVMPositionBuilderAtEnd(builder, entryBlock)

  let argumentsCount = 2
  var argumentValues = [LLVMValueRef]()
  
  argumentValues.append(LLVMConstInt(int32, UInt64(a), 0))
  argumentValues.append(LLVMConstInt(int32, UInt64(b), 0))

  let argumentsPointer = UnsafeMutablePointer<LLVMValueRef>.alloc(strideof(LLVMValueRef) * argumentsCount)
  defer {
    argumentsPointer.dealloc(strideof(LLVMValueRef) * argumentsCount)
  }
  argumentsPointer.initializeFrom(argumentValues)

  let callTemp = LLVMBuildCall(builder, 
                               sumFunction,
                               argumentsPointer,
                               UInt32(argumentsCount), "sum_temp")
  LLVMBuildRet(builder, callTemp)

  let executionEngine = UnsafeMutablePointer<LLVMExecutionEngineRef>.alloc(strideof(LLVMExecutionEngineRef))
  let error = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(strideof(UnsafeMutablePointer<Int8>))

  defer {
    error.dealloc(strideof(UnsafeMutablePointer<Int8>))
    executionEngine.dealloc(strideof(LLVMExecutionEngineRef))
  }

  let res = LLVMCreateExecutionEngineForModule(executionEngine, module, error)
  if res != 0 {
    let msg = String.fromCString(error.memory)
    print("\(msg)")
    exit(1)
  }

  let value = LLVMRunFunction(executionEngine.memory, wrapperFunction, 0, nil)
  let result = LLVMGenericValueToInt(value, 0)
  return Int(result)
}

print("\(runFunction(5, 6))")
print("\(runFunction(7, 142))")
print("\(runFunction(557, 1024))")

LLVMDisposeModule(module)

