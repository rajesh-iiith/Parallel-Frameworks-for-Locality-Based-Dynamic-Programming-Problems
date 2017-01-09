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
			cout << h_array(i,j)<< " ";
			//cout << h_array(i,j).value1 << " ";
		}
		cout << "\n";
	}
}



//for the time being, print just last two rows
void write_array_file(cellType *h_array,std::ofstream& myfile)
{	
	for (int i = nRows-2; i < nRows; ++i)
	{	
		for (int j = 0; j < TOTAL_COLS; ++j)
		{
			myfile << h_array(i,j)<< " ";
			//myfile << h_array(i,j).value1 << "\t";
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

cellType* create_array_host_1D(int size)
{
	return((cellType*)calloc(size, sizeof(cellType)));
}

void copy_host_to_device(cellType* h_array, cellType* d_array)
{
	cudaMemcpy(d_array, h_array, sizeof(cellType)*(nRows*TOTAL_COLS), cudaMemcpyHostToDevice);
}

void copy_host_to_device_1D(cellType* h_array, cellType* d_array, int size)
{
	cudaMemcpy(d_array, h_array, sizeof(cellType)*(size), cudaMemcpyHostToDevice);
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
			h_array(rowNumber, i) = rand() % 10;
		}
	}
	else
	{
		for (int i = 0; i < TOTAL_COLS; ++i)
		{
			h_array(rowNumber, i) = value;
		}
	}
	
}

void initialize_this_1D_array(cellType* array, int size)
{
	array[0] = 0; 
	for (int i = 1; i < size; ++i)
		{
			array[i] = rand() % 10;
		}
}

void initialize_this_col(cellType *h_array, int colNumber, int mode, int value)
{
	if (mode == 1)
	{
		for (int i = 0; i < nRows; ++i)
		{
			h_array(i, colNumber) = rand() % 10;
		}
	}
	else
	{
		for (int i = 0; i < nRows; ++i)
		{
			h_array(i, colNumber) = value;
		}
	}
	
}

#endif