/////////////////////////////////////////////////////////////////////////
/// Z-Terminal Serial Communication v1.0
/// for GNU/Linux kernel versions 6.0+  
/// by Ben Provenzano III - 07/01/2023 v5 - 04/13/2025 v6
/////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h>
#include <ctype.h>

#define buffLen 32
char *line = NULL;
int serial_port;
const char device[] = "/dev/zterm-tty"; // serial port alias
const size_t maxCmdLength = 32;
size_t writeLineSize = 0;
char serCharBuf[buffLen];
size_t enableSend = 0;
size_t lineSize = 0;

int serialRead() {
 // Read from the serial port in a loop
 char target_char = '|';
 bool _return = 0;
 printf("Waiting for response...\n");
 while(1) {
    // set serial port to non-blocking mode
    int _serflags = fcntl(serial_port, F_GETFL, 0);   
    if (_serflags == -1) {
      perror("Failed to set serial port to non-blocking mode");
      return 1;
    } else {
      fcntl(serial_port, F_SETFL, _serflags | O_NONBLOCK);
    }
    // read serial port
    ssize_t num_bytes = read(serial_port, serCharBuf, buffLen);
    // check if the serial port is available
    if (access(device, F_OK) != 0) {
      printf("Serial port not available\n");
      return 1;
    }
    // exit when sending disabled
    if (enableSend == 0) {
      return 0;
    }
    // response size check
    if (num_bytes > 0) {
      size_t i;
      size_t ack_resp = 0;
      for (i = 0; i < num_bytes; i++) {
        // read response
        char _curchar = serCharBuf[i];
        // write to console
        printf("%c", _curchar);
        // check target characters have been received
        if (_curchar == target_char) {
          ack_resp++;
        }
      }
      if (ack_resp == 2) { // two pipes received
        printf("OK\n");
        return 0;
      }
    } else {
      // no data available, continue reading input
      if (errno != EAGAIN && errno != EWOULDBLOCK) {
        // error occurred
        printf("Failed to read serial port\n");
        return 1;
      }
    }
   // END num_bytes COND // 
  }
}

int serialWrite() {
  int status = 0;
  // check if the serial port is available
  if (access(device, F_OK) != 0) {
    printf("Serial port not available\n");
    writeLineSize = 0;
    return 1;
  }
  // write data in chunks
  for (int i = 0; i < writeLineSize; i += maxCmdLength) {
  	// define buffers
    char _chunkBuf[buffLen];
    char _rawData[buffLen];
    _chunkBuf[0] = '\0';
    _rawData[0] = '\0';
    // build output string
    strcat(_rawData, "<0,0,"); 
    // Calculate the size of the current chunk
    int chunkLength = (i + maxCmdLength <= writeLineSize) ? maxCmdLength : writeLineSize - i;
    // Copy the chunk from the input string to the buffer
    strncpy(_chunkBuf, line + i, chunkLength);
    // null-terminate the buffer
    _chunkBuf[chunkLength] = '\0';
    strcat(_rawData, _chunkBuf); 
    strcat(_rawData, ">");
    printf("Serial Data: %s\n", _rawData);
    // write to the serial port
    write(serial_port, _rawData, buffLen); 
    // wait for response
    status = serialRead();
  }
  writeLineSize = 0;
  return status;
}

// reset line array
void clearLine() {
  enableSend = 0;
  writeLineSize = 0;
  lineSize = 0;
  free(line);
  line = (char*) malloc(1 * sizeof(char));
  line[0] = '\0';
}

// main entry point //
int main(int argc, char *argv[]) {
// parse first command line argument
  for (int i = 0; i < argc; i++) {
    if (argc != 2) {
      printf("Z-Terminal Xmit v2.1\n");
      printf("Invalid # of arguments!\n");
      return 1; 
    }
  }
  char* argData = malloc(strlen(argv[1]) + 1);
  strcpy(argData, argv[1]);
  size_t argLength = strlen(argData);
  // open the serial port
  serial_port = open(device, O_RDWR);
  if (serial_port < 0) {
    perror("Error opening serial port");
    return 1;
  }
  // configure the serial port
  struct termios tty;
  if (tcgetattr(serial_port, &tty) != 0) {
    perror("Error configuring serial port");
    return 1;
  }
  // set the baud rate 
  cfsetospeed(&tty, B9600);
  cfsetispeed(&tty, B9600);
  tty.c_cflag &= ~PARENB;  // disable parity bit
  tty.c_cflag &= ~CSTOPB;  // set one stop bit
  tty.c_cflag &= ~CSIZE;   // clear data size bits
  tty.c_cflag |= CS8;      // set 8 data bits
  tty.c_cflag &= ~CRTSCTS; // disable hardware flow control
  tty.c_cflag &= ~HUPCL;   // disable DST & RST (prevent system reset)
  // apply the serial settings
  if (tcsetattr(serial_port, TCSANOW, &tty) != 0) {
    perror("Error applying serial port settings");
    return 1;
  }
  // serial initialization mode
  if (argLength == 1) {
    if (argData[0] == 'i') {
      printf("Serial port initialized\n");
      return 0;
    }
  }
  // program status
  int status = 0;
  // read command line argument
  for (int i = 0; i <= argLength; i++) {
    // detect control mode (1st)
    char charin = argData[i];
    if (charin != '\r' && 
        charin != '\n' && 
        charin != '\0') {
      // allocate memory
      line = realloc(line, (lineSize + 1));
      // write to line data array
      line[lineSize] = charin;
      // increment index
      lineSize++;
    }
  }
  // terminate string
  line = realloc(line, (lineSize + 1));
  line[lineSize] = '\0';
  writeLineSize = lineSize;
  enableSend = 1;
  // main loop
  while(1) {
    // transmit to serial
    if (enableSend > 0) {
      status = serialWrite();
      clearLine();
      close(serial_port);
      break;
    }
  }
  free(argData);
  return status;
}