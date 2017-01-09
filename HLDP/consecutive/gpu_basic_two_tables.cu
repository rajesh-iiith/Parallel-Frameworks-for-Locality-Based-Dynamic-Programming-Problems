
#include "headers/myHeaders.h"
#include "headers/myUtilityFunctions.h"

using namespace std;



__global__ void update_array_gpu_two_tables(int i, int numberOfThreadsRequired, cellType *d_array, cellType *d_T )
{
   long j=blockIdx.x *blockDim.x + threadIdx.x + 1;
   
   if (j>= numberOfThreadsRequired || j < dependencyWidthLeft)
      {}
   else
   {
   	d_array(i,j)= (d_array(i-1,j) + d_array(i-1,j-1)) * d_array(i-1,j-2) / (d_array(i-1,j-3) + d_array(i-1,j-4) +d_array(i-1,j-5) +d_array(i-1,j-6) +1);
   	d_T(i,j)= (d_T(i-1,j) + d_T(i-1,j-1)) * d_T(i-1,j-2) / (d_T(i-1,j-3) + d_T(i-1,j-4) +d_T(i-1,j-5) +d_T(i-1,j-6) +1);
   }
}


int main(int argc, char const *argv[])
{	
	
	//create array at host : initialize accordingly
	cellType *h_array, *h_T;
	h_array = create_array_host();
	h_T = create_array_host();

 
	//Create array at device
	cellType *d_array, *d_T;
	cudaMalloc((void**) &d_array, sizeof(cellType)*(nRows*TOTAL_COLS));
	cudaMalloc((void**) &d_T, sizeof(cellType)*(nRows*TOTAL_COLS));

	//copy host array to device arrray, if needed
	copy_host_to_device(h_array, d_array);
	copy_host_to_device(h_T, d_T);
	
	//configure kernel
	configure_kernal(TOTAL_COLS);

	GpuTimer phase1;
	phase1.Start();
	
	//execute on GPU, row by row
   for (int i = 1; i < nRows; ++i)
   {
	   	update_array_gpu_two_tables<<<dim3(g,1,1), dim3(x,1,1)>>>(i, TOTAL_COLS, d_array, d_T);
   }

	phase1.Stop();
	cout <<"Time (basic GPU): " <<phase1.Elapsed()<< " Milli Seconds\n";

	//copy back to cpu
    copy_device_to_host(h_array, d_array);
    copy_device_to_host(h_T, d_T);
	
	//Access the resultant matrix : dump into output file
	//write_array_console(h_array);
	//write_array_file(h_array, "../files_output/output_s.txt");
	
	
	return 0;
}
