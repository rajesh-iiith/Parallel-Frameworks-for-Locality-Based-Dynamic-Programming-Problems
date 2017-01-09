#include "headers/myHeaders.h"

//using statements
using namespace std;

int main(int argc, char const *argv[])
{ 
  // Original array is 2d array : input image / matrix / DP table 
  arrayOrg=new int *[nRows];
  for(int z=0 ; z<nRows ; z++)
  {
    arrayOrg[z]=new int[nCols];
  }

  //flatten the array to 1d array
  h_array = (int*)calloc(nRows*nCols, sizeof(int));
  for (int i = 0; i < nRows; ++i)
  {
    for (int j = 0; j < nCols; ++j)
    {
     //h_array[i*nCols + j] = arrayOrg [i][j];
      h_array[i*nCols + j] = rand() % 10;
    }
  }
  //free arrayOrg
  for(int z=0 ; z<nRows ; z++)
  {
    free(arrayOrg[z]);
  }
  free(arrayOrg);

  //load h_array to GPU
  // Load main resource (DP table/ Image i.e. h_array) to GPU
  int *d_array;
  cudaMalloc((void**) &d_array, sizeof(int)*(nRows*nCols));
  cudaMemcpy(d_array, h_array,sizeof(int)*(nRows*nCols), cudaMemcpyHostToDevice);



  // initialiation : not required if we are inputting the image : can be replaced by input code
  /*for (int i = 0; i < nRows; ++i)
  { 
    for (int j = 0; j < nCols; ++j)
    {
      h_array[i*nCols + j] = rand() % 10;
    }
  }*/


 double time1 = omp_get_wtime();
 int x_start = 1;
 int y_start = 1;
 //omp_set_nested(1);
 for (int i = 1; i <= (nRows/tileLength) ; ++i)
  {
      operate_on_block_gpu <<<dim3(i,1,1), dim3(tileLength,1,1)>>> (i, d_array, x_start, y_start);
      x_start = x_start + tileLength;
  } 

    x_start = x_start - tileLength;
    y_start = y_start + tileLength;
    for (int i = (nRows/tileLength)-1; i >= 1 ; --i)
  {
      operate_on_block_gpu <<<dim3(i,1,1), dim3(tileLength,1,1)>>> (i, d_array, x_start, y_start);
      y_start = y_start + tileLength;
  } 

  cout << "Time (Blocked): " << (omp_get_wtime() - time1)*1000 << "\n";
  cudaMemcpy(h_array , d_array ,sizeof(int) * (nRows*nCols), cudaMemcpyDeviceToHost);

  //Access the resultant matrix or write to file
  
 /* ofstream myfile ("../output_t.txt");
  for (int i = 0; i < nRows; ++i)
  { 
    for (int j = 0; j < nCols; ++j)
    {
      myfile << h_array[i*nCols + j] << "\t";
      
    }
    myfile << "\n";
  }*/
  
  cout << "Result(Blocked): "<< h_array[nRows*nCols -1] <<"\n";
  return 0;
}


__global__ void operate_on_block_gpu (int i, int *d_array, int x_start, int y_start)
{
      //long tid=blockIdx.x *blockDim.x + threadIdx.x;
      
       
          int x_my_block = x_start - (blockIdx.x) * tileLength;
          int y_my_block = y_start + (blockIdx.x) * tileLength;
        

        //operate_on_block (x_start, y_start, subsequence1, subsequence2);

                      int x_start_local = x_my_block;
                      int y_start_local = y_my_block;
                        for (int i = 1; i <= tileLength; ++i)
                        {
                          int x_my = x_start_local + (i-1)*1;
                          
                          for (int j = 1; j <= tileLength; ++j)
                          {
                            int y_my = y_start_local + (j-1)*1;
                ExpressionGPU;
                          }
                            
                            
                        }
    
}

