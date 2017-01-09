declare -i number_of_rows=4001
declare -i number_of_cols=4001


echo "Size: $number_of_rows * $number_of_cols"

echo "Sequential CPU"
nvcc -g -G -arch=sm_20 -Xcompiler -fopenmp -lpthread -lcuda -lcudart -lgomp -DBLOCK_SIZE=256 -DnRows=$number_of_rows -DnCols=$number_of_cols -DTILE_ROWS=256 -DTILE_COLS=256 -DdependencyWidthLeft=4 -DdependencyWidthRight=0 cpu_basic.cu
chmod 777 a.out
./a.out

for ((i=128; i<=1024; i=i*2 )) ; 
do
    echo "GPU Basic( block size : $i)"
    nvcc -g -G -arch=sm_20 -Xcompiler -fopenmp -lpthread -lcuda -lcudart -lgomp -DBLOCK_SIZE=$i -DnRows=$number_of_rows -DnCols=$number_of_cols -DTILE_ROWS=256 -DTILE_COLS=256 -DdependencyWidthLeft=4 -DdependencyWidthRight=0 gpu_basic.cu
    chmod 777 a.out
    ./a.out
    ./a.out
    ./a.out

    echo "Checking correctness:"
    if cmp -s files_output/o_cpu_basic.txt files_output/o_gpu_basic.txt
    then 
        echo "Correct, Files Same"
    else
        echo "Incorrect, Files changed"
    fi

done

for ((i=25; i<=1000; i=i*2 )) ; 
do
	echo "GPU Tiled Shared-Memory( tile size : $i * $i)"
    nvcc -g -G -arch=sm_20 -Xcompiler -fopenmp -lpthread -lcuda -lcudart -lgomp -DBLOCK_SIZE=256 -DnRows=$number_of_rows -DnCols=$number_of_cols -DTILE_ROWS=$i -DTILE_COLS=$i gpu_tiled_shmem.cu
    chmod 777 a.out
    ./a.out
    ./a.out
    ./a.out

    echo "Checking correctness:"
    if cmp -s files_output/o_cpu_basic.txt files_output/o_gpu_tiled_shmem.txt
    then 
    	echo "Correct, Files Same"
	else
		echo "Incorrect, Files changed"
	fi

done