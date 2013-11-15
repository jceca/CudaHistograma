#include <stdio.h>
#include "image.h"
#include <time.h>
#define SIZE 2048*1024
#define BLOCKS 1000
#define THREADS 256
__global__ void histo_MultiBlock( unsigned char *buffer,long size,unsigned int *histo ) {

	__shared__ unsigned int temp[256];
	int i = threadIdx.x + blockIdx.x * THREADS;
	int offset= THREADS * BLOCKS;
	int memoffset = blockIdx.x * THREADS;
if(threadIdx.x <256)
	temp[threadIdx.x] = 0;
	__syncthreads();

	while(i<size){
		atomicAdd( &temp[buffer[i]], 1);
		i+=offset;
	}
	__syncthreads();
if(threadIdx.x <256)
	atomicAdd( &(histo[threadIdx.x+memoffset]), temp[threadIdx.x] );
}

int main(void){

unsigned int host_histo[BLOCKS][256];
unsigned char *dev_buffer;
unsigned int *dev_histo;
cudaEvent_t start, stop;
float elapsedTime;

//pedimos memoria
cudaMalloc( (void**)&dev_buffer, SIZE );
cudaMemcpy( dev_buffer, image, SIZE, cudaMemcpyHostToDevice );
cudaMalloc( (void**)&dev_histo,256 * BLOCKS * sizeof(long) );
cudaMemset( dev_histo, 0, 256*BLOCKS *sizeof(long) );
//Medicion de tiempo de ejecucion
cudaEventCreate(&start);
cudaEventCreate(&stop);
// Start record
cudaEventRecord(start, 0);
//KERNEL EXECUTION
histo_MultiBlock<<<BLOCKS,THREADS>>>(dev_buffer,SIZE,dev_histo);
// Stop event
cudaEventRecord(stop, 0);
cudaEventSynchronize(stop);
cudaEventElapsedTime(&elapsedTime, start, stop); // that's our time!

//KERNEL HAS FINISHED 
printf("Kernel ejecutado en %3.2f ms\nCon %d bloques y %d hilos\n",elapsedTime,BLOCKS,THREADS);
//retorno de valores desde dev a host
cudaMemcpy( host_histo, dev_histo, 256*BLOCKS*sizeof(int), cudaMemcpyDeviceToHost );
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
cudaEventDestroy(start);
cudaEventDestroy(stop);
cudaFree(dev_histo);
cudaFree(dev_buffer);

return 0;
}
