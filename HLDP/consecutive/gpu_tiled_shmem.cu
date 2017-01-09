
#include "headers/myHeaders.h"
#include "headers/myUtilityFunctions.h"

using namespace std;

__global__ void update_array_gpu_tiled(int mode, int i, cellType *d_array)
{
   int myBlockId = (blockIdx.x) + 1;
   int r,c;

   //generate hanging points (r,c)
   if (mode == 1)
   {
    	r = 1 + (i-1) * TILE_ROWS - ( (myBlockId - 1) * TILE_ROWS);
    	c = (myBlockId - 1) * TILE_COLS + dependencyWidthLeft;
    }
   else
   {
   		int midPointIteration = nCols / TILE_COLS;
   		r = (1 + (midPointIteration - 1) * TILE_ROWS) - ((myBlockId - 1) * TILE_ROWS);
		c = ((midPointIteration - i) * (TILE_COLS)) + ((myBlockId - 1)* TILE_COLS) + dependencyWidthLeft ;
   }

   //generate my location and process the block
   // myCol is the column assigned to thread x of a given block
   int myCol = c + threadIdx.x - dependencyWidthLeft;
   
   __shared__ cellType sharedArray [TILE_COLS + dependencyWidthLeft];
   

   for (int iter = 1; iter <= TILE_ROWS; ++iter)
   {
   	int myRow = r + (iter-1);
   	sharedArray[threadIdx.x] = d_array(myRow-1, myCol);
   	__syncthreads();
   	if (threadIdx.x >= dependencyWidthLeft)
   	{
   			int a = (d_array(myRow, myCol).value1 + sharedArray[threadIdx.x].value1) / (sharedArray[threadIdx.x].value2 + 3) ;
			int b = (d_array(myRow, myCol).value1 + sharedArray[threadIdx.x - 1].value1) / (sharedArray[threadIdx.x - 1].value2 + 3);
			int c = (d_array(myRow, myCol).value1 + sharedArray[threadIdx.x - 2].value1) + (sharedArray[threadIdx.x - 2].value2 + 3);

			if ((a >= b) && (a >=c))
			{
				d_array(myRow, myCol).value1 = a;
				d_array(myRow, myCol).value2 = sharedArray[threadIdx.x].value2 + 3;
			}
			else
			{
				if ((b >= a) && (b >=c))
				{
					d_array(myRow, myCol).value1 = b;
					d_array(myRow, myCol).value2 = sharedArray[threadIdx.x - 1].value2 + 3;
				}
				else
				{
					d_array(myRow, myCol).value1 = c;
					d_array(myRow, myCol).value2 = sharedArray[threadIdx.x - 2].value2 + 3;
				}
			}
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
	initialize_this_row(h_array, 0, 1, -1);

	 
	//Create array at device
	cellType *d_array;
	cudaMalloc((void**) &d_array, sizeof(cellType)*((nRows) * TOTAL_COLS));

	//copy host array to device arrray, if needed
	copy_host_to_device(h_array, d_array);

	GpuTimer phase1;
	phase1.Start();
	
	//create a wrapper to design tiling iterations
	int ThreadsPerBlock = dependencyWidthLeft + TILE_COLS;
	for (int i = 1; i <= (nRows/TILE_ROWS); i++)
	{
		//number of blocks in the ith iteration will be equal to i
		update_array_gpu_tiled<<<dim3(i,1,1), dim3(ThreadsPerBlock,1,1)>>>(1, i, d_array);
	}
	for (int i = (nRows/TILE_ROWS)-1; i >= 1; i--)
	{
		//number of blocks in the ith iteration will be equal to i
		update_array_gpu_tiled<<<dim3(i,1,1), dim3(ThreadsPerBlock,1,1)>>>(2, i, d_array);
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

