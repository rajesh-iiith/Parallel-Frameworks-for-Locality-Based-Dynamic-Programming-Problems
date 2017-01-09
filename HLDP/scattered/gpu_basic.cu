
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
	initialize_this_row(h_array, 0, 0, 0);
	initialize_this_col(h_array, 0, 0, 0);
	 
	//Create array at device
	cellType *d_array;
	cudaMalloc((void**) &d_array, sizeof(cellType)*(nRows*TOTAL_COLS));

	//copy host array to device arrray, if needed
	copy_host_to_device(h_array, d_array);

	// create/initialize and transfer other resources and pass to the function
	//int W = nRows;

	/*int h_v[5] = {0, 10, 40, 30, 50};
	int h_w[5] = {0, 5, 4, 6, 3};*/
	
	int *h_v = create_array_host_1D(nRows);
	initialize_this_1D_array(h_v, nRows);
	int *d_v;
	cudaMalloc((void**) &d_v, sizeof(int)*(nRows));
	copy_host_to_device_1D(h_v, d_v, nRows);

	int *h_w = create_array_host_1D(nRows);
	initialize_this_1D_array(h_w, nRows);
	int *d_w;
	cudaMalloc((void**) &d_w, sizeof(int)*(nRows));
	copy_host_to_device_1D(h_w, d_w, nRows);
	
	//configure kernel
	configure_kernal(TOTAL_COLS);

	GpuTimer phase1;
	phase1.Start();
	
	//execute on GPU, row by row
   for (int i = 1; i < nRows; ++i)
   {
	   	update_array_gpu<<<dim3(g,1,1), dim3(x,1,1)>>>(i, nCols, d_array, d_v, d_w);
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

__global__ void update_array_gpu(int i, int numberOfThreadsRequired, cellType *d_array, int *d_v, int *d_w)
{
   long j=blockIdx.x *blockDim.x + threadIdx.x + 1;

   if (j>= numberOfThreadsRequired || j < 1)
      {}
   else
   {
		int j_ext = j - d_w[i];
		if (j_ext <= 0)
			j_ext = 0;
		int a = d_array(i-1,j);
		int b = d_v[i] + d_array(i-1,j_ext);
		(( (d_w[i]) > j || (a >= b)) ? d_array(i,j) = a : d_array(i,j) = b );
	}
}
