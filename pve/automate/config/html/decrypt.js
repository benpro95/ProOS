import fetch, {
  Blob,
  blobFrom,
  blobFromSync,
  File,
  fileFrom,
  fileFromSync,
  FormData,
  Headers,
  Request,
  Response,
} from 'node-fetch'

if (!globalThis.fetch) {
  globalThis.fetch = fetch
  globalThis.Headers = Headers
  globalThis.Request = Request
  globalThis.Response = Response
}

// read hash as input
const myArgs = process.argv.slice(2);

var saltValue = "";
var hash = myArgs[0];

async function runMain() {
    let res = null;
    try {
        res = await Promise.all([
            loadSalt(),
            decrypt()
        ]);
    } catch (err) {
        console.log('Salt read fail >>', res, err);
    }
  saltValue = null;
}

async function loadSalt() {
  saltValue = myArgs[1];
};

async function decrypt() {
  //To decipher, you need to create a decipher and use it:
  var decrypted = null;
  const myDecipher = decipher(saltValue);
  decrypted = (myDecipher(hash));
  console.log(decrypted);
};


const cipher = salt => {
    const textToChars = text => text.split('').map(c => c.charCodeAt(0));
    const byteHex = n => ("0" + Number(n).toString(16)).substr(-2);
    const applySaltToChar = code => textToChars(salt).reduce((a,b) => a ^ b, code);

    return text => text.split('')
      .map(textToChars)
      .map(applySaltToChar)
      .map(byteHex)
      .join('');
}

const decipher = salt => {
    const textToChars = text => text.split('').map(c => c.charCodeAt(0));
    const applySaltToChar = code => textToChars(salt).reduce((a,b) => a ^ b, code);
    return encoded => encoded.match(/.{1,2}/g)
      .map(hex => parseInt(hex, 16))
      .map(applySaltToChar)
      .map(charCode => String.fromCharCode(charCode))
      .join('');
}

runMain();
