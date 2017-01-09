//program for triangular tiling scheme for horizintal parallelism

//include statements
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include "omp.h"
#include <fstream>
#include <iomanip>

//define statements
// 4097 8193 16385
#define nRows 16385
#define nCols 16385
#define tileLength 16
// 128 is best block size in case of lcs (on the basis of experiments on 10k * 10k)
#define BLOCK_SIZE 128
#define CUTOFF_HANDOVER 500
#define CUTOFF_HYBRID 0

//recheck D things
#define ExpressionCPU Z = (B + C + 2) / 2
#define ExpressionGPU d_Z = (d_B + d_C + 2) / 2 

#define A h_array[ (x_my)*nCols + (y_my - 1) ]
#define B h_array[ (x_my - 1)*nCols + (y_my - 1) ]
#define C h_array[ (x_my - 1)*nCols + (y_my) ]
#define D h_array[ (x_my - 1)*nCols + (y_my + 1) ]
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
void operate_on_valleys (int itr, int x_start, int y_start);
void operate_on_peaks (int itr, int x_start, int y_start);
void fix_boundary_tile_left(int itr, int x_start, int y_start);
void fix_boundary_tile_right(int itr, int x_start, int y_start);

__global__ void operate_on_valleys_gpu (int i, int *d_array, int x_start, int y_start);
__global__ void operate_on_peaks_gpu (int i, int *d_array, int x_start, int y_start);
__global__ void fix_boundary_tile_left_gpu(int itr, int *d_array, int x_start,int y_start);
__global__ void fix_boundary_tile_right_gpu(int itr, int *d_array, int x_start,int y_start);

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


  // initialiation : not required if we are inputting the image : can be replaced by input code
  for (int i = 0; i < nRows; ++i)
  { 
    for (int j = 0; j < nCols; ++j)
    {
      h_array[i*nCols + j] = 0;
    }
  }

  //load h_array to GPU
  // Load main resource (DP table/ Image i.e. h_array) to GPU
  int *d_array;
  cudaMalloc((void**) &d_array, sizeof(int)*(nRows*nCols));
  cudaMemcpy(d_array, h_array,sizeof(int)*(nRows*nCols), cudaMemcpyHostToDevice);

 double time1 = omp_get_wtime();

 int x_start = 1;
 int y_start = 1;
 //omp_set_nested(1);

 for (int itr = 1; itr <= (nRows-1)/tileLength; ++itr)
 {
       // valleys
        operate_on_valleys_gpu <<<dim3((nRows-1)/(2*tileLength),1,1), dim3(2*tileLength,1,1)>>> (itr, d_array, x_start, y_start);
        //operate_on_valleys (itr, x_start, y_start);
        y_start = (2 * tileLength);
        // peaks 
        operate_on_peaks_gpu <<<dim3((nRows-1)/(2*tileLength)-1,1,1), dim3(2*tileLength,1,1)>>> (itr, d_array, x_start, y_start);
        //operate_on_peaks(itr, x_start, y_start);
       
        //fix boundary triangles : can also use squares for ease
        y_start = 1;
        fix_boundary_tile_left_gpu<<<dim3(1,1,1), dim3(tileLength,1,1)>>>(itr, d_array, x_start, y_start);
        //fix_boundary_tile_left(itr, x_start, y_start);
        y_start = (nRows-1);
        fix_boundary_tile_right_gpu<<<dim3(1,1,1), dim3(tileLength,1,1)>>>(itr, d_array, x_start, y_start);
        //fix_boundary_tile_right(1, x_start, y_start);

        y_start = 1;
        x_start = x_start + tileLength;

  }
  cout << "Time (Blocked): " << omp_get_wtime() - time1 << "\n";
  cudaMemcpy(h_array , d_array ,sizeof(int) * (nRows*nCols), cudaMemcpyDeviceToHost);
  
  //Access the resultant matrix or write to file
  
  /*for (int i = 0; i < 50; ++i)
  { 
    for (int j = 0; j < 50; ++j)
    {
      cout << setfill('0') << setw(2) << h_array[i*nCols + j] << " ";
    }
    cout << "\n";
  }*/

  // cout << "\n";
  
  // for (int i = nRows-1; i < nRows; ++i)
  // { 
  //   for(int j = 0; j < nRows; ++j)
  //   {
  //     if(h_array[i*nCols + j] + 1 != h_array[i * nCols + j + 1])
  //     {
  //       printf("%d, %d\n", i, j);
  //       break;
  //     }
  //   }
  // }

  // for (int i = 0; i < nRows; ++i)
  // { 
  //   if(h_array[i*nCols + nRows-1] + 1 != h_array[(i+1) * nCols + nRows-1])
  //   {
  //     printf("%d\n", i);
  //     break;
  //   }
  // }

  cout << "\n";

  cout << "Result(triangular Blocked): "<< h_array[nRows*nCols -1] <<"\n";
  return 0;
}

__global__ void operate_on_valleys_gpu (int i, int *d_array, int x_start, int y_start)
{
    
        y_start = 1 + (blockIdx.x)*(tileLength *2);
        //y_start = 1 + (i-1)*(tileLength *2); 

            int x_my = x_start;
            int y_my = y_start;
            for (int j = tileLength; j >= 1; --j)
            {   
              int k = threadIdx.x + 1;
                
                if ( k <= (2*j) )
                {
                  y_my = y_my + (k-1);
                  ExpressionGPU;
                }
                
                x_my = x_my + 1;
                y_my = y_start +  tileLength - j + 1;
            }

   
}
__global__ void operate_on_peaks_gpu (int i, int *d_array, int x_start, int y_start)
{

              y_start = (2 * tileLength) + (blockIdx.x)*(tileLength *2);
            //y_start = (2 * tileLength) + (i-1)*(tileLength *2); 

              int x_my = x_start + 1;
              int y_my = y_start;
              
              for (int j = 2; j <= tileLength; ++j)
              {   
                  int k = threadIdx.x + 1;
                    if (k <= (2*(j-1)))
                    {
                      y_my = y_my + (k-1);
                      ExpressionGPU;
                    }

                  x_my = x_my + 1;
                  y_my = y_start - j + 1;
              }

}


__global__ void fix_boundary_tile_left_gpu(int itr, int *d_array, int x_start,int y_start)
{
      int x_my = x_start + 1;
      int y_my = y_start;

      for (int j = 2; j <= tileLength; ++j)
      {   
          int k = threadIdx.x + 1;
          if (k <= (j-1))
          {
            y_my = y_my + (k-1);
            ExpressionGPU;
          }
          x_my = x_my + 1;
          y_my = 1;
      }
}

__global__ void fix_boundary_tile_right_gpu(int itr, int *d_array, int x_start,int y_start)
{
      int x_my = x_start + 1;
      int y_my = y_start;

      for (int j = 2; j <= tileLength; ++j)
      {   
          int k = threadIdx.x + 1;
          if (k <= (j-1))
          {
            y_my = y_my - (k-1);
            ExpressionGPU;
          }
          x_my = x_my + 1;
          y_my = y_start;
      }
}

void operate_on_valleys (int itr, int x_start, int y_start)
{     
      #pragma omp parallel for private(y_start)
       for (int i = 1; i <= (nRows-1) / (tileLength * 2) ; ++i)
        { 
          y_start = 1 + (i-1)*(tileLength *2);  
            int x_my = x_start;
            int y_my = y_start;
            //cout << " test: "<< x_my << "," << y_my << "\n";
            for (int j = tileLength; j >= 1; --j)
            {   
                //#pragma omp parallel for
                for (int k = 1; k <= (2*j); ++k)
                {
                  //cout << " debug:: "<< x_my << "," << y_my << "\n";
                  ExpressionCPU;
                  y_my = y_my + 1;
                }
                
                x_my = x_my + 1;
                y_my = y_start +  tileLength - j + 1;
            }

    }
}

void operate_on_peaks (int itr, int x_start, int y_start)
{    

      #pragma omp parallel for private(y_start)
       for (int i = 1; i <= ((nRows-1) / (2*tileLength)) - 1; ++i)
        {   
            y_start = (2 * tileLength) + (i-1)*(tileLength *2);   
              int x_my = x_start + 1;
              int y_my = y_start;
              //cout << " test: "<< x_my << "," << y_my << "\n";
              for (int j = 2; j <= tileLength; ++j)
              {   
                  //#pragma omp parallel for
                  for (int k = 1; k <= (2*(j-1)); ++k)
                  {
                    //cout << " debug:: "<< x_my << "," << y_my << "\n";
                    ExpressionCPU;
                    y_my = y_my + 1;
                  }
                  
                  x_my = x_my + 1;
                  y_my = y_start - j + 1;
              }

        }
}

void fix_boundary_tile_left(int itr, int x_start, int y_start)
{ 
      int x_my = x_start + 1;
      int y_my = y_start;

      for (int j = 2; j <= tileLength; ++j)
      {
          //#pragma omp parallel for
          for (int k = 1; k <= (j-1); ++k)
          {
            //cout << " debug:: "<< x_my << "," << y_my << "\n";
            ExpressionCPU;
            y_my = y_my + 1;
          }
          x_my = x_my + 1;
          y_my = 1;
      }
}

void fix_boundary_tile_right(int itr, int x_start, int y_start)
{ 
      int x_my = x_start + 1;
      int y_my = y_start;
      //cout << " debug:: "<< x_my << "," << y_my << "\n";
      for (int j = 2; j <= tileLength; ++j)
      {   
          //#pragma omp parallel for
          for (int k = 1; k <= (j-1); ++k)
          {
            //cout << " debug:: "<< x_my << "," << y_my << "\n";
            ExpressionCPU;
            y_my = y_my - 1;
          }
          x_my = x_my + 1;
          y_my = y_start;
      }
}
