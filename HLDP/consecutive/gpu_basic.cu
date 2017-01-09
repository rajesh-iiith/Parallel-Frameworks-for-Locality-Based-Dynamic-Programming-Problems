
#include "headers/myHeaders.h"
#include "headers/myUtilityFunctions.h"

using namespace std;


int main(int argc, char const *argv[])
{	
	
	//create array at host : initialize accordingly
	cellType *h_array;
	h_array = create_array_host();

	//initialize base row arguments (cellType *h_array, int rowNumber, int mode, int value)
	// : mode =1 for random initialization, put any value in that case
	initialize_this_row(h_array, 0, 1, -1);
	 
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
	cout <<"Time (Basic GPU): " <<phase1.Elapsed()<< " Milli Seconds\n";

	//copy back to cpu
    copy_device_to_host(h_array, d_array);
	
	//Access the resultant matrix : dump into output file
	//write_array_console(h_array);
	//ofstream myfile ("files_output/o_gpu_basic.txt");
	//write_array_file(h_array, myfile);
	
	
	return 0;
}

__global__ void update_array_gpu(int i, int numberOfThreadsRequired, cellType *d_array )
{
   long j=blockIdx.x *blockDim.x + threadIdx.x + 1;
   
   if (j>= numberOfThreadsRequired || j < dependencyWidthLeft)
      {}
   else
   {
   			int a = (d_array(i,j).value1 + d_array(i-1,j).value1) / (d_array(i-1,j).value2 + 3) ;
			int b = (d_array(i,j).value1 + d_array(i-1,j-1).value1) / (d_array(i-1,j-1).value2 + 3);
			int c = (d_array(i,j).value1 + d_array(i-1,j-2).value1) + (d_array(i-1,j-2).value2 + 3);

			if ((a >= b) && (a >=c))
			{
				d_array(i,j).value1 = a;
				d_array(i,j).value2 = d_array(i-1,j).value2 + 3;
			}
			else
			{
				if ((b >= a) && (b >=c))
				{
					d_array(i,j).value1 = b;
					d_array(i,j).value2 = d_array(i-1,j-1).value2 + 3;
				}
				else
				{
					d_array(i,j).value1 = c;
					d_array(i,j).value2 = d_array(i-1,j-2).value2 + 3;
				}
			}
   }
}
