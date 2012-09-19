#include "child.h"

struct sharedMemStruct{
  char * data;
  int * numChars;
};

void sigHandler(int n){
  signal(n, sigHandler);
}

//void consumerReadText(key_t dataKey, key_t numCharsKey){
int main(int argc, char** argv){
  signal(SIGUSR1, sigHandler);
  signal(SIGUSR2, sigHandler);
  key_t dataKey = atoi(argv[1]);
  key_t numCharsKey = atoi(argv[2]);
  pid_t parentPID = (pid_t)atoi(argv[3]);
  FILE *outputFile = fopen("output", "w");
  if(outputFile == NULL){
    perror("Error opening output file\n");
    exit(0);
  }
  //-----------Get Shared Memory-----------------
  int sharedMemId, charsReadId;
  sharedMemId = shmget(dataKey, 0, 0);
  charsReadId = shmget(numCharsKey, 0, 0);
  if(sharedMemId == -1 || charsReadId == -1){
    perror("Error getting shared memory to consumer.\n");
    exit(0);
  }
  
  int flag = 00400| 00200 | 00040 | 00020 | 00004 | 00002 ;
  
  struct sharedMemStruct sharedMem;
  sharedMem.data = shmat(sharedMemId, (void*) NULL, flag);
  sharedMem.numChars = shmat(charsReadId, (void*)NULL, flag);
  if(sharedMem.data == (char*) -1 || sharedMem.numChars == (int*) -1){
    perror("Error attaching shared memory to consumer.\n");
    exit(1);
  }
  //---Read in from shared memory and write to output----
  while(*sharedMem.numChars != -1){
    kill(parentPID, SIGUSR2);
    sigpause(SIGUSR1); //Wait for SIGUSR1
    char *tempString = (char*)malloc(sizeof(char) * (*sharedMem.numChars) + 1);
    int i;
    for(i = 0; i < (*sharedMem.numChars); i++){
      tempString[i] = sharedMem.data[i];
    }
    tempString[i+1] = '\0';
    if((*sharedMem.numChars) >=0){
      fwrite(sharedMem.data, sizeof(char) * 1, sizeof(char) * (*sharedMem.numChars), outputFile);
    }
    
    free(tempString);
    kill(getppid(), SIGUSR2); //Send SIGUSR2
  }
  fclose(outputFile);
  *sharedMem.numChars = 0;
  shmdt((void*) sharedMem.data);
  shmctl(sharedMemId, IPC_RMID, NULL);
  exit(0);
  
}
