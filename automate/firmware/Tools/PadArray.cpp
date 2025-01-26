// C++ left and right padding of a char array
// by Ben Provenzano III - 05/27/23

#define printBufLen 1000
char printBuf[printBufLen];

// input string
char* msg = "Benjamin Provenzano III";
// padding length
uint32_t count = 80;
// padding character
char chr = '_';

void setup() {
  // serial interface
  Serial.begin(9600);
}

// left and right pad (string in, padding length, padding character, 0=right pad, 1=left pad)
void padArray(char* _str, uint32_t _padlen, char _pchr, bool _lr) {
  // clear buffer
  for(size_t i = 0; i < printBufLen; ++i){
    printBuf[i] = 0;
  } // init
  char _schr;
  uint32_t _outidx = 0;
  uint32_t _inlen = strlen(_str); // read string length
  uint32_t _slen = _inlen + _padlen; // output length padding + string 
  // loop character by character
  for (uint32_t i = 0; i < _slen; i++ ) {
    uint32_t _bpnt = 0;
    // padding break point
    if (_lr == 0){ 
      _bpnt = _inlen; // R (string length)
    } else {  
      _bpnt = _padlen; // L (padding length)
    } 
    if (i >= _bpnt){ // switch writing padding <-> string
      if (_lr == 0){ 
        _schr = _pchr;  // R (padding chars)
      } else {
        _schr = _str[i - _padlen]; // L (string after padding)
      }
    } else {
      if (_lr == 0){ 
        _schr = _str[i]; // R (string before padding)
      } else {  
        _schr = _pchr; // L (padding chars)
      }
    }
    // write each character to array
    printBuf[_outidx] = _schr;
    _outidx++;
  }  
}


void loop() {
  // loop 0 to padding length
  for (uint32_t i = 0; i < count ; i++ ) {
  	// left pad
    padArray(msg,i,chr,1);
    Serial.print(printBuf);
    Serial.println();
    Serial.println();
    // right pad
    padArray(msg,i,chr,0);
    Serial.print(printBuf);
    Serial.println();
    delay(20);
  }
  // loop padding length to 0
  for (uint32_t i = count; i > 0 ; i-- ) {
  	// left pad
    padArray(msg,i,chr,0);
    Serial.print(printBuf);
    Serial.println();
    Serial.println();
    // right pad
    padArray(msg,i,chr,1);
    Serial.print(printBuf);
    Serial.println();
    delay(20);
  }
}

