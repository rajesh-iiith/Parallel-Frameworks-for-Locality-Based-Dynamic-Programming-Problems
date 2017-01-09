
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

   //named even/odd by the iteration number in which array is used
   const int columnWidth = TILE_COLS + dependencyWidthLeft;
   __shared__ cellType jointArray [2 * (columnWidth)];
   
   // iter: 1
   jointArray[columnWidth + threadIdx.x] = d_array(r-1, myCol);
   __syncthreads();
   if (threadIdx.x >= dependencyWidthLeft)
   	{
		jointArray[threadIdx.x] = (jointArray[columnWidth + threadIdx.x] + jointArray[columnWidth + threadIdx.x -1] + jointArray[columnWidth + threadIdx.x -2] + 1) % 10;	
		d_array(r, myCol) = jointArray[threadIdx.x];
   	}
   	__syncthreads();

   	// iter: 2 and onwards
   for (int iter = 2; iter <= TILE_ROWS; ++iter)
   {
	   	int myRow = r + (iter-1);
	   	int oo_ee = -((iter % 2) - 1 ) * columnWidth;
	   	int oe_eo = (iter % 2) * columnWidth;
	   	//step 1: copy the required portion from global and remaining portion from shared
	   	
   		if ( (threadIdx.x < dependencyWidthLeft) )	
   		{
   			jointArray[oe_eo + threadIdx.x] = d_array(myRow-1, myCol);
   		}
	 	__syncthreads();

	   	// step 2: operate and don't forget to copy shared and global memory both.
	   	if (threadIdx.x >= dependencyWidthLeft)
	   	{	
	   		jointArray[oo_ee + threadIdx.x] = (jointArray[oe_eo + threadIdx.x] + jointArray[oe_eo + threadIdx.x -1] + jointArray[oe_eo + threadIdx.x -2] + 1) %10;
	   		d_array(myRow, myCol) = jointArray[oo_ee + threadIdx.x];		
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
	ofstream myfile ("files_output/o_gpu_tiled_shmem_v2.txt");
	write_array_file(h_array, myfile);
	
	
	return 0;
}

