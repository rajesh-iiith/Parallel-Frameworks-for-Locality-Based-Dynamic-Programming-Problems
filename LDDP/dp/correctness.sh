for ((i=4097; i<=17000; i=i+4096 )) ; 
do
	cd hybrid
	nvcc -g -G -arch=sm_20 -Xcompiler -fopenmp -lpthread -lcuda -lcudart -lgomp -D nRows=$i -D nCols=$i dpCpu.cu
	./a.out
	cd ..
	cd tiling
	nvcc -g -G -arch=sm_20 -Xcompiler -fopenmp -lpthread -lcuda -lcudart -lgomp -D nRows=$i -D nCols=$i dpTiledGpu.cu
	./a.out
	cd ..
	diff output_s.txt output_p.txt
done