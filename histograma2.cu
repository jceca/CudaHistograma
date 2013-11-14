#include <stdio.h>
#include "image.h"
#include <time.h>
#define SIZE 2048*1024
#define BLOCKS 12

__global__ void histo_MultiBlock( unsigned char *buffer,long size,unsigned int *histo ) {

__shared__ unsigned int temp[256];
int i = threadIdx.x + blockIdx.x * blockDim.x;
int offset= blockDim.x * gridDim.x;
int memoffset = blockIdx.x * blockDim.x;
temp[threadIdx.x] = 0;
__syncthreads();

while(i<size){
	
	atomicAdd( &temp[buffer[i]], 1);
	i+=offset;
}
__syncthreads();
atomicAdd( &(histo[threadIdx.x+memoffset]), temp[threadIdx.x] );
}

int main(void){

unsigned char *dev_buffer;
unsigned int *dev_histo;

//pedimos memoria
cudaMalloc( (void**)&dev_buffer, SIZE );
cudaMemcpy( dev_buffer, image, SIZE, cudaMemcpyHostToDevice );

cudaMalloc( (void**)&dev_histo,256 * BLOCKS * sizeof(long) );
cudaMemset( dev_histo, 0, 256*BLOCKS *sizeof(int) );
//KERNEL EXECUTION
histo_MultiBlock<<<BLOCKS,256>>>(dev_buffer,SIZE,dev_histo);

//KERNEL HAS FINISHED 
unsigned int host_histo[BLOCKS][256];
//retorno de valores desde dev a host
cudaMemcpy( host_histo, dev_histo, 256*BLOCKS*sizeof(int),cudaMemcpyDeviceToHost );
/*
for(long i=0;i<256;i++){
	for(int j=1;j<BLOCKS;j++){
		printf("%d ",host_histo[j][i]);			
	}
}
printf("\n\n");*/
//unimos histogramas
for(long i=0;i<256;i++){
	for(int j=1;j<BLOCKS;j++){
		host_histo[0][i]+=host_histo[j][i];			
	}
}
//calculamos si el histograma es correcto en CPU, debemos obtener 0 (restamos en vez de sumar uno)
for(int i=0;i<256;i++){
	printf("%d ",host_histo[0][i]);
}
for(int i=0;i<SIZE;i++){
	host_histo[0][image[i]]--;
}
printf("\n\n");
//buscamos valores distintos de 0
for(int i=0;i<256;i++){
	if(host_histo[0][i]!=0){
		printf("valor %d incorrecto\n",i);
		break;
	}
}
//liberamos memoria
cudaFree(dev_histo);
cudaFree(dev_buffer);

return 0;
}
