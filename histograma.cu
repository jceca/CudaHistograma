#include <stdio.h>
#include "image.h"
#include <time.h>
#define SIZE 2048*1024

__global__ void histo_MonoBlock( unsigned char *buffer,long size,unsigned int *histo ) {

__shared__ unsigned int temp[256];
temp[threadIdx.x] = 0;
__syncthreads();

int i = threadIdx.x , offset = blockDim.x;
while (i < size) {
	atomicAdd( &temp[buffer[i]], 1);
	i += offset;
}
__syncthreads();

atomicAdd( &(histo[threadIdx.x]), temp[threadIdx.x] );

}


int main(void){

unsigned char *dev_buffer;
unsigned int *dev_histo;

//pedimos memoria
cudaMalloc( (void**)&dev_buffer, SIZE );
cudaMemcpy( dev_buffer, image, SIZE, cudaMemcpyHostToDevice );

cudaMalloc( (void**)&dev_histo,256 * sizeof(long) );
cudaMemset( dev_histo, 0, 256*sizeof(int) );
//KERNEL EXECUTION
histo_MonoBlock<<<1,256>>>(dev_buffer,SIZE,dev_histo);
//KERNEL HAS FINISHED 
unsigned int host_histo[256];
//retorno de valores desde dev a host
cudaMemcpy( host_histo, dev_histo, 256*sizeof(int),cudaMemcpyDeviceToHost );
//calculamos si el histograma es correcto en CPU, debemos obtener 0 (restamos en vez de sumar uno)
for(int i=0;i<SIZE;i++){
	host_histo[image[i]]--;
}
//buscamos valores distintos de 0
for(int i=0;i<256;i++){
	if(host_histo[i]!=0) printf("valor %d incorrecto\n",i);
}
//liberamos memoria
cudaFree(dev_histo);
cudaFree(dev_buffer);

return 0;
}
