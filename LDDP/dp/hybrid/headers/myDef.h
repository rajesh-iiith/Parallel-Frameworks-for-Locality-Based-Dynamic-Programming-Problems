#define A1 h_array[digSize-i-1 + j]
#define B1 h_array[digSize-2*i + j]
#define C1 h_array[digSize-i + j]

#define d_A1 d_array[digSize-i-1 + j]
#define d_B1 d_array[digSize-2*i + j]
#define d_C1 d_array[digSize-i + j]


#ifndef MYDEF_H
#define MYDEF_H

#define A2 h_array[digSize - (nRows - (i - 1)) + j]
#define B2 h_array[digSize - 2*(nRows - (i - 1)) + j]
#define C2 h_array[digSize - (nRows - (i - 1)) + 1 + j]
#define B2ex h_array[digSize - 2*(nRows - (i - 1)) + 1 + j]

#define d_A2 d_array[digSize - (nRows - (i - 1)) + j]
#define d_B2 d_array[digSize - 2*(nRows - (i - 1)) + j]
#define d_C2 d_array[digSize - (nRows - (i - 1)) + 1 + j]
#define d_B2ex d_array[digSize - 2*(nRows - (i - 1)) + 1 + j]

#define Z h_array[digSize + j]
#define d_Z d_array[digSize + j]


//CPU declarations

void cpu_left (int i, int digSize, int *h_array, char *subsequence1, char *subsequence2);
void cpu_mid (int i, int digSize, int *h_array, char *subsequence1, char *subsequence2);
void cpu_bottom (int i, int digSize, int *h_array, char *subsequence1, char *subsequence2);

//GPU declarations

__global__ void gpu_left (int i, int digSize, int *d_array, char *d_subsequence1, char *d_subsequence2);
__global__ void gpu_mid (int i, int digSize, int *d_array, char *d_subsequence1, char *d_subsequence2);
__global__ void gpu_bottom (int i, int digSize, int *d_array, char *d_subsequence1, char *d_subsequence2);

//others
void configure_kernal(long numberOfThreadsRequired);

#endif