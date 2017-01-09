#include "headers/myHeaders.h"

//using statements
using namespace std;


int main(int argc, char const *argv[])
{	
	omp_set_nested(1);
    omp_set_dynamic(1);
	// Original array is 2d array : input image / matrix / DP table
	int **arrayOrg; 
	arrayOrg=new int *[nRows];
	for(int z=0 ; z<nRows ; z++)
	{
		arrayOrg[z]=new int[nCols];
	}

	// initialiation : not required if we are inputting the image : can be replaced by input code
	for (int i = 0; i < nRows; ++i)
	{	
		for (int j = 0; j < nCols; ++j)
		{
			arrayOrg[i][j] = 1;
		}
	}

	// memory coalescing : Store in cloumn major order (since vertical parallelism), change to 1D array

	//thrust::host_vector<int> h_array(nRows * nCols);
	int *h_array = (int*)calloc(nRows*nCols, sizeof(int));
	int m = nRows;
	int n = nCols;
	int count = 0;
	int smallerDim;
	(nRows > nCols ? smallerDim = nCols : smallerDim = nRows );

	for (int i = 0; i < smallerDim; ++i)
	{	
		for (int j = 0; j < n; ++j)
		{
			h_array[count + j] = arrayOrg[i][j+i];
		}
		for (int j = 0; j < m-1; ++j)
		{
			h_array[count + n + j] = arrayOrg[j+1+i][i];
		}
		count =  (m + n - 1) + count;
		m = m - 1;
		n = n - 1;
		
	}

	
//operate
	count = nRows + nCols -1;
	m = nRows - 1;
	n = nCols - 1;
	int oldCount = 0;
	double time2 = omp_get_wtime();

	if (n > m)
	{
	
		for (int i = 1; i < smallerDim; ++i)
		{	
			update_array_one_cpu(m, n, count, oldCount, h_array);
			oldCount = count;
			count =  (m + n - 1) + count;
			m = m - 1;
			n = n - 1;
			
		}
	}

	else
	{
		
		for (int i = 1; i < smallerDim; ++i)
		{	
			update_array_two_cpu(m, n, count, oldCount, h_array);
			oldCount = count;
			count =  (m + n - 1) + count;
			m = m - 1;
			n = n - 1;
			
		}
	}
	
	cout << "\n";
	
	cout << (omp_get_wtime() - time2)*1000 <<endl;
	

	//convert into 2d matrix : in the original order 
	m = nRows;
	n = nCols;
	count = 0;
	
	for (int i = 0; i < smallerDim; ++i)
	{	
		for (int j = 0; j < n; ++j)
		{
			arrayOrg[i][j+i] = h_array[count + j];
		}
		for (int j = 0; j < m-1; ++j)
		{
			arrayOrg[j+1+i][i] = h_array[count + n + j];
		}
		count =  (m + n - 1) + count;
		m = m - 1;
		n = n - 1;
		
	}

	//Access the resultant matrix

	/*for (int i = 0; i < nRows; ++i)
	{	
		for (int j = 0; j < nCols; ++j)
		{
			cout << arrayOrg[i][j] ;
			//myfile << arrayOrg[i][j] << "\t";
		}
		//myfile << "\n";
		cout << "\n" ;
	}*/
	
	return 0;
}


void update_array_one_cpu(int m, int n, int count, int oldCount, int *h_array)
{
	#pragma omp parallel for
		for (int j = 0; j < n; ++j)
		{
			CPU_Expression_1;
			if (j < (m - 1) )
			{
				CPU_Expression_2;
			}
		}	
}
void update_array_two_cpu(int m, int n, int count, int oldCount, int *h_array)
{
	#pragma omp parallel for
		for (int j = 0; j < m; ++j)
		{
			CPU_Expression_2;	
			if (j < n)
			{
				CPU_Expression_1;
			}
		}
}
