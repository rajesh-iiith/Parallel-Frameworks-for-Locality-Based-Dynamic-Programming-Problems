
#ifndef MYDEF_H
#define MYDEF_H

#define A h_array[ (x_my)*nCols + (y_my - 1) ]
#define B h_array[ (x_my - 1)*nCols + (y_my - 1) ]
#define C h_array[ (x_my - 1)*nCols + (y_my) ]
#define Z h_array[ (x_my)*nCols + (y_my) ]

#define d_A d_array[ (x_my)*nCols + (y_my - 1) ]
#define d_B d_array[ (x_my - 1)*nCols + (y_my - 1) ]
#define d_C d_array[ (x_my - 1)*nCols + (y_my) ]
#define d_Z d_array[ (x_my)*nCols + (y_my) ]


//global variables
int x,g;
int **arrayOrg;
int *h_array;

//CPU declarations
void operate_on_block_one (int i, int x_start, int y_start, char *subsequence1, char *subsequence2);
void operate_on_block_two (int i, int x_start, int y_start, char *subsequence1, char *subsequence2);

//GPU declarations
__global__ void operate_on_block_one_gpu (int i, int *d_array, int x_start, int y_start, char *d_subsequence1, char *d_subsequence2);
__global__ void operate_on_block_two_gpu (int i, int *d_array, int x_start, int y_start, char *d_subsequence1, char *d_subsequence2);

#endif