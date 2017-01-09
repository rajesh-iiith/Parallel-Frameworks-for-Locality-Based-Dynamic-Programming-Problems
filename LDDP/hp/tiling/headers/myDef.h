
#ifndef MYDEF_H
#define MYDEF_H


#define ExpressionGPU ( (d_B <= d_C) ? (d_Z = d_B + d_Z) : (d_Z = d_C + d_Z))
#define ExpressionCPU ( (B <= C) ? (Z = B + Z) : (Z = C + Z))


#define A h_array[ (x_my)*nCols + (y_my - 1) ]
#define B h_array[ (x_my - 1)*nCols + (y_my - 1) ]
#define C h_array[ (x_my - 1)*nCols + (y_my) ]
#define Z h_array[ (x_my)*nCols + (y_my) ]

#define d_A d_array[ (x_my)*nCols + (y_my - 1) ]
#define d_B d_array[ (x_my - 1)*nCols + (y_my - 1) ]
#define d_C d_array[ (x_my - 1)*nCols + (y_my) ]
#define d_Z d_array[ (x_my)*nCols + (y_my) ]

void operate_on_block_cpu (int i, int x_start, int y_start);
__global__ void operate_on_block_gpu (int i, int *d_array, int x_start, int y_start);

#endif