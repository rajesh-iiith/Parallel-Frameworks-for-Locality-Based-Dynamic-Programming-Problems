
#include "headers/myHeaders.h"

using namespace std;


int main(int argc, char const *argv[])
{	
	// Original array is 2d array : input image / matrix / DP table
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
			arrayOrg[i][j] = rand() % 10 ;
		}
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

	//copy the h_array to gpu
	int *d_array;
	cudaMalloc((void**) &d_array, sizeof(int)*(nRows*nCols));
    cudaMemcpy(d_array, h_array,sizeof(int)*(nRows*nCols), cudaMemcpyHostToDevice);

    //configure kernel
	configure_kernal(nCols);
	
	//Execute on GPU 
	struct timeval start, end;
 	gettimeofday(&start, NULL);
	double time1 = omp_get_wtime();
	
	
   for (int i = 1; i < nRows; ++i)
   {
	   	update_array_gpu<<<dim3(g,1,1), dim3(x,1,1)>>>(i, nCols, d_array);
   }

	gettimeofday(&end, NULL);
  	double run_time = ((end.tv_sec - start.tv_sec)*1000 + (end.tv_usec - start.tv_usec)/1000.0);
	printf("Time (hp-gpu): %.3lf\n", run_time);
	cout <<"Time (hp-gpu): " <<(omp_get_wtime() - time1)*1000<< "\n";
	//cout << "Result on gpu: " << h_array [nRows*nCols - 1] << "\n";

	//copy back to cpu
	cudaMemcpy(h_array, d_array,sizeof(int)*(nRows*nCols), cudaMemcpyDeviceToHost);

	//Access the resultant matrix : dump into output file
	
	/*ofstream myfile ("../output_p.txt");
	for (int i = 0; i < nRows; ++i)
	{	
		for (int j = 0; j < nCols; ++j)
		{
			myfile << h_array[i*nCols + j] << "\t";
		}
		myfile << "\n";
	}*/
	
	return 0;
}



__global__ void update_array_gpu(int i, int numberOfThreadsRequired, int *d_array )
{
   long j=blockIdx.x *blockDim.x + threadIdx.x + 1;
   
   if (j>= numberOfThreadsRequired)
      {}
   else
   {
       GPU_Expression;   
   }
}

void configure_kernal(long numberOfThreadsRequired)
{
   if (numberOfThreadsRequired <= BLOCK_SIZE)
      {x=numberOfThreadsRequired ; g=1;}
   else
      {
         g= (numberOfThreadsRequired / BLOCK_SIZE ) + 1; x= BLOCK_SIZE;
      }

}