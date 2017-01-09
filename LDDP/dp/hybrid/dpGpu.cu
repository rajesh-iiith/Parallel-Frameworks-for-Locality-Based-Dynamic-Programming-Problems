
#include "headers/myHeaders.h"

using namespace std;


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


	//Execute on GPU
	struct timeval start, end;
 	gettimeofday(&start, NULL);

	double time1 = omp_get_wtime();

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
	gettimeofday(&end, NULL);
  	double run_time = ((end.tv_sec - start.tv_sec)*1000 + (end.tv_usec - start.tv_usec)/1000.0);
	printf("Time (gpu): %.3lf\n", run_time);
	//cout << "Time (gpu): "<< (omp_get_wtime() - time1) * 1000 << "\n";

	
	//copyback h_array to cpu
	cudaMemcpy(h_array, d_array,sizeof(int)*nRows*nCols, cudaMemcpyDeviceToHost);
	//cout << "Result on gpu: "<< h_array [nRows*nCols - 1] << "\n";


/*	//convert into 2d matrix : in the original order i.e. row order


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
*/	
	return 0;
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