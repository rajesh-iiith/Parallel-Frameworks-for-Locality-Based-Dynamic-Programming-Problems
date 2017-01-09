for ((i=200; i<=2000; i=i+200 )) ; 
do
	echo "Hybrid (4k x 4k) for cutoff: $i"
	nvcc -g -G -arch=sm_20 -Xcompiler -fopenmp -lpthread -lcuda -lcudart -lgomp -D nRows=4097 -D nCols=4097 -D CUTOFF_HANDOVER=$i dpHybrid.cu
    ./a.out
    ./a.out
    ./a.out
done

for ((i=4097; i<=17000; i=i+4096 )) ; 
do
	echo "Hybrid ( size : $i) for cutoff 1200"
	nvcc -g -G -arch=sm_20 -Xcompiler -fopenmp -lpthread -lcuda -lcudart -lgomp -D nRows=$i -D nCols=$i -D CUTOFF_HANDOVER=1200 dpHybrid.cu
    ./a.out
    ./a.out
    ./a.out
done

for ((i=4097; i<=17000; i=i+4096 )) ; 
do
	echo "CPU ( size : $i)"
	nvcc -g -G -arch=sm_20 -Xcompiler -fopenmp -lpthread -lcuda -lcudart -lgomp -D nRows=$i -D nCols=$i dpCpu.cu
    ./a.out
    ./a.out
    ./a.out
done

for ((i=4097; i<=17000; i=i+4096 )) ; 
do
	echo "GPU ( size : $i)"
	nvcc -g -G -arch=sm_20 -Xcompiler -fopenmp -lpthread -lcuda -lcudart -lgomp -D nRows=$i -D nCols=$i dpGpu.cu
    ./a.out
    ./a.out
    ./a.out
done