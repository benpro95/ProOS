/////////////////////////////////////////////////////////////////////////
/// Z-Terminal Serial Communication v1.0
/// for GNU/Linux kernel versions 6.0+  
/// by Ben Provenzano III - 07/01/2023 v5 - 04/24/2025 v6
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
const char targetChar = '\n';
const size_t sleepInverval = 75; // time to pause reading in µs (limit CPU usage)
const size_t maxWaitTime = 1750000; // max time to wait for serial response in µs
const char device[] = "/dev/zterm-tty"; // serial port alias
const size_t maxCmdLength = 32;
char serCharBuf[buffLen];
size_t enableSend = 0;
size_t lineSize = 0;

int serialRead() {
  // Read from the serial port in a loop
  size_t readTime = 0;
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
    // response size check
    if (num_bytes > 0) {
      size_t _idx;
      size_t ack_resp = 0;
      for (_idx = 0; _idx < num_bytes; _idx++) {
        // read response
        char _curchar = serCharBuf[_idx];
        // check target characters have been received
        if (_curchar == targetChar) {
          printf("\n(OK)\n");
          return 0; // success
        } else {
          // write to console
          printf("%c", _curchar);
        }
      }
    } else {
      // no data available, continue reading input
      if (errno != EAGAIN && errno != EWOULDBLOCK) {
        // error occurred
        printf("Failed to read serial port\n");
        return 1;
      }
    }
    if (readTime >= maxWaitTime) {
      printf("Max response wait time exceeded\n");
      return 1;
    }
    usleep(sleepInverval); // limit CPU when reading
    readTime = sleepInverval + readTime;
   // END num_bytes COND // 
  }
}

int serialWrite() {
  int status = 0;
  // check if the serial port is available
  if (access(device, F_OK) != 0) {
    printf("Serial port not available\n");
    return 1;
  }
  // define buffers
  char _rawData[buffLen];
  _rawData[0] = '\0';
  // output control characters
  strcat(_rawData, "<9,9,");
  // append message
  strcat(_rawData, line);
  strcat(_rawData, ">");
  strcat(_rawData, "\n");
  printf("Serial Data: %s", _rawData);
  strcat(_rawData, "\0");
  // write to the serial port
  size_t rawlen = strlen(_rawData);
  write(serial_port, _rawData, rawlen); 
  // wait for response
  status = serialRead();
  return status;
}

// reset line array
void clearLine() {
  enableSend = 0;
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
  cfsetospeed(&tty, B9600); // baud rate out
  cfsetispeed(&tty, B9600); // baud rate in
  tty.c_cflag &= ~PARENB;  // disable parity bit
  tty.c_cflag &= ~CSTOPB;  // set one stop bit
  tty.c_cflag &= ~CSIZE;   // clear data size bits
  tty.c_cflag |= CS8;      // set 8 data bits
  tty.c_cflag &= ~CRTSCTS; // disable hardware flow control
  tty.c_cflag &= ~HUPCL;   // disable DST & RST (prevent system reset on UNO)
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