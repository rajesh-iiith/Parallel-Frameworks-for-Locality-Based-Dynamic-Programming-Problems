//define statements

#define B h_array[(i-1) * nCols + (j-1)]
#define C h_array[(i-1) * nCols + (j)]
#define D h_array[(i-1) * nCols + (j+1)]
#define Z h_array[(i) * nCols + (j)]

#define d_B d_array[(i-1) * nCols + (j-1)]
#define d_C d_array[(i-1) * nCols + (j)]
#define d_D d_array[(i-1) * nCols + (j+1)]
#define d_Z d_array[(i) * nCols + (j)]

//#define CPU_Expression ( ( (B <= C) && (B <= D) ) ? (Z = B + Z) : ( ( (C <= B) && (C <= D) ) ? (Z = C + Z) : (Z = D + Z) ) )
#define CPU_Expression ( (B <= C) ? (Z = B + Z) : (Z = C + Z))
//#define GPU_Expression ( ( (d_B <= d_C) && (d_B <= d_D) ) ? (d_Z = d_B + d_Z) : ( ( (d_C <= d_B) && (d_C <= d_D) ) ? (d_Z = d_C + d_Z ) : (d_Z = d_D + d_Z) ) )
#define GPU_Expression ( (d_B <= d_C) ? (d_Z = d_B + d_Z) : (d_Z = d_C + d_Z))


//CPU declarations
void update_array_cpu(int i);

//GPU declarations
__global__ void update_array_gpu(int, int, int *d_array);

//others
void configure_kernal(long);
