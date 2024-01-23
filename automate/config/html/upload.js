 function upload(file) {
            var blob = file;
            var BYTES_PER_CHUNK = 128; 
            var SIZE = file.size;               
            var start = 0;
            var end = BYTES_PER_CHUNK;
            var completed = 0;
            var count = SIZE % BYTES_PER_CHUNK == 0 ? SIZE / BYTES_PER_CHUNK : Math.floor(SIZE / BYTES_PER_CHUNK) + 1;
            var index = 1;
            while (start < SIZE) {
                var chunk = blob.slice(start, end);
                var data = new FormData();
                data.append("TOTAL_CHUNK", count);
                data.append("CHUNK_INDEX", index++);
                data.append("CHUNK", chunk);

                var xhr = new XMLHttpRequest();
                xhr.open("POST", "UploadChunks", true);
                xhr.setRequestHeader("Content-Type", "multipart/form-data");
                xhr.send(data);

               /* fetch("/UploadFile/MultiUpload", {
                    method: 'post',
                    body: data
                });*/
                   
                start = end
                end = start + BYTES_PER_CHUNK;
            }   
        }     
