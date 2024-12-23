/////////////////////////////////////////////////////////////////////////
/// Z-Terminal Serial Communication v1.0
/// for GNU/Linux kernel versions 5.0+  
/// by Ben Provenzano III - 07/01/2023
/////////////////////////////////////////////////////////////////////////

// Libraries //
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h>
#include <ctype.h>

// max buffer length
#define buffLen 32

// FIFO device
char input;
int fifo_fd = -1;
char *line = NULL;
const char *fifo_path = "/dev/zterm";
// serial device
int serial_port;
const char device[] = "/dev/zterm-tty"; 
// max serial data chunk bytes
const size_t maxCmdLength = 16;
// signature matching
const char sigChars[] = {"$?-|"}; // control mode
size_t sigMatches = 0;
size_t sigLen = 0;
// control data
char controlDat[buffLen];
size_t controlCount = 0;
size_t controlLen = 0;
bool controlMode = 0;
// line output data
size_t lineSize = 0;
size_t writeLineSize = 0;
char serCharBuf[buffLen];
// flags
size_t enableSend = 0;
bool readMode = 0;
//////////////////

  
void pauseExec() {
  // reading pause
  size_t _time = 10;
  if (readMode == 0) {
    // idle pause
     _time = 5000;
  }
  usleep(_time);
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


void controlParser() {
  char _rawData[buffLen];
  size_t _datint = 0;
  size_t _cmdint = 0;
  bool _notdigit = 0;
  bool _write = 0;
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
    _datint = atoi(controlDat);
  }  
  // character delay
  if(_ctlchar == 'd'){
    // register select
    _cmdint = 4; 
    // send command
    _write = 1; 
  }
  // backlight mode
  if(_ctlchar == 'b'){
    // register select
    _cmdint = 5; 
    // send command
    _write = 1; 
  }  
  // clear display
  if(_ctlchar == 'c'){
    // erase display register
    if(_datint < 4){
      // clear line data
      clearLine();
      if(_datint != 0){
        _cmdint = _datint;
        // send command
        _write = 1;
      }  
    } // no data sent
    _datint = 0;
  } // write serial port
  if(_write == 1){
    char _cmdstr[10];
    char _datstr[10];
    // cast integers to chars
    sprintf(_cmdstr, "%zu", _cmdint);
    sprintf(_datstr, "%zu", _datint);
    // build output string
    _rawData[0]='<';
    _rawData[1]='\0';
    strcat(_rawData, _cmdstr);   
    strcat(_rawData, ","); 
    strcat(_rawData, _datstr);  
    strcat(_rawData, ",>"); 
    printf("Control data: %s\n", _rawData);
    // transmit
    usleep(10000);
    write(serial_port, _rawData, buffLen);
    usleep(10000);
    memset(_rawData, 0, buffLen);
    _write = 0;
  }
}


void controlDetect() {
// detect control mode signature
  if (lineSize < sigLen) {
    // count matched characters
    if (input == sigChars[sigMatches]) {
      sigMatches = sigMatches + 1; 
      if (sigMatches >= sigLen){
        // all characters matched enable
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
}


void eofAction() {
  if (readMode == 1) {
/// action runs when EOF is detected    
    if (controlMode == 0) { // not in control mode
      if (enableSend == 0) { // not currently sending
        if (lineSize > 0) { // one character or more
          // enable transmit
          writeLineSize = lineSize;
          if (lineSize == 1){
            enableSend = 2; // single character (no delay)
          } else {
            enableSend = 1;
          } 
        }
        // terminate line (add extra nulls)
        for (size_t i = 0; i < buffLen * 2; i++) {
          line = realloc(line, (lineSize + 1));
          line[lineSize] = '\0';
          lineSize++;
        }
      }  
    } else { // control mode 
      controlParser();
    } 
    // reset counters
    controlMode = 0;
    controlCount = 0;
    sigMatches = 0;
    lineSize = 0;    
    readMode = 0;
  }
}  


void readIn() {
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
    // EOF detected
    if (bytesRead <= 0) {
      eofAction();
    }
    // when a character is detected
    if (bytesRead > 0) {
      // detect control mode (1st)
      if (input != '\r' && input != '\n') {
        controlDetect();
        // when not in send mode
        if (enableSend == 0) { // (2nd)
          // allocate memory
          line = realloc(line, (lineSize + 1));
          // write to line data array
          line[lineSize] = input;
        }
        //printf("Read: %c\n", input);
        // increment index
        lineSize++;
        // active read
        readMode = 1;
      }  
    }  
  }
  // increase dead time when not reading (reduce CPU load)
  pauseExec();
}


int serialRead() {
 // Read from the serial port in a loop
 char target_char = '*';
 bool _return = 0;
 printf("Waiting for acknowledge...\n");
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
      bool ack_resp = false;
      for (i = 0; i < num_bytes; i++) {
        // read response
        char _curchar = serCharBuf[i];
        if (_curchar != '\n') {
          printf("%c", _curchar);
        }
        // check target character is received
        if (serCharBuf[i] == target_char) {
          ack_resp = true;
        }
      }
      if (ack_resp == true) {
        printf("\nReceived response.\n\n\n");
        return 0;
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
  size_t _delay = 1;
  // write data in chunks
  for (int i = 0; i < writeLineSize; i += maxCmdLength) {
  	// define buffers
    char _chunkBuf[buffLen];
    char _rawData[buffLen];
    _chunkBuf[0] = '\0';
    _rawData[0] = '\0';
    // no delay mode
    if (enableSend == 2) {
      _delay = 0; 
    }
    // convert delay data
    char _delaystr[10];
    sprintf(_delaystr, "%zu", _delay);
    // build output string
    strcat(_rawData, "<0,"); 
    strcat(_rawData, _delaystr); 
    strcat(_rawData, ",");
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
  // set the baud rate 
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
  printf("Z-Terminal Xmit v1.11\n");
  // main loop
  while(1) {
    // read FIFO (not-blocking)
    readIn();
    // transmit to serial
    if (enableSend > 0) {
       status = serialWrite();
       clearLine();
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