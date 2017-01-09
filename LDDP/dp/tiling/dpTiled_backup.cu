//include statements
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include "omp.h"
#include <fstream>

//define statements
#define nRows 16385
#define nCols 16385
#define tileLength 32
// 128 is best block size in case of lcs (on the basis of experiments on 10k * 10k)
#define BLOCK_SIZE 128
#define CUTOFF_HANDOVER 500
#define CUTOFF_HYBRID 0

#define A h_array[ (x_my)*nCols + (y_my - 1) ]
#define B h_array[ (x_my - 1)*nCols + (y_my - 1) ]
#define C h_array[ (x_my - 1)*nCols + (y_my) ]
#define Z h_array[ (x_my)*nCols + (y_my) ]

#define d_A d_array[ (x_my)*nCols + (y_my - 1) ]
#define d_B d_array[ (x_my - 1)*nCols + (y_my - 1) ]
#define d_C d_array[ (x_my - 1)*nCols + (y_my) ]
#define d_Z d_array[ (x_my)*nCols + (y_my) ]



//using statements
using namespace std;

//global variables
int x,g;
int **arrayOrg;
int *h_array;
//CPU declarations
void operate_on_block_one (int i, int x_start, int y_start, char *subsequence1, char *subsequence2);
void operate_on_block_two (int i, int x_start, int y_start, char *subsequence1, char *subsequence2);
__global__ void operate_on_block_one_gpu (int i, int *d_array, int x_start, int y_start, char *d_subsequence1, char *d_subsequence2);
__global__ void operate_on_block_two_gpu (int i, int *d_array, int x_start, int y_start, char *d_subsequence1, char *d_subsequence2);

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
     h_array[i*nCols + j] = arrayOrg [i][j];
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

  // Load external reseorces. e.g. subsequences in case of LCS
  //1. To CPU

   char *subsequence1 = new char[nRows];
   for (int i = 1; i < nRows; ++i)
   {
    subsequence1 [i] = rand()%4 + 67;
   }
   char *subsequence2 = new char[nCols];
   for (int i = 1; i < nRows; ++i)
   {
    subsequence2 [i] = rand()%4 + 67;
   }

   //2. To GPU

   char *d_subsequence1;
   cudaMalloc((void**) &d_subsequence1, sizeof(char)*nRows);
   cudaMemcpy(d_subsequence1, subsequence1,sizeof(char)*nRows, cudaMemcpyHostToDevice);
   char *d_subsequence2;
   cudaMalloc((void**) &d_subsequence2, sizeof(char)*nCols);
   cudaMemcpy(d_subsequence2, subsequence2,sizeof(char)*nCols, cudaMemcpyHostToDevice);

  // initialiation : not required if we are inputting the image : can be replaced by input code
  for (int i = 0; i < nRows; ++i)
  { 
    for (int j = 0; j < nCols; ++j)
    {
      h_array[i*nCols + j] = 0;
    }
  }

 double time1 = omp_get_wtime();
 int x_start = 1;
 int y_start = 1;
 //omp_set_nested(1);
 for (int i = 1; i <= (nRows/tileLength) ; ++i)
  {
    
      operate_on_block_one_gpu <<<dim3(i,1,1), dim3(tileLength,1,1)>>> (i, d_array, x_start, y_start, d_subsequence1, d_subsequence2);
      x_start = x_start + tileLength;
  } 

    x_start = x_start - tileLength;
    y_start = y_start + tileLength;
    for (int i = (nRows/tileLength)-1; i >= 1 ; --i)
  {
    
      operate_on_block_two_gpu <<<dim3(i,1,1), dim3(tileLength,1,1)>>> (i, d_array, x_start, y_start, d_subsequence1, d_subsequence2);
      //printf("i:%d\n", i);
      y_start = y_start + tileLength;
  } 

  cout << "Time (Blocked): " << omp_get_wtime() - time1 << "\n";
  cudaMemcpy(h_array , d_array ,sizeof(int) * (nRows*nCols), cudaMemcpyDeviceToHost);

  //Access the resultant matrix or write to file
  
  ofstream myfile ("output_p.txt");
  for (int i = 0; i < nRows; ++i)
  { 
    for (int j = 0; j < nCols; ++j)
    {
      myfile << h_array[i*nCols + j] << "\t";
      
    }
    myfile << "\n";
  }

  cout << "\n";
  
  cout << "Result(Blocked): "<< h_array[nRows*nCols -1] <<"\n";
  //ofstream myfile ("output_p.txt");
  /*for (int i = nRows*nCols -100; i < nRows*nCols; ++i)
  {
    myfile << h_array[i] << "\t";
  }
  */
  return 0;
}


__global__ void operate_on_block_one_gpu (int i, int *d_array, int x_start, int y_start, char *d_subsequence1, char *d_subsequence2)
{
      long tid=blockIdx.x *blockDim.x + threadIdx.x;
      
       
          int x_my_block = x_start - (blockIdx.x) * tileLength;
          int y_my_block = y_start + (blockIdx.x) * tileLength;
          //printf("%d%d%d%d\n", i,blockIdx.x + 1, x_my_block,y_my_block);
        

        //operate_on_block (x_start, y_start, subsequence1, subsequence2);

      

                      int x_start_local = x_my_block;
                      int y_start_local = y_my_block;

                        for (int i = 1; i <= tileLength; ++i)
                        {
                          //#pragma omp parallel for
                          int j= (tid % tileLength) + 1;
                          //printf("%d-%d\n",j,i);
                          if (j <= i)
                          {
                            //printf("%d\n",j);
                            int x_my = x_start_local - (j-1)*1;
                            int y_my = y_start_local + (j-1)*1;
                            //printf("%d%d\n",x_my,y_my );
                              if (d_subsequence1 [x_my] == d_subsequence2 [y_my])
                                  {
                                    d_Z = 1 + d_B;
                                  }
                              else
                                  {
                                    ( d_A > d_C ? d_Z = d_A : d_Z = d_C );
                                  }
                          }
                            x_start_local = x_start_local + 1;
                        }

                        x_start_local = x_start_local - 1;
                        y_start_local = y_start_local + 1;

                          for (int i = tileLength-1; i >= 1 ; --i)
                          {
                                int j= (tid % tileLength) + 1;
                                if (j <= i)
                                {
                                  int x_my = x_start_local - (j-1)*1;
                                  int y_my = y_start_local + (j-1)*1;
                                  //printf("%d%d\n",x_my,y_my );
                                  if (d_subsequence1 [x_my] == d_subsequence2 [y_my])
                                    {
                                      d_Z = 1 + d_B;
                                    }
                                  else
                                    {
                                      ( d_A > d_C ? d_Z = d_A : d_Z = d_C );
                                    }

                                }

                              y_start_local = y_start_local + 1;
                          } 
    
}



__global__ void operate_on_block_two_gpu (int i, int *d_array, int x_start, int y_start, char *d_subsequence1, char *d_subsequence2)
{
      long tid=blockIdx.x *blockDim.x + threadIdx.x;
      
        int x_my_block = x_start - (blockIdx.x)*tileLength;
        int y_my_block = y_start + (blockIdx.x)*tileLength;

        //operate_on_block (x_my, y_my, subsequence1, subsequence2);

      

                      int x_start_local = x_my_block;
                      int y_start_local = y_my_block;
                        for (int i = 1; i <= tileLength; ++i)
                        {
                          int j= (tid % tileLength) + 1;
                          if (j <= i)
                          {
                            int x_my = x_start_local - (j-1)*1;
                            int y_my = y_start_local + (j-1)*1;
                              if (d_subsequence1 [x_my] == d_subsequence2 [y_my])
                                  {
                                    d_Z = 1 + d_B;
                                  }
                              else
                                  {
                                    ( d_A > d_C ? d_Z = d_A : d_Z = d_C );
                                  }
                          }
                            x_start_local = x_start_local + 1;
                        }

                        x_start_local = x_start_local - 1;
                        y_start_local = y_start_local + 1;

                          for (int i = tileLength-1; i >= 1 ; --i)
                          {
                                int j= (tid % tileLength) + 1;
                                if (j <= i)
                                {
                                  int x_my = x_start_local - (j-1)*1;
                                  int y_my = y_start_local + (j-1)*1;

                                  if (d_subsequence1 [x_my] == d_subsequence2 [y_my])
                                    {
                                      d_Z = 1 + d_B;
                                    }
                                  else
                                    {
                                      ( d_A > d_C ? d_Z = d_A : d_Z = d_C );
                                    }

                                }

                              y_start_local = y_start_local + 1;
                          } 
    
}

























/*void operate_on_block_one (int i, int x_start, int y_start, char *subsequence1, char *subsequence2)
{
      #pragma omp parallel for
      for (int j = 1; j <= i; ++j)
      {
        int x_my_block = x_start - (j-1)*tileLength;
        int y_my_block = y_start + (j-1)*tileLength;

        //operate_on_block (x_start, y_start, subsequence1, subsequence2);

      

                      int x_start_local = x_my_block;
                      int y_start_local = y_my_block;
                        for (int i = 1; i <= tileLength; ++i)
                        {
                          //#pragma omp parallel for
                          for (int j = 1; j <= i; ++j)
                          {
                            int x_my = x_start_local - (j-1)*1;
                            int y_my = y_start_local + (j-1)*1;
                              if (subsequence1 [x_my] == subsequence2 [y_my])
                                  {
                                    Z = 1 + B;
                                  }
                              else
                                  {
                                    ( A > C ? Z = A : Z = C );
                                  }
                          }
                            x_start_local = x_start_local + 1;
                        }

                        x_start_local = x_start_local - 1;
                        y_start_local = y_start_local + 1;

                          for (int i = tileLength-1; i >= 1 ; --i)
                          {
                              //#pragma omp parallel for
                              for (int j = 1; j <= i; ++j)
                                {
                                  int x_my = x_start_local - (j-1)*1;
                                  int y_my = y_start_local + (j-1)*1;

                                  if (subsequence1 [x_my] == subsequence2 [y_my])
                                    {
                                      Z = 1 + B;
                                    }
                                  else
                                    {
                                      ( A > C ? Z = A : Z = C );
                                    }

                                }

                              y_start_local = y_start_local + 1;
                          } 

          }
    
}



void operate_on_block_two (int i, int x_start, int y_start, char *subsequence1, char *subsequence2)
{
      #pragma omp parallel for
      for (int j = 1; j <= i; ++j)
      {
        int x_my_block = x_start - (j-1)*tileLength;
        int y_my_block = y_start + (j-1)*tileLength;

        //operate_on_block (x_my, y_my, subsequence1, subsequence2);

      

                      int x_start_local = x_my_block;
                      int y_start_local = y_my_block;
                        for (int i = 1; i <= tileLength; ++i)
                        {
                          //#pragma omp parallel for
                          for (int j = 1; j <= i; ++j)
                          {
                            int x_my = x_start_local - (j-1)*1;
                            int y_my = y_start_local + (j-1)*1;
                              if (subsequence1 [x_my] == subsequence2 [y_my])
                                  {
                                    Z = 1 + B;
                                  }
                              else
                                  {
                                    ( A > C ? Z = A : Z = C );
                                  }
                          }
                            x_start_local = x_start_local + 1;
                        }

                        x_start_local = x_start_local - 1;
                        y_start_local = y_start_local + 1;

                          for (int i = tileLength-1; i >= 1 ; --i)
                          {
                              //#pragma omp parallel for
                              for (int j = 1; j <= i; ++j)
                                {
                                  int x_my = x_start_local - (j-1)*1;
                                  int y_my = y_start_local + (j-1)*1;

                                  if (subsequence1 [x_my] == subsequence2 [y_my])
                                    {
                                      Z = 1 + B;
                                    }
                                  else
                                    {
                                      ( A > C ? Z = A : Z = C );
                                    }

                                }

                              y_start_local = y_start_local + 1;
                          } 

          }
    
}
*/