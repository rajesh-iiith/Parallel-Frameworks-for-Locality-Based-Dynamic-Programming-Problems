
#include "headers/myHeaders.h"
#include "headers/myUtilityFunctions.h"

using namespace std;

__global__ void update_array_gpu_tiled(int mode, int i, cellType *d_array, int *d_v, int *d_w, int dependencyWidthLeft)
{
   int myBlockId = (blockIdx.x) + 1;
   int r,c;

   //generate hanging points (r,c)
   if (mode == 1)
   {
    	r = 1 + (i-1) * TILE_ROWS - ( (myBlockId - 1) * TILE_ROWS);
    	c = 1 + (myBlockId - 1) * TILE_COLS;
    }
   else
   {
   		int midPointIteration = nCols / TILE_COLS;
   		r = (1 + (midPointIteration - 1) * TILE_ROWS) - ((myBlockId - 1) * TILE_ROWS);
		c = 1 + ((midPointIteration - i) * (TILE_COLS)) + ((myBlockId - 1)* TILE_COLS);
   }

	//correct till r,c
   //generate my location and process the block
   // myCol is the column assigned to thread x of a given block
   int myCol = c + threadIdx.x - dependencyWidthLeft;
  __shared__ cellType sharedArray [TILE_COLS + 10];
   
   for (int iter = 1; iter <= TILE_ROWS; ++iter)
   {
   	int myRow = r + (iter-1);
   	//copy
   	if (myCol >= 0)
   		sharedArray[threadIdx.x] = d_array(myRow-1, myCol);
   	else
   		sharedArray[threadIdx.x] = d_array(myRow-1, 0);
   	__syncthreads();
   	
   	if (threadIdx.x >= dependencyWidthLeft)
   	{
   		int a = sharedArray[threadIdx.x];
		int b = d_v[myRow] + sharedArray[threadIdx.x - d_w[myRow]];
		(( (d_w[myRow] > myCol) || (a >= b)) ? d_array(myRow,myCol) = a : d_array(myRow,myCol) = b );
   	  //d_array(myRow, myCol) = (sharedArray[threadIdx.x] + sharedArray[threadIdx.x -1 ] + sharedArray[threadIdx.x -2] + 1) % 10;
   	}
   	__syncthreads();
   }
}



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

	GpuTimer phase1;
	phase1.Start();
	
	int dependencyWidthLeft = 10;
	//create a wrapper to design tiling iterations
	int ThreadsPerBlock = dependencyWidthLeft + TILE_COLS;
	for (int i = 1; i <= (nRows/TILE_ROWS); i++)
	{
		//number of blocks in the ith iteration will be equal to i
		update_array_gpu_tiled<<<dim3(i,1,1), dim3(ThreadsPerBlock,1,1)>>>(1, i, d_array, d_v, d_w, dependencyWidthLeft);
	}
	for (int i = (nRows/TILE_ROWS)-1; i >= 1; i--)
	{
		//number of blocks in the ith iteration will be equal to i
		update_array_gpu_tiled<<<dim3(i,1,1), dim3(ThreadsPerBlock,1,1)>>>(2, i, d_array, d_v, d_w, dependencyWidthLeft);
	}
	
	phase1.Stop();
	cout <<"Time (Tiled GPU): " <<phase1.Elapsed()<< " Milli Seconds\n";

	//copy back to cpu
    copy_device_to_host(h_array, d_array);
	
	//Access the resultant matrix : dump into output file
	//write_array_console(h_array);
	//ofstream myfile ("files_output/o_gpu_tiled_shmem.txt");
	//write_array_file(h_array, myfile);
	
	
	return 0;
}

