
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
	configure_kernal(TOTAL_COLS);

	GpuTimer phase1;
	phase1.Start();
	
	//execute on GPU, row by row
   for (int i = 1; i < nRows; ++i)
   {
	   	update_array_gpu<<<dim3(g,1,1), dim3(x,1,1)>>>(i, TOTAL_COLS, d_array);
   }

	phase1.Stop();
	cout <<"Time (basic GPU): " <<phase1.Elapsed()<< " Milli Seconds\n";

	//copy back to cpu
    copy_device_to_host(h_array, d_array);
	
	//Access the resultant matrix : dump into output file
	//write_array_console(h_array);
	//write_array_file(h_array, "../files_output/output_s.txt");
	
	
	return 0;
}

__global__ void update_array_gpu(int i, int numberOfThreadsRequired, cellType *d_array )
{
   long j=blockIdx.x *blockDim.x + threadIdx.x + 1;
   
   if (j>= numberOfThreadsRequired || j < dependencyWidthLeft)
      {}
   else
   {
   	d_array(i,j).value1= (d_array(i-1,j).value1 + d_array(i-1,j-1).value1) * d_array(i-1,j-2).value1 / (d_array(i-1,j-3).value1 + d_array(i-1,j-4).value1 +d_array(i-1,j-5).value1 +d_array(i-1,j-6).value1 +1);
   	d_array(i,j).value2= (d_array(i-1,j).value2 + d_array(i-1,j-1).value2) * d_array(i-1,j-2).value2 / (d_array(i-1,j-3).value2 + d_array(i-1,j-4).value2 +d_array(i-1,j-5).value2 +d_array(i-1,j-6).value2 +1);

   	//d_array(i,j)= (d_array(i-1,j) + d_array(i-1,j-1)) * d_array(i-1,j-2) / (d_array(i-1,j-3) + d_array(i-1,j-4) +d_array(i-1,j-5) +d_array(i-1,j-6) +1);

   }
}
