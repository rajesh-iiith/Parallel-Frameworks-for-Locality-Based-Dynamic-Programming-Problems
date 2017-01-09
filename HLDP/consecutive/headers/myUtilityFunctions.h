#ifndef MYUTILITYFUNCTIONS_H
#define MYUTILITYFUNCTIONS_H

#include "myHeaders.h"

using namespace std;

//display the 1D array like 2D
void write_array_console(cellType *h_array)
{
	for (int i = 0; i < nRows; ++i)
	{	
		for (int j = 0; j < TOTAL_COLS; ++j)
		{
			//cout << h_array(i,j)<< " ";
			cout << h_array(i,j).value1 << " ";
		}
		cout << "\n";
	}
}



//for the time being, print just last two rows
void write_array_file(cellType *h_array,std::ofstream& myfile)
{	
	for (int i = (nRows-2); i < nRows; ++i)
	{	
		for (int j = 0; j < TOTAL_COLS; ++j)
		{
			//myfile << h_array(i,j)<< " ";
			myfile << h_array(i,j).value1 << "\t";
		}
		myfile << "\n";
	}

	myfile.close();
}


void configure_kernal(long numberOfThreadsRequired)
{
   if (numberOfThreadsRequired <= BLOCK_SIZE)
      {
      	x=numberOfThreadsRequired;
      	g=1;
      }
   else
      {
         g= (numberOfThreadsRequired / BLOCK_SIZE ) + 1; x= BLOCK_SIZE;
      }

}

void configure_kernal_shmem(long numberOfThreadsRequired)
{
	 g= (numberOfThreadsRequired / BLOCK_SIZE ); x= BLOCK_SIZE;
}

cellType* create_array_host()
{
	return((cellType*)calloc(nRows*TOTAL_COLS, sizeof(cellType)));
}


void copy_host_to_device(cellType* h_array, cellType* d_array)
{
	cudaMemcpy(d_array, h_array, sizeof(cellType)*(nRows*TOTAL_COLS), cudaMemcpyHostToDevice);
}

void copy_device_to_host(cellType* h_array, cellType* d_array)
{
	cudaMemcpy(h_array, d_array, sizeof(cellType)*(nRows*TOTAL_COLS), cudaMemcpyDeviceToHost);
}

//mode = 2 for specific values, mode = 1 for random values
void initialize_this_row(cellType *h_array, int rowNumber, int mode, int value)
{
	if (mode == 1)
	{
		for (int i = 0; i < TOTAL_COLS; ++i)
		{
			h_array(rowNumber, i).value1 = rand() % 10;
		}
	}
	else
	{
		for (int i = 0; i < TOTAL_COLS; ++i)
		{
			h_array(rowNumber, i).value1 = value;
		}
	}
	
}

#endif