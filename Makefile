all:
	xcrun -sdk macosx swiftc hello_llvm.swift \
					-module-link-name LLVM_C \
					`./build/bin/llvm-config --libs interpreter` \
					-L ./build/lib \
					-lc++ -lcurses \
					-I ./llvm/include -I ./build/include \
					-Xcc -D__STDC_CONSTANT_MACROS \
					-Xcc -D__STDC_LIMIT_MACROS \
					-Xcc -D__STDC_FORMAT_MACROS

