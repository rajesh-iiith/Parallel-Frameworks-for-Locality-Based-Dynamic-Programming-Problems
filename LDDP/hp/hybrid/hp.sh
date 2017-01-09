for ((i=4097; i<=17000; i=i+4096 )) ; 
do
	echo "CPU ( size : $i)"
	nvcc -g -G -arch=sm_20 -Xcompiler -fopenmp -lpthread -lcuda -lcudart -lgomp -D nRows=$i -D nCols=$i hpGpu.cu
    ./a.out
    ./a.out
    ./a.out
done
