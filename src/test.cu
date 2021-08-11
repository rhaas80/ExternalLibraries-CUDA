#include "cctk.h"
#include "cctk_Parameters.h"
#include <stdlib.h>
#include <cuda.h>

__global__ void vector_add(float *out, float *a, float *b, int n)
{
  for(int i = 0; i < n; i++){
    out[i] = a[i] + b[i];
  }
}

extern "C"
int CUDA_Test(void) {
  DECLARE_CCTK_PARAMETERS;

  const int N = 10;
  float *a, *b, *out; 
  
  // Allocate memory
  a   = (float*)malloc(sizeof(float) * N);
  b   = (float*)malloc(sizeof(float) * N);
  out = (float*)malloc(sizeof(float) * N);
  for(int i = 0; i < N; i++) {
    a[i] = 1.;
    b[i] = 0.;
    out[i] = 42;
  }
  
  float *d_a, *d_b, *d_out;
  cudaMalloc((void**)&d_a, sizeof(float) * N);
  cudaMalloc((void**)&d_b, sizeof(float) * N);
  cudaMalloc((void**)&d_out, sizeof(float) * N);
  
  cudaMemcpy(d_a, a, sizeof(float) * N, cudaMemcpyHostToDevice);
  cudaMemcpy(d_b, b, sizeof(float) * N, cudaMemcpyHostToDevice);
  
  vector_add<<<1,1>>>(d_out, d_a, d_b, N);
  cudaError_t err = cudaGetLastError();
  
  cudaMemcpy(d_out, out, sizeof(float) * N, cudaMemcpyDeviceToHost);
  if(err == cudaSuccess) {
    if(out[0] != a[0] + b[0]) {
      CCTK_VERROR("CUDA kernel produced incorrrect result %f != %f", out[0],
                  a[0] + b[0]);
    }
  } else {
    CCTK_VERROR("CUDA failed with %s", cudaGetErrorString(err));
  }
   
  cudaFree((void**)&d_a);
  cudaFree((void**)&d_b);
  cudaFree((void**)&d_out);
  free(out);
  free(b);
  free(a);

  return 0;
} 
