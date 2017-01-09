
#include "headers/myHeaders.h"
#include "headers/myUtilityFunctions.h"

using namespace std;


int main(int argc, char const *argv[])
{	
	
	//create array at host : initialize accordingly
	cellType *h_array;
	h_array = create_array_host();
	 
	//Create array at device
	cellType *d_array;
	cudaMalloc((void**) &d_array, sizeof(cellType)*(nRows*TOTAL_COLS));

	//copy host array to device arrray, if needed
	copy_host_to_device(h_array, d_array);
	
	//configure kernel
	//cwThreads do both copy and work, cThreads just do copy 
	int cwThreadsPerBlock = BLOCK_SIZE - dependencyWidthLeft;
	int threadsToBeLaunched = (((nCols / cwThreadsPerBlock) + 1) * BLOCK_SIZE);
	int lastGloballyActiveThread = TOTAL_COLS + ((nCols / cwThreadsPerBlock) * dependencyWidthLeft);
	configure_kernal_shmem(threadsToBeLaunched);
	cout << dependencyWidthLeft <<","<< threadsToBeLaunched << "," << g << "," << x << "\n"; 

	GpuTimer phase1;
	phase1.Start();
	
	//execute on GPU, row by row
   for (int i = 1; i < nRows; ++i)
   {
	   	update_array_gpu_shmem<<<dim3(g,1,1), dim3(x,1,1)>>>(i, lastGloballyActiveThread, cwThreadsPerBlock, d_array);
   }

	phase1.Stop();
	cout <<"Time (shared mamory GPU): " <<phase1.Elapsed()<< " Milli Seconds\n";

	//copy back to cpu
    copy_device_to_host(h_array, d_array);
	
	//Access the resultant matrix : dump into output file
	//write_array_console(h_array);
	//write_array_file(h_array, "../files_output/output_s.txt");
	
	
	return 0;
}

__global__ void update_array_gpu_shmem(int i, int lastGloballyActiveThread, int cwThreadsPerBlock, cellType *d_array )
{
   //create shared array
   __shared__ cellType d_array_shared[BLOCK_SIZE];
   
   //copy appropriate chunk of global array into shared array 
   long local_index = threadIdx.x; //logically sud be +1
   long j = local_index + (cwThreadsPerBlock*blockIdx.x);
   long global_index = blockIdx.x *blockDim.x + threadIdx.x + 1;
   
   d_array_shared[local_index] = d_array(i-1,j);

   //synch threads after copy
   //__syncthreads();

   if (global_index >= lastGloballyActiveThread + 1 || threadIdx.x <= (dependencyWidthLeft - 1))
      {}
   else
   {
	//write back the result into global array


	d_array(i,j) =  (d_array_shared[local_index]  + d_array_shared[local_index -1]) * d_array_shared[local_index -2]  / (d_array_shared[local_index -3] + d_array_shared[local_index -4] + d_array_shared[local_index -5] + d_array_shared[local_index -6] + 1);
	
   }
}