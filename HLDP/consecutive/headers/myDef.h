//define statements

//#define cellType int
#define h_array(i,j) h_array[((i)*(TOTAL_COLS)) + (j)]
#define d_array(i,j) d_array[((i)*(TOTAL_COLS)) + (j)]

#define h_T(i,j) h_array[((i)*(TOTAL_COLS)) + (j)]
#define d_T(i,j) d_array[((i)*(TOTAL_COLS)) + (j)]

//global variables
int x,g;
struct cellType
{
	int value1;
	int value2;
};

//CPU declarations
void update_array_cpu(int i, cellType *h_array);
void update_array_cpu_hybrid(int i, cellType *h_array);

//GPU declarations
__global__ void update_array_gpu(int, int, cellType *d_array);
__global__ void update_array_gpu_hybrid(int, int, cellType *d_array);
__global__ void update_array_gpu_shmem(int i, int numberOfThreadsRequired, int, cellType *d_array );


//others
void configure_kernal(long);

//other functions
void write_array_console(cellType *h_array);
void write_array_file(int *h_array, std::ofstream& myfile);
void initialize_this_row(cellType *h_array, int rowNumber, int mode, int value);


