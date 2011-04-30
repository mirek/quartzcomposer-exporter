
#import <Foundation/Foundation.h>

#include "stdlib.h"
#include "stdio.h"
#include "quicklz.h"

int main(int argc, char *argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

  qlz_state_compress *state_compress = (qlz_state_compress *)malloc(sizeof(qlz_state_compress));
  qlz_state_decompress *state_decompress = (qlz_state_decompress *)malloc(sizeof(qlz_state_decompress));
  
  char original[] = "LZ compression finds repeated strings: Five, six, seven, eight, nine, fifteen, sixteen, seventeen, fifteen, sixteen, seventeen.";
  
  // Always allocate size + 400 bytes for the destination buffer when compressing.
  char *compressed = (char *)malloc(strlen(original) + 400);
  char *decompressed = (char *)malloc(strlen(original));
  int r;
  
  r = qlz_compress(original, compressed, strlen(original), state_compress);
  printf("Compressed %d bytes into %d bytes.\n", (int)strlen(original), r);
  
  r = qlz_decompress(compressed, decompressed, state_decompress);
  printf("Decompressed back to %d bytes.\n", r);
  
  [pool drain];
  return 0;
}