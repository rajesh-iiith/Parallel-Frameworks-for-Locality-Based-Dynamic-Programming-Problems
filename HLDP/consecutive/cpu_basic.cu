
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
	initialize_this_row(h_array, 0, 1, -1);
	 
	//Execute on CPU
	double start_time = omp_get_wtime();
	
   for (int i = 1; i < nRows; ++i)
   {
   		update_array_cpu(i, h_array);
   }

	cout <<"Time (basic CPU): " <<(omp_get_wtime() - start_time)*1000<< " Milli Seconds\n";
	
	//Access the resultant matrix : dump into output file
	//write_array_console(h_array);
	//ofstream myfile ("files_output/o_cpu_basic.txt");
	//write_array_file(h_array, myfile);
	
	
	return 0;
}


void update_array_cpu(int i, cellType *h_array)
{
		#pragma omp parallel for
		for (int j = dependencyWidthLeft; j < nCols + dependencyWidthLeft ; ++j)
	   	{	
	   		int a = (h_array(i,j).value1 + h_array(i-1,j).value1) / (h_array(i-1,j).value2 + 3) ;
			int b = (h_array(i,j).value1 + h_array(i-1,j-1).value1) / (h_array(i-1,j-1).value2 + 3);
			int c = (h_array(i,j).value1 + h_array(i-1,j-2).value1) + (h_array(i-1,j-2).value2 + 3);

			if ((a >= b) && (a >=c))
			{
				h_array(i,j).value1 = a;
				h_array(i,j).value2 = h_array(i-1,j).value2 + 3;
			}
			else
			{
				if ((b >= a) && (b >=c))
				{
					h_array(i,j).value1 = b;
					h_array(i,j).value2 = h_array(i-1,j-1).value2 + 3;
				}
				else
				{
					h_array(i,j).value1 = c;
					h_array(i,j).value2 = h_array(i-1,j-2).value2 + 3;
				}
			}
		}
}

