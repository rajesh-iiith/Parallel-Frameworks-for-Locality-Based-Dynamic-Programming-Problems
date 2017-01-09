
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

	//Execute on CPU
	struct timeval start, end;
 	gettimeofday(&start, NULL);
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
	gettimeofday(&end, NULL);
  	double run_time = ((end.tv_sec - start.tv_sec)*1000 + (end.tv_usec - start.tv_usec)/1000.0);
	printf("Time (cpu): %.3lf\n", run_time);
	//cout <<"Time (cpu): " <<(omp_get_wtime() - time1)*1000<< "\n";
	//cout << "Result on cpu: " << h_array [nRows*nCols - 1] << "\n";
	


	
	//convert into 2d matrix : in the original order i.e. row order
/*	digSize = 0;
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
	
	ofstream myfile ("../output_s.txt");
	for (int i = 0; i < nRows; ++i)
	{	
		for (int j = 0; j < nCols; ++j)
		{
			myfile << arrayOrg[i][j] << "\t";
			
		}
		myfile << "\n";
	}

	cout << "\n";*/
	
	/*ofstream myfile ("output_s.txt");
	for (int i = nRows*nCols -100; i < nRows*nCols; ++i)
	{
		myfile << h_array[i] << "\t";
	}*/
	
	
	return 0;
}

void cpu_left (int i, int digSize, int *h_array, char *subsequence1, char *subsequence2)
{
		#pragma omp parallel for
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
		#pragma omp parallel for
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
	#pragma omp parallel for
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
