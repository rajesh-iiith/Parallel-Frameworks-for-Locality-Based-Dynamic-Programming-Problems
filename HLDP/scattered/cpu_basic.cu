
#include "headers/myHeaders.h"
#include "headers/myUtilityFunctions.h"

using namespace std;


int main(int argc, char const *argv[])
{	
	//create 1-D array at host : initialize accordingly
	cellType *h_array;
	h_array = create_array_host();

	//initialize base row arguments (cellType *h_array, int rowNumber, int mode, int value)
	// : mode =1 for random initialization, put any value in that case
	initialize_this_row(h_array, 0, 0, 0);
	initialize_this_col(h_array, 0, 0, 0);

	// create/initialize and transfer other resources and pass to the function
	//int W = nRows;
	
	int *h_v = create_array_host_1D(nRows);
	initialize_this_1D_array(h_v, nRows);
	int *h_w = create_array_host_1D(nRows);
	initialize_this_1D_array(h_w, nRows);
	/*int h_v[5] = {0, 10, 40, 30, 50};
	int h_w[5] = {0, 5, 4, 6, 3};*/
	 
	//Execute on CPU
	double start_time = omp_get_wtime();
	
   for (int i = 1; i < nRows; ++i)
   {
   		update_array_cpu(i, h_array, h_v, h_w);
   }

	cout <<"Time (basic CPU): " <<(omp_get_wtime() - start_time)*1000<< " Milli Seconds\n";
	
	//Access the resultant matrix : dump into output file
	//write_array_console(h_array);
	//ofstream myfile ("files_output/o_cpu_basic.txt");
	//write_array_file(h_array, myfile);
	
	
	return 0;
}


void update_array_cpu(int i, cellType *h_array, cellType* h_v, cellType* h_w)
{
		//printf("%d %d\n", h_w[i], h_v[i]);
		#pragma omp parallel for
		for (int j = 1; j < nCols ; ++j)
	   	{	
	   		int j_ext = j - h_w[i];
	   		if (j_ext <= 0)
	   			j_ext = 0;
	   		int a = h_array(i-1,j);
	   		int b = h_v[i] + h_array(i-1,j_ext);
			(( (h_w[i]) > j || (a >= b)) ? h_array(i,j) = a : h_array(i,j) = b );
	   		//h_array(i,j)= h_array(i-1,j) + h_array(i-1,j_ext) + 1;
		}
}

