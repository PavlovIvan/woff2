all: woff2 woff2_c

brotli:
	make -C src/brotli/ -f ../Makefile.brotli

woff2: brotli
	make -C src/woff2/ -f ../Makefile.woff2
	npm install

woff2_c: brotli_c
	mkdir -p build/cpp/woff2
	cd build/cpp/woff2; cmake -DBROTLIDEC_INCLUDE_DIRS=../brotli/installed/include \
	  -DBROTLIDEC_LIBRARIES=../brotli/installed/lib/libbrotlidec.so \
	  -DBROTLIENC_INCLUDE_DIRS=../brotli/installed/include \
	  -DBROTLIENC_LIBRARIES=../brotli/installed/lib/libbrotlienc.so ../../../src/woff2
	make -C build/cpp/woff2

brotli_c:
	mkdir -p build/cpp/brotli
	cd build/cpp/brotli; cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=./installed ../../../src/brotli
	cd build/cpp/brotli; cmake --build . --config Release --target install

test: files_exist
	mkdir -p test/temporary
	cp test/fixtures/fontelico.ttf test/temporary
	
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:build/cpp/brotli/installed/lib; build/cpp/woff2/woff2_compress test/temporary/fontelico.ttf
	node bin/woff2_compress.js test/temporary/fontelico.ttf test/temporary/fontelico_js.woff2
	cmp test/temporary/fontelico.woff2 test/temporary/fontelico_js.woff2
	
	rm test/temporary/fontelico.ttf
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:build/cpp/brotli/installed/lib; build/cpp/woff2/woff2_decompress test/temporary/fontelico.woff2
	node bin/woff2_decompress.js test/temporary/fontelico.woff2 test/temporary/fontelico_js.ttf
	cmp test/temporary/fontelico.ttf test/temporary/fontelico_js.ttf

	rm test/temporary/*

benchmark: files_exist
	test/benchmark.sh

files_exist:
	[ -e build/cpp/woff2/woff2_compress ]
	[ -e build/cpp/woff2/woff2_decompress ]
	[ -e build/woff2/compress_binding.js ]
	[ -e build/woff2/compress_binding.wasm ]
	[ -e build/woff2/decompress_binding.js ]
	[ -e build/woff2/decompress_binding.wasm ]

clean:
	make -C src/brotli/ -f ../Makefile.brotli clean	
	make -C src/woff2/ -f ../Makefile.woff2 clean
	rm -rf src/brotli/out
	rm -rf src/woff2/out
