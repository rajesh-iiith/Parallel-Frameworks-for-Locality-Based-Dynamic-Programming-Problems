
#ifndef MYPARAMS_H
#define MYPARAMS_H


//define statements
//#define nRows 8193
//#define nCols 8193
#define tileLength 32
// 128 is best block size in case of lcs (on the basis of experiments on 10k * 10k)
#define BLOCK_SIZE 128
#define CUTOFF_HANDOVER 500
#define CUTOFF_HYBRID 0

//global variables
int x,g;
int **arrayOrg;
int *h_array;

#endif
