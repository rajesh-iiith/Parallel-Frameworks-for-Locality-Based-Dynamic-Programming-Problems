
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
   
   int *h_v = create_array_host_1D(nCols);
   initialize_this_1D_array(h_v, nCols);
   int *d_v;
   cudaMalloc((void**) &d_v, sizeof(int)*(nCols));
   copy_host_to_device_1D(h_v, d_v, nCols);

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
      update_array_gpu_hybrid<<<dim3(g,1,1), dim3(x,1,1)>>>(i, nCols, d_array, d_v, d_w);
   }

   phase1.Stop();
   cout <<"Time (Basic GPU): " <<phase1.Elapsed()<< " Milli Seconds\n";

   //copy back to cpu
    copy_device_to_host(h_array, d_array);
   
   //Access the resultant matrix : dump into output file
   //write_array_console(h_array);
   ofstream myfile ("files_output/o_gpu_basic.txt");
   //write_array_file(h_array, myfile);
   
   
   return 0;
}

__global__ void update_array_gpu_hybrid(int i, int numberOfThreadsRequired, cellType *d_array, int *d_v, int *d_w)
{
   long j=blockIdx.x *blockDim.x + threadIdx.x + 1;
   __shared__ cellType sharedArray [nCols];

   if (j>= numberOfThreadsRequired || j < 1)
      {}
   else
   {  
      int j_ext_1 = j - d_v[j+1];
      int j_ext_2 = j + d_v[j-2];
      int j_ext_3 = j - d_v[j+3];
      int j_ext_4 = j + d_v[j+7];
      int j_ext_5 = j - d_v[j+3];
      int j_ext_6 = j + d_v[j+7];

      if (j_ext_1 < 0 || j_ext_1 > nCols-1)
         j_ext_1 = 0;
      if (j_ext_2 < 0 || j_ext_2 > nCols-1)
         j_ext_2 = 0;
      if (j_ext_3 < 0 || j_ext_3 > nCols-1)
         j_ext_3 = 0;
      if (j_ext_4 < 0 || j_ext_4 > nCols-1)
         j_ext_4 = 0;
      if (j_ext_5 < 0 || j_ext_5 > nCols-1)
         j_ext_5 = 0;
      if (j_ext_6 < 0 || j_ext_6 > nCols-1)
         j_ext_6 = 0;

      sharedArray[j] = d_array(i-1,j);
      if (j % 5 == 0)
      {
         
      sharedArray[j] = sharedArray[j_ext_1] + sharedArray[j_ext_2] + sharedArray[j_ext_3] + sharedArray[j_ext_4] + sharedArray[j_ext_5] + sharedArray[j_ext_6];
      
      //d_array(i,j) = d_array(i-1,j_ext_1) + d_array(i-1,j_ext_2) + d_array(i-1,j_ext_3) + d_array(i-1,j_ext_4) + d_array(i-1,j_ext_5) + d_array(i-1,j_ext_6) ;
      }
      
      
   }

   
}
