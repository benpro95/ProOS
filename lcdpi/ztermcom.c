/// Z-Terminal Serial Communication v1.0
/// for GNU/Linux kernel versions 5.0+  
/// by Ben Provenzano III - 07/01/2023

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h>
#include <ctype.h>
#include <sys/select.h>

// divide to whole number macro
#define ROUND_DIVIDE(numer, denom) (((numer) + (denom) / 2) / (denom))
// max buffer length
#define buffLen 128

// FIFO device
char input;
int fifo_fd = -1;
char *line = NULL;
const char *fifo_path = "/dev/zterm";
// serial device
int serial_port;
const char device[] = "/dev/ttyACM0"; 
// max serial data chunk bytes
const size_t maxCmdLength = 32;
// signature matching
const char sigChars[] = {"$?-|"}; // control mode
size_t sigMatches = 0;
size_t sigLen = 0;
// control data
char controlDat[6];
size_t controlCount = 0;
size_t controlLen = 0;
bool controlMode = 0;
// line output data
int writeLoops = 0;
size_t lineSize = 0;
size_t serCharBufSize = buffLen;
char serCharBuf[buffLen];
char rawData[buffLen];
char chunkBuf[buffLen];
size_t delayTime = 0; 
// flags
bool enableSend = 0;
bool readMode = 0;

  
void pauseExec() {
  // reading pause
  size_t _time = 5;
  if (readMode == 0) {
    // idle pause
     _time = 5000;
  }
  usleep(_time);
}


void controlParser() {
  size_t _dataint = 0;
  bool _notdigit = 0;
  // read 1st position then replace with zero
  char _ctlchar = controlDat[0];
  controlDat[0] = '0';
  // check data is numeric
  for (size_t i = 0; i < controlCount; i++) {
    if(!isdigit(controlDat[i])){
       _notdigit = 1;
    }
  } // cast to integer
  if(_notdigit == 0){
    _dataint = atoi(controlDat);
  }  
  // character delay
  if(_ctlchar == 'd'){
    printf("Setting delay: %zu\n", _dataint);
    delayTime = _dataint;
  }
  // clear display
  if(_ctlchar == 'c'){
  	char _datstr[3];
  	// convert clear int to char
  	sprintf(_datstr, "%zu", _dataint);
  	// build output string
  	rawData[0]='<';
  	strcat(rawData, _datstr);   
  	strcat(rawData, ",0,0>"); 
  	printf("Control data: %s\n", rawData);
  	size_t _size = sizeof(rawData);
  	write(serial_port, rawData, _size);
  	memset(rawData, 0, _size);
  	// clear line data
  	enableSend = 0;
  	writeLoops = 0;
  	line = realloc(line,1);
  	line[0] = '\0';
  	lineSize = 0;
  }
}


void readIn() {
  // increase dead time when not reading (reduce CPU load)
  pauseExec();
  // set a zero timeout for non-blocking check 
  fd_set rfds;
  FD_ZERO(&rfds);
  FD_SET(fifo_fd, &rfds);
  struct timeval tv;
  tv.tv_sec = 0;
  tv.tv_usec = 0;
  // check if there is data available to read from the FIFO
  int result = select(fifo_fd + 1, &rfds, NULL, NULL, &tv);
  // data is available 
  if (result > 0) {
    // read command line (stdin)
    ssize_t bytesRead = read(fifo_fd, &input, sizeof(input));
    // when a character is detected
    if (bytesRead > 0) {
      if (enableSend == 0) {
        // allocate memory
        line = realloc(line, (lineSize + 1));
      }
      //// newline is sent ////
      if (input == '\n') { 
        if (controlMode == 0) {
          if (enableSend == 0) {
            // calcuate transmission rounds
            if (lineSize <= 0) {
              lineSize = 1;
            } 
            writeLoops = 
              (ROUND_DIVIDE(lineSize,maxCmdLength) + 1);
            // enable transmit
            enableSend = 1;
            // terminate line
            line[lineSize] = '\0';
          }  
        } else { // control mode 
          controlParser();
        } 
        // reset control mode
        controlMode = 0;
        controlCount = 0;
        sigMatches = 0;
        lineSize = 0; 
        readMode = 0;     
      } else {
      //// any other chararacter is sent ////
        readMode = 1;
        if (enableSend == 0) {
          // write to line data array
          line[lineSize] = input; 
        }
        // detect control mode signature
        if (lineSize < sigLen) {
          // count matched characters
          if (input == sigChars[sigMatches]) {
            sigMatches = sigMatches + 1; 
            if (sigMatches >= sigLen){
              // all characters matched
              controlMode = 1;
            } 
          }  
        } // store control data after signature
        if (controlMode == 1) { 
          if (lineSize >= sigLen) { // skip over last signature char
            if (lineSize < (sigLen + controlLen)) { // do not allow overflow 
              // write each character to array
              controlDat[controlCount] = input;
              controlDat[controlCount + 1] = '\0';
              controlCount++;
            }
          }
        }
        // increment index
        //printf("Read: %c\n", input);
        lineSize++; 
      }
    }
  }
}


int setSerialNonBlock(int fd) {
  int flags = fcntl(fd, F_GETFL, 0);
  if (flags == -1) {
      return -1;
  }
  return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}


int serialRead() {
 // Read from the serial port in a loop
 char target_char = '*';
 bool _return = 0;
 printf("Waiting for acknowledge...\n");
 while(1) {
    // set serial port to non-blocking mode
    if (setSerialNonBlock(serial_port) == -1) {
      perror("Failed to set serial port to non-blocking mode");
      return 1;
    }
    // read serial port
    ssize_t num_bytes = read(serial_port, serCharBuf, serCharBufSize);
    // check if the serial port is available
    if (access(device, F_OK) != 0) {
      printf("Serial port not available\n");
      return 1;
    }
    if (num_bytes > 0) {
      // Check if the target character is received
      size_t i;
      for (i = 0; i < num_bytes; i++) {
        // check for input
        if (serCharBuf[i] == target_char) {
          printf("Received acknowledge '%c'\n", target_char);
          return 0;
        }
      }
    } else {
      // no data available, continue reading input
      if (errno == EAGAIN || errno == EWOULDBLOCK) {
        // continue to read input (non-blocking)
        readIn();
      } else {
        // error occurred
        printf("Failed to read serial port\n");
        return 1;
      }
    }
  }
}


int serialWrite() {
  int status = 0;
  // check if the serial port is available
  if (access(device, F_OK) != 0) {
    printf("Serial port not available\n");
    return 1;
  }
  int i;
  size_t startpos = 0;
  // write max-char segments
  for (i = 1; i <= writeLoops; ++i) {
    char delaystr[8];
    // read / convert delay data
    sprintf(delaystr, "%zu", delayTime);
    // build output string
    rawData[0]='<';
    strcat(rawData, "0,"); 
    strcat(rawData, delaystr);    
    strcat(rawData, ",");
    if (writeLoops > 1) {
      strncpy(chunkBuf, line + (startpos), maxCmdLength);
      startpos = startpos + maxCmdLength;
      strcat(rawData, chunkBuf); 
      strcat(rawData, ">"); 
    } else {
      strcat(rawData, line);  
      strcat(rawData, ">"); 
    }
    printf("Serial Data: %s\n", rawData);
    // write to the serial port
    write(serial_port, rawData, sizeof(rawData)); 
    // deallocate buffers
    memset(rawData, 0, sizeof(rawData));
    memset(chunkBuf, 0, sizeof(chunkBuf));
    // wait for response
    status = serialRead();
    // exit loop if reset
    if (enableSend == 0) {
      break;
    }      
  }
  return status;
}


int main() {
  // determine array lengths 
  controlLen = (sizeof(controlDat) - 1);
  sigLen = (sizeof(sigChars) - 1);  
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
  // set the baud rate (for example, 9600)
  cfsetospeed(&tty, B9600);
  cfsetispeed(&tty, B9600);
  // set other settings (8N1)
  tty.c_cflag &= ~PARENB;  // Disable parity bit
  tty.c_cflag &= ~CSTOPB;  // Set one stop bit
  tty.c_cflag &= ~CSIZE;   // Clear data size bits
  tty.c_cflag |= CS8;      // Set 8 data bits
  tty.c_cflag &= ~CRTSCTS; // Disable hardware flow control
  // apply the serial settings
  if (tcsetattr(serial_port, TCSANOW, &tty) != 0) {
    perror("Error applying serial port settings");
    return 1;
  } 
  // open the FIFO buffer in non-blocking mode
  fifo_fd = open(fifo_path, O_RDONLY | O_NONBLOCK);
  if (fifo_fd == -1) {
      perror("Failed to open FIFO");
      return 1;
  }
  // program status 
  int status = 0;
  printf("Z-Terminal Xmit v1.0\n");
  // wait for boot response
  status = serialRead();
  // main loop
  while(1) {
    // read FIFO (not-blocking)
    readIn();
    // transmit to serial
    if (enableSend == 1) {
       status = serialWrite();
       enableSend = 0;
    }
    // error occured
    if (status == 1) {
      // close the serial port
      close(serial_port);
      // close FIFO
      close(fifo_fd);
      break;
    }
  }
  return status;
}