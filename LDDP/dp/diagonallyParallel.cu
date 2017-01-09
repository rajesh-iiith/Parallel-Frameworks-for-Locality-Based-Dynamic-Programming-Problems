//include statements
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include "omp.h"
#include <fstream>

//define statements
#define nRows 16385
#define nCols 16385
// 128 is best block size in case of lcs (on the basis of experiments on 10k * 10k)
#define BLOCK_SIZE 128
#define CUTOFF_HANDOVER 500
#define CUTOFF_HYBRID 0

#define A1 h_array[digSize-i-1 + j]
#define B1 h_array[digSize-2*i + j]
#define C1 h_array[digSize-i + j]

#define d_A1 d_array[digSize-i-1 + j]
#define d_B1 d_array[digSize-2*i + j]
#define d_C1 d_array[digSize-i + j]

#define A2 h_array[digSize - (nRows - (i - 1)) + j]
#define B2 h_array[digSize - 2*(nRows - (i - 1)) + j]
#define C2 h_array[digSize - (nRows - (i - 1)) + 1 + j]
#define B2ex h_array[digSize - 2*(nRows - (i - 1)) + 1 + j]

#define d_A2 d_array[digSize - (nRows - (i - 1)) + j]
#define d_B2 d_array[digSize - 2*(nRows - (i - 1)) + j]
#define d_C2 d_array[digSize - (nRows - (i - 1)) + 1 + j]
#define d_B2ex d_array[digSize - 2*(nRows - (i - 1)) + 1 + j]

#define Z h_array[digSize + j]
#define d_Z d_array[digSize + j]



//using statements
using namespace std;

//global variables
int x,g;
//CPU declarations
void cpu_left (int i, int digSize, int *h_array, char *subsequence1, char *subsequence2);
void cpu_mid (int i, int digSize, int *h_array, char *subsequence1, char *subsequence2);
void cpu_bottom (int i, int digSize, int *h_array, char *subsequence1, char *subsequence2);

//GPU declarations
void configure_kernal(long);
__global__ void gpu_left (int i, int digSize, int *d_array, char *d_subsequence1, char *d_subsequence2);
__global__ void gpu_mid (int i, int digSize, int *d_array, char *d_subsequence1, char *d_subsequence2);
__global__ void gpu_bottom (int i, int digSize, int *d_array, char *d_subsequence1, char *d_subsequence2);


int main(int argc, char const *argv[])
{	
	
	
	// Original array is 2d array : input image / matrix / DP table
	int **arrayOrg; 
	arrayOrg=new int *[nRows];
	for(int z=0 ; z<nRows ; z++)
	{
		arrayOrg[z]=new int[nCols];
	}

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
			arrayOrg[i][j] = 0;
		}
	}

	// memory coalescing : change to 1D array

	int *h_array = (int*)calloc(nRows*nCols, sizeof(int));
	
	int digSize = 0;
	for (int i = 0; i < nRows; ++i)
	{	
		digSize = digSize + i;
		for (int j = 0; j <= i; ++j)
		{
			h_array[digSize + j] = arrayOrg[i - j][j];
		}
		
	}
	
	for (int i = 1; i < nRows; ++i)
	{	
		digSize = digSize + nRows - (i - 1);
		for (int j = 0; j < (nRows - i); ++j)
		{
			h_array[digSize + j] = arrayOrg[nRows - j - 1][i+j];
		}
	}

	// Load main resource (DP table/ Image i.e. h_array) to GPU
	int *d_array;
	cudaMalloc((void**) &d_array, sizeof(int)*(nRows*nCols));
    cudaMemcpy(d_array, h_array,sizeof(int)*(nRows*nCols), cudaMemcpyHostToDevice);

	//Execute on CPU
	double time1 = omp_get_wtime();
	digSize = 0;
	omp_set_dynamic(0);
    omp_set_num_threads(6);
	for (int i = 0; i < nRows; ++i)
	{	
		digSize = digSize + i;
		cpu_left(i, digSize, h_array, subsequence1, subsequence2);
	}

	for (int i = 1; i < 2; ++i)
	{	
		digSize = digSize + nRows - (i - 1);
		cpu_mid(i, digSize, h_array, subsequence1, subsequence2);
	}
	
	for (int i = 2; i < nRows; ++i)
	{	
		digSize = digSize + nRows - (i - 1);
		cpu_bottom(i, digSize, h_array, subsequence1, subsequence2);
	}

	cout << "\n";
	cout <<"Time on cpu: " <<omp_get_wtime() - time1 << "\n";
	cout << "Result on cpu: " << h_array [nRows*nCols - 1] << "\n";
	

	/*//Execute on GPU
	double time2 = omp_get_wtime();
	digSize = 0;
	for (int i = 0; i < nRows; ++i)
	{	
		digSize = digSize + i;
		configure_kernal(i-1);
		gpu_left<<<dim3(g,1,1), dim3(x,1,1)>>>(i, digSize, d_array, d_subsequence1, d_subsequence2);
	}

	for (int i = 1; i < 2; ++i)
	{	
		digSize = digSize + nRows - (i - 1);
		configure_kernal(nRows-i);
		gpu_mid<<<dim3(g,1,1), dim3(x,1,1)>>>(i, digSize, d_array, d_subsequence1, d_subsequence2);
	}
	
	for (int i = 2; i < nRows; ++i)
	{	
		digSize = digSize + nRows - (i - 1);
		configure_kernal(nRows-i);
		gpu_bottom<<<dim3(g,1,1), dim3(x,1,1)>>>(i, digSize, d_array, d_subsequence1, d_subsequence2);
	}

	cout << "\n";
	cout <<"Time on gpu: " <<omp_get_wtime() - time2 << "\n";

	
	//copyback h_array to cpu
	cudaMemcpy(h_array, d_array,sizeof(int)*nRows*nCols, cudaMemcpyDeviceToHost);
	cout << "Result on gpu: "<< h_array [nRows*nCols - 1] << "\n";
*/
	//Execute on Hybrid (CPU + GPU) : Handover

	/*double time3 = omp_get_wtime();
	digSize = 0;
	int i;
	for (i = 0; i < CUTOFF_HANDOVER; ++i)
	{	
		digSize = digSize + i;
		cpu_left(i, digSize, h_array, subsequence1, subsequence2);
	}
	//int locate = digSize - (2*i -1);
	//cudaMemcpy(d_array + locate, h_array + locate ,sizeof(int) * 2*i, cudaMemcpyHostToDevice);
	for (i = CUTOFF_HANDOVER; i < nRows; ++i)
	{	
		digSize = digSize + i;
		configure_kernal(i-1);
		gpu_left<<<dim3(g,1,1), dim3(x,1,1)>>>(i, digSize, d_array, d_subsequence1, d_subsequence2);
	}

	for (i = 1; i < 2; ++i)
	{	
		digSize = digSize + nRows - (i - 1);
		configure_kernal(nRows-i);
		gpu_mid<<<dim3(g,1,1), dim3(x,1,1)>>>(i, digSize, d_array, d_subsequence1, d_subsequence2);
	}
	
	for (i = 2; i < nRows - CUTOFF_HANDOVER; ++i)
	{	
		digSize = digSize + nRows - (i - 1);
		configure_kernal(nRows-i);
		gpu_bottom<<<dim3(g,1,1), dim3(x,1,1)>>>(i, digSize, d_array, d_subsequence1, d_subsequence2);
	}
	//locate = digSize - 2*(nRows - (i - 1));
	//cudaMemcpy(h_array + locate, d_array + locate ,sizeof(int) * 2*(nRows-i), cudaMemcpyDeviceToHost);
	for (i = nRows - CUTOFF_HANDOVER; i < nRows; ++i)
	{	
		digSize = digSize + nRows - (i - 1);
		cpu_bottom(i, digSize, h_array, subsequence1, subsequence2);
	}

	cout << "\n";
	cout <<"Time on Hybrid: " <<omp_get_wtime() - time3 << "\n";
	cout << "Result on Hybrid: "<< h_array [nRows*nCols - 1] << "\n";*/


	//convert into 2d matrix : in the original order i.e. row order


	digSize = 0;
	for (int i = 0; i < nRows; ++i)
	{	
		digSize = digSize + i;
		for (int j = 0; j <= i; ++j)
		{
			arrayOrg[i - j][j] = h_array[digSize + j];
		}
		
	}
	
	for (int i = 1; i < nRows; ++i)
	{	
		digSize = digSize + nRows - (i - 1);
		for (int j = 0; j < (nRows - i); ++j)
		{
			arrayOrg[nRows - j - 1][i+j] = h_array[digSize + j] ;
		}
	}
	//Access the resultant matrix or write to file
	
	ofstream myfile ("output_s.txt");
	for (int i = 0; i < nRows; ++i)
	{	
		for (int j = 0; j < nCols; ++j)
		{
			myfile << arrayOrg[i][j] << "\t";
			
		}
		myfile << "\n";
	}

	cout << "\n";
	/*ofstream myfile ("output_s.txt");
	for (int i = nRows*nCols -100; i < nRows*nCols; ++i)
	{
		myfile << h_array[i] << "\t";
	}*/
	
	
	return 0;
}

void cpu_left (int i, int digSize, int *h_array, char *subsequence1, char *subsequence2)
{
		//#pragma omp parallel for
		for (int j = 1; j <= i-1; ++j)
		{
			if (subsequence1 [i - j] == subsequence2 [j])
			{
				Z = 1 + B1;
			}
			else
			{
				( A1 > C1 ? Z = A1 : Z = C1 );
			}
		}
}
void cpu_mid(int i, int digSize, int *h_array, char *subsequence1, char *subsequence2)
{
		//#pragma omp parallel for
		for (int j = 0; j < (nRows - i); ++j)
		{
			if (subsequence1 [nRows - j - 1] == subsequence2 [i + j])
			{
				Z = 1 + B2ex;
			}
			else
			{
				( A2 > C2 ? Z = A2 : Z = C2 );
			}
		}
}
void cpu_bottom(int i, int digSize, int *h_array, char *subsequence1, char *subsequence2)
{
	//#pragma omp parallel for
	for (int j = 0; j < (nRows - i); ++j)
		{
			if (subsequence1 [nRows - j - 1] == subsequence2 [i + j])
			{
				Z = 1 + B2;
			}
			else
			{
				( A2 > C2 ? Z = A2 : Z = C2 );
			}
		}

}

__global__ void gpu_left (int i, int digSize, int *d_array, char *d_subsequence1, char *d_subsequence2)
{
		long j=blockIdx.x *blockDim.x + threadIdx.x + 1;
   		if (j > i-1)
      	{

      	}
		else
		{
			if (d_subsequence1 [i - j] == d_subsequence2 [j])
			{
				d_Z = 1 + d_B1;
			}
			else
			{
				( d_A1 > d_C1 ? d_Z = d_A1 : d_Z = d_C1 );
			}
		}
}
__global__ void gpu_mid(int i, int digSize, int *d_array, char *d_subsequence1, char *d_subsequence2)
{
		long j=blockIdx.x *blockDim.x + threadIdx.x ;
   		if (j >= (nRows - i))
      	{

      	}
		else
		{
			if (d_subsequence1 [nRows - j - 1] == d_subsequence2 [i + j])
			{
				d_Z = 1 + d_B2ex;
			}
			else
			{
				( d_A2 > d_C2 ? d_Z = d_A2 : d_Z = d_C2 );
			}
		}
}
__global__ void gpu_bottom(int i, int digSize, int *d_array, char *d_subsequence1, char *d_subsequence2)
{
		long j=blockIdx.x *blockDim.x + threadIdx.x ;
   		if (j >= (nRows - i))
      	{

      	}
		else
		{
			if (d_subsequence1 [nRows - j - 1] == d_subsequence2 [i + j])
			{
				d_Z = 1 + d_B2;
			}
			else
			{
				( d_A2 > d_C2 ? d_Z = d_A2 : d_Z = d_C2 );
			}
		}

}


void configure_kernal(long numberOfThreadsRequired)
{
   if (numberOfThreadsRequired <= BLOCK_SIZE)
      {
      	 g = 1; x = numberOfThreadsRequired ;
      }
   else
      {
         g = (numberOfThreadsRequired / BLOCK_SIZE)+1; x = BLOCK_SIZE;
      }

}