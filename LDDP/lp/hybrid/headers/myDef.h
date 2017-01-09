//define statements

#define B1 h_array[oldCount + j]
#define B2 h_array[oldCount + n + 1 + j]
#define Z1 h_array[count + j]
#define Z2 h_array[count + n + j]
#define d_B1 d_array[oldCount + j]
#define d_B2 d_array[oldCount + n + 1 + j]
#define d_Z1 d_array[count + j]
#define d_Z2 d_array[count + n + j]

#define CPU_Expression_1 ( (B1 >= Z1) ? (Z1 = B1) : (Z1 = Z1 + 1))
#define CPU_Expression_2 ( (B2 >= Z2) ? (Z2 = B2) : (Z2 = Z2 + 1))
#define GPU_Expression_1 ( (d_B1 >= d_Z1) ? (d_Z1 = d_B1) :(d_Z1 = d_Z1 + 1))
#define GPU_Expression_2 ( (d_B2 >= d_Z2) ? (d_Z2 = d_B2) :(d_Z2 = d_Z2 + 1))

//using statements
using namespace std;

//declarations
void configure_kernal(long);
__global__ void update_array_one_gpu(int, int, int, int, int, int, int *d_array);
__global__ void update_array_two_gpu(int, int, int, int, int, int, int *d_array);
void update_array_one_cpu(int m, int n, int count, int oldCount, int *h_array);
void update_array_two_cpu(int m, int n, int count, int oldCount, int *h_array);
